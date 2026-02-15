const Allocator = std.mem.Allocator;

pub const XdrDecodingError = error{
    InvalidEnumValue,
    InvalidUnionDiscriminant,
    InvalidPadding,
    Overflow,
    EndOfStream,
    OutOfMemory,
};

pub const XdrEncodingError = error{
    OutOfMemory,
};

pub fn BoundedArray(comptime T: type, comptime max_len: usize) type {
    return struct {
        data: []T,
        max: usize = max_len,

        const Self = @This();

        pub fn init(data: []T) !Self {
            if (data.len > max_len) return error.Overflow;
            return Self{ .data = data };
        }
    };
}

/// Generic XDR decode dispatch. Handles primitives and delegates to
/// T.xdrDecode for compound types.
pub fn xdrDecode(comptime T: type, allocator: Allocator, reader: anytype) !T {
    if (T == bool) {
        const v = try reader.readInt(i32, .big);
        return v != 0;
    }
    if (T == i32) return try reader.readInt(i32, .big);
    if (T == u32) return try reader.readInt(u32, .big);
    if (T == i64) return try reader.readInt(i64, .big);
    if (T == u64) return try reader.readInt(u64, .big);
    if (T == f32) return @bitCast(try reader.readInt(u32, .big));
    if (T == f64) return @bitCast(try reader.readInt(u64, .big));
    if (@hasDecl(T, "xdrDecode")) return try T.xdrDecode(allocator, reader);
    @compileError("xdrDecode: unsupported type " ++ @typeName(T));
}

/// Generic XDR encode dispatch. Handles primitives and delegates to
/// T.xdrEncode for compound types.
pub fn xdrEncode(comptime T: type, writer: anytype, value: T) !void {
    if (T == bool) {
        try writer.writeInt(i32, if (value) @as(i32, 1) else @as(i32, 0), .big);
        return;
    }
    if (T == i32) { try writer.writeInt(i32, value, .big); return; }
    if (T == u32) { try writer.writeInt(u32, value, .big); return; }
    if (T == i64) { try writer.writeInt(i64, value, .big); return; }
    if (T == u64) { try writer.writeInt(u64, value, .big); return; }
    if (T == f32) { try writer.writeInt(u32, @bitCast(value), .big); return; }
    if (T == f64) { try writer.writeInt(u64, @bitCast(value), .big); return; }
    if (@hasDecl(T, "xdrEncode")) { try value.xdrEncode(writer); return; }
    @compileError("xdrEncode: unsupported type " ++ @typeName(T));
}
