//! Type resolution, reference computation, and attribute generation.

use crate::ast::{Definition, Size, Type, XdrSpec};
use heck::{ToSnakeCase, ToUpperCamelCase};
use std::collections::{HashMap, HashSet};

/// Configuration options for code generation.
#[derive(Debug, Clone, Default)]
pub struct Options {
    /// Types that have custom Default implementations (skip derive(Default))
    pub custom_default_impl: HashSet<String>,
    /// Types that have custom FromStr/Display implementations (use SerializeDisplay)
    pub custom_str_impl: HashSet<String>,
    /// Types that should NOT have Display/FromStr/schemars generated (have special handling elsewhere)
    pub no_display_fromstr: HashSet<String>,
}

/// Type information collected from the XDR spec.
pub struct TypeInfo {
    /// All type names defined in the spec
    pub type_names: HashSet<String>,
    /// Map from type name to its definition
    pub definitions: HashMap<String, Definition>,
    /// Map from type name to the types it references in its fields
    pub type_field_types: HashMap<String, Vec<String>>,
    /// Map from const name to its value
    pub const_values: HashMap<String, i64>,
}

impl TypeInfo {
    /// Build type information from an XDR spec.
    pub fn build(spec: &XdrSpec) -> Self {
        let mut type_names = HashSet::new();
        let mut definitions = HashMap::new();
        let mut type_field_types: HashMap<String, Vec<String>> = HashMap::new();
        let mut const_values = HashMap::new();

        // Collect all definitions
        for def in spec.all_definitions() {
            let name = rust_type_name(def.name());
            type_names.insert(name.clone());
            definitions.insert(name.clone(), def.clone());

            // Collect field types for cyclic detection
            let field_types = collect_field_types(def);
            type_field_types.insert(name, field_types);

            // Collect const values
            if let Definition::Const(c) = def {
                const_values.insert(c.name.clone(), c.value);
            }
        }

        Self {
            type_names,
            definitions,
            type_field_types,
            const_values,
        }
    }

    /// Resolve a size to a string, using const values for named sizes.
    pub fn size_to_literal(&self, size: &Size) -> String {
        match size {
            Size::Literal(n) => n.to_string(),
            Size::Named(name) => {
                // Look up the const value and return the literal
                if let Some(&value) = self.const_values.get(name) {
                    value.to_string()
                } else {
                    // Fallback to the name if not found (shouldn't happen)
                    rust_type_name(name)
                }
            }
        }
    }

    /// Check if `type_with_fields` has a cyclic reference to `target_type`.
    pub fn is_cyclic(&self, type_with_fields: &str, target_type: &str) -> bool {
        self.is_cyclic_inner(type_with_fields, target_type, &mut HashSet::new())
    }

    fn is_cyclic_inner(
        &self,
        type_with_fields: &str,
        target_type: &str,
        seen: &mut HashSet<String>,
    ) -> bool {
        if seen.contains(type_with_fields) {
            return false;
        }
        seen.insert(type_with_fields.to_string());

        if let Some(field_types) = self.type_field_types.get(type_with_fields) {
            for ft in field_types {
                if ft == target_type {
                    return true;
                }
                if self.is_cyclic_inner(ft, target_type, seen) {
                    return true;
                }
            }
        }
        false
    }
}

// =============================================================================
// Public API functions - main exports used by generator
// =============================================================================

/// Convert an XDR name to a Zig type name (UpperCamelCase).
pub fn rust_type_name(name: &str) -> String {
    let name = escape_name(name);
    name.to_upper_camel_case()
}

/// Convert an XDR name to a Zig field name (snake_case).
pub fn rust_field_name(name: &str) -> String {
    let snake = name.to_snake_case();
    // Apply escape AFTER snake_case since to_snake_case strips trailing underscores
    escape_field_name(&snake)
}

