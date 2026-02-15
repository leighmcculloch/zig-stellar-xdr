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

        pub fn xdrDecode(allocator: Allocator, reader: anytype) anyerror!Self {
            const len = try reader.readInt(u32, .big);
            if (len > max_len) return error.Overflow;
            if (T == u8) {
                const data = try allocator.alloc(u8, len);
                try reader.readNoEof(data);
                const padding = (4 -% (len % 4)) % 4;
                var i: u32 = 0;
                while (i < padding) : (i += 1) {
                    _ = try reader.readByte();
                }
                return Self{ .data = data };
            } else {
                const data = try allocator.alloc(T, len);
                for (data) |*item| {
                    item.* = try xdrDecodeGeneric(T, allocator, reader);
                }
                return Self{ .data = data };
            }
        }

        pub fn xdrEncode(self: Self, writer: anytype) anyerror!void {
            const len: u32 = @intCast(self.data.len);
            try writer.writeInt(u32, len, .big);
            if (T == u8) {
                try writer.writeAll(self.data);
                const padding = (4 -% (len % 4)) % 4;
                var i: u32 = 0;
                while (i < padding) : (i += 1) {
                    try writer.writeByte(0);
                }
            } else {
                for (self.data) |item| {
                    try xdrEncodeGeneric(T, writer, item);
                }
            }
        }
    };
}

/// Generic XDR decode dispatch. Handles primitives, fixed arrays, optionals,
/// slices, pointers, and delegates to T.xdrDecode for compound types.
pub fn xdrDecode(comptime T: type, allocator: Allocator, reader: anytype) anyerror!T {
    return xdrDecodeGeneric(T, allocator, reader);
}

fn xdrDecodeGeneric(comptime T: type, allocator: Allocator, reader: anytype) anyerror!T {
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

    const info = @typeInfo(T);

    // Fixed-size arrays [N]T
    if (info == .array) {
        const child = info.array.child;
        const len = info.array.len;
        if (child == u8) {
            var result: [len]u8 = undefined;
            try reader.readNoEof(&result);
            const padding = (4 -% (len % 4)) % 4;
            comptime var i: usize = 0;
            inline while (i < padding) : (i += 1) {
                _ = try reader.readByte();
            }
            return result;
        } else {
            var result: [len]child = undefined;
            for (&result) |*item| {
                item.* = try xdrDecodeGeneric(child, allocator, reader);
            }
            return result;
        }
    }

    // Optional ?T
    if (info == .optional) {
        const flag = try reader.readInt(i32, .big);
        if (flag != 0) {
            return try xdrDecodeGeneric(info.optional.child, allocator, reader);
        }
        return null;
    }

    // Slices []T (variable-length, unbounded)
    if (info == .pointer and info.pointer.size == .slice) {
        const len = try reader.readInt(u32, .big);
        const child = info.pointer.child;
        if (child == u8) {
            const data = try allocator.alloc(u8, len);
            try reader.readNoEof(data);
            const padding = (4 -% (len % 4)) % 4;
            var i: u32 = 0;
            while (i < padding) : (i += 1) {
                _ = try reader.readByte();
            }
            return data;
        } else {
            const data = try allocator.alloc(child, len);
            for (data) |*item| {
                item.* = try xdrDecodeGeneric(child, allocator, reader);
            }
            return data;
        }
    }

    // Single pointer *T (for cyclic/boxed types)
    if (info == .pointer and info.pointer.size == .one) {
        const ptr = try allocator.create(info.pointer.child);
        ptr.* = try xdrDecodeGeneric(info.pointer.child, allocator, reader);
        return ptr;
    }

    // Compound types with xdrDecode method
    if (@hasDecl(T, "xdrDecode")) return try T.xdrDecode(allocator, reader);

    @compileError("xdrDecode: unsupported type " ++ @typeName(T));
}

/// Generic XDR encode dispatch. Handles primitives, fixed arrays, optionals,
/// slices, pointers, and delegates to T.xdrEncode for compound types.
pub fn xdrEncode(comptime T: type, writer: anytype, value: T) anyerror!void {
    return xdrEncodeGeneric(T, writer, value);
}

fn xdrEncodeGeneric(comptime T: type, writer: anytype, value: T) anyerror!void {
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

    const info = @typeInfo(T);

    // Fixed-size arrays [N]T
    if (info == .array) {
        const child = info.array.child;
        const len = info.array.len;
        if (child == u8) {
            try writer.writeAll(&value);
            const padding = (4 -% (len % 4)) % 4;
            comptime var i: usize = 0;
            inline while (i < padding) : (i += 1) {
                try writer.writeByte(0);
            }
        } else {
            for (value) |item| {
                try xdrEncodeGeneric(child, writer, item);
            }
        }
        return;
    }

    // Optional ?T
    if (info == .optional) {
        if (value) |v| {
            try writer.writeInt(i32, 1, .big);
            try xdrEncodeGeneric(info.optional.child, writer, v);
        } else {
            try writer.writeInt(i32, 0, .big);
        }
        return;
    }

    // Slices []T (variable-length, unbounded)
    if (info == .pointer and info.pointer.size == .slice) {
        const len: u32 = @intCast(value.len);
        try writer.writeInt(u32, len, .big);
        const child = info.pointer.child;
        if (child == u8) {
            try writer.writeAll(value);
            const padding = (4 -% (len % 4)) % 4;
            var i: u32 = 0;
            while (i < padding) : (i += 1) {
                try writer.writeByte(0);
            }
        } else {
            for (value) |item| {
                try xdrEncodeGeneric(child, writer, item);
            }
        }
        return;
    }

    // Single pointer *T (for cyclic/boxed types)
    if (info == .pointer and info.pointer.size == .one) {
        try xdrEncodeGeneric(info.pointer.child, writer, value.*);
        return;
    }

    // Compound types with xdrEncode method
    if (@hasDecl(T, "xdrEncode")) { try value.xdrEncode(writer); return; }

    @compileError("xdrEncode: unsupported type " ++ @typeName(T));
}