/// Get the Zig type reference for an XDR type.
pub fn rust_type_ref(type_: &Type, parent_type: Option<&str>, type_info: &TypeInfo) -> String {
    let base = base_rust_type_ref_with_info(type_, type_info);

    // Check for cyclic reference (only for simple and optional types)
    let is_cyclic = if let Some(parent) = parent_type {
        if let Some(base_name) = base_type_name(type_) {
            type_info.is_cyclic(&base_name, parent)
        } else {
            false
        }
    } else {
        false
    };

    match type_ {
        Type::Optional(inner) => {
            let inner_ref = base_rust_type_ref_with_info(inner, type_info);
            if is_cyclic {
                format!("?*{inner_ref}")
            } else {
                format!("?{inner_ref}")
            }
        }
        Type::Array { element_type, size } => {
            let elem = base_rust_type_ref_with_info(element_type, type_info);
            let size = type_info.size_to_literal(size);
            format!("[{size}]{elem}")
        }
        Type::VarArray {
            element_type,
            max_size,
        } => {
            let elem = base_rust_type_ref_with_info(element_type, type_info);
            match max_size {
                Some(size) => format!("BoundedArray({elem}, {})", type_info.size_to_literal(size)),
                None => format!("[]{elem}"),
            }
        }
        _ => {
            if is_cyclic {
                format!("*{base}")
            } else {
                base
            }
        }
    }
}

/// Get the base Zig type reference (without pointer/optional wrapping).
pub fn base_rust_type_ref(type_: &Type) -> String {
    match type_ {
        Type::Int => "i32".to_string(),
        Type::UnsignedInt => "u32".to_string(),
        Type::Hyper => "i64".to_string(),
        Type::UnsignedHyper => "u64".to_string(),
        Type::Float => "f32".to_string(),
        Type::Double => "f64".to_string(),
        Type::Bool => "bool".to_string(),
        Type::OpaqueFixed(size) => format!("[{}]u8", size_to_zig(size)),
        Type::OpaqueVar(max) => match max {
            Some(size) => format!("BoundedArray(u8, {})", size_to_zig(size)),
            None => "[]u8".to_string(),
        },
        Type::String(max) => match max {
            Some(size) => format!("BoundedArray(u8, {})", size_to_zig(size)),
            None => "[]u8".to_string(),
        },
        Type::Ident(name) => rust_type_name(name),
        Type::Optional(inner) => format!("?{}", base_rust_type_ref(inner)),
        Type::Array { element_type, size } => {
            format!(
                "[{}]{}",
                size_to_zig(size),
                base_rust_type_ref(element_type),
            )
        }
        Type::VarArray {
            element_type,
            max_size,
        } => {
            let elem = base_rust_type_ref(element_type);
            match max_size {
                Some(size) => format!("BoundedArray({elem}, {})", size_to_zig(size)),
                None => format!("[]{elem}"),
            }
        }
        Type::AnonymousUnion {
            discriminant, arms, ..
        } => {
            panic!(
                "AnonymousUnion should have been extracted during parsing. \
                 Discriminant: {:?}, Arms count: {}",
                discriminant.name,
                arms.len()
            )
        }
    }
}

/// Get the type to use in a decode call.
pub fn rust_read_call_type(
    type_: &Type,
    parent_type: Option<&str>,
    type_info: &TypeInfo,
) -> String {
    rust_type_ref(type_, parent_type, type_info)
}

/// Get the element type for an array/opaque.
pub fn element_type_for_vec(type_: &Type) -> String {
    match type_ {
        Type::OpaqueFixed(_) | Type::OpaqueVar(_) | Type::String(_) => "u8".to_string(),
        Type::Array { element_type, .. } | Type::VarArray { element_type, .. } => {
            base_rust_type_ref(element_type)
        }
        Type::Ident(name) => rust_type_name(name),
        _ => "u8".to_string(),
    }
}

/// Get the serde_as type for i64/u64 fields.
/// Returns None - not applicable for Zig output.
pub fn serde_as_type(_type_: &Type) -> Option<String> {
    None
}

// =============================================================================
// Type classification utilities
// =============================================================================

/// Check if a type is a builtin (maps directly to a Zig primitive).
pub fn is_builtin_type(type_: &Type) -> bool {
    matches!(
        type_,
        Type::Int
            | Type::UnsignedInt
            | Type::Hyper
            | Type::UnsignedHyper
            | Type::Float
            | Type::Double
            | Type::Bool
    )
}

/// Check if a type is a fixed-length opaque array.
pub fn is_fixed_opaque(type_: &Type) -> bool {
    matches!(type_, Type::OpaqueFixed(_))
}

/// Check if a type is a fixed-length array (including fixed opaque).
pub fn is_fixed_array(type_: &Type) -> bool {
    matches!(type_, Type::OpaqueFixed(_) | Type::Array { .. })
}

/// Check if a type is a variable-length array.
pub fn is_var_array(type_: &Type) -> bool {
    matches!(
        type_,
        Type::OpaqueVar(_) | Type::String(_) | Type::VarArray { .. }
    )
}

// =============================================================================
// Internal utilities
// =============================================================================

/// Collect the base type names referenced in a definition's fields.
fn collect_field_types(def: &Definition) -> Vec<String> {
    match def {
        Definition::Struct(s) => s
            .members
            .iter()
            .filter_map(|m| base_type_name(&m.type_))
            .collect(),
        Definition::Union(u) => u
            .arms
            .iter()
            .filter_map(|arm| arm.type_.as_ref().and_then(base_type_name))
            .collect(),
        Definition::Typedef(_) | Definition::Enum(_) | Definition::Const(_) => vec![],
    }
}

/// Get the base type name from a Type (for cyclic detection).
fn base_type_name(type_: &Type) -> Option<String> {
    match type_ {
        Type::Ident(name) => Some(rust_type_name(name)),
        Type::Optional(inner) => base_type_name(inner),
        Type::Array { element_type, .. } => base_type_name(element_type),
        Type::VarArray { element_type, .. } => base_type_name(element_type),
        _ => None,
    }
}

/// Get the base Zig type reference with type_info for resolving const sizes to literals.
fn base_rust_type_ref_with_info(type_: &Type, type_info: &TypeInfo) -> String {
    match type_ {
        Type::Int => "i32".to_string(),
        Type::UnsignedInt => "u32".to_string(),
        Type::Hyper => "i64".to_string(),
        Type::UnsignedHyper => "u64".to_string(),
        Type::Float => "f32".to_string(),
        Type::Double => "f64".to_string(),
        Type::Bool => "bool".to_string(),
        Type::OpaqueFixed(size) => format!("[{}]u8", type_info.size_to_literal(size)),
        Type::OpaqueVar(max) => match max {
            Some(size) => format!("BoundedArray(u8, {})", type_info.size_to_literal(size)),
            None => "[]u8".to_string(),
        },
        Type::String(max) => match max {
            Some(size) => format!("BoundedArray(u8, {})", type_info.size_to_literal(size)),
            None => "[]u8".to_string(),
        },
        Type::Ident(name) => rust_type_name(name),
        Type::Optional(inner) => {
            format!("?{}", base_rust_type_ref_with_info(inner, type_info))
        }
        Type::Array { element_type, size } => {
            format!(
                "[{}]{}",
                type_info.size_to_literal(size),
                base_rust_type_ref_with_info(element_type, type_info),
            )
        }
        Type::VarArray {
            element_type,
            max_size,
        } => {
            let elem = base_rust_type_ref_with_info(element_type, type_info);
            match max_size {
                Some(size) => format!("BoundedArray({elem}, {})", type_info.size_to_literal(size)),
                None => format!("[]{elem}"),
            }
        }
        Type::AnonymousUnion {
            discriminant, arms, ..
        } => {
            panic!(
                "AnonymousUnion should have been extracted during parsing. \
                 Discriminant: {:?}, Arms count: {}",
                discriminant.name,
                arms.len()
            )
        }
    }
}

fn size_to_zig(size: &Size) -> String {
    match size {
        Size::Literal(n) => n.to_string(),
        Size::Named(name) => rust_type_name(name),
    }
}

/// Escape reserved names for type names.
fn escape_name(name: &str) -> String {
    match name {
        "type" => "type_".to_string(),
        "Error" => "SError".to_string(),
        _ => name.to_string(),
    }
}

/// Escape reserved names for field names (after snake_case conversion).
fn escape_field_name(name: &str) -> String {
    match name {
        "type" => "@\"type\"".to_string(),
        "error" => "@\"error\"".to_string(),
        "return" => "@\"return\"".to_string(),
        _ => name.to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rust_type_name() {
        assert_eq!(rust_type_name("public_key"), "PublicKey");
        assert_eq!(
            rust_type_name("PUBLIC_KEY_TYPE_ED25519"),
            "PublicKeyTypeEd25519"
        );
    }

    #[test]
    fn test_rust_field_name() {
        assert_eq!(rust_field_name("publicKey"), "public_key");
        assert_eq!(rust_field_name("type"), "@\"type\"");
    }

    #[test]
    fn test_base_rust_type_ref() {
        assert_eq!(base_rust_type_ref(&Type::Int), "i32");
        assert_eq!(base_rust_type_ref(&Type::UnsignedHyper), "u64");
        assert_eq!(
            base_rust_type_ref(&Type::OpaqueFixed(Size::Literal(32))),
            "[32]u8"
        );
    }
}
