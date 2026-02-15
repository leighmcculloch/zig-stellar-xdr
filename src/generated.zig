// Generated from:
//  xdr/Stellar-SCP.x
//  xdr/Stellar-contract-config-setting.x
//  xdr/Stellar-contract-env-meta.x
//  xdr/Stellar-contract-meta.x
//  xdr/Stellar-contract-spec.x
//  xdr/Stellar-contract.x
//  xdr/Stellar-exporter.x
//  xdr/Stellar-internal.x
//  xdr/Stellar-ledger-entries.x
//  xdr/Stellar-ledger.x
//  xdr/Stellar-overlay.x
//  xdr/Stellar-transaction.x
//  xdr/Stellar-types.x

const std = @import("std");

/// `XDR_FILES_SHA256` is a list of pairs of source files and their SHA256 hashes.
pub const XDR_FILES_SHA256 = [_]struct { []const u8, []const u8 }{
    .{ "xdr/Stellar-SCP.x", "6aed428fb6c2d000f5bc1eef0ba685d6108f3faa96208ffa588c0e2990813939" },
    .{ "xdr/Stellar-contract-config-setting.x", "26c2c761d5e175c8b2f373611c942ef4484a6cd33f142f69638b2df82be85313" },
    .{ "xdr/Stellar-contract-env-meta.x", "75a271414d852096fea3283c63b7f2a702f2905f78fc28eb60ec7d7bd366a780" },
    .{ "xdr/Stellar-contract-meta.x", "f01532c11ca044e19d9f9f16fe373e9af64835da473be556b9a807ee3319ae0d" },
    .{ "xdr/Stellar-contract-spec.x", "7d99679155f6ce029f4f2bd8e1bf09524ef2f3e4ca8973265085cfcfdbdae987" },
    .{ "xdr/Stellar-contract.x", "dce61df115c93fef5bb352beac1b504a518cb11dcb8ee029b1bb1b5f8fe52982" },
    .{ "xdr/Stellar-exporter.x", "a00c83d02e8c8382e06f79a191f1fb5abd097a4bbcab8481c67467e3270e0529" },
    .{ "xdr/Stellar-internal.x", "227835866c1b2122d1eaf28839ba85ea7289d1cb681dda4ca619c2da3d71fe00" },
    .{ "xdr/Stellar-ledger-entries.x", "5157cad76b008b3606fe5bc2cfe87596827d8e02d16cbec3cedc297bb571aa54" },
    .{ "xdr/Stellar-ledger.x", "cf936606885dd265082e553aa433c2cf47b720b6d58839b154cf71096b885d1e" },
    .{ "xdr/Stellar-overlay.x", "8c9b9c13c86fa4672f03d741705b41e7221be0fc48e1ea6eeb1ba07d31ec0723" },
    .{ "xdr/Stellar-transaction.x", "7c4c951f233ad7cdabedd740abd9697626ec5bc03ce97bf60cbaeee1481a48d1" },
    .{ "xdr/Stellar-types.x", "4d7a1d1f1fa0034ddbff27d8a533e59b6154bef295306c6256066def77a5a999" },
};

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
    if (T == i32) {
        try writer.writeInt(i32, value, .big);
        return;
    }
    if (T == u32) {
        try writer.writeInt(u32, value, .big);
        return;
    }
    if (T == i64) {
        try writer.writeInt(i64, value, .big);
        return;
    }
    if (T == u64) {
        try writer.writeInt(u64, value, .big);
        return;
    }
    if (T == f32) {
        try writer.writeInt(u32, @bitCast(value), .big);
        return;
    }
    if (T == f64) {
        try writer.writeInt(u64, @bitCast(value), .big);
        return;
    }

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
    if (@hasDecl(T, "xdrEncode")) {
        try value.xdrEncode(writer);
        return;
    }

    @compileError("xdrEncode: unsupported type " ++ @typeName(T));
}

/// Value is an XDR Typedef defined as:
///
/// ```text
/// typedef opaque Value<>;
/// ```
///
pub const Value = struct {
    value: []u8,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !Value {
        return Value{
            .value = try xdrDecodeGeneric([]u8, allocator, reader),
        };
    }

    pub fn xdrEncode(self: Value, writer: anytype) !void {
        try xdrEncodeGeneric([]u8, writer, self.value);
    }

    pub fn asSlice(self: Value) []const u8 {
        return self.value.data;
    }
};

/// ScpBallot is an XDR Struct defined as:
///
/// ```text
/// struct SCPBallot
/// {
///     uint32 counter; // n
///     Value value;    // x
/// };
/// ```
///
pub const ScpBallot = struct {
    counter: u32,
    value: Value,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScpBallot {
        return ScpBallot{
            .counter = try xdrDecodeGeneric(u32, allocator, reader),
            .value = try xdrDecodeGeneric(Value, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScpBallot, writer: anytype) !void {
        try xdrEncodeGeneric(u32, writer, self.counter);
        try xdrEncodeGeneric(Value, writer, self.value);
    }
};

/// ScpStatementType is an XDR Enum defined as:
///
/// ```text
/// enum SCPStatementType
/// {
///     SCP_ST_PREPARE = 0,
///     SCP_ST_CONFIRM = 1,
///     SCP_ST_EXTERNALIZE = 2,
///     SCP_ST_NOMINATE = 3
/// };
/// ```
///
pub const ScpStatementType = enum(i32) {
    Prepare = 0,
    Confirm = 1,
    Externalize = 2,
    Nominate = 3,
    _,

    pub const variants = [_]ScpStatementType{
        .Prepare,
        .Confirm,
        .Externalize,
        .Nominate,
    };

    pub fn name(self: ScpStatementType) []const u8 {
        return switch (self) {
            .Prepare => "Prepare",
            .Confirm => "Confirm",
            .Externalize => "Externalize",
            .Nominate => "Nominate",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScpStatementType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ScpStatementType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ScpNomination is an XDR Struct defined as:
///
/// ```text
/// struct SCPNomination
/// {
///     Hash quorumSetHash; // D
///     Value votes<>;      // X
///     Value accepted<>;   // Y
/// };
/// ```
///
pub const ScpNomination = struct {
    quorum_set_hash: Hash,
    votes: []Value,
    accepted: []Value,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScpNomination {
        return ScpNomination{
            .quorum_set_hash = try xdrDecodeGeneric(Hash, allocator, reader),
            .votes = try xdrDecodeGeneric([]Value, allocator, reader),
            .accepted = try xdrDecodeGeneric([]Value, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScpNomination, writer: anytype) !void {
        try xdrEncodeGeneric(Hash, writer, self.quorum_set_hash);
        try xdrEncodeGeneric([]Value, writer, self.votes);
        try xdrEncodeGeneric([]Value, writer, self.accepted);
    }
};

/// ScpStatementPrepare is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///         {
///             Hash quorumSetHash;       // D
///             SCPBallot ballot;         // b
///             SCPBallot* prepared;      // p
///             SCPBallot* preparedPrime; // p'
///             uint32 nC;                // c.n
///             uint32 nH;                // h.n
///         }
/// ```
///
pub const ScpStatementPrepare = struct {
    quorum_set_hash: Hash,
    ballot: ScpBallot,
    prepared: ?ScpBallot,
    prepared_prime: ?ScpBallot,
    n_c: u32,
    n_h: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScpStatementPrepare {
        return ScpStatementPrepare{
            .quorum_set_hash = try xdrDecodeGeneric(Hash, allocator, reader),
            .ballot = try xdrDecodeGeneric(ScpBallot, allocator, reader),
            .prepared = try xdrDecodeGeneric(?ScpBallot, allocator, reader),
            .prepared_prime = try xdrDecodeGeneric(?ScpBallot, allocator, reader),
            .n_c = try xdrDecodeGeneric(u32, allocator, reader),
            .n_h = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScpStatementPrepare, writer: anytype) !void {
        try xdrEncodeGeneric(Hash, writer, self.quorum_set_hash);
        try xdrEncodeGeneric(ScpBallot, writer, self.ballot);
        try xdrEncodeGeneric(?ScpBallot, writer, self.prepared);
        try xdrEncodeGeneric(?ScpBallot, writer, self.prepared_prime);
        try xdrEncodeGeneric(u32, writer, self.n_c);
        try xdrEncodeGeneric(u32, writer, self.n_h);
    }
};

/// ScpStatementConfirm is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///         {
///             SCPBallot ballot;   // b
///             uint32 nPrepared;   // p.n
///             uint32 nCommit;     // c.n
///             uint32 nH;          // h.n
///             Hash quorumSetHash; // D
///         }
/// ```
///
pub const ScpStatementConfirm = struct {
    ballot: ScpBallot,
    n_prepared: u32,
    n_commit: u32,
    n_h: u32,
    quorum_set_hash: Hash,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScpStatementConfirm {
        return ScpStatementConfirm{
            .ballot = try xdrDecodeGeneric(ScpBallot, allocator, reader),
            .n_prepared = try xdrDecodeGeneric(u32, allocator, reader),
            .n_commit = try xdrDecodeGeneric(u32, allocator, reader),
            .n_h = try xdrDecodeGeneric(u32, allocator, reader),
            .quorum_set_hash = try xdrDecodeGeneric(Hash, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScpStatementConfirm, writer: anytype) !void {
        try xdrEncodeGeneric(ScpBallot, writer, self.ballot);
        try xdrEncodeGeneric(u32, writer, self.n_prepared);
        try xdrEncodeGeneric(u32, writer, self.n_commit);
        try xdrEncodeGeneric(u32, writer, self.n_h);
        try xdrEncodeGeneric(Hash, writer, self.quorum_set_hash);
    }
};

/// ScpStatementExternalize is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///         {
///             SCPBallot commit;         // c
///             uint32 nH;                // h.n
///             Hash commitQuorumSetHash; // D used before EXTERNALIZE
///         }
/// ```
///
pub const ScpStatementExternalize = struct {
    commit: ScpBallot,
    n_h: u32,
    commit_quorum_set_hash: Hash,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScpStatementExternalize {
        return ScpStatementExternalize{
            .commit = try xdrDecodeGeneric(ScpBallot, allocator, reader),
            .n_h = try xdrDecodeGeneric(u32, allocator, reader),
            .commit_quorum_set_hash = try xdrDecodeGeneric(Hash, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScpStatementExternalize, writer: anytype) !void {
        try xdrEncodeGeneric(ScpBallot, writer, self.commit);
        try xdrEncodeGeneric(u32, writer, self.n_h);
        try xdrEncodeGeneric(Hash, writer, self.commit_quorum_set_hash);
    }
};

/// ScpStatementPledges is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (SCPStatementType type)
///     {
///     case SCP_ST_PREPARE:
///         struct
///         {
///             Hash quorumSetHash;       // D
///             SCPBallot ballot;         // b
///             SCPBallot* prepared;      // p
///             SCPBallot* preparedPrime; // p'
///             uint32 nC;                // c.n
///             uint32 nH;                // h.n
///         } prepare;
///     case SCP_ST_CONFIRM:
///         struct
///         {
///             SCPBallot ballot;   // b
///             uint32 nPrepared;   // p.n
///             uint32 nCommit;     // c.n
///             uint32 nH;          // h.n
///             Hash quorumSetHash; // D
///         } confirm;
///     case SCP_ST_EXTERNALIZE:
///         struct
///         {
///             SCPBallot commit;         // c
///             uint32 nH;                // h.n
///             Hash commitQuorumSetHash; // D used before EXTERNALIZE
///         } externalize;
///     case SCP_ST_NOMINATE:
///         SCPNomination nominate;
///     }
/// ```
///
pub const ScpStatementPledges = union(enum) {
    Prepare: ScpStatementPrepare,
    Confirm: ScpStatementConfirm,
    Externalize: ScpStatementExternalize,
    Nominate: ScpNomination,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScpStatementPledges {
        const disc = try ScpStatementType.xdrDecode(allocator, reader);
        return switch (disc) {
            .Prepare => ScpStatementPledges{ .Prepare = try xdrDecodeGeneric(ScpStatementPrepare, allocator, reader) },
            .Confirm => ScpStatementPledges{ .Confirm = try xdrDecodeGeneric(ScpStatementConfirm, allocator, reader) },
            .Externalize => ScpStatementPledges{ .Externalize = try xdrDecodeGeneric(ScpStatementExternalize, allocator, reader) },
            .Nominate => ScpStatementPledges{ .Nominate = try xdrDecodeGeneric(ScpNomination, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ScpStatementPledges, writer: anytype) !void {
        const disc: ScpStatementType = switch (self) {
            .Prepare => .Prepare,
            .Confirm => .Confirm,
            .Externalize => .Externalize,
            .Nominate => .Nominate,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Prepare => |v| try xdrEncodeGeneric(ScpStatementPrepare, writer, v),
            .Confirm => |v| try xdrEncodeGeneric(ScpStatementConfirm, writer, v),
            .Externalize => |v| try xdrEncodeGeneric(ScpStatementExternalize, writer, v),
            .Nominate => |v| try xdrEncodeGeneric(ScpNomination, writer, v),
        }
    }
};

/// ScpStatement is an XDR Struct defined as:
///
/// ```text
/// struct SCPStatement
/// {
///     NodeID nodeID;    // v
///     uint64 slotIndex; // i
///
///     union switch (SCPStatementType type)
///     {
///     case SCP_ST_PREPARE:
///         struct
///         {
///             Hash quorumSetHash;       // D
///             SCPBallot ballot;         // b
///             SCPBallot* prepared;      // p
///             SCPBallot* preparedPrime; // p'
///             uint32 nC;                // c.n
///             uint32 nH;                // h.n
///         } prepare;
///     case SCP_ST_CONFIRM:
///         struct
///         {
///             SCPBallot ballot;   // b
///             uint32 nPrepared;   // p.n
///             uint32 nCommit;     // c.n
///             uint32 nH;          // h.n
///             Hash quorumSetHash; // D
///         } confirm;
///     case SCP_ST_EXTERNALIZE:
///         struct
///         {
///             SCPBallot commit;         // c
///             uint32 nH;                // h.n
///             Hash commitQuorumSetHash; // D used before EXTERNALIZE
///         } externalize;
///     case SCP_ST_NOMINATE:
///         SCPNomination nominate;
///     }
///     pledges;
/// };
/// ```
///
pub const ScpStatement = struct {
    node_id: NodeId,
    slot_index: u64,
    pledges: ScpStatementPledges,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScpStatement {
        return ScpStatement{
            .node_id = try xdrDecodeGeneric(NodeId, allocator, reader),
            .slot_index = try xdrDecodeGeneric(u64, allocator, reader),
            .pledges = try xdrDecodeGeneric(ScpStatementPledges, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScpStatement, writer: anytype) !void {
        try xdrEncodeGeneric(NodeId, writer, self.node_id);
        try xdrEncodeGeneric(u64, writer, self.slot_index);
        try xdrEncodeGeneric(ScpStatementPledges, writer, self.pledges);
    }
};

/// ScpEnvelope is an XDR Struct defined as:
///
/// ```text
/// struct SCPEnvelope
/// {
///     SCPStatement statement;
///     Signature signature;
/// };
/// ```
///
pub const ScpEnvelope = struct {
    statement: ScpStatement,
    signature: Signature,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScpEnvelope {
        return ScpEnvelope{
            .statement = try xdrDecodeGeneric(ScpStatement, allocator, reader),
            .signature = try xdrDecodeGeneric(Signature, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScpEnvelope, writer: anytype) !void {
        try xdrEncodeGeneric(ScpStatement, writer, self.statement);
        try xdrEncodeGeneric(Signature, writer, self.signature);
    }
};

/// ScpQuorumSet is an XDR Struct defined as:
///
/// ```text
/// struct SCPQuorumSet
/// {
///     uint32 threshold;
///     NodeID validators<>;
///     SCPQuorumSet innerSets<>;
/// };
/// ```
///
pub const ScpQuorumSet = struct {
    threshold: u32,
    validators: []NodeId,
    inner_sets: []ScpQuorumSet,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScpQuorumSet {
        return ScpQuorumSet{
            .threshold = try xdrDecodeGeneric(u32, allocator, reader),
            .validators = try xdrDecodeGeneric([]NodeId, allocator, reader),
            .inner_sets = try xdrDecodeGeneric([]ScpQuorumSet, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScpQuorumSet, writer: anytype) !void {
        try xdrEncodeGeneric(u32, writer, self.threshold);
        try xdrEncodeGeneric([]NodeId, writer, self.validators);
        try xdrEncodeGeneric([]ScpQuorumSet, writer, self.inner_sets);
    }
};

/// ConfigSettingContractExecutionLanesV0 is an XDR Struct defined as:
///
/// ```text
/// struct ConfigSettingContractExecutionLanesV0
/// {
///     // maximum number of Soroban transactions per ledger
///     uint32 ledgerMaxTxCount;
/// };
/// ```
///
pub const ConfigSettingContractExecutionLanesV0 = struct {
    ledger_max_tx_count: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ConfigSettingContractExecutionLanesV0 {
        return ConfigSettingContractExecutionLanesV0{
            .ledger_max_tx_count = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ConfigSettingContractExecutionLanesV0, writer: anytype) !void {
        try xdrEncodeGeneric(u32, writer, self.ledger_max_tx_count);
    }
};

/// ConfigSettingContractComputeV0 is an XDR Struct defined as:
///
/// ```text
/// struct ConfigSettingContractComputeV0
/// {
///     // Maximum instructions per ledger
///     int64 ledgerMaxInstructions;
///     // Maximum instructions per transaction
///     int64 txMaxInstructions;
///     // Cost of 10000 instructions
///     int64 feeRatePerInstructionsIncrement;
///
///     // Memory limit per transaction. Unlike instructions, there is no fee
///     // for memory, just the limit.
///     uint32 txMemoryLimit;
/// };
/// ```
///
pub const ConfigSettingContractComputeV0 = struct {
    ledger_max_instructions: i64,
    tx_max_instructions: i64,
    fee_rate_per_instructions_increment: i64,
    tx_memory_limit: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ConfigSettingContractComputeV0 {
        return ConfigSettingContractComputeV0{
            .ledger_max_instructions = try xdrDecodeGeneric(i64, allocator, reader),
            .tx_max_instructions = try xdrDecodeGeneric(i64, allocator, reader),
            .fee_rate_per_instructions_increment = try xdrDecodeGeneric(i64, allocator, reader),
            .tx_memory_limit = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ConfigSettingContractComputeV0, writer: anytype) !void {
        try xdrEncodeGeneric(i64, writer, self.ledger_max_instructions);
        try xdrEncodeGeneric(i64, writer, self.tx_max_instructions);
        try xdrEncodeGeneric(i64, writer, self.fee_rate_per_instructions_increment);
        try xdrEncodeGeneric(u32, writer, self.tx_memory_limit);
    }
};

/// ConfigSettingContractParallelComputeV0 is an XDR Struct defined as:
///
/// ```text
/// struct ConfigSettingContractParallelComputeV0
/// {
///     // Maximum number of clusters with dependent transactions allowed in a
///     // stage of parallel tx set component.
///     // This effectively sets the lower bound on the number of physical threads
///     // necessary to effectively apply transaction sets in parallel.
///     uint32 ledgerMaxDependentTxClusters;
/// };
/// ```
///
pub const ConfigSettingContractParallelComputeV0 = struct {
    ledger_max_dependent_tx_clusters: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ConfigSettingContractParallelComputeV0 {
        return ConfigSettingContractParallelComputeV0{
            .ledger_max_dependent_tx_clusters = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ConfigSettingContractParallelComputeV0, writer: anytype) !void {
        try xdrEncodeGeneric(u32, writer, self.ledger_max_dependent_tx_clusters);
    }
};

/// ConfigSettingContractLedgerCostV0 is an XDR Struct defined as:
///
/// ```text
/// struct ConfigSettingContractLedgerCostV0
/// {
///     // Maximum number of disk entry read operations per ledger
///     uint32 ledgerMaxDiskReadEntries;
///     // Maximum number of bytes of disk reads that can be performed per ledger
///     uint32 ledgerMaxDiskReadBytes;
///     // Maximum number of ledger entry write operations per ledger
///     uint32 ledgerMaxWriteLedgerEntries;
///     // Maximum number of bytes that can be written per ledger
///     uint32 ledgerMaxWriteBytes;
///
///     // Maximum number of disk entry read operations per transaction
///     uint32 txMaxDiskReadEntries;
///     // Maximum number of bytes of disk reads that can be performed per transaction
///     uint32 txMaxDiskReadBytes;
///     // Maximum number of ledger entry write operations per transaction
///     uint32 txMaxWriteLedgerEntries;
///     // Maximum number of bytes that can be written per transaction
///     uint32 txMaxWriteBytes;
///
///     int64 feeDiskReadLedgerEntry;  // Fee per disk ledger entry read
///     int64 feeWriteLedgerEntry;     // Fee per ledger entry write
///
///     int64 feeDiskRead1KB;          // Fee for reading 1KB disk
///
///     // The following parameters determine the write fee per 1KB.
///     // Rent fee grows linearly until soroban state reaches this size
///     int64 sorobanStateTargetSizeBytes;
///     // Fee per 1KB rent when the soroban state is empty
///     int64 rentFee1KBSorobanStateSizeLow;
///     // Fee per 1KB rent when the soroban state has reached `sorobanStateTargetSizeBytes`
///     int64 rentFee1KBSorobanStateSizeHigh;
///     // Rent fee multiplier for any additional data past the first `sorobanStateTargetSizeBytes`
///     uint32 sorobanStateRentFeeGrowthFactor;
/// };
/// ```
///
pub const ConfigSettingContractLedgerCostV0 = struct {
    ledger_max_disk_read_entries: u32,
    ledger_max_disk_read_bytes: u32,
    ledger_max_write_ledger_entries: u32,
    ledger_max_write_bytes: u32,
    tx_max_disk_read_entries: u32,
    tx_max_disk_read_bytes: u32,
    tx_max_write_ledger_entries: u32,
    tx_max_write_bytes: u32,
    fee_disk_read_ledger_entry: i64,
    fee_write_ledger_entry: i64,
    fee_disk_read1_kb: i64,
    soroban_state_target_size_bytes: i64,
    rent_fee1_kb_soroban_state_size_low: i64,
    rent_fee1_kb_soroban_state_size_high: i64,
    soroban_state_rent_fee_growth_factor: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ConfigSettingContractLedgerCostV0 {
        return ConfigSettingContractLedgerCostV0{
            .ledger_max_disk_read_entries = try xdrDecodeGeneric(u32, allocator, reader),
            .ledger_max_disk_read_bytes = try xdrDecodeGeneric(u32, allocator, reader),
            .ledger_max_write_ledger_entries = try xdrDecodeGeneric(u32, allocator, reader),
            .ledger_max_write_bytes = try xdrDecodeGeneric(u32, allocator, reader),
            .tx_max_disk_read_entries = try xdrDecodeGeneric(u32, allocator, reader),
            .tx_max_disk_read_bytes = try xdrDecodeGeneric(u32, allocator, reader),
            .tx_max_write_ledger_entries = try xdrDecodeGeneric(u32, allocator, reader),
            .tx_max_write_bytes = try xdrDecodeGeneric(u32, allocator, reader),
            .fee_disk_read_ledger_entry = try xdrDecodeGeneric(i64, allocator, reader),
            .fee_write_ledger_entry = try xdrDecodeGeneric(i64, allocator, reader),
            .fee_disk_read1_kb = try xdrDecodeGeneric(i64, allocator, reader),
            .soroban_state_target_size_bytes = try xdrDecodeGeneric(i64, allocator, reader),
            .rent_fee1_kb_soroban_state_size_low = try xdrDecodeGeneric(i64, allocator, reader),
            .rent_fee1_kb_soroban_state_size_high = try xdrDecodeGeneric(i64, allocator, reader),
            .soroban_state_rent_fee_growth_factor = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ConfigSettingContractLedgerCostV0, writer: anytype) !void {
        try xdrEncodeGeneric(u32, writer, self.ledger_max_disk_read_entries);
        try xdrEncodeGeneric(u32, writer, self.ledger_max_disk_read_bytes);
        try xdrEncodeGeneric(u32, writer, self.ledger_max_write_ledger_entries);
        try xdrEncodeGeneric(u32, writer, self.ledger_max_write_bytes);
        try xdrEncodeGeneric(u32, writer, self.tx_max_disk_read_entries);
        try xdrEncodeGeneric(u32, writer, self.tx_max_disk_read_bytes);
        try xdrEncodeGeneric(u32, writer, self.tx_max_write_ledger_entries);
        try xdrEncodeGeneric(u32, writer, self.tx_max_write_bytes);
        try xdrEncodeGeneric(i64, writer, self.fee_disk_read_ledger_entry);
        try xdrEncodeGeneric(i64, writer, self.fee_write_ledger_entry);
        try xdrEncodeGeneric(i64, writer, self.fee_disk_read1_kb);
        try xdrEncodeGeneric(i64, writer, self.soroban_state_target_size_bytes);
        try xdrEncodeGeneric(i64, writer, self.rent_fee1_kb_soroban_state_size_low);
        try xdrEncodeGeneric(i64, writer, self.rent_fee1_kb_soroban_state_size_high);
        try xdrEncodeGeneric(u32, writer, self.soroban_state_rent_fee_growth_factor);
    }
};

/// ConfigSettingContractLedgerCostExtV0 is an XDR Struct defined as:
///
/// ```text
/// struct ConfigSettingContractLedgerCostExtV0
/// {
///     // Maximum number of RO+RW entries in the transaction footprint.
///     uint32 txMaxFootprintEntries;
///     // Fee per 1 KB of data written to the ledger.
///     // Unlike the rent fee, this is a flat fee that is charged for any ledger
///     // write, independent of the type of the entry being written.
///     int64 feeWrite1KB;
/// };
/// ```
///
pub const ConfigSettingContractLedgerCostExtV0 = struct {
    tx_max_footprint_entries: u32,
    fee_write1_kb: i64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ConfigSettingContractLedgerCostExtV0 {
        return ConfigSettingContractLedgerCostExtV0{
            .tx_max_footprint_entries = try xdrDecodeGeneric(u32, allocator, reader),
            .fee_write1_kb = try xdrDecodeGeneric(i64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ConfigSettingContractLedgerCostExtV0, writer: anytype) !void {
        try xdrEncodeGeneric(u32, writer, self.tx_max_footprint_entries);
        try xdrEncodeGeneric(i64, writer, self.fee_write1_kb);
    }
};

/// ConfigSettingContractHistoricalDataV0 is an XDR Struct defined as:
///
/// ```text
/// struct ConfigSettingContractHistoricalDataV0
/// {
///     int64 feeHistorical1KB; // Fee for storing 1KB in archives
/// };
/// ```
///
pub const ConfigSettingContractHistoricalDataV0 = struct {
    fee_historical1_kb: i64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ConfigSettingContractHistoricalDataV0 {
        return ConfigSettingContractHistoricalDataV0{
            .fee_historical1_kb = try xdrDecodeGeneric(i64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ConfigSettingContractHistoricalDataV0, writer: anytype) !void {
        try xdrEncodeGeneric(i64, writer, self.fee_historical1_kb);
    }
};

/// ConfigSettingContractEventsV0 is an XDR Struct defined as:
///
/// ```text
/// struct ConfigSettingContractEventsV0
/// {
///     // Maximum size of events that a contract call can emit.
///     uint32 txMaxContractEventsSizeBytes;
///     // Fee for generating 1KB of contract events.
///     int64 feeContractEvents1KB;
/// };
/// ```
///
pub const ConfigSettingContractEventsV0 = struct {
    tx_max_contract_events_size_bytes: u32,
    fee_contract_events1_kb: i64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ConfigSettingContractEventsV0 {
        return ConfigSettingContractEventsV0{
            .tx_max_contract_events_size_bytes = try xdrDecodeGeneric(u32, allocator, reader),
            .fee_contract_events1_kb = try xdrDecodeGeneric(i64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ConfigSettingContractEventsV0, writer: anytype) !void {
        try xdrEncodeGeneric(u32, writer, self.tx_max_contract_events_size_bytes);
        try xdrEncodeGeneric(i64, writer, self.fee_contract_events1_kb);
    }
};

/// ConfigSettingContractBandwidthV0 is an XDR Struct defined as:
///
/// ```text
/// struct ConfigSettingContractBandwidthV0
/// {
///     // Maximum sum of all transaction sizes in the ledger in bytes
///     uint32 ledgerMaxTxsSizeBytes;
///     // Maximum size in bytes for a transaction
///     uint32 txMaxSizeBytes;
///
///     // Fee for 1 KB of transaction size
///     int64 feeTxSize1KB;
/// };
/// ```
///
pub const ConfigSettingContractBandwidthV0 = struct {
    ledger_max_txs_size_bytes: u32,
    tx_max_size_bytes: u32,
    fee_tx_size1_kb: i64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ConfigSettingContractBandwidthV0 {
        return ConfigSettingContractBandwidthV0{
            .ledger_max_txs_size_bytes = try xdrDecodeGeneric(u32, allocator, reader),
            .tx_max_size_bytes = try xdrDecodeGeneric(u32, allocator, reader),
            .fee_tx_size1_kb = try xdrDecodeGeneric(i64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ConfigSettingContractBandwidthV0, writer: anytype) !void {
        try xdrEncodeGeneric(u32, writer, self.ledger_max_txs_size_bytes);
        try xdrEncodeGeneric(u32, writer, self.tx_max_size_bytes);
        try xdrEncodeGeneric(i64, writer, self.fee_tx_size1_kb);
    }
};

/// ContractCostType is an XDR Enum defined as:
///
/// ```text
/// enum ContractCostType {
///     // Cost of running 1 wasm instruction
///     WasmInsnExec = 0,
///     // Cost of allocating a slice of memory (in bytes)
///     MemAlloc = 1,
///     // Cost of copying a slice of bytes into a pre-allocated memory
///     MemCpy = 2,
///     // Cost of comparing two slices of memory
///     MemCmp = 3,
///     // Cost of a host function dispatch, not including the actual work done by
///     // the function nor the cost of VM invocation machinary
///     DispatchHostFunction = 4,
///     // Cost of visiting a host object from the host object storage. Exists to
///     // make sure some baseline cost coverage, i.e. repeatly visiting objects
///     // by the guest will always incur some charges.
///     VisitObject = 5,
///     // Cost of serializing an xdr object to bytes
///     ValSer = 6,
///     // Cost of deserializing an xdr object from bytes
///     ValDeser = 7,
///     // Cost of computing the sha256 hash from bytes
///     ComputeSha256Hash = 8,
///     // Cost of computing the ed25519 pubkey from bytes
///     ComputeEd25519PubKey = 9,
///     // Cost of verifying ed25519 signature of a payload.
///     VerifyEd25519Sig = 10,
///     // Cost of instantiation a VM from wasm bytes code.
///     VmInstantiation = 11,
///     // Cost of instantiation a VM from a cached state.
///     VmCachedInstantiation = 12,
///     // Cost of invoking a function on the VM. If the function is a host function,
///     // additional cost will be covered by `DispatchHostFunction`.
///     InvokeVmFunction = 13,
///     // Cost of computing a keccak256 hash from bytes.
///     ComputeKeccak256Hash = 14,
///     // Cost of decoding an ECDSA signature computed from a 256-bit prime modulus
///     // curve (e.g. secp256k1 and secp256r1)
///     DecodeEcdsaCurve256Sig = 15,
///     // Cost of recovering an ECDSA secp256k1 key from a signature.
///     RecoverEcdsaSecp256k1Key = 16,
///     // Cost of int256 addition (`+`) and subtraction (`-`) operations
///     Int256AddSub = 17,
///     // Cost of int256 multiplication (`*`) operation
///     Int256Mul = 18,
///     // Cost of int256 division (`/`) operation
///     Int256Div = 19,
///     // Cost of int256 power (`exp`) operation
///     Int256Pow = 20,
///     // Cost of int256 shift (`shl`, `shr`) operation
///     Int256Shift = 21,
///     // Cost of drawing random bytes using a ChaCha20 PRNG
///     ChaCha20DrawBytes = 22,
///
///     // Cost of parsing wasm bytes that only encode instructions.
///     ParseWasmInstructions = 23,
///     // Cost of parsing a known number of wasm functions.
///     ParseWasmFunctions = 24,
///     // Cost of parsing a known number of wasm globals.
///     ParseWasmGlobals = 25,
///     // Cost of parsing a known number of wasm table entries.
///     ParseWasmTableEntries = 26,
///     // Cost of parsing a known number of wasm types.
///     ParseWasmTypes = 27,
///     // Cost of parsing a known number of wasm data segments.
///     ParseWasmDataSegments = 28,
///     // Cost of parsing a known number of wasm element segments.
///     ParseWasmElemSegments = 29,
///     // Cost of parsing a known number of wasm imports.
///     ParseWasmImports = 30,
///     // Cost of parsing a known number of wasm exports.
///     ParseWasmExports = 31,
///     // Cost of parsing a known number of data segment bytes.
///     ParseWasmDataSegmentBytes = 32,
///
///     // Cost of instantiating wasm bytes that only encode instructions.
///     InstantiateWasmInstructions = 33,
///     // Cost of instantiating a known number of wasm functions.
///     InstantiateWasmFunctions = 34,
///     // Cost of instantiating a known number of wasm globals.
///     InstantiateWasmGlobals = 35,
///     // Cost of instantiating a known number of wasm table entries.
///     InstantiateWasmTableEntries = 36,
///     // Cost of instantiating a known number of wasm types.
///     InstantiateWasmTypes = 37,
///     // Cost of instantiating a known number of wasm data segments.
///     InstantiateWasmDataSegments = 38,
///     // Cost of instantiating a known number of wasm element segments.
///     InstantiateWasmElemSegments = 39,
///     // Cost of instantiating a known number of wasm imports.
///     InstantiateWasmImports = 40,
///     // Cost of instantiating a known number of wasm exports.
///     InstantiateWasmExports = 41,
///     // Cost of instantiating a known number of data segment bytes.
///     InstantiateWasmDataSegmentBytes = 42,
///
///     // Cost of decoding a bytes array representing an uncompressed SEC-1 encoded
///     // point on a 256-bit elliptic curve
///     Sec1DecodePointUncompressed = 43,
///     // Cost of verifying an ECDSA Secp256r1 signature
///     VerifyEcdsaSecp256r1Sig = 44,
///
///     // Cost of encoding a BLS12-381 Fp (base field element)
///     Bls12381EncodeFp = 45,
///     // Cost of decoding a BLS12-381 Fp (base field element)
///     Bls12381DecodeFp = 46,
///     // Cost of checking a G1 point lies on the curve
///     Bls12381G1CheckPointOnCurve = 47,
///     // Cost of checking a G1 point belongs to the correct subgroup
///     Bls12381G1CheckPointInSubgroup = 48,
///     // Cost of checking a G2 point lies on the curve
///     Bls12381G2CheckPointOnCurve = 49,
///     // Cost of checking a G2 point belongs to the correct subgroup
///     Bls12381G2CheckPointInSubgroup = 50,
///     // Cost of converting a BLS12-381 G1 point from projective to affine coordinates
///     Bls12381G1ProjectiveToAffine = 51,
///     // Cost of converting a BLS12-381 G2 point from projective to affine coordinates
///     Bls12381G2ProjectiveToAffine = 52,
///     // Cost of performing BLS12-381 G1 point addition
///     Bls12381G1Add = 53,
///     // Cost of performing BLS12-381 G1 scalar multiplication
///     Bls12381G1Mul = 54,
///     // Cost of performing BLS12-381 G1 multi-scalar multiplication (MSM)
///     Bls12381G1Msm = 55,
///     // Cost of mapping a BLS12-381 Fp field element to a G1 point
///     Bls12381MapFpToG1 = 56,
///     // Cost of hashing to a BLS12-381 G1 point
///     Bls12381HashToG1 = 57,
///     // Cost of performing BLS12-381 G2 point addition
///     Bls12381G2Add = 58,
///     // Cost of performing BLS12-381 G2 scalar multiplication
///     Bls12381G2Mul = 59,
///     // Cost of performing BLS12-381 G2 multi-scalar multiplication (MSM)
///     Bls12381G2Msm = 60,
///     // Cost of mapping a BLS12-381 Fp2 field element to a G2 point
///     Bls12381MapFp2ToG2 = 61,
///     // Cost of hashing to a BLS12-381 G2 point
///     Bls12381HashToG2 = 62,
///     // Cost of performing BLS12-381 pairing operation
///     Bls12381Pairing = 63,
///     // Cost of converting a BLS12-381 scalar element from U256
///     Bls12381FrFromU256 = 64,
///     // Cost of converting a BLS12-381 scalar element to U256
///     Bls12381FrToU256 = 65,
///     // Cost of performing BLS12-381 scalar element addition/subtraction
///     Bls12381FrAddSub = 66,
///     // Cost of performing BLS12-381 scalar element multiplication
///     Bls12381FrMul = 67,
///     // Cost of performing BLS12-381 scalar element exponentiation
///     Bls12381FrPow = 68,
///     // Cost of performing BLS12-381 scalar element inversion
///     Bls12381FrInv = 69,
///
///     // Cost of encoding a BN254 Fp (base field element)
///     Bn254EncodeFp = 70,
///     // Cost of decoding a BN254 Fp (base field element)
///     Bn254DecodeFp = 71,
///     // Cost of checking a G1 point lies on the curve
///     Bn254G1CheckPointOnCurve = 72,
///     // Cost of checking a G2 point lies on the curve
///     Bn254G2CheckPointOnCurve = 73,
///     // Cost of checking a G2 point belongs to the correct subgroup
///     Bn254G2CheckPointInSubgroup = 74,
///     // Cost of converting a BN254 G1 point from projective to affine coordinates
///     Bn254G1ProjectiveToAffine = 75,
///     // Cost of performing BN254 G1 point addition
///     Bn254G1Add = 76,
///     // Cost of performing BN254 G1 scalar multiplication
///     Bn254G1Mul = 77,
///     // Cost of performing BN254 pairing operation
///     Bn254Pairing = 78,
///     // Cost of converting a BN254 scalar element from U256
///     Bn254FrFromU256 = 79,
///     // Cost of converting a BN254 scalar element to U256
///     Bn254FrToU256 = 80,
///     // // Cost of performing BN254 scalar element addition/subtraction
///     Bn254FrAddSub = 81,
///     // Cost of performing BN254 scalar element multiplication
///     Bn254FrMul = 82,
///     // Cost of performing BN254 scalar element exponentiation
///     Bn254FrPow = 83,
///      // Cost of performing BN254 scalar element inversion
///     Bn254FrInv = 84
/// };
/// ```
///
pub const ContractCostType = enum(i32) {
    WasmInsnExec = 0,
    MemAlloc = 1,
    MemCpy = 2,
    MemCmp = 3,
    DispatchHostFunction = 4,
    VisitObject = 5,
    ValSer = 6,
    ValDeser = 7,
    ComputeSha256Hash = 8,
    ComputeEd25519PubKey = 9,
    VerifyEd25519Sig = 10,
    VmInstantiation = 11,
    VmCachedInstantiation = 12,
    InvokeVmFunction = 13,
    ComputeKeccak256Hash = 14,
    DecodeEcdsaCurve256Sig = 15,
    RecoverEcdsaSecp256k1Key = 16,
    Int256AddSub = 17,
    Int256Mul = 18,
    Int256Div = 19,
    Int256Pow = 20,
    Int256Shift = 21,
    ChaCha20DrawBytes = 22,
    ParseWasmInstructions = 23,
    ParseWasmFunctions = 24,
    ParseWasmGlobals = 25,
    ParseWasmTableEntries = 26,
    ParseWasmTypes = 27,
    ParseWasmDataSegments = 28,
    ParseWasmElemSegments = 29,
    ParseWasmImports = 30,
    ParseWasmExports = 31,
    ParseWasmDataSegmentBytes = 32,
    InstantiateWasmInstructions = 33,
    InstantiateWasmFunctions = 34,
    InstantiateWasmGlobals = 35,
    InstantiateWasmTableEntries = 36,
    InstantiateWasmTypes = 37,
    InstantiateWasmDataSegments = 38,
    InstantiateWasmElemSegments = 39,
    InstantiateWasmImports = 40,
    InstantiateWasmExports = 41,
    InstantiateWasmDataSegmentBytes = 42,
    Sec1DecodePointUncompressed = 43,
    VerifyEcdsaSecp256r1Sig = 44,
    Bls12381EncodeFp = 45,
    Bls12381DecodeFp = 46,
    Bls12381G1CheckPointOnCurve = 47,
    Bls12381G1CheckPointInSubgroup = 48,
    Bls12381G2CheckPointOnCurve = 49,
    Bls12381G2CheckPointInSubgroup = 50,
    Bls12381G1ProjectiveToAffine = 51,
    Bls12381G2ProjectiveToAffine = 52,
    Bls12381G1Add = 53,
    Bls12381G1Mul = 54,
    Bls12381G1Msm = 55,
    Bls12381MapFpToG1 = 56,
    Bls12381HashToG1 = 57,
    Bls12381G2Add = 58,
    Bls12381G2Mul = 59,
    Bls12381G2Msm = 60,
    Bls12381MapFp2ToG2 = 61,
    Bls12381HashToG2 = 62,
    Bls12381Pairing = 63,
    Bls12381FrFromU256 = 64,
    Bls12381FrToU256 = 65,
    Bls12381FrAddSub = 66,
    Bls12381FrMul = 67,
    Bls12381FrPow = 68,
    Bls12381FrInv = 69,
    Bn254EncodeFp = 70,
    Bn254DecodeFp = 71,
    Bn254G1CheckPointOnCurve = 72,
    Bn254G2CheckPointOnCurve = 73,
    Bn254G2CheckPointInSubgroup = 74,
    Bn254G1ProjectiveToAffine = 75,
    Bn254G1Add = 76,
    Bn254G1Mul = 77,
    Bn254Pairing = 78,
    Bn254FrFromU256 = 79,
    Bn254FrToU256 = 80,
    Bn254FrAddSub = 81,
    Bn254FrMul = 82,
    Bn254FrPow = 83,
    Bn254FrInv = 84,
    _,

    pub const variants = [_]ContractCostType{
        .WasmInsnExec,
        .MemAlloc,
        .MemCpy,
        .MemCmp,
        .DispatchHostFunction,
        .VisitObject,
        .ValSer,
        .ValDeser,
        .ComputeSha256Hash,
        .ComputeEd25519PubKey,
        .VerifyEd25519Sig,
        .VmInstantiation,
        .VmCachedInstantiation,
        .InvokeVmFunction,
        .ComputeKeccak256Hash,
        .DecodeEcdsaCurve256Sig,
        .RecoverEcdsaSecp256k1Key,
        .Int256AddSub,
        .Int256Mul,
        .Int256Div,
        .Int256Pow,
        .Int256Shift,
        .ChaCha20DrawBytes,
        .ParseWasmInstructions,
        .ParseWasmFunctions,
        .ParseWasmGlobals,
        .ParseWasmTableEntries,
        .ParseWasmTypes,
        .ParseWasmDataSegments,
        .ParseWasmElemSegments,
        .ParseWasmImports,
        .ParseWasmExports,
        .ParseWasmDataSegmentBytes,
        .InstantiateWasmInstructions,
        .InstantiateWasmFunctions,
        .InstantiateWasmGlobals,
        .InstantiateWasmTableEntries,
        .InstantiateWasmTypes,
        .InstantiateWasmDataSegments,
        .InstantiateWasmElemSegments,
        .InstantiateWasmImports,
        .InstantiateWasmExports,
        .InstantiateWasmDataSegmentBytes,
        .Sec1DecodePointUncompressed,
        .VerifyEcdsaSecp256r1Sig,
        .Bls12381EncodeFp,
        .Bls12381DecodeFp,
        .Bls12381G1CheckPointOnCurve,
        .Bls12381G1CheckPointInSubgroup,
        .Bls12381G2CheckPointOnCurve,
        .Bls12381G2CheckPointInSubgroup,
        .Bls12381G1ProjectiveToAffine,
        .Bls12381G2ProjectiveToAffine,
        .Bls12381G1Add,
        .Bls12381G1Mul,
        .Bls12381G1Msm,
        .Bls12381MapFpToG1,
        .Bls12381HashToG1,
        .Bls12381G2Add,
        .Bls12381G2Mul,
        .Bls12381G2Msm,
        .Bls12381MapFp2ToG2,
        .Bls12381HashToG2,
        .Bls12381Pairing,
        .Bls12381FrFromU256,
        .Bls12381FrToU256,
        .Bls12381FrAddSub,
        .Bls12381FrMul,
        .Bls12381FrPow,
        .Bls12381FrInv,
        .Bn254EncodeFp,
        .Bn254DecodeFp,
        .Bn254G1CheckPointOnCurve,
        .Bn254G2CheckPointOnCurve,
        .Bn254G2CheckPointInSubgroup,
        .Bn254G1ProjectiveToAffine,
        .Bn254G1Add,
        .Bn254G1Mul,
        .Bn254Pairing,
        .Bn254FrFromU256,
        .Bn254FrToU256,
        .Bn254FrAddSub,
        .Bn254FrMul,
        .Bn254FrPow,
        .Bn254FrInv,
    };

    pub fn name(self: ContractCostType) []const u8 {
        return switch (self) {
            .WasmInsnExec => "WasmInsnExec",
            .MemAlloc => "MemAlloc",
            .MemCpy => "MemCpy",
            .MemCmp => "MemCmp",
            .DispatchHostFunction => "DispatchHostFunction",
            .VisitObject => "VisitObject",
            .ValSer => "ValSer",
            .ValDeser => "ValDeser",
            .ComputeSha256Hash => "ComputeSha256Hash",
            .ComputeEd25519PubKey => "ComputeEd25519PubKey",
            .VerifyEd25519Sig => "VerifyEd25519Sig",
            .VmInstantiation => "VmInstantiation",
            .VmCachedInstantiation => "VmCachedInstantiation",
            .InvokeVmFunction => "InvokeVmFunction",
            .ComputeKeccak256Hash => "ComputeKeccak256Hash",
            .DecodeEcdsaCurve256Sig => "DecodeEcdsaCurve256Sig",
            .RecoverEcdsaSecp256k1Key => "RecoverEcdsaSecp256k1Key",
            .Int256AddSub => "Int256AddSub",
            .Int256Mul => "Int256Mul",
            .Int256Div => "Int256Div",
            .Int256Pow => "Int256Pow",
            .Int256Shift => "Int256Shift",
            .ChaCha20DrawBytes => "ChaCha20DrawBytes",
            .ParseWasmInstructions => "ParseWasmInstructions",
            .ParseWasmFunctions => "ParseWasmFunctions",
            .ParseWasmGlobals => "ParseWasmGlobals",
            .ParseWasmTableEntries => "ParseWasmTableEntries",
            .ParseWasmTypes => "ParseWasmTypes",
            .ParseWasmDataSegments => "ParseWasmDataSegments",
            .ParseWasmElemSegments => "ParseWasmElemSegments",
            .ParseWasmImports => "ParseWasmImports",
            .ParseWasmExports => "ParseWasmExports",
            .ParseWasmDataSegmentBytes => "ParseWasmDataSegmentBytes",
            .InstantiateWasmInstructions => "InstantiateWasmInstructions",
            .InstantiateWasmFunctions => "InstantiateWasmFunctions",
            .InstantiateWasmGlobals => "InstantiateWasmGlobals",
            .InstantiateWasmTableEntries => "InstantiateWasmTableEntries",
            .InstantiateWasmTypes => "InstantiateWasmTypes",
            .InstantiateWasmDataSegments => "InstantiateWasmDataSegments",
            .InstantiateWasmElemSegments => "InstantiateWasmElemSegments",
            .InstantiateWasmImports => "InstantiateWasmImports",
            .InstantiateWasmExports => "InstantiateWasmExports",
            .InstantiateWasmDataSegmentBytes => "InstantiateWasmDataSegmentBytes",
            .Sec1DecodePointUncompressed => "Sec1DecodePointUncompressed",
            .VerifyEcdsaSecp256r1Sig => "VerifyEcdsaSecp256r1Sig",
            .Bls12381EncodeFp => "Bls12381EncodeFp",
            .Bls12381DecodeFp => "Bls12381DecodeFp",
            .Bls12381G1CheckPointOnCurve => "Bls12381G1CheckPointOnCurve",
            .Bls12381G1CheckPointInSubgroup => "Bls12381G1CheckPointInSubgroup",
            .Bls12381G2CheckPointOnCurve => "Bls12381G2CheckPointOnCurve",
            .Bls12381G2CheckPointInSubgroup => "Bls12381G2CheckPointInSubgroup",
            .Bls12381G1ProjectiveToAffine => "Bls12381G1ProjectiveToAffine",
            .Bls12381G2ProjectiveToAffine => "Bls12381G2ProjectiveToAffine",
            .Bls12381G1Add => "Bls12381G1Add",
            .Bls12381G1Mul => "Bls12381G1Mul",
            .Bls12381G1Msm => "Bls12381G1Msm",
            .Bls12381MapFpToG1 => "Bls12381MapFpToG1",
            .Bls12381HashToG1 => "Bls12381HashToG1",
            .Bls12381G2Add => "Bls12381G2Add",
            .Bls12381G2Mul => "Bls12381G2Mul",
            .Bls12381G2Msm => "Bls12381G2Msm",
            .Bls12381MapFp2ToG2 => "Bls12381MapFp2ToG2",
            .Bls12381HashToG2 => "Bls12381HashToG2",
            .Bls12381Pairing => "Bls12381Pairing",
            .Bls12381FrFromU256 => "Bls12381FrFromU256",
            .Bls12381FrToU256 => "Bls12381FrToU256",
            .Bls12381FrAddSub => "Bls12381FrAddSub",
            .Bls12381FrMul => "Bls12381FrMul",
            .Bls12381FrPow => "Bls12381FrPow",
            .Bls12381FrInv => "Bls12381FrInv",
            .Bn254EncodeFp => "Bn254EncodeFp",
            .Bn254DecodeFp => "Bn254DecodeFp",
            .Bn254G1CheckPointOnCurve => "Bn254G1CheckPointOnCurve",
            .Bn254G2CheckPointOnCurve => "Bn254G2CheckPointOnCurve",
            .Bn254G2CheckPointInSubgroup => "Bn254G2CheckPointInSubgroup",
            .Bn254G1ProjectiveToAffine => "Bn254G1ProjectiveToAffine",
            .Bn254G1Add => "Bn254G1Add",
            .Bn254G1Mul => "Bn254G1Mul",
            .Bn254Pairing => "Bn254Pairing",
            .Bn254FrFromU256 => "Bn254FrFromU256",
            .Bn254FrToU256 => "Bn254FrToU256",
            .Bn254FrAddSub => "Bn254FrAddSub",
            .Bn254FrMul => "Bn254FrMul",
            .Bn254FrPow => "Bn254FrPow",
            .Bn254FrInv => "Bn254FrInv",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ContractCostType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ContractCostType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ContractCostParamEntry is an XDR Struct defined as:
///
/// ```text
/// struct ContractCostParamEntry {
///     // use `ext` to add more terms (e.g. higher order polynomials) in the future
///     ExtensionPoint ext;
///
///     int64 constTerm;
///     int64 linearTerm;
/// };
/// ```
///
pub const ContractCostParamEntry = struct {
    ext: ExtensionPoint,
    const_term: i64,
    linear_term: i64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ContractCostParamEntry {
        return ContractCostParamEntry{
            .ext = try xdrDecodeGeneric(ExtensionPoint, allocator, reader),
            .const_term = try xdrDecodeGeneric(i64, allocator, reader),
            .linear_term = try xdrDecodeGeneric(i64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ContractCostParamEntry, writer: anytype) !void {
        try xdrEncodeGeneric(ExtensionPoint, writer, self.ext);
        try xdrEncodeGeneric(i64, writer, self.const_term);
        try xdrEncodeGeneric(i64, writer, self.linear_term);
    }
};

/// StateArchivalSettings is an XDR Struct defined as:
///
/// ```text
/// struct StateArchivalSettings {
///     uint32 maxEntryTTL;
///     uint32 minTemporaryTTL;
///     uint32 minPersistentTTL;
///
///     // rent_fee = wfee_rate_average / rent_rate_denominator_for_type
///     int64 persistentRentRateDenominator;
///     int64 tempRentRateDenominator;
///
///     // max number of entries that emit archival meta in a single ledger
///     uint32 maxEntriesToArchive;
///
///     // Number of snapshots to use when calculating average live Soroban State size
///     uint32 liveSorobanStateSizeWindowSampleSize;
///
///     // How often to sample the live Soroban State size for the average, in ledgers
///     uint32 liveSorobanStateSizeWindowSamplePeriod;
///
///     // Maximum number of bytes that we scan for eviction per ledger
///     uint32 evictionScanSize;
///
///     // Lowest BucketList level to be scanned to evict entries
///     uint32 startingEvictionScanLevel;
/// };
/// ```
///
pub const StateArchivalSettings = struct {
    max_entry_ttl: u32,
    min_temporary_ttl: u32,
    min_persistent_ttl: u32,
    persistent_rent_rate_denominator: i64,
    temp_rent_rate_denominator: i64,
    max_entries_to_archive: u32,
    live_soroban_state_size_window_sample_size: u32,
    live_soroban_state_size_window_sample_period: u32,
    eviction_scan_size: u32,
    starting_eviction_scan_level: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !StateArchivalSettings {
        return StateArchivalSettings{
            .max_entry_ttl = try xdrDecodeGeneric(u32, allocator, reader),
            .min_temporary_ttl = try xdrDecodeGeneric(u32, allocator, reader),
            .min_persistent_ttl = try xdrDecodeGeneric(u32, allocator, reader),
            .persistent_rent_rate_denominator = try xdrDecodeGeneric(i64, allocator, reader),
            .temp_rent_rate_denominator = try xdrDecodeGeneric(i64, allocator, reader),
            .max_entries_to_archive = try xdrDecodeGeneric(u32, allocator, reader),
            .live_soroban_state_size_window_sample_size = try xdrDecodeGeneric(u32, allocator, reader),
            .live_soroban_state_size_window_sample_period = try xdrDecodeGeneric(u32, allocator, reader),
            .eviction_scan_size = try xdrDecodeGeneric(u32, allocator, reader),
            .starting_eviction_scan_level = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: StateArchivalSettings, writer: anytype) !void {
        try xdrEncodeGeneric(u32, writer, self.max_entry_ttl);
        try xdrEncodeGeneric(u32, writer, self.min_temporary_ttl);
        try xdrEncodeGeneric(u32, writer, self.min_persistent_ttl);
        try xdrEncodeGeneric(i64, writer, self.persistent_rent_rate_denominator);
        try xdrEncodeGeneric(i64, writer, self.temp_rent_rate_denominator);
        try xdrEncodeGeneric(u32, writer, self.max_entries_to_archive);
        try xdrEncodeGeneric(u32, writer, self.live_soroban_state_size_window_sample_size);
        try xdrEncodeGeneric(u32, writer, self.live_soroban_state_size_window_sample_period);
        try xdrEncodeGeneric(u32, writer, self.eviction_scan_size);
        try xdrEncodeGeneric(u32, writer, self.starting_eviction_scan_level);
    }
};

/// EvictionIterator is an XDR Struct defined as:
///
/// ```text
/// struct EvictionIterator {
///     uint32 bucketListLevel;
///     bool isCurrBucket;
///     uint64 bucketFileOffset;
/// };
/// ```
///
pub const EvictionIterator = struct {
    bucket_list_level: u32,
    is_curr_bucket: bool,
    bucket_file_offset: u64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !EvictionIterator {
        return EvictionIterator{
            .bucket_list_level = try xdrDecodeGeneric(u32, allocator, reader),
            .is_curr_bucket = try xdrDecodeGeneric(bool, allocator, reader),
            .bucket_file_offset = try xdrDecodeGeneric(u64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: EvictionIterator, writer: anytype) !void {
        try xdrEncodeGeneric(u32, writer, self.bucket_list_level);
        try xdrEncodeGeneric(bool, writer, self.is_curr_bucket);
        try xdrEncodeGeneric(u64, writer, self.bucket_file_offset);
    }
};

/// ConfigSettingScpTiming is an XDR Struct defined as:
///
/// ```text
/// struct ConfigSettingSCPTiming {
///     uint32 ledgerTargetCloseTimeMilliseconds;
///     uint32 nominationTimeoutInitialMilliseconds;
///     uint32 nominationTimeoutIncrementMilliseconds;
///     uint32 ballotTimeoutInitialMilliseconds;
///     uint32 ballotTimeoutIncrementMilliseconds;
/// };
/// ```
///
pub const ConfigSettingScpTiming = struct {
    ledger_target_close_time_milliseconds: u32,
    nomination_timeout_initial_milliseconds: u32,
    nomination_timeout_increment_milliseconds: u32,
    ballot_timeout_initial_milliseconds: u32,
    ballot_timeout_increment_milliseconds: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ConfigSettingScpTiming {
        return ConfigSettingScpTiming{
            .ledger_target_close_time_milliseconds = try xdrDecodeGeneric(u32, allocator, reader),
            .nomination_timeout_initial_milliseconds = try xdrDecodeGeneric(u32, allocator, reader),
            .nomination_timeout_increment_milliseconds = try xdrDecodeGeneric(u32, allocator, reader),
            .ballot_timeout_initial_milliseconds = try xdrDecodeGeneric(u32, allocator, reader),
            .ballot_timeout_increment_milliseconds = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ConfigSettingScpTiming, writer: anytype) !void {
        try xdrEncodeGeneric(u32, writer, self.ledger_target_close_time_milliseconds);
        try xdrEncodeGeneric(u32, writer, self.nomination_timeout_initial_milliseconds);
        try xdrEncodeGeneric(u32, writer, self.nomination_timeout_increment_milliseconds);
        try xdrEncodeGeneric(u32, writer, self.ballot_timeout_initial_milliseconds);
        try xdrEncodeGeneric(u32, writer, self.ballot_timeout_increment_milliseconds);
    }
};

/// ContractCostCountLimit is an XDR Const defined as:
///
/// ```text
/// const CONTRACT_COST_COUNT_LIMIT = 1024;
/// ```
///
pub const CONTRACT_COST_COUNT_LIMIT: u64 = 1024;

/// ContractCostParams is an XDR Typedef defined as:
///
/// ```text
/// typedef ContractCostParamEntry ContractCostParams<CONTRACT_COST_COUNT_LIMIT>;
/// ```
///
pub const ContractCostParams = struct {
    value: BoundedArray(ContractCostParamEntry, 1024),

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ContractCostParams {
        return ContractCostParams{
            .value = try xdrDecodeGeneric(BoundedArray(ContractCostParamEntry, 1024), allocator, reader),
        };
    }

    pub fn xdrEncode(self: ContractCostParams, writer: anytype) !void {
        try xdrEncodeGeneric(BoundedArray(ContractCostParamEntry, 1024), writer, self.value);
    }

    pub fn asSlice(self: ContractCostParams) []const ContractCostParamEntry {
        return self.value.data;
    }
};

/// ConfigSettingId is an XDR Enum defined as:
///
/// ```text
/// enum ConfigSettingID
/// {
///     CONFIG_SETTING_CONTRACT_MAX_SIZE_BYTES = 0,
///     CONFIG_SETTING_CONTRACT_COMPUTE_V0 = 1,
///     CONFIG_SETTING_CONTRACT_LEDGER_COST_V0 = 2,
///     CONFIG_SETTING_CONTRACT_HISTORICAL_DATA_V0 = 3,
///     CONFIG_SETTING_CONTRACT_EVENTS_V0 = 4,
///     CONFIG_SETTING_CONTRACT_BANDWIDTH_V0 = 5,
///     CONFIG_SETTING_CONTRACT_COST_PARAMS_CPU_INSTRUCTIONS = 6,
///     CONFIG_SETTING_CONTRACT_COST_PARAMS_MEMORY_BYTES = 7,
///     CONFIG_SETTING_CONTRACT_DATA_KEY_SIZE_BYTES = 8,
///     CONFIG_SETTING_CONTRACT_DATA_ENTRY_SIZE_BYTES = 9,
///     CONFIG_SETTING_STATE_ARCHIVAL = 10,
///     CONFIG_SETTING_CONTRACT_EXECUTION_LANES = 11,
///     CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW = 12,
///     CONFIG_SETTING_EVICTION_ITERATOR = 13,
///     CONFIG_SETTING_CONTRACT_PARALLEL_COMPUTE_V0 = 14,
///     CONFIG_SETTING_CONTRACT_LEDGER_COST_EXT_V0 = 15,
///     CONFIG_SETTING_SCP_TIMING = 16
/// };
/// ```
///
pub const ConfigSettingId = enum(i32) {
    ContractMaxSizeBytes = 0,
    ContractComputeV0 = 1,
    ContractLedgerCostV0 = 2,
    ContractHistoricalDataV0 = 3,
    ContractEventsV0 = 4,
    ContractBandwidthV0 = 5,
    ContractCostParamsCpuInstructions = 6,
    ContractCostParamsMemoryBytes = 7,
    ContractDataKeySizeBytes = 8,
    ContractDataEntrySizeBytes = 9,
    StateArchival = 10,
    ContractExecutionLanes = 11,
    LiveSorobanStateSizeWindow = 12,
    EvictionIterator = 13,
    ContractParallelComputeV0 = 14,
    ContractLedgerCostExtV0 = 15,
    ScpTiming = 16,
    _,

    pub const variants = [_]ConfigSettingId{
        .ContractMaxSizeBytes,
        .ContractComputeV0,
        .ContractLedgerCostV0,
        .ContractHistoricalDataV0,
        .ContractEventsV0,
        .ContractBandwidthV0,
        .ContractCostParamsCpuInstructions,
        .ContractCostParamsMemoryBytes,
        .ContractDataKeySizeBytes,
        .ContractDataEntrySizeBytes,
        .StateArchival,
        .ContractExecutionLanes,
        .LiveSorobanStateSizeWindow,
        .EvictionIterator,
        .ContractParallelComputeV0,
        .ContractLedgerCostExtV0,
        .ScpTiming,
    };

    pub fn name(self: ConfigSettingId) []const u8 {
        return switch (self) {
            .ContractMaxSizeBytes => "ContractMaxSizeBytes",
            .ContractComputeV0 => "ContractComputeV0",
            .ContractLedgerCostV0 => "ContractLedgerCostV0",
            .ContractHistoricalDataV0 => "ContractHistoricalDataV0",
            .ContractEventsV0 => "ContractEventsV0",
            .ContractBandwidthV0 => "ContractBandwidthV0",
            .ContractCostParamsCpuInstructions => "ContractCostParamsCpuInstructions",
            .ContractCostParamsMemoryBytes => "ContractCostParamsMemoryBytes",
            .ContractDataKeySizeBytes => "ContractDataKeySizeBytes",
            .ContractDataEntrySizeBytes => "ContractDataEntrySizeBytes",
            .StateArchival => "StateArchival",
            .ContractExecutionLanes => "ContractExecutionLanes",
            .LiveSorobanStateSizeWindow => "LiveSorobanStateSizeWindow",
            .EvictionIterator => "EvictionIterator",
            .ContractParallelComputeV0 => "ContractParallelComputeV0",
            .ContractLedgerCostExtV0 => "ContractLedgerCostExtV0",
            .ScpTiming => "ScpTiming",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ConfigSettingId {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ConfigSettingId, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ConfigSettingEntry is an XDR Union defined as:
///
/// ```text
/// union ConfigSettingEntry switch (ConfigSettingID configSettingID)
/// {
/// case CONFIG_SETTING_CONTRACT_MAX_SIZE_BYTES:
///     uint32 contractMaxSizeBytes;
/// case CONFIG_SETTING_CONTRACT_COMPUTE_V0:
///     ConfigSettingContractComputeV0 contractCompute;
/// case CONFIG_SETTING_CONTRACT_LEDGER_COST_V0:
///     ConfigSettingContractLedgerCostV0 contractLedgerCost;
/// case CONFIG_SETTING_CONTRACT_HISTORICAL_DATA_V0:
///     ConfigSettingContractHistoricalDataV0 contractHistoricalData;
/// case CONFIG_SETTING_CONTRACT_EVENTS_V0:
///     ConfigSettingContractEventsV0 contractEvents;
/// case CONFIG_SETTING_CONTRACT_BANDWIDTH_V0:
///     ConfigSettingContractBandwidthV0 contractBandwidth;
/// case CONFIG_SETTING_CONTRACT_COST_PARAMS_CPU_INSTRUCTIONS:
///     ContractCostParams contractCostParamsCpuInsns;
/// case CONFIG_SETTING_CONTRACT_COST_PARAMS_MEMORY_BYTES:
///     ContractCostParams contractCostParamsMemBytes;
/// case CONFIG_SETTING_CONTRACT_DATA_KEY_SIZE_BYTES:
///     uint32 contractDataKeySizeBytes;
/// case CONFIG_SETTING_CONTRACT_DATA_ENTRY_SIZE_BYTES:
///     uint32 contractDataEntrySizeBytes;
/// case CONFIG_SETTING_STATE_ARCHIVAL:
///     StateArchivalSettings stateArchivalSettings;
/// case CONFIG_SETTING_CONTRACT_EXECUTION_LANES:
///     ConfigSettingContractExecutionLanesV0 contractExecutionLanes;
/// case CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW:
///     uint64 liveSorobanStateSizeWindow<>;
/// case CONFIG_SETTING_EVICTION_ITERATOR:
///     EvictionIterator evictionIterator;
/// case CONFIG_SETTING_CONTRACT_PARALLEL_COMPUTE_V0:
///     ConfigSettingContractParallelComputeV0 contractParallelCompute;
/// case CONFIG_SETTING_CONTRACT_LEDGER_COST_EXT_V0:
///     ConfigSettingContractLedgerCostExtV0 contractLedgerCostExt;
/// case CONFIG_SETTING_SCP_TIMING:
///     ConfigSettingSCPTiming contractSCPTiming;
/// };
/// ```
///
pub const ConfigSettingEntry = union(enum) {
    ContractMaxSizeBytes: u32,
    ContractComputeV0: ConfigSettingContractComputeV0,
    ContractLedgerCostV0: ConfigSettingContractLedgerCostV0,
    ContractHistoricalDataV0: ConfigSettingContractHistoricalDataV0,
    ContractEventsV0: ConfigSettingContractEventsV0,
    ContractBandwidthV0: ConfigSettingContractBandwidthV0,
    ContractCostParamsCpuInstructions: ContractCostParams,
    ContractCostParamsMemoryBytes: ContractCostParams,
    ContractDataKeySizeBytes: u32,
    ContractDataEntrySizeBytes: u32,
    StateArchival: StateArchivalSettings,
    ContractExecutionLanes: ConfigSettingContractExecutionLanesV0,
    LiveSorobanStateSizeWindow: []u64,
    EvictionIterator: EvictionIterator,
    ContractParallelComputeV0: ConfigSettingContractParallelComputeV0,
    ContractLedgerCostExtV0: ConfigSettingContractLedgerCostExtV0,
    ScpTiming: ConfigSettingScpTiming,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ConfigSettingEntry {
        const disc = try ConfigSettingId.xdrDecode(allocator, reader);
        return switch (disc) {
            .ContractMaxSizeBytes => ConfigSettingEntry{ .ContractMaxSizeBytes = try xdrDecodeGeneric(u32, allocator, reader) },
            .ContractComputeV0 => ConfigSettingEntry{ .ContractComputeV0 = try xdrDecodeGeneric(ConfigSettingContractComputeV0, allocator, reader) },
            .ContractLedgerCostV0 => ConfigSettingEntry{ .ContractLedgerCostV0 = try xdrDecodeGeneric(ConfigSettingContractLedgerCostV0, allocator, reader) },
            .ContractHistoricalDataV0 => ConfigSettingEntry{ .ContractHistoricalDataV0 = try xdrDecodeGeneric(ConfigSettingContractHistoricalDataV0, allocator, reader) },
            .ContractEventsV0 => ConfigSettingEntry{ .ContractEventsV0 = try xdrDecodeGeneric(ConfigSettingContractEventsV0, allocator, reader) },
            .ContractBandwidthV0 => ConfigSettingEntry{ .ContractBandwidthV0 = try xdrDecodeGeneric(ConfigSettingContractBandwidthV0, allocator, reader) },
            .ContractCostParamsCpuInstructions => ConfigSettingEntry{ .ContractCostParamsCpuInstructions = try xdrDecodeGeneric(ContractCostParams, allocator, reader) },
            .ContractCostParamsMemoryBytes => ConfigSettingEntry{ .ContractCostParamsMemoryBytes = try xdrDecodeGeneric(ContractCostParams, allocator, reader) },
            .ContractDataKeySizeBytes => ConfigSettingEntry{ .ContractDataKeySizeBytes = try xdrDecodeGeneric(u32, allocator, reader) },
            .ContractDataEntrySizeBytes => ConfigSettingEntry{ .ContractDataEntrySizeBytes = try xdrDecodeGeneric(u32, allocator, reader) },
            .StateArchival => ConfigSettingEntry{ .StateArchival = try xdrDecodeGeneric(StateArchivalSettings, allocator, reader) },
            .ContractExecutionLanes => ConfigSettingEntry{ .ContractExecutionLanes = try xdrDecodeGeneric(ConfigSettingContractExecutionLanesV0, allocator, reader) },
            .LiveSorobanStateSizeWindow => ConfigSettingEntry{ .LiveSorobanStateSizeWindow = try xdrDecodeGeneric([]u64, allocator, reader) },
            .EvictionIterator => ConfigSettingEntry{ .EvictionIterator = try xdrDecodeGeneric(EvictionIterator, allocator, reader) },
            .ContractParallelComputeV0 => ConfigSettingEntry{ .ContractParallelComputeV0 = try xdrDecodeGeneric(ConfigSettingContractParallelComputeV0, allocator, reader) },
            .ContractLedgerCostExtV0 => ConfigSettingEntry{ .ContractLedgerCostExtV0 = try xdrDecodeGeneric(ConfigSettingContractLedgerCostExtV0, allocator, reader) },
            .ScpTiming => ConfigSettingEntry{ .ScpTiming = try xdrDecodeGeneric(ConfigSettingScpTiming, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ConfigSettingEntry, writer: anytype) !void {
        const disc: ConfigSettingId = switch (self) {
            .ContractMaxSizeBytes => .ContractMaxSizeBytes,
            .ContractComputeV0 => .ContractComputeV0,
            .ContractLedgerCostV0 => .ContractLedgerCostV0,
            .ContractHistoricalDataV0 => .ContractHistoricalDataV0,
            .ContractEventsV0 => .ContractEventsV0,
            .ContractBandwidthV0 => .ContractBandwidthV0,
            .ContractCostParamsCpuInstructions => .ContractCostParamsCpuInstructions,
            .ContractCostParamsMemoryBytes => .ContractCostParamsMemoryBytes,
            .ContractDataKeySizeBytes => .ContractDataKeySizeBytes,
            .ContractDataEntrySizeBytes => .ContractDataEntrySizeBytes,
            .StateArchival => .StateArchival,
            .ContractExecutionLanes => .ContractExecutionLanes,
            .LiveSorobanStateSizeWindow => .LiveSorobanStateSizeWindow,
            .EvictionIterator => .EvictionIterator,
            .ContractParallelComputeV0 => .ContractParallelComputeV0,
            .ContractLedgerCostExtV0 => .ContractLedgerCostExtV0,
            .ScpTiming => .ScpTiming,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .ContractMaxSizeBytes => |v| try xdrEncodeGeneric(u32, writer, v),
            .ContractComputeV0 => |v| try xdrEncodeGeneric(ConfigSettingContractComputeV0, writer, v),
            .ContractLedgerCostV0 => |v| try xdrEncodeGeneric(ConfigSettingContractLedgerCostV0, writer, v),
            .ContractHistoricalDataV0 => |v| try xdrEncodeGeneric(ConfigSettingContractHistoricalDataV0, writer, v),
            .ContractEventsV0 => |v| try xdrEncodeGeneric(ConfigSettingContractEventsV0, writer, v),
            .ContractBandwidthV0 => |v| try xdrEncodeGeneric(ConfigSettingContractBandwidthV0, writer, v),
            .ContractCostParamsCpuInstructions => |v| try xdrEncodeGeneric(ContractCostParams, writer, v),
            .ContractCostParamsMemoryBytes => |v| try xdrEncodeGeneric(ContractCostParams, writer, v),
            .ContractDataKeySizeBytes => |v| try xdrEncodeGeneric(u32, writer, v),
            .ContractDataEntrySizeBytes => |v| try xdrEncodeGeneric(u32, writer, v),
            .StateArchival => |v| try xdrEncodeGeneric(StateArchivalSettings, writer, v),
            .ContractExecutionLanes => |v| try xdrEncodeGeneric(ConfigSettingContractExecutionLanesV0, writer, v),
            .LiveSorobanStateSizeWindow => |v| try xdrEncodeGeneric([]u64, writer, v),
            .EvictionIterator => |v| try xdrEncodeGeneric(EvictionIterator, writer, v),
            .ContractParallelComputeV0 => |v| try xdrEncodeGeneric(ConfigSettingContractParallelComputeV0, writer, v),
            .ContractLedgerCostExtV0 => |v| try xdrEncodeGeneric(ConfigSettingContractLedgerCostExtV0, writer, v),
            .ScpTiming => |v| try xdrEncodeGeneric(ConfigSettingScpTiming, writer, v),
        }
    }
};

/// ScEnvMetaKind is an XDR Enum defined as:
///
/// ```text
/// enum SCEnvMetaKind
/// {
///     SC_ENV_META_KIND_INTERFACE_VERSION = 0
/// };
/// ```
///
pub const ScEnvMetaKind = enum(i32) {
    ScEnvMetaKindInterfaceVersion = 0,
    _,

    pub const variants = [_]ScEnvMetaKind{
        .ScEnvMetaKindInterfaceVersion,
    };

    pub fn name(self: ScEnvMetaKind) []const u8 {
        return switch (self) {
            .ScEnvMetaKindInterfaceVersion => "ScEnvMetaKindInterfaceVersion",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScEnvMetaKind {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ScEnvMetaKind, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ScEnvMetaEntryInterfaceVersion is an XDR NestedStruct defined as:
///
/// ```text
/// struct {
///         uint32 protocol;
///         uint32 preRelease;
///     }
/// ```
///
pub const ScEnvMetaEntryInterfaceVersion = struct {
    protocol: u32,
    pre_release: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScEnvMetaEntryInterfaceVersion {
        return ScEnvMetaEntryInterfaceVersion{
            .protocol = try xdrDecodeGeneric(u32, allocator, reader),
            .pre_release = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScEnvMetaEntryInterfaceVersion, writer: anytype) !void {
        try xdrEncodeGeneric(u32, writer, self.protocol);
        try xdrEncodeGeneric(u32, writer, self.pre_release);
    }
};

/// ScEnvMetaEntry is an XDR Union defined as:
///
/// ```text
/// union SCEnvMetaEntry switch (SCEnvMetaKind kind)
/// {
/// case SC_ENV_META_KIND_INTERFACE_VERSION:
///     struct {
///         uint32 protocol;
///         uint32 preRelease;
///     } interfaceVersion;
/// };
/// ```
///
pub const ScEnvMetaEntry = union(enum) {
    ScEnvMetaKindInterfaceVersion: ScEnvMetaEntryInterfaceVersion,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScEnvMetaEntry {
        const disc = try ScEnvMetaKind.xdrDecode(allocator, reader);
        return switch (disc) {
            .ScEnvMetaKindInterfaceVersion => ScEnvMetaEntry{ .ScEnvMetaKindInterfaceVersion = try xdrDecodeGeneric(ScEnvMetaEntryInterfaceVersion, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ScEnvMetaEntry, writer: anytype) !void {
        const disc: ScEnvMetaKind = switch (self) {
            .ScEnvMetaKindInterfaceVersion => .ScEnvMetaKindInterfaceVersion,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .ScEnvMetaKindInterfaceVersion => |v| try xdrEncodeGeneric(ScEnvMetaEntryInterfaceVersion, writer, v),
        }
    }
};

/// ScMetaV0 is an XDR Struct defined as:
///
/// ```text
/// struct SCMetaV0
/// {
///     string key<>;
///     string val<>;
/// };
/// ```
///
pub const ScMetaV0 = struct {
    key: []u8,
    val: []u8,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScMetaV0 {
        return ScMetaV0{
            .key = try xdrDecodeGeneric([]u8, allocator, reader),
            .val = try xdrDecodeGeneric([]u8, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScMetaV0, writer: anytype) !void {
        try xdrEncodeGeneric([]u8, writer, self.key);
        try xdrEncodeGeneric([]u8, writer, self.val);
    }
};

/// ScMetaKind is an XDR Enum defined as:
///
/// ```text
/// enum SCMetaKind
/// {
///     SC_META_V0 = 0
/// };
/// ```
///
pub const ScMetaKind = enum(i32) {
    ScMetaV0 = 0,
    _,

    pub const variants = [_]ScMetaKind{
        .ScMetaV0,
    };

    pub fn name(self: ScMetaKind) []const u8 {
        return switch (self) {
            .ScMetaV0 => "ScMetaV0",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScMetaKind {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ScMetaKind, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ScMetaEntry is an XDR Union defined as:
///
/// ```text
/// union SCMetaEntry switch (SCMetaKind kind)
/// {
/// case SC_META_V0:
///     SCMetaV0 v0;
/// };
/// ```
///
pub const ScMetaEntry = union(enum) {
    ScMetaV0: ScMetaV0,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScMetaEntry {
        const disc = try ScMetaKind.xdrDecode(allocator, reader);
        return switch (disc) {
            .ScMetaV0 => ScMetaEntry{ .ScMetaV0 = try xdrDecodeGeneric(ScMetaV0, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ScMetaEntry, writer: anytype) !void {
        const disc: ScMetaKind = switch (self) {
            .ScMetaV0 => .ScMetaV0,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .ScMetaV0 => |v| try xdrEncodeGeneric(ScMetaV0, writer, v),
        }
    }
};

/// ScSpecDocLimit is an XDR Const defined as:
///
/// ```text
/// const SC_SPEC_DOC_LIMIT = 1024;
/// ```
///
pub const SC_SPEC_DOC_LIMIT: u64 = 1024;

/// ScSpecType is an XDR Enum defined as:
///
/// ```text
/// enum SCSpecType
/// {
///     SC_SPEC_TYPE_VAL = 0,
///
///     // Types with no parameters.
///     SC_SPEC_TYPE_BOOL = 1,
///     SC_SPEC_TYPE_VOID = 2,
///     SC_SPEC_TYPE_ERROR = 3,
///     SC_SPEC_TYPE_U32 = 4,
///     SC_SPEC_TYPE_I32 = 5,
///     SC_SPEC_TYPE_U64 = 6,
///     SC_SPEC_TYPE_I64 = 7,
///     SC_SPEC_TYPE_TIMEPOINT = 8,
///     SC_SPEC_TYPE_DURATION = 9,
///     SC_SPEC_TYPE_U128 = 10,
///     SC_SPEC_TYPE_I128 = 11,
///     SC_SPEC_TYPE_U256 = 12,
///     SC_SPEC_TYPE_I256 = 13,
///     SC_SPEC_TYPE_BYTES = 14,
///     SC_SPEC_TYPE_STRING = 16,
///     SC_SPEC_TYPE_SYMBOL = 17,
///     SC_SPEC_TYPE_ADDRESS = 19,
///     SC_SPEC_TYPE_MUXED_ADDRESS = 20,
///
///     // Types with parameters.
///     SC_SPEC_TYPE_OPTION = 1000,
///     SC_SPEC_TYPE_RESULT = 1001,
///     SC_SPEC_TYPE_VEC = 1002,
///     SC_SPEC_TYPE_MAP = 1004,
///     SC_SPEC_TYPE_TUPLE = 1005,
///     SC_SPEC_TYPE_BYTES_N = 1006,
///
///     // User defined types.
///     SC_SPEC_TYPE_UDT = 2000
/// };
/// ```
///
pub const ScSpecType = enum(i32) {
    Val = 0,
    Bool = 1,
    Void = 2,
    Error = 3,
    U32 = 4,
    I32 = 5,
    U64 = 6,
    I64 = 7,
    Timepoint = 8,
    Duration = 9,
    U128 = 10,
    I128 = 11,
    U256 = 12,
    I256 = 13,
    Bytes = 14,
    String = 16,
    Symbol = 17,
    Address = 19,
    MuxedAddress = 20,
    Option = 1000,
    Result = 1001,
    Vec = 1002,
    Map = 1004,
    Tuple = 1005,
    BytesN = 1006,
    Udt = 2000,
    _,

    pub const variants = [_]ScSpecType{
        .Val,
        .Bool,
        .Void,
        .Error,
        .U32,
        .I32,
        .U64,
        .I64,
        .Timepoint,
        .Duration,
        .U128,
        .I128,
        .U256,
        .I256,
        .Bytes,
        .String,
        .Symbol,
        .Address,
        .MuxedAddress,
        .Option,
        .Result,
        .Vec,
        .Map,
        .Tuple,
        .BytesN,
        .Udt,
    };

    pub fn name(self: ScSpecType) []const u8 {
        return switch (self) {
            .Val => "Val",
            .Bool => "Bool",
            .Void => "Void",
            .Error => "Error",
            .U32 => "U32",
            .I32 => "I32",
            .U64 => "U64",
            .I64 => "I64",
            .Timepoint => "Timepoint",
            .Duration => "Duration",
            .U128 => "U128",
            .I128 => "I128",
            .U256 => "U256",
            .I256 => "I256",
            .Bytes => "Bytes",
            .String => "String",
            .Symbol => "Symbol",
            .Address => "Address",
            .MuxedAddress => "MuxedAddress",
            .Option => "Option",
            .Result => "Result",
            .Vec => "Vec",
            .Map => "Map",
            .Tuple => "Tuple",
            .BytesN => "BytesN",
            .Udt => "Udt",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ScSpecType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ScSpecTypeOption is an XDR Struct defined as:
///
/// ```text
/// struct SCSpecTypeOption
/// {
///     SCSpecTypeDef valueType;
/// };
/// ```
///
pub const ScSpecTypeOption = struct {
    value_type: *ScSpecTypeDef,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecTypeOption {
        return ScSpecTypeOption{
            .value_type = try xdrDecodeGeneric(*ScSpecTypeDef, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScSpecTypeOption, writer: anytype) !void {
        try xdrEncodeGeneric(*ScSpecTypeDef, writer, self.value_type);
    }
};

/// ScSpecTypeResult is an XDR Struct defined as:
///
/// ```text
/// struct SCSpecTypeResult
/// {
///     SCSpecTypeDef okType;
///     SCSpecTypeDef errorType;
/// };
/// ```
///
pub const ScSpecTypeResult = struct {
    ok_type: *ScSpecTypeDef,
    error_type: *ScSpecTypeDef,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecTypeResult {
        return ScSpecTypeResult{
            .ok_type = try xdrDecodeGeneric(*ScSpecTypeDef, allocator, reader),
            .error_type = try xdrDecodeGeneric(*ScSpecTypeDef, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScSpecTypeResult, writer: anytype) !void {
        try xdrEncodeGeneric(*ScSpecTypeDef, writer, self.ok_type);
        try xdrEncodeGeneric(*ScSpecTypeDef, writer, self.error_type);
    }
};

/// ScSpecTypeVec is an XDR Struct defined as:
///
/// ```text
/// struct SCSpecTypeVec
/// {
///     SCSpecTypeDef elementType;
/// };
/// ```
///
pub const ScSpecTypeVec = struct {
    element_type: *ScSpecTypeDef,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecTypeVec {
        return ScSpecTypeVec{
            .element_type = try xdrDecodeGeneric(*ScSpecTypeDef, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScSpecTypeVec, writer: anytype) !void {
        try xdrEncodeGeneric(*ScSpecTypeDef, writer, self.element_type);
    }
};

/// ScSpecTypeMap is an XDR Struct defined as:
///
/// ```text
/// struct SCSpecTypeMap
/// {
///     SCSpecTypeDef keyType;
///     SCSpecTypeDef valueType;
/// };
/// ```
///
pub const ScSpecTypeMap = struct {
    key_type: *ScSpecTypeDef,
    value_type: *ScSpecTypeDef,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecTypeMap {
        return ScSpecTypeMap{
            .key_type = try xdrDecodeGeneric(*ScSpecTypeDef, allocator, reader),
            .value_type = try xdrDecodeGeneric(*ScSpecTypeDef, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScSpecTypeMap, writer: anytype) !void {
        try xdrEncodeGeneric(*ScSpecTypeDef, writer, self.key_type);
        try xdrEncodeGeneric(*ScSpecTypeDef, writer, self.value_type);
    }
};

/// ScSpecTypeTuple is an XDR Struct defined as:
///
/// ```text
/// struct SCSpecTypeTuple
/// {
///     SCSpecTypeDef valueTypes<12>;
/// };
/// ```
///
pub const ScSpecTypeTuple = struct {
    value_types: BoundedArray(ScSpecTypeDef, 12),

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecTypeTuple {
        return ScSpecTypeTuple{
            .value_types = try xdrDecodeGeneric(BoundedArray(ScSpecTypeDef, 12), allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScSpecTypeTuple, writer: anytype) !void {
        try xdrEncodeGeneric(BoundedArray(ScSpecTypeDef, 12), writer, self.value_types);
    }
};

/// ScSpecTypeBytesN is an XDR Struct defined as:
///
/// ```text
/// struct SCSpecTypeBytesN
/// {
///     uint32 n;
/// };
/// ```
///
pub const ScSpecTypeBytesN = struct {
    n: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecTypeBytesN {
        return ScSpecTypeBytesN{
            .n = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScSpecTypeBytesN, writer: anytype) !void {
        try xdrEncodeGeneric(u32, writer, self.n);
    }
};

/// ScSpecTypeUdt is an XDR Struct defined as:
///
/// ```text
/// struct SCSpecTypeUDT
/// {
///     string name<60>;
/// };
/// ```
///
pub const ScSpecTypeUdt = struct {
    name: BoundedArray(u8, 60),

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecTypeUdt {
        return ScSpecTypeUdt{
            .name = try xdrDecodeGeneric(BoundedArray(u8, 60), allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScSpecTypeUdt, writer: anytype) !void {
        try xdrEncodeGeneric(BoundedArray(u8, 60), writer, self.name);
    }
};

/// ScSpecTypeDef is an XDR Union defined as:
///
/// ```text
/// union SCSpecTypeDef switch (SCSpecType type)
/// {
/// case SC_SPEC_TYPE_VAL:
/// case SC_SPEC_TYPE_BOOL:
/// case SC_SPEC_TYPE_VOID:
/// case SC_SPEC_TYPE_ERROR:
/// case SC_SPEC_TYPE_U32:
/// case SC_SPEC_TYPE_I32:
/// case SC_SPEC_TYPE_U64:
/// case SC_SPEC_TYPE_I64:
/// case SC_SPEC_TYPE_TIMEPOINT:
/// case SC_SPEC_TYPE_DURATION:
/// case SC_SPEC_TYPE_U128:
/// case SC_SPEC_TYPE_I128:
/// case SC_SPEC_TYPE_U256:
/// case SC_SPEC_TYPE_I256:
/// case SC_SPEC_TYPE_BYTES:
/// case SC_SPEC_TYPE_STRING:
/// case SC_SPEC_TYPE_SYMBOL:
/// case SC_SPEC_TYPE_ADDRESS:
/// case SC_SPEC_TYPE_MUXED_ADDRESS:
///     void;
/// case SC_SPEC_TYPE_OPTION:
///     SCSpecTypeOption option;
/// case SC_SPEC_TYPE_RESULT:
///     SCSpecTypeResult result;
/// case SC_SPEC_TYPE_VEC:
///     SCSpecTypeVec vec;
/// case SC_SPEC_TYPE_MAP:
///     SCSpecTypeMap map;
/// case SC_SPEC_TYPE_TUPLE:
///     SCSpecTypeTuple tuple;
/// case SC_SPEC_TYPE_BYTES_N:
///     SCSpecTypeBytesN bytesN;
/// case SC_SPEC_TYPE_UDT:
///     SCSpecTypeUDT udt;
/// };
/// ```
///
pub const ScSpecTypeDef = union(enum) {
    Val,
    Bool,
    Void,
    Error,
    U32,
    I32,
    U64,
    I64,
    Timepoint,
    Duration,
    U128,
    I128,
    U256,
    I256,
    Bytes,
    String,
    Symbol,
    Address,
    MuxedAddress,
    Option: *ScSpecTypeOption,
    Result: *ScSpecTypeResult,
    Vec: *ScSpecTypeVec,
    Map: *ScSpecTypeMap,
    Tuple: *ScSpecTypeTuple,
    BytesN: ScSpecTypeBytesN,
    Udt: ScSpecTypeUdt,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecTypeDef {
        const disc = try ScSpecType.xdrDecode(allocator, reader);
        return switch (disc) {
            .Val => ScSpecTypeDef{ .Val = {} },
            .Bool => ScSpecTypeDef{ .Bool = {} },
            .Void => ScSpecTypeDef{ .Void = {} },
            .Error => ScSpecTypeDef{ .Error = {} },
            .U32 => ScSpecTypeDef{ .U32 = {} },
            .I32 => ScSpecTypeDef{ .I32 = {} },
            .U64 => ScSpecTypeDef{ .U64 = {} },
            .I64 => ScSpecTypeDef{ .I64 = {} },
            .Timepoint => ScSpecTypeDef{ .Timepoint = {} },
            .Duration => ScSpecTypeDef{ .Duration = {} },
            .U128 => ScSpecTypeDef{ .U128 = {} },
            .I128 => ScSpecTypeDef{ .I128 = {} },
            .U256 => ScSpecTypeDef{ .U256 = {} },
            .I256 => ScSpecTypeDef{ .I256 = {} },
            .Bytes => ScSpecTypeDef{ .Bytes = {} },
            .String => ScSpecTypeDef{ .String = {} },
            .Symbol => ScSpecTypeDef{ .Symbol = {} },
            .Address => ScSpecTypeDef{ .Address = {} },
            .MuxedAddress => ScSpecTypeDef{ .MuxedAddress = {} },
            .Option => ScSpecTypeDef{ .Option = try xdrDecodeGeneric(*ScSpecTypeOption, allocator, reader) },
            .Result => ScSpecTypeDef{ .Result = try xdrDecodeGeneric(*ScSpecTypeResult, allocator, reader) },
            .Vec => ScSpecTypeDef{ .Vec = try xdrDecodeGeneric(*ScSpecTypeVec, allocator, reader) },
            .Map => ScSpecTypeDef{ .Map = try xdrDecodeGeneric(*ScSpecTypeMap, allocator, reader) },
            .Tuple => ScSpecTypeDef{ .Tuple = try xdrDecodeGeneric(*ScSpecTypeTuple, allocator, reader) },
            .BytesN => ScSpecTypeDef{ .BytesN = try xdrDecodeGeneric(ScSpecTypeBytesN, allocator, reader) },
            .Udt => ScSpecTypeDef{ .Udt = try xdrDecodeGeneric(ScSpecTypeUdt, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ScSpecTypeDef, writer: anytype) !void {
        const disc: ScSpecType = switch (self) {
            .Val => .Val,
            .Bool => .Bool,
            .Void => .Void,
            .Error => .Error,
            .U32 => .U32,
            .I32 => .I32,
            .U64 => .U64,
            .I64 => .I64,
            .Timepoint => .Timepoint,
            .Duration => .Duration,
            .U128 => .U128,
            .I128 => .I128,
            .U256 => .U256,
            .I256 => .I256,
            .Bytes => .Bytes,
            .String => .String,
            .Symbol => .Symbol,
            .Address => .Address,
            .MuxedAddress => .MuxedAddress,
            .Option => .Option,
            .Result => .Result,
            .Vec => .Vec,
            .Map => .Map,
            .Tuple => .Tuple,
            .BytesN => .BytesN,
            .Udt => .Udt,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Val => {},
            .Bool => {},
            .Void => {},
            .Error => {},
            .U32 => {},
            .I32 => {},
            .U64 => {},
            .I64 => {},
            .Timepoint => {},
            .Duration => {},
            .U128 => {},
            .I128 => {},
            .U256 => {},
            .I256 => {},
            .Bytes => {},
            .String => {},
            .Symbol => {},
            .Address => {},
            .MuxedAddress => {},
            .Option => |v| try xdrEncodeGeneric(*ScSpecTypeOption, writer, v),
            .Result => |v| try xdrEncodeGeneric(*ScSpecTypeResult, writer, v),
            .Vec => |v| try xdrEncodeGeneric(*ScSpecTypeVec, writer, v),
            .Map => |v| try xdrEncodeGeneric(*ScSpecTypeMap, writer, v),
            .Tuple => |v| try xdrEncodeGeneric(*ScSpecTypeTuple, writer, v),
            .BytesN => |v| try xdrEncodeGeneric(ScSpecTypeBytesN, writer, v),
            .Udt => |v| try xdrEncodeGeneric(ScSpecTypeUdt, writer, v),
        }
    }
};

/// ScSpecUdtStructFieldV0 is an XDR Struct defined as:
///
/// ```text
/// struct SCSpecUDTStructFieldV0
/// {
///     string doc<SC_SPEC_DOC_LIMIT>;
///     string name<30>;
///     SCSpecTypeDef type;
/// };
/// ```
///
pub const ScSpecUdtStructFieldV0 = struct {
    doc: BoundedArray(u8, 1024),
    name: BoundedArray(u8, 30),
    type: ScSpecTypeDef,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecUdtStructFieldV0 {
        return ScSpecUdtStructFieldV0{
            .doc = try xdrDecodeGeneric(BoundedArray(u8, 1024), allocator, reader),
            .name = try xdrDecodeGeneric(BoundedArray(u8, 30), allocator, reader),
            .type = try xdrDecodeGeneric(ScSpecTypeDef, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScSpecUdtStructFieldV0, writer: anytype) !void {
        try xdrEncodeGeneric(BoundedArray(u8, 1024), writer, self.doc);
        try xdrEncodeGeneric(BoundedArray(u8, 30), writer, self.name);
        try xdrEncodeGeneric(ScSpecTypeDef, writer, self.type);
    }
};

/// ScSpecUdtStructV0 is an XDR Struct defined as:
///
/// ```text
/// struct SCSpecUDTStructV0
/// {
///     string doc<SC_SPEC_DOC_LIMIT>;
///     string lib<80>;
///     string name<60>;
///     SCSpecUDTStructFieldV0 fields<>;
/// };
/// ```
///
pub const ScSpecUdtStructV0 = struct {
    doc: BoundedArray(u8, 1024),
    lib: BoundedArray(u8, 80),
    name: BoundedArray(u8, 60),
    fields: []ScSpecUdtStructFieldV0,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecUdtStructV0 {
        return ScSpecUdtStructV0{
            .doc = try xdrDecodeGeneric(BoundedArray(u8, 1024), allocator, reader),
            .lib = try xdrDecodeGeneric(BoundedArray(u8, 80), allocator, reader),
            .name = try xdrDecodeGeneric(BoundedArray(u8, 60), allocator, reader),
            .fields = try xdrDecodeGeneric([]ScSpecUdtStructFieldV0, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScSpecUdtStructV0, writer: anytype) !void {
        try xdrEncodeGeneric(BoundedArray(u8, 1024), writer, self.doc);
        try xdrEncodeGeneric(BoundedArray(u8, 80), writer, self.lib);
        try xdrEncodeGeneric(BoundedArray(u8, 60), writer, self.name);
        try xdrEncodeGeneric([]ScSpecUdtStructFieldV0, writer, self.fields);
    }
};

/// ScSpecUdtUnionCaseVoidV0 is an XDR Struct defined as:
///
/// ```text
/// struct SCSpecUDTUnionCaseVoidV0
/// {
///     string doc<SC_SPEC_DOC_LIMIT>;
///     string name<60>;
/// };
/// ```
///
pub const ScSpecUdtUnionCaseVoidV0 = struct {
    doc: BoundedArray(u8, 1024),
    name: BoundedArray(u8, 60),

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecUdtUnionCaseVoidV0 {
        return ScSpecUdtUnionCaseVoidV0{
            .doc = try xdrDecodeGeneric(BoundedArray(u8, 1024), allocator, reader),
            .name = try xdrDecodeGeneric(BoundedArray(u8, 60), allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScSpecUdtUnionCaseVoidV0, writer: anytype) !void {
        try xdrEncodeGeneric(BoundedArray(u8, 1024), writer, self.doc);
        try xdrEncodeGeneric(BoundedArray(u8, 60), writer, self.name);
    }
};

/// ScSpecUdtUnionCaseTupleV0 is an XDR Struct defined as:
///
/// ```text
/// struct SCSpecUDTUnionCaseTupleV0
/// {
///     string doc<SC_SPEC_DOC_LIMIT>;
///     string name<60>;
///     SCSpecTypeDef type<>;
/// };
/// ```
///
pub const ScSpecUdtUnionCaseTupleV0 = struct {
    doc: BoundedArray(u8, 1024),
    name: BoundedArray(u8, 60),
    type: []ScSpecTypeDef,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecUdtUnionCaseTupleV0 {
        return ScSpecUdtUnionCaseTupleV0{
            .doc = try xdrDecodeGeneric(BoundedArray(u8, 1024), allocator, reader),
            .name = try xdrDecodeGeneric(BoundedArray(u8, 60), allocator, reader),
            .type = try xdrDecodeGeneric([]ScSpecTypeDef, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScSpecUdtUnionCaseTupleV0, writer: anytype) !void {
        try xdrEncodeGeneric(BoundedArray(u8, 1024), writer, self.doc);
        try xdrEncodeGeneric(BoundedArray(u8, 60), writer, self.name);
        try xdrEncodeGeneric([]ScSpecTypeDef, writer, self.type);
    }
};

/// ScSpecUdtUnionCaseV0Kind is an XDR Enum defined as:
///
/// ```text
/// enum SCSpecUDTUnionCaseV0Kind
/// {
///     SC_SPEC_UDT_UNION_CASE_VOID_V0 = 0,
///     SC_SPEC_UDT_UNION_CASE_TUPLE_V0 = 1
/// };
/// ```
///
pub const ScSpecUdtUnionCaseV0Kind = enum(i32) {
    VoidV0 = 0,
    TupleV0 = 1,
    _,

    pub const variants = [_]ScSpecUdtUnionCaseV0Kind{
        .VoidV0,
        .TupleV0,
    };

    pub fn name(self: ScSpecUdtUnionCaseV0Kind) []const u8 {
        return switch (self) {
            .VoidV0 => "VoidV0",
            .TupleV0 => "TupleV0",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecUdtUnionCaseV0Kind {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ScSpecUdtUnionCaseV0Kind, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ScSpecUdtUnionCaseV0 is an XDR Union defined as:
///
/// ```text
/// union SCSpecUDTUnionCaseV0 switch (SCSpecUDTUnionCaseV0Kind kind)
/// {
/// case SC_SPEC_UDT_UNION_CASE_VOID_V0:
///     SCSpecUDTUnionCaseVoidV0 voidCase;
/// case SC_SPEC_UDT_UNION_CASE_TUPLE_V0:
///     SCSpecUDTUnionCaseTupleV0 tupleCase;
/// };
/// ```
///
pub const ScSpecUdtUnionCaseV0 = union(enum) {
    VoidV0: ScSpecUdtUnionCaseVoidV0,
    TupleV0: ScSpecUdtUnionCaseTupleV0,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecUdtUnionCaseV0 {
        const disc = try ScSpecUdtUnionCaseV0Kind.xdrDecode(allocator, reader);
        return switch (disc) {
            .VoidV0 => ScSpecUdtUnionCaseV0{ .VoidV0 = try xdrDecodeGeneric(ScSpecUdtUnionCaseVoidV0, allocator, reader) },
            .TupleV0 => ScSpecUdtUnionCaseV0{ .TupleV0 = try xdrDecodeGeneric(ScSpecUdtUnionCaseTupleV0, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ScSpecUdtUnionCaseV0, writer: anytype) !void {
        const disc: ScSpecUdtUnionCaseV0Kind = switch (self) {
            .VoidV0 => .VoidV0,
            .TupleV0 => .TupleV0,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .VoidV0 => |v| try xdrEncodeGeneric(ScSpecUdtUnionCaseVoidV0, writer, v),
            .TupleV0 => |v| try xdrEncodeGeneric(ScSpecUdtUnionCaseTupleV0, writer, v),
        }
    }
};

/// ScSpecUdtUnionV0 is an XDR Struct defined as:
///
/// ```text
/// struct SCSpecUDTUnionV0
/// {
///     string doc<SC_SPEC_DOC_LIMIT>;
///     string lib<80>;
///     string name<60>;
///     SCSpecUDTUnionCaseV0 cases<>;
/// };
/// ```
///
pub const ScSpecUdtUnionV0 = struct {
    doc: BoundedArray(u8, 1024),
    lib: BoundedArray(u8, 80),
    name: BoundedArray(u8, 60),
    cases: []ScSpecUdtUnionCaseV0,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecUdtUnionV0 {
        return ScSpecUdtUnionV0{
            .doc = try xdrDecodeGeneric(BoundedArray(u8, 1024), allocator, reader),
            .lib = try xdrDecodeGeneric(BoundedArray(u8, 80), allocator, reader),
            .name = try xdrDecodeGeneric(BoundedArray(u8, 60), allocator, reader),
            .cases = try xdrDecodeGeneric([]ScSpecUdtUnionCaseV0, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScSpecUdtUnionV0, writer: anytype) !void {
        try xdrEncodeGeneric(BoundedArray(u8, 1024), writer, self.doc);
        try xdrEncodeGeneric(BoundedArray(u8, 80), writer, self.lib);
        try xdrEncodeGeneric(BoundedArray(u8, 60), writer, self.name);
        try xdrEncodeGeneric([]ScSpecUdtUnionCaseV0, writer, self.cases);
    }
};

/// ScSpecUdtEnumCaseV0 is an XDR Struct defined as:
///
/// ```text
/// struct SCSpecUDTEnumCaseV0
/// {
///     string doc<SC_SPEC_DOC_LIMIT>;
///     string name<60>;
///     uint32 value;
/// };
/// ```
///
pub const ScSpecUdtEnumCaseV0 = struct {
    doc: BoundedArray(u8, 1024),
    name: BoundedArray(u8, 60),
    value: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecUdtEnumCaseV0 {
        return ScSpecUdtEnumCaseV0{
            .doc = try xdrDecodeGeneric(BoundedArray(u8, 1024), allocator, reader),
            .name = try xdrDecodeGeneric(BoundedArray(u8, 60), allocator, reader),
            .value = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScSpecUdtEnumCaseV0, writer: anytype) !void {
        try xdrEncodeGeneric(BoundedArray(u8, 1024), writer, self.doc);
        try xdrEncodeGeneric(BoundedArray(u8, 60), writer, self.name);
        try xdrEncodeGeneric(u32, writer, self.value);
    }
};

/// ScSpecUdtEnumV0 is an XDR Struct defined as:
///
/// ```text
/// struct SCSpecUDTEnumV0
/// {
///     string doc<SC_SPEC_DOC_LIMIT>;
///     string lib<80>;
///     string name<60>;
///     SCSpecUDTEnumCaseV0 cases<>;
/// };
/// ```
///
pub const ScSpecUdtEnumV0 = struct {
    doc: BoundedArray(u8, 1024),
    lib: BoundedArray(u8, 80),
    name: BoundedArray(u8, 60),
    cases: []ScSpecUdtEnumCaseV0,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecUdtEnumV0 {
        return ScSpecUdtEnumV0{
            .doc = try xdrDecodeGeneric(BoundedArray(u8, 1024), allocator, reader),
            .lib = try xdrDecodeGeneric(BoundedArray(u8, 80), allocator, reader),
            .name = try xdrDecodeGeneric(BoundedArray(u8, 60), allocator, reader),
            .cases = try xdrDecodeGeneric([]ScSpecUdtEnumCaseV0, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScSpecUdtEnumV0, writer: anytype) !void {
        try xdrEncodeGeneric(BoundedArray(u8, 1024), writer, self.doc);
        try xdrEncodeGeneric(BoundedArray(u8, 80), writer, self.lib);
        try xdrEncodeGeneric(BoundedArray(u8, 60), writer, self.name);
        try xdrEncodeGeneric([]ScSpecUdtEnumCaseV0, writer, self.cases);
    }
};

/// ScSpecUdtErrorEnumCaseV0 is an XDR Struct defined as:
///
/// ```text
/// struct SCSpecUDTErrorEnumCaseV0
/// {
///     string doc<SC_SPEC_DOC_LIMIT>;
///     string name<60>;
///     uint32 value;
/// };
/// ```
///
pub const ScSpecUdtErrorEnumCaseV0 = struct {
    doc: BoundedArray(u8, 1024),
    name: BoundedArray(u8, 60),
    value: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecUdtErrorEnumCaseV0 {
        return ScSpecUdtErrorEnumCaseV0{
            .doc = try xdrDecodeGeneric(BoundedArray(u8, 1024), allocator, reader),
            .name = try xdrDecodeGeneric(BoundedArray(u8, 60), allocator, reader),
            .value = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScSpecUdtErrorEnumCaseV0, writer: anytype) !void {
        try xdrEncodeGeneric(BoundedArray(u8, 1024), writer, self.doc);
        try xdrEncodeGeneric(BoundedArray(u8, 60), writer, self.name);
        try xdrEncodeGeneric(u32, writer, self.value);
    }
};

/// ScSpecUdtErrorEnumV0 is an XDR Struct defined as:
///
/// ```text
/// struct SCSpecUDTErrorEnumV0
/// {
///     string doc<SC_SPEC_DOC_LIMIT>;
///     string lib<80>;
///     string name<60>;
///     SCSpecUDTErrorEnumCaseV0 cases<>;
/// };
/// ```
///
pub const ScSpecUdtErrorEnumV0 = struct {
    doc: BoundedArray(u8, 1024),
    lib: BoundedArray(u8, 80),
    name: BoundedArray(u8, 60),
    cases: []ScSpecUdtErrorEnumCaseV0,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecUdtErrorEnumV0 {
        return ScSpecUdtErrorEnumV0{
            .doc = try xdrDecodeGeneric(BoundedArray(u8, 1024), allocator, reader),
            .lib = try xdrDecodeGeneric(BoundedArray(u8, 80), allocator, reader),
            .name = try xdrDecodeGeneric(BoundedArray(u8, 60), allocator, reader),
            .cases = try xdrDecodeGeneric([]ScSpecUdtErrorEnumCaseV0, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScSpecUdtErrorEnumV0, writer: anytype) !void {
        try xdrEncodeGeneric(BoundedArray(u8, 1024), writer, self.doc);
        try xdrEncodeGeneric(BoundedArray(u8, 80), writer, self.lib);
        try xdrEncodeGeneric(BoundedArray(u8, 60), writer, self.name);
        try xdrEncodeGeneric([]ScSpecUdtErrorEnumCaseV0, writer, self.cases);
    }
};

/// ScSpecFunctionInputV0 is an XDR Struct defined as:
///
/// ```text
/// struct SCSpecFunctionInputV0
/// {
///     string doc<SC_SPEC_DOC_LIMIT>;
///     string name<30>;
///     SCSpecTypeDef type;
/// };
/// ```
///
pub const ScSpecFunctionInputV0 = struct {
    doc: BoundedArray(u8, 1024),
    name: BoundedArray(u8, 30),
    type: ScSpecTypeDef,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecFunctionInputV0 {
        return ScSpecFunctionInputV0{
            .doc = try xdrDecodeGeneric(BoundedArray(u8, 1024), allocator, reader),
            .name = try xdrDecodeGeneric(BoundedArray(u8, 30), allocator, reader),
            .type = try xdrDecodeGeneric(ScSpecTypeDef, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScSpecFunctionInputV0, writer: anytype) !void {
        try xdrEncodeGeneric(BoundedArray(u8, 1024), writer, self.doc);
        try xdrEncodeGeneric(BoundedArray(u8, 30), writer, self.name);
        try xdrEncodeGeneric(ScSpecTypeDef, writer, self.type);
    }
};

/// ScSpecFunctionV0 is an XDR Struct defined as:
///
/// ```text
/// struct SCSpecFunctionV0
/// {
///     string doc<SC_SPEC_DOC_LIMIT>;
///     SCSymbol name;
///     SCSpecFunctionInputV0 inputs<>;
///     SCSpecTypeDef outputs<1>;
/// };
/// ```
///
pub const ScSpecFunctionV0 = struct {
    doc: BoundedArray(u8, 1024),
    name: ScSymbol,
    inputs: []ScSpecFunctionInputV0,
    outputs: BoundedArray(ScSpecTypeDef, 1),

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecFunctionV0 {
        return ScSpecFunctionV0{
            .doc = try xdrDecodeGeneric(BoundedArray(u8, 1024), allocator, reader),
            .name = try xdrDecodeGeneric(ScSymbol, allocator, reader),
            .inputs = try xdrDecodeGeneric([]ScSpecFunctionInputV0, allocator, reader),
            .outputs = try xdrDecodeGeneric(BoundedArray(ScSpecTypeDef, 1), allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScSpecFunctionV0, writer: anytype) !void {
        try xdrEncodeGeneric(BoundedArray(u8, 1024), writer, self.doc);
        try xdrEncodeGeneric(ScSymbol, writer, self.name);
        try xdrEncodeGeneric([]ScSpecFunctionInputV0, writer, self.inputs);
        try xdrEncodeGeneric(BoundedArray(ScSpecTypeDef, 1), writer, self.outputs);
    }
};

/// ScSpecEventParamLocationV0 is an XDR Enum defined as:
///
/// ```text
/// enum SCSpecEventParamLocationV0
/// {
///     SC_SPEC_EVENT_PARAM_LOCATION_DATA = 0,
///     SC_SPEC_EVENT_PARAM_LOCATION_TOPIC_LIST = 1
/// };
/// ```
///
pub const ScSpecEventParamLocationV0 = enum(i32) {
    Data = 0,
    TopicList = 1,
    _,

    pub const variants = [_]ScSpecEventParamLocationV0{
        .Data,
        .TopicList,
    };

    pub fn name(self: ScSpecEventParamLocationV0) []const u8 {
        return switch (self) {
            .Data => "Data",
            .TopicList => "TopicList",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecEventParamLocationV0 {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ScSpecEventParamLocationV0, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ScSpecEventParamV0 is an XDR Struct defined as:
///
/// ```text
/// struct SCSpecEventParamV0
/// {
///     string doc<SC_SPEC_DOC_LIMIT>;
///     string name<30>;
///     SCSpecTypeDef type;
///     SCSpecEventParamLocationV0 location;
/// };
/// ```
///
pub const ScSpecEventParamV0 = struct {
    doc: BoundedArray(u8, 1024),
    name: BoundedArray(u8, 30),
    type: ScSpecTypeDef,
    location: ScSpecEventParamLocationV0,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecEventParamV0 {
        return ScSpecEventParamV0{
            .doc = try xdrDecodeGeneric(BoundedArray(u8, 1024), allocator, reader),
            .name = try xdrDecodeGeneric(BoundedArray(u8, 30), allocator, reader),
            .type = try xdrDecodeGeneric(ScSpecTypeDef, allocator, reader),
            .location = try xdrDecodeGeneric(ScSpecEventParamLocationV0, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScSpecEventParamV0, writer: anytype) !void {
        try xdrEncodeGeneric(BoundedArray(u8, 1024), writer, self.doc);
        try xdrEncodeGeneric(BoundedArray(u8, 30), writer, self.name);
        try xdrEncodeGeneric(ScSpecTypeDef, writer, self.type);
        try xdrEncodeGeneric(ScSpecEventParamLocationV0, writer, self.location);
    }
};

/// ScSpecEventDataFormat is an XDR Enum defined as:
///
/// ```text
/// enum SCSpecEventDataFormat
/// {
///     SC_SPEC_EVENT_DATA_FORMAT_SINGLE_VALUE = 0,
///     SC_SPEC_EVENT_DATA_FORMAT_VEC = 1,
///     SC_SPEC_EVENT_DATA_FORMAT_MAP = 2
/// };
/// ```
///
pub const ScSpecEventDataFormat = enum(i32) {
    SingleValue = 0,
    Vec = 1,
    Map = 2,
    _,

    pub const variants = [_]ScSpecEventDataFormat{
        .SingleValue,
        .Vec,
        .Map,
    };

    pub fn name(self: ScSpecEventDataFormat) []const u8 {
        return switch (self) {
            .SingleValue => "SingleValue",
            .Vec => "Vec",
            .Map => "Map",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecEventDataFormat {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ScSpecEventDataFormat, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ScSpecEventV0 is an XDR Struct defined as:
///
/// ```text
/// struct SCSpecEventV0
/// {
///     string doc<SC_SPEC_DOC_LIMIT>;
///     string lib<80>;
///     SCSymbol name;
///     SCSymbol prefixTopics<2>;
///     SCSpecEventParamV0 params<>;
///     SCSpecEventDataFormat dataFormat;
/// };
/// ```
///
pub const ScSpecEventV0 = struct {
    doc: BoundedArray(u8, 1024),
    lib: BoundedArray(u8, 80),
    name: ScSymbol,
    prefix_topics: BoundedArray(ScSymbol, 2),
    params: []ScSpecEventParamV0,
    data_format: ScSpecEventDataFormat,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecEventV0 {
        return ScSpecEventV0{
            .doc = try xdrDecodeGeneric(BoundedArray(u8, 1024), allocator, reader),
            .lib = try xdrDecodeGeneric(BoundedArray(u8, 80), allocator, reader),
            .name = try xdrDecodeGeneric(ScSymbol, allocator, reader),
            .prefix_topics = try xdrDecodeGeneric(BoundedArray(ScSymbol, 2), allocator, reader),
            .params = try xdrDecodeGeneric([]ScSpecEventParamV0, allocator, reader),
            .data_format = try xdrDecodeGeneric(ScSpecEventDataFormat, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScSpecEventV0, writer: anytype) !void {
        try xdrEncodeGeneric(BoundedArray(u8, 1024), writer, self.doc);
        try xdrEncodeGeneric(BoundedArray(u8, 80), writer, self.lib);
        try xdrEncodeGeneric(ScSymbol, writer, self.name);
        try xdrEncodeGeneric(BoundedArray(ScSymbol, 2), writer, self.prefix_topics);
        try xdrEncodeGeneric([]ScSpecEventParamV0, writer, self.params);
        try xdrEncodeGeneric(ScSpecEventDataFormat, writer, self.data_format);
    }
};

/// ScSpecEntryKind is an XDR Enum defined as:
///
/// ```text
/// enum SCSpecEntryKind
/// {
///     SC_SPEC_ENTRY_FUNCTION_V0 = 0,
///     SC_SPEC_ENTRY_UDT_STRUCT_V0 = 1,
///     SC_SPEC_ENTRY_UDT_UNION_V0 = 2,
///     SC_SPEC_ENTRY_UDT_ENUM_V0 = 3,
///     SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0 = 4,
///     SC_SPEC_ENTRY_EVENT_V0 = 5
/// };
/// ```
///
pub const ScSpecEntryKind = enum(i32) {
    FunctionV0 = 0,
    UdtStructV0 = 1,
    UdtUnionV0 = 2,
    UdtEnumV0 = 3,
    UdtErrorEnumV0 = 4,
    EventV0 = 5,
    _,

    pub const variants = [_]ScSpecEntryKind{
        .FunctionV0,
        .UdtStructV0,
        .UdtUnionV0,
        .UdtEnumV0,
        .UdtErrorEnumV0,
        .EventV0,
    };

    pub fn name(self: ScSpecEntryKind) []const u8 {
        return switch (self) {
            .FunctionV0 => "FunctionV0",
            .UdtStructV0 => "UdtStructV0",
            .UdtUnionV0 => "UdtUnionV0",
            .UdtEnumV0 => "UdtEnumV0",
            .UdtErrorEnumV0 => "UdtErrorEnumV0",
            .EventV0 => "EventV0",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecEntryKind {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ScSpecEntryKind, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ScSpecEntry is an XDR Union defined as:
///
/// ```text
/// union SCSpecEntry switch (SCSpecEntryKind kind)
/// {
/// case SC_SPEC_ENTRY_FUNCTION_V0:
///     SCSpecFunctionV0 functionV0;
/// case SC_SPEC_ENTRY_UDT_STRUCT_V0:
///     SCSpecUDTStructV0 udtStructV0;
/// case SC_SPEC_ENTRY_UDT_UNION_V0:
///     SCSpecUDTUnionV0 udtUnionV0;
/// case SC_SPEC_ENTRY_UDT_ENUM_V0:
///     SCSpecUDTEnumV0 udtEnumV0;
/// case SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0:
///     SCSpecUDTErrorEnumV0 udtErrorEnumV0;
/// case SC_SPEC_ENTRY_EVENT_V0:
///     SCSpecEventV0 eventV0;
/// };
/// ```
///
pub const ScSpecEntry = union(enum) {
    FunctionV0: ScSpecFunctionV0,
    UdtStructV0: ScSpecUdtStructV0,
    UdtUnionV0: ScSpecUdtUnionV0,
    UdtEnumV0: ScSpecUdtEnumV0,
    UdtErrorEnumV0: ScSpecUdtErrorEnumV0,
    EventV0: ScSpecEventV0,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSpecEntry {
        const disc = try ScSpecEntryKind.xdrDecode(allocator, reader);
        return switch (disc) {
            .FunctionV0 => ScSpecEntry{ .FunctionV0 = try xdrDecodeGeneric(ScSpecFunctionV0, allocator, reader) },
            .UdtStructV0 => ScSpecEntry{ .UdtStructV0 = try xdrDecodeGeneric(ScSpecUdtStructV0, allocator, reader) },
            .UdtUnionV0 => ScSpecEntry{ .UdtUnionV0 = try xdrDecodeGeneric(ScSpecUdtUnionV0, allocator, reader) },
            .UdtEnumV0 => ScSpecEntry{ .UdtEnumV0 = try xdrDecodeGeneric(ScSpecUdtEnumV0, allocator, reader) },
            .UdtErrorEnumV0 => ScSpecEntry{ .UdtErrorEnumV0 = try xdrDecodeGeneric(ScSpecUdtErrorEnumV0, allocator, reader) },
            .EventV0 => ScSpecEntry{ .EventV0 = try xdrDecodeGeneric(ScSpecEventV0, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ScSpecEntry, writer: anytype) !void {
        const disc: ScSpecEntryKind = switch (self) {
            .FunctionV0 => .FunctionV0,
            .UdtStructV0 => .UdtStructV0,
            .UdtUnionV0 => .UdtUnionV0,
            .UdtEnumV0 => .UdtEnumV0,
            .UdtErrorEnumV0 => .UdtErrorEnumV0,
            .EventV0 => .EventV0,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .FunctionV0 => |v| try xdrEncodeGeneric(ScSpecFunctionV0, writer, v),
            .UdtStructV0 => |v| try xdrEncodeGeneric(ScSpecUdtStructV0, writer, v),
            .UdtUnionV0 => |v| try xdrEncodeGeneric(ScSpecUdtUnionV0, writer, v),
            .UdtEnumV0 => |v| try xdrEncodeGeneric(ScSpecUdtEnumV0, writer, v),
            .UdtErrorEnumV0 => |v| try xdrEncodeGeneric(ScSpecUdtErrorEnumV0, writer, v),
            .EventV0 => |v| try xdrEncodeGeneric(ScSpecEventV0, writer, v),
        }
    }
};

/// ScValType is an XDR Enum defined as:
///
/// ```text
/// enum SCValType
/// {
///     SCV_BOOL = 0,
///     SCV_VOID = 1,
///     SCV_ERROR = 2,
///
///     // 32 bits is the smallest type in WASM or XDR; no need for u8/u16.
///     SCV_U32 = 3,
///     SCV_I32 = 4,
///
///     // 64 bits is naturally supported by both WASM and XDR also.
///     SCV_U64 = 5,
///     SCV_I64 = 6,
///
///     // Time-related u64 subtypes with their own functions and formatting.
///     SCV_TIMEPOINT = 7,
///     SCV_DURATION = 8,
///
///     // 128 bits is naturally supported by Rust and we use it for Soroban
///     // fixed-point arithmetic prices / balances / similar "quantities". These
///     // are represented in XDR as a pair of 2 u64s.
///     SCV_U128 = 9,
///     SCV_I128 = 10,
///
///     // 256 bits is the size of sha256 output, ed25519 keys, and the EVM machine
///     // word, so for interop use we include this even though it requires a small
///     // amount of Rust guest and/or host library code.
///     SCV_U256 = 11,
///     SCV_I256 = 12,
///
///     // Bytes come in 3 flavors, 2 of which have meaningfully different
///     // formatting and validity-checking / domain-restriction.
///     SCV_BYTES = 13,
///     SCV_STRING = 14,
///     SCV_SYMBOL = 15,
///
///     // Vecs and maps are just polymorphic containers of other ScVals.
///     SCV_VEC = 16,
///     SCV_MAP = 17,
///
///     // Address is the universal identifier for contracts and classic
///     // accounts.
///     SCV_ADDRESS = 18,
///
///     // The following are the internal SCVal variants that are not
///     // exposed to the contracts.
///     SCV_CONTRACT_INSTANCE = 19,
///
///     // SCV_LEDGER_KEY_CONTRACT_INSTANCE and SCV_LEDGER_KEY_NONCE are unique
///     // symbolic SCVals used as the key for ledger entries for a contract's
///     // instance and an address' nonce, respectively.
///     SCV_LEDGER_KEY_CONTRACT_INSTANCE = 20,
///     SCV_LEDGER_KEY_NONCE = 21
/// };
/// ```
///
pub const ScValType = enum(i32) {
    Bool = 0,
    Void = 1,
    Error = 2,
    U32 = 3,
    I32 = 4,
    U64 = 5,
    I64 = 6,
    Timepoint = 7,
    Duration = 8,
    U128 = 9,
    I128 = 10,
    U256 = 11,
    I256 = 12,
    Bytes = 13,
    String = 14,
    Symbol = 15,
    Vec = 16,
    Map = 17,
    Address = 18,
    ContractInstance = 19,
    LedgerKeyContractInstance = 20,
    LedgerKeyNonce = 21,
    _,

    pub const variants = [_]ScValType{
        .Bool,
        .Void,
        .Error,
        .U32,
        .I32,
        .U64,
        .I64,
        .Timepoint,
        .Duration,
        .U128,
        .I128,
        .U256,
        .I256,
        .Bytes,
        .String,
        .Symbol,
        .Vec,
        .Map,
        .Address,
        .ContractInstance,
        .LedgerKeyContractInstance,
        .LedgerKeyNonce,
    };

    pub fn name(self: ScValType) []const u8 {
        return switch (self) {
            .Bool => "Bool",
            .Void => "Void",
            .Error => "Error",
            .U32 => "U32",
            .I32 => "I32",
            .U64 => "U64",
            .I64 => "I64",
            .Timepoint => "Timepoint",
            .Duration => "Duration",
            .U128 => "U128",
            .I128 => "I128",
            .U256 => "U256",
            .I256 => "I256",
            .Bytes => "Bytes",
            .String => "String",
            .Symbol => "Symbol",
            .Vec => "Vec",
            .Map => "Map",
            .Address => "Address",
            .ContractInstance => "ContractInstance",
            .LedgerKeyContractInstance => "LedgerKeyContractInstance",
            .LedgerKeyNonce => "LedgerKeyNonce",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScValType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ScValType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ScErrorType is an XDR Enum defined as:
///
/// ```text
/// enum SCErrorType
/// {
///     SCE_CONTRACT = 0,          // Contract-specific, user-defined codes.
///     SCE_WASM_VM = 1,           // Errors while interpreting WASM bytecode.
///     SCE_CONTEXT = 2,           // Errors in the contract's host context.
///     SCE_STORAGE = 3,           // Errors accessing host storage.
///     SCE_OBJECT = 4,            // Errors working with host objects.
///     SCE_CRYPTO = 5,            // Errors in cryptographic operations.
///     SCE_EVENTS = 6,            // Errors while emitting events.
///     SCE_BUDGET = 7,            // Errors relating to budget limits.
///     SCE_VALUE = 8,             // Errors working with host values or SCVals.
///     SCE_AUTH = 9               // Errors from the authentication subsystem.
/// };
/// ```
///
pub const ScErrorType = enum(i32) {
    Contract = 0,
    WasmVm = 1,
    Context = 2,
    Storage = 3,
    Object = 4,
    Crypto = 5,
    Events = 6,
    Budget = 7,
    Value = 8,
    Auth = 9,
    _,

    pub const variants = [_]ScErrorType{
        .Contract,
        .WasmVm,
        .Context,
        .Storage,
        .Object,
        .Crypto,
        .Events,
        .Budget,
        .Value,
        .Auth,
    };

    pub fn name(self: ScErrorType) []const u8 {
        return switch (self) {
            .Contract => "Contract",
            .WasmVm => "WasmVm",
            .Context => "Context",
            .Storage => "Storage",
            .Object => "Object",
            .Crypto => "Crypto",
            .Events => "Events",
            .Budget => "Budget",
            .Value => "Value",
            .Auth => "Auth",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScErrorType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ScErrorType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ScErrorCode is an XDR Enum defined as:
///
/// ```text
/// enum SCErrorCode
/// {
///     SCEC_ARITH_DOMAIN = 0,      // Some arithmetic was undefined (overflow, divide-by-zero).
///     SCEC_INDEX_BOUNDS = 1,      // Something was indexed beyond its bounds.
///     SCEC_INVALID_INPUT = 2,     // User provided some otherwise-bad data.
///     SCEC_MISSING_VALUE = 3,     // Some value was required but not provided.
///     SCEC_EXISTING_VALUE = 4,    // Some value was provided where not allowed.
///     SCEC_EXCEEDED_LIMIT = 5,    // Some arbitrary limit -- gas or otherwise -- was hit.
///     SCEC_INVALID_ACTION = 6,    // Data was valid but action requested was not.
///     SCEC_INTERNAL_ERROR = 7,    // The host detected an error in its own logic.
///     SCEC_UNEXPECTED_TYPE = 8,   // Some type wasn't as expected.
///     SCEC_UNEXPECTED_SIZE = 9    // Something's size wasn't as expected.
/// };
/// ```
///
pub const ScErrorCode = enum(i32) {
    ArithDomain = 0,
    IndexBounds = 1,
    InvalidInput = 2,
    MissingValue = 3,
    ExistingValue = 4,
    ExceededLimit = 5,
    InvalidAction = 6,
    InternalError = 7,
    UnexpectedType = 8,
    UnexpectedSize = 9,
    _,

    pub const variants = [_]ScErrorCode{
        .ArithDomain,
        .IndexBounds,
        .InvalidInput,
        .MissingValue,
        .ExistingValue,
        .ExceededLimit,
        .InvalidAction,
        .InternalError,
        .UnexpectedType,
        .UnexpectedSize,
    };

    pub fn name(self: ScErrorCode) []const u8 {
        return switch (self) {
            .ArithDomain => "ArithDomain",
            .IndexBounds => "IndexBounds",
            .InvalidInput => "InvalidInput",
            .MissingValue => "MissingValue",
            .ExistingValue => "ExistingValue",
            .ExceededLimit => "ExceededLimit",
            .InvalidAction => "InvalidAction",
            .InternalError => "InternalError",
            .UnexpectedType => "UnexpectedType",
            .UnexpectedSize => "UnexpectedSize",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScErrorCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ScErrorCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ScError is an XDR Union defined as:
///
/// ```text
/// union SCError switch (SCErrorType type)
/// {
/// case SCE_CONTRACT:
///     uint32 contractCode;
/// case SCE_WASM_VM:
/// case SCE_CONTEXT:
/// case SCE_STORAGE:
/// case SCE_OBJECT:
/// case SCE_CRYPTO:
/// case SCE_EVENTS:
/// case SCE_BUDGET:
/// case SCE_VALUE:
/// case SCE_AUTH:
///     SCErrorCode code;
/// };
/// ```
///
pub const ScError = union(enum) {
    Contract: u32,
    WasmVm: ScErrorCode,
    Context: ScErrorCode,
    Storage: ScErrorCode,
    Object: ScErrorCode,
    Crypto: ScErrorCode,
    Events: ScErrorCode,
    Budget: ScErrorCode,
    Value: ScErrorCode,
    Auth: ScErrorCode,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScError {
        const disc = try ScErrorType.xdrDecode(allocator, reader);
        return switch (disc) {
            .Contract => ScError{ .Contract = try xdrDecodeGeneric(u32, allocator, reader) },
            .WasmVm => ScError{ .WasmVm = try xdrDecodeGeneric(ScErrorCode, allocator, reader) },
            .Context => ScError{ .Context = try xdrDecodeGeneric(ScErrorCode, allocator, reader) },
            .Storage => ScError{ .Storage = try xdrDecodeGeneric(ScErrorCode, allocator, reader) },
            .Object => ScError{ .Object = try xdrDecodeGeneric(ScErrorCode, allocator, reader) },
            .Crypto => ScError{ .Crypto = try xdrDecodeGeneric(ScErrorCode, allocator, reader) },
            .Events => ScError{ .Events = try xdrDecodeGeneric(ScErrorCode, allocator, reader) },
            .Budget => ScError{ .Budget = try xdrDecodeGeneric(ScErrorCode, allocator, reader) },
            .Value => ScError{ .Value = try xdrDecodeGeneric(ScErrorCode, allocator, reader) },
            .Auth => ScError{ .Auth = try xdrDecodeGeneric(ScErrorCode, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ScError, writer: anytype) !void {
        const disc: ScErrorType = switch (self) {
            .Contract => .Contract,
            .WasmVm => .WasmVm,
            .Context => .Context,
            .Storage => .Storage,
            .Object => .Object,
            .Crypto => .Crypto,
            .Events => .Events,
            .Budget => .Budget,
            .Value => .Value,
            .Auth => .Auth,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Contract => |v| try xdrEncodeGeneric(u32, writer, v),
            .WasmVm => |v| try xdrEncodeGeneric(ScErrorCode, writer, v),
            .Context => |v| try xdrEncodeGeneric(ScErrorCode, writer, v),
            .Storage => |v| try xdrEncodeGeneric(ScErrorCode, writer, v),
            .Object => |v| try xdrEncodeGeneric(ScErrorCode, writer, v),
            .Crypto => |v| try xdrEncodeGeneric(ScErrorCode, writer, v),
            .Events => |v| try xdrEncodeGeneric(ScErrorCode, writer, v),
            .Budget => |v| try xdrEncodeGeneric(ScErrorCode, writer, v),
            .Value => |v| try xdrEncodeGeneric(ScErrorCode, writer, v),
            .Auth => |v| try xdrEncodeGeneric(ScErrorCode, writer, v),
        }
    }
};

/// UInt128Parts is an XDR Struct defined as:
///
/// ```text
/// struct UInt128Parts {
///     uint64 hi;
///     uint64 lo;
/// };
/// ```
///
pub const UInt128Parts = struct {
    hi: u64,
    lo: u64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !UInt128Parts {
        return UInt128Parts{
            .hi = try xdrDecodeGeneric(u64, allocator, reader),
            .lo = try xdrDecodeGeneric(u64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: UInt128Parts, writer: anytype) !void {
        try xdrEncodeGeneric(u64, writer, self.hi);
        try xdrEncodeGeneric(u64, writer, self.lo);
    }
};

/// Int128Parts is an XDR Struct defined as:
///
/// ```text
/// struct Int128Parts {
///     int64 hi;
///     uint64 lo;
/// };
/// ```
///
pub const Int128Parts = struct {
    hi: i64,
    lo: u64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !Int128Parts {
        return Int128Parts{
            .hi = try xdrDecodeGeneric(i64, allocator, reader),
            .lo = try xdrDecodeGeneric(u64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: Int128Parts, writer: anytype) !void {
        try xdrEncodeGeneric(i64, writer, self.hi);
        try xdrEncodeGeneric(u64, writer, self.lo);
    }
};

/// UInt256Parts is an XDR Struct defined as:
///
/// ```text
/// struct UInt256Parts {
///     uint64 hi_hi;
///     uint64 hi_lo;
///     uint64 lo_hi;
///     uint64 lo_lo;
/// };
/// ```
///
pub const UInt256Parts = struct {
    hi_hi: u64,
    hi_lo: u64,
    lo_hi: u64,
    lo_lo: u64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !UInt256Parts {
        return UInt256Parts{
            .hi_hi = try xdrDecodeGeneric(u64, allocator, reader),
            .hi_lo = try xdrDecodeGeneric(u64, allocator, reader),
            .lo_hi = try xdrDecodeGeneric(u64, allocator, reader),
            .lo_lo = try xdrDecodeGeneric(u64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: UInt256Parts, writer: anytype) !void {
        try xdrEncodeGeneric(u64, writer, self.hi_hi);
        try xdrEncodeGeneric(u64, writer, self.hi_lo);
        try xdrEncodeGeneric(u64, writer, self.lo_hi);
        try xdrEncodeGeneric(u64, writer, self.lo_lo);
    }
};

/// Int256Parts is an XDR Struct defined as:
///
/// ```text
/// struct Int256Parts {
///     int64 hi_hi;
///     uint64 hi_lo;
///     uint64 lo_hi;
///     uint64 lo_lo;
/// };
/// ```
///
pub const Int256Parts = struct {
    hi_hi: i64,
    hi_lo: u64,
    lo_hi: u64,
    lo_lo: u64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !Int256Parts {
        return Int256Parts{
            .hi_hi = try xdrDecodeGeneric(i64, allocator, reader),
            .hi_lo = try xdrDecodeGeneric(u64, allocator, reader),
            .lo_hi = try xdrDecodeGeneric(u64, allocator, reader),
            .lo_lo = try xdrDecodeGeneric(u64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: Int256Parts, writer: anytype) !void {
        try xdrEncodeGeneric(i64, writer, self.hi_hi);
        try xdrEncodeGeneric(u64, writer, self.hi_lo);
        try xdrEncodeGeneric(u64, writer, self.lo_hi);
        try xdrEncodeGeneric(u64, writer, self.lo_lo);
    }
};

/// ContractExecutableType is an XDR Enum defined as:
///
/// ```text
/// enum ContractExecutableType
/// {
///     CONTRACT_EXECUTABLE_WASM = 0,
///     CONTRACT_EXECUTABLE_STELLAR_ASSET = 1
/// };
/// ```
///
pub const ContractExecutableType = enum(i32) {
    Wasm = 0,
    StellarAsset = 1,
    _,

    pub const variants = [_]ContractExecutableType{
        .Wasm,
        .StellarAsset,
    };

    pub fn name(self: ContractExecutableType) []const u8 {
        return switch (self) {
            .Wasm => "Wasm",
            .StellarAsset => "StellarAsset",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ContractExecutableType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ContractExecutableType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ContractExecutable is an XDR Union defined as:
///
/// ```text
/// union ContractExecutable switch (ContractExecutableType type)
/// {
/// case CONTRACT_EXECUTABLE_WASM:
///     Hash wasm_hash;
/// case CONTRACT_EXECUTABLE_STELLAR_ASSET:
///     void;
/// };
/// ```
///
pub const ContractExecutable = union(enum) {
    Wasm: Hash,
    StellarAsset,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ContractExecutable {
        const disc = try ContractExecutableType.xdrDecode(allocator, reader);
        return switch (disc) {
            .Wasm => ContractExecutable{ .Wasm = try xdrDecodeGeneric(Hash, allocator, reader) },
            .StellarAsset => ContractExecutable{ .StellarAsset = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ContractExecutable, writer: anytype) !void {
        const disc: ContractExecutableType = switch (self) {
            .Wasm => .Wasm,
            .StellarAsset => .StellarAsset,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Wasm => |v| try xdrEncodeGeneric(Hash, writer, v),
            .StellarAsset => {},
        }
    }
};

/// ScAddressType is an XDR Enum defined as:
///
/// ```text
/// enum SCAddressType
/// {
///     SC_ADDRESS_TYPE_ACCOUNT = 0,
///     SC_ADDRESS_TYPE_CONTRACT = 1,
///     SC_ADDRESS_TYPE_MUXED_ACCOUNT = 2,
///     SC_ADDRESS_TYPE_CLAIMABLE_BALANCE = 3,
///     SC_ADDRESS_TYPE_LIQUIDITY_POOL = 4
/// };
/// ```
///
pub const ScAddressType = enum(i32) {
    Account = 0,
    Contract = 1,
    MuxedAccount = 2,
    ClaimableBalance = 3,
    LiquidityPool = 4,
    _,

    pub const variants = [_]ScAddressType{
        .Account,
        .Contract,
        .MuxedAccount,
        .ClaimableBalance,
        .LiquidityPool,
    };

    pub fn name(self: ScAddressType) []const u8 {
        return switch (self) {
            .Account => "Account",
            .Contract => "Contract",
            .MuxedAccount => "MuxedAccount",
            .ClaimableBalance => "ClaimableBalance",
            .LiquidityPool => "LiquidityPool",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScAddressType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ScAddressType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// MuxedEd25519Account is an XDR Struct defined as:
///
/// ```text
/// struct MuxedEd25519Account
/// {
///     uint64 id;
///     uint256 ed25519;
/// };
/// ```
///
pub const MuxedEd25519Account = struct {
    id: u64,
    ed25519: Uint256,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !MuxedEd25519Account {
        return MuxedEd25519Account{
            .id = try xdrDecodeGeneric(u64, allocator, reader),
            .ed25519 = try xdrDecodeGeneric(Uint256, allocator, reader),
        };
    }

    pub fn xdrEncode(self: MuxedEd25519Account, writer: anytype) !void {
        try xdrEncodeGeneric(u64, writer, self.id);
        try xdrEncodeGeneric(Uint256, writer, self.ed25519);
    }
};

/// ScAddress is an XDR Union defined as:
///
/// ```text
/// union SCAddress switch (SCAddressType type)
/// {
/// case SC_ADDRESS_TYPE_ACCOUNT:
///     AccountID accountId;
/// case SC_ADDRESS_TYPE_CONTRACT:
///     ContractID contractId;
/// case SC_ADDRESS_TYPE_MUXED_ACCOUNT:
///     MuxedEd25519Account muxedAccount;
/// case SC_ADDRESS_TYPE_CLAIMABLE_BALANCE:
///     ClaimableBalanceID claimableBalanceId;
/// case SC_ADDRESS_TYPE_LIQUIDITY_POOL:
///     PoolID liquidityPoolId;
/// };
/// ```
///
pub const ScAddress = union(enum) {
    Account: AccountId,
    Contract: ContractId,
    MuxedAccount: MuxedEd25519Account,
    ClaimableBalance: ClaimableBalanceId,
    LiquidityPool: PoolId,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScAddress {
        const disc = try ScAddressType.xdrDecode(allocator, reader);
        return switch (disc) {
            .Account => ScAddress{ .Account = try xdrDecodeGeneric(AccountId, allocator, reader) },
            .Contract => ScAddress{ .Contract = try xdrDecodeGeneric(ContractId, allocator, reader) },
            .MuxedAccount => ScAddress{ .MuxedAccount = try xdrDecodeGeneric(MuxedEd25519Account, allocator, reader) },
            .ClaimableBalance => ScAddress{ .ClaimableBalance = try xdrDecodeGeneric(ClaimableBalanceId, allocator, reader) },
            .LiquidityPool => ScAddress{ .LiquidityPool = try xdrDecodeGeneric(PoolId, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ScAddress, writer: anytype) !void {
        const disc: ScAddressType = switch (self) {
            .Account => .Account,
            .Contract => .Contract,
            .MuxedAccount => .MuxedAccount,
            .ClaimableBalance => .ClaimableBalance,
            .LiquidityPool => .LiquidityPool,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Account => |v| try xdrEncodeGeneric(AccountId, writer, v),
            .Contract => |v| try xdrEncodeGeneric(ContractId, writer, v),
            .MuxedAccount => |v| try xdrEncodeGeneric(MuxedEd25519Account, writer, v),
            .ClaimableBalance => |v| try xdrEncodeGeneric(ClaimableBalanceId, writer, v),
            .LiquidityPool => |v| try xdrEncodeGeneric(PoolId, writer, v),
        }
    }
};

/// ScsymbolLimit is an XDR Const defined as:
///
/// ```text
/// const SCSYMBOL_LIMIT = 32;
/// ```
///
pub const SCSYMBOL_LIMIT: u64 = 32;

/// ScVec is an XDR Typedef defined as:
///
/// ```text
/// typedef SCVal SCVec<>;
/// ```
///
pub const ScVec = struct {
    value: []ScVal,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScVec {
        return ScVec{
            .value = try xdrDecodeGeneric([]ScVal, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScVec, writer: anytype) !void {
        try xdrEncodeGeneric([]ScVal, writer, self.value);
    }

    pub fn asSlice(self: ScVec) []const ScVal {
        return self.value.data;
    }
};

/// ScMap is an XDR Typedef defined as:
///
/// ```text
/// typedef SCMapEntry SCMap<>;
/// ```
///
pub const ScMap = struct {
    value: []ScMapEntry,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScMap {
        return ScMap{
            .value = try xdrDecodeGeneric([]ScMapEntry, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScMap, writer: anytype) !void {
        try xdrEncodeGeneric([]ScMapEntry, writer, self.value);
    }

    pub fn asSlice(self: ScMap) []const ScMapEntry {
        return self.value.data;
    }
};

/// ScBytes is an XDR Typedef defined as:
///
/// ```text
/// typedef opaque SCBytes<>;
/// ```
///
pub const ScBytes = struct {
    value: []u8,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScBytes {
        return ScBytes{
            .value = try xdrDecodeGeneric([]u8, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScBytes, writer: anytype) !void {
        try xdrEncodeGeneric([]u8, writer, self.value);
    }

    pub fn asSlice(self: ScBytes) []const u8 {
        return self.value.data;
    }
};

/// ScString is an XDR Typedef defined as:
///
/// ```text
/// typedef string SCString<>;
/// ```
///
pub const ScString = struct {
    value: []u8,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScString {
        return ScString{
            .value = try xdrDecodeGeneric([]u8, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScString, writer: anytype) !void {
        try xdrEncodeGeneric([]u8, writer, self.value);
    }

    pub fn asSlice(self: ScString) []const u8 {
        return self.value.data;
    }
};

/// ScSymbol is an XDR Typedef defined as:
///
/// ```text
/// typedef string SCSymbol<SCSYMBOL_LIMIT>;
/// ```
///
pub const ScSymbol = struct {
    value: BoundedArray(u8, 32),

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScSymbol {
        return ScSymbol{
            .value = try xdrDecodeGeneric(BoundedArray(u8, 32), allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScSymbol, writer: anytype) !void {
        try xdrEncodeGeneric(BoundedArray(u8, 32), writer, self.value);
    }

    pub fn asSlice(self: ScSymbol) []const u8 {
        return self.value.data;
    }
};

/// ScNonceKey is an XDR Struct defined as:
///
/// ```text
/// struct SCNonceKey {
///     int64 nonce;
/// };
/// ```
///
pub const ScNonceKey = struct {
    nonce: i64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScNonceKey {
        return ScNonceKey{
            .nonce = try xdrDecodeGeneric(i64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScNonceKey, writer: anytype) !void {
        try xdrEncodeGeneric(i64, writer, self.nonce);
    }
};

/// ScContractInstance is an XDR Struct defined as:
///
/// ```text
/// struct SCContractInstance {
///     ContractExecutable executable;
///     SCMap* storage;
/// };
/// ```
///
pub const ScContractInstance = struct {
    executable: ContractExecutable,
    storage: ?ScMap,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScContractInstance {
        return ScContractInstance{
            .executable = try xdrDecodeGeneric(ContractExecutable, allocator, reader),
            .storage = try xdrDecodeGeneric(?ScMap, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScContractInstance, writer: anytype) !void {
        try xdrEncodeGeneric(ContractExecutable, writer, self.executable);
        try xdrEncodeGeneric(?ScMap, writer, self.storage);
    }
};

/// ScVal is an XDR Union defined as:
///
/// ```text
/// union SCVal switch (SCValType type)
/// {
///
/// case SCV_BOOL:
///     bool b;
/// case SCV_VOID:
///     void;
/// case SCV_ERROR:
///     SCError error;
///
/// case SCV_U32:
///     uint32 u32;
/// case SCV_I32:
///     int32 i32;
///
/// case SCV_U64:
///     uint64 u64;
/// case SCV_I64:
///     int64 i64;
/// case SCV_TIMEPOINT:
///     TimePoint timepoint;
/// case SCV_DURATION:
///     Duration duration;
///
/// case SCV_U128:
///     UInt128Parts u128;
/// case SCV_I128:
///     Int128Parts i128;
///
/// case SCV_U256:
///     UInt256Parts u256;
/// case SCV_I256:
///     Int256Parts i256;
///
/// case SCV_BYTES:
///     SCBytes bytes;
/// case SCV_STRING:
///     SCString str;
/// case SCV_SYMBOL:
///     SCSymbol sym;
///
/// // Vec and Map are recursive so need to live
/// // behind an option, due to xdrpp limitations.
/// case SCV_VEC:
///     SCVec *vec;
/// case SCV_MAP:
///     SCMap *map;
///
/// case SCV_ADDRESS:
///     SCAddress address;
///
/// // Special SCVals reserved for system-constructed contract-data
/// // ledger keys, not generally usable elsewhere.
/// case SCV_CONTRACT_INSTANCE:
///     SCContractInstance instance;
/// case SCV_LEDGER_KEY_CONTRACT_INSTANCE:
///     void;
/// case SCV_LEDGER_KEY_NONCE:
///     SCNonceKey nonce_key;
/// };
/// ```
///
pub const ScVal = union(enum) {
    Bool: bool,
    Void,
    Error: ScError,
    U32: u32,
    I32: i32,
    U64: u64,
    I64: i64,
    Timepoint: TimePoint,
    Duration: Duration,
    U128: UInt128Parts,
    I128: Int128Parts,
    U256: UInt256Parts,
    I256: Int256Parts,
    Bytes: ScBytes,
    String: ScString,
    Symbol: ScSymbol,
    Vec: ?ScVec,
    Map: ?ScMap,
    Address: ScAddress,
    ContractInstance: ScContractInstance,
    LedgerKeyContractInstance,
    LedgerKeyNonce: ScNonceKey,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScVal {
        const disc = try ScValType.xdrDecode(allocator, reader);
        return switch (disc) {
            .Bool => ScVal{ .Bool = try xdrDecodeGeneric(bool, allocator, reader) },
            .Void => ScVal{ .Void = {} },
            .Error => ScVal{ .Error = try xdrDecodeGeneric(ScError, allocator, reader) },
            .U32 => ScVal{ .U32 = try xdrDecodeGeneric(u32, allocator, reader) },
            .I32 => ScVal{ .I32 = try xdrDecodeGeneric(i32, allocator, reader) },
            .U64 => ScVal{ .U64 = try xdrDecodeGeneric(u64, allocator, reader) },
            .I64 => ScVal{ .I64 = try xdrDecodeGeneric(i64, allocator, reader) },
            .Timepoint => ScVal{ .Timepoint = try xdrDecodeGeneric(TimePoint, allocator, reader) },
            .Duration => ScVal{ .Duration = try xdrDecodeGeneric(Duration, allocator, reader) },
            .U128 => ScVal{ .U128 = try xdrDecodeGeneric(UInt128Parts, allocator, reader) },
            .I128 => ScVal{ .I128 = try xdrDecodeGeneric(Int128Parts, allocator, reader) },
            .U256 => ScVal{ .U256 = try xdrDecodeGeneric(UInt256Parts, allocator, reader) },
            .I256 => ScVal{ .I256 = try xdrDecodeGeneric(Int256Parts, allocator, reader) },
            .Bytes => ScVal{ .Bytes = try xdrDecodeGeneric(ScBytes, allocator, reader) },
            .String => ScVal{ .String = try xdrDecodeGeneric(ScString, allocator, reader) },
            .Symbol => ScVal{ .Symbol = try xdrDecodeGeneric(ScSymbol, allocator, reader) },
            .Vec => ScVal{ .Vec = try xdrDecodeGeneric(?ScVec, allocator, reader) },
            .Map => ScVal{ .Map = try xdrDecodeGeneric(?ScMap, allocator, reader) },
            .Address => ScVal{ .Address = try xdrDecodeGeneric(ScAddress, allocator, reader) },
            .ContractInstance => ScVal{ .ContractInstance = try xdrDecodeGeneric(ScContractInstance, allocator, reader) },
            .LedgerKeyContractInstance => ScVal{ .LedgerKeyContractInstance = {} },
            .LedgerKeyNonce => ScVal{ .LedgerKeyNonce = try xdrDecodeGeneric(ScNonceKey, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ScVal, writer: anytype) !void {
        const disc: ScValType = switch (self) {
            .Bool => .Bool,
            .Void => .Void,
            .Error => .Error,
            .U32 => .U32,
            .I32 => .I32,
            .U64 => .U64,
            .I64 => .I64,
            .Timepoint => .Timepoint,
            .Duration => .Duration,
            .U128 => .U128,
            .I128 => .I128,
            .U256 => .U256,
            .I256 => .I256,
            .Bytes => .Bytes,
            .String => .String,
            .Symbol => .Symbol,
            .Vec => .Vec,
            .Map => .Map,
            .Address => .Address,
            .ContractInstance => .ContractInstance,
            .LedgerKeyContractInstance => .LedgerKeyContractInstance,
            .LedgerKeyNonce => .LedgerKeyNonce,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Bool => |v| try xdrEncodeGeneric(bool, writer, v),
            .Void => {},
            .Error => |v| try xdrEncodeGeneric(ScError, writer, v),
            .U32 => |v| try xdrEncodeGeneric(u32, writer, v),
            .I32 => |v| try xdrEncodeGeneric(i32, writer, v),
            .U64 => |v| try xdrEncodeGeneric(u64, writer, v),
            .I64 => |v| try xdrEncodeGeneric(i64, writer, v),
            .Timepoint => |v| try xdrEncodeGeneric(TimePoint, writer, v),
            .Duration => |v| try xdrEncodeGeneric(Duration, writer, v),
            .U128 => |v| try xdrEncodeGeneric(UInt128Parts, writer, v),
            .I128 => |v| try xdrEncodeGeneric(Int128Parts, writer, v),
            .U256 => |v| try xdrEncodeGeneric(UInt256Parts, writer, v),
            .I256 => |v| try xdrEncodeGeneric(Int256Parts, writer, v),
            .Bytes => |v| try xdrEncodeGeneric(ScBytes, writer, v),
            .String => |v| try xdrEncodeGeneric(ScString, writer, v),
            .Symbol => |v| try xdrEncodeGeneric(ScSymbol, writer, v),
            .Vec => |v| try xdrEncodeGeneric(?ScVec, writer, v),
            .Map => |v| try xdrEncodeGeneric(?ScMap, writer, v),
            .Address => |v| try xdrEncodeGeneric(ScAddress, writer, v),
            .ContractInstance => |v| try xdrEncodeGeneric(ScContractInstance, writer, v),
            .LedgerKeyContractInstance => {},
            .LedgerKeyNonce => |v| try xdrEncodeGeneric(ScNonceKey, writer, v),
        }
    }
};

/// ScMapEntry is an XDR Struct defined as:
///
/// ```text
/// struct SCMapEntry
/// {
///     SCVal key;
///     SCVal val;
/// };
/// ```
///
pub const ScMapEntry = struct {
    key: ScVal,
    val: ScVal,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScMapEntry {
        return ScMapEntry{
            .key = try xdrDecodeGeneric(ScVal, allocator, reader),
            .val = try xdrDecodeGeneric(ScVal, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScMapEntry, writer: anytype) !void {
        try xdrEncodeGeneric(ScVal, writer, self.key);
        try xdrEncodeGeneric(ScVal, writer, self.val);
    }
};

/// LedgerCloseMetaBatch is an XDR Struct defined as:
///
/// ```text
/// struct LedgerCloseMetaBatch
/// {
///     // starting ledger sequence number in the batch
///     uint32 startSequence;
///
///     // ending ledger sequence number in the batch
///     uint32 endSequence;
///
///     // Ledger close meta for each ledger within the batch
///     LedgerCloseMeta ledgerCloseMetas<>;
/// };
/// ```
///
pub const LedgerCloseMetaBatch = struct {
    start_sequence: u32,
    end_sequence: u32,
    ledger_close_metas: []LedgerCloseMeta,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerCloseMetaBatch {
        return LedgerCloseMetaBatch{
            .start_sequence = try xdrDecodeGeneric(u32, allocator, reader),
            .end_sequence = try xdrDecodeGeneric(u32, allocator, reader),
            .ledger_close_metas = try xdrDecodeGeneric([]LedgerCloseMeta, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LedgerCloseMetaBatch, writer: anytype) !void {
        try xdrEncodeGeneric(u32, writer, self.start_sequence);
        try xdrEncodeGeneric(u32, writer, self.end_sequence);
        try xdrEncodeGeneric([]LedgerCloseMeta, writer, self.ledger_close_metas);
    }
};

/// StoredTransactionSet is an XDR Union defined as:
///
/// ```text
/// union StoredTransactionSet switch (int v)
/// {
/// case 0:
///     TransactionSet txSet;
/// case 1:
///     GeneralizedTransactionSet generalizedTxSet;
/// };
/// ```
///
pub const StoredTransactionSet = union(enum) {
    V0: TransactionSet,
    V1: GeneralizedTransactionSet,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !StoredTransactionSet {
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => StoredTransactionSet{ .V0 = try xdrDecodeGeneric(TransactionSet, allocator, reader) },
            1 => StoredTransactionSet{ .V1 = try xdrDecodeGeneric(GeneralizedTransactionSet, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: StoredTransactionSet, writer: anytype) !void {
        switch (self) {
            .V0 => |v| {
                try writer.writeInt(i32, 0, .big);
                try xdrEncodeGeneric(TransactionSet, writer, v);
            },
            .V1 => |v| {
                try writer.writeInt(i32, 1, .big);
                try xdrEncodeGeneric(GeneralizedTransactionSet, writer, v);
            },
        }
    }
};

/// StoredDebugTransactionSet is an XDR Struct defined as:
///
/// ```text
/// struct StoredDebugTransactionSet
/// {
///     StoredTransactionSet txSet;
///     uint32 ledgerSeq;
///     StellarValue scpValue;
/// };
/// ```
///
pub const StoredDebugTransactionSet = struct {
    tx_set: StoredTransactionSet,
    ledger_seq: u32,
    scp_value: StellarValue,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !StoredDebugTransactionSet {
        return StoredDebugTransactionSet{
            .tx_set = try xdrDecodeGeneric(StoredTransactionSet, allocator, reader),
            .ledger_seq = try xdrDecodeGeneric(u32, allocator, reader),
            .scp_value = try xdrDecodeGeneric(StellarValue, allocator, reader),
        };
    }

    pub fn xdrEncode(self: StoredDebugTransactionSet, writer: anytype) !void {
        try xdrEncodeGeneric(StoredTransactionSet, writer, self.tx_set);
        try xdrEncodeGeneric(u32, writer, self.ledger_seq);
        try xdrEncodeGeneric(StellarValue, writer, self.scp_value);
    }
};

/// PersistedScpStateV0 is an XDR Struct defined as:
///
/// ```text
/// struct PersistedSCPStateV0
/// {
///     SCPEnvelope scpEnvelopes<>;
///     SCPQuorumSet quorumSets<>;
///     StoredTransactionSet txSets<>;
/// };
/// ```
///
pub const PersistedScpStateV0 = struct {
    scp_envelopes: []ScpEnvelope,
    quorum_sets: []ScpQuorumSet,
    tx_sets: []StoredTransactionSet,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !PersistedScpStateV0 {
        return PersistedScpStateV0{
            .scp_envelopes = try xdrDecodeGeneric([]ScpEnvelope, allocator, reader),
            .quorum_sets = try xdrDecodeGeneric([]ScpQuorumSet, allocator, reader),
            .tx_sets = try xdrDecodeGeneric([]StoredTransactionSet, allocator, reader),
        };
    }

    pub fn xdrEncode(self: PersistedScpStateV0, writer: anytype) !void {
        try xdrEncodeGeneric([]ScpEnvelope, writer, self.scp_envelopes);
        try xdrEncodeGeneric([]ScpQuorumSet, writer, self.quorum_sets);
        try xdrEncodeGeneric([]StoredTransactionSet, writer, self.tx_sets);
    }
};

/// PersistedScpStateV1 is an XDR Struct defined as:
///
/// ```text
/// struct PersistedSCPStateV1
/// {
///     // Tx sets are saved separately
///     SCPEnvelope scpEnvelopes<>;
///     SCPQuorumSet quorumSets<>;
/// };
/// ```
///
pub const PersistedScpStateV1 = struct {
    scp_envelopes: []ScpEnvelope,
    quorum_sets: []ScpQuorumSet,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !PersistedScpStateV1 {
        return PersistedScpStateV1{
            .scp_envelopes = try xdrDecodeGeneric([]ScpEnvelope, allocator, reader),
            .quorum_sets = try xdrDecodeGeneric([]ScpQuorumSet, allocator, reader),
        };
    }

    pub fn xdrEncode(self: PersistedScpStateV1, writer: anytype) !void {
        try xdrEncodeGeneric([]ScpEnvelope, writer, self.scp_envelopes);
        try xdrEncodeGeneric([]ScpQuorumSet, writer, self.quorum_sets);
    }
};

/// PersistedScpState is an XDR Union defined as:
///
/// ```text
/// union PersistedSCPState switch (int v)
/// {
/// case 0:
///     PersistedSCPStateV0 v0;
/// case 1:
///     PersistedSCPStateV1 v1;
/// };
/// ```
///
pub const PersistedScpState = union(enum) {
    V0: PersistedScpStateV0,
    V1: PersistedScpStateV1,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !PersistedScpState {
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => PersistedScpState{ .V0 = try xdrDecodeGeneric(PersistedScpStateV0, allocator, reader) },
            1 => PersistedScpState{ .V1 = try xdrDecodeGeneric(PersistedScpStateV1, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: PersistedScpState, writer: anytype) !void {
        switch (self) {
            .V0 => |v| {
                try writer.writeInt(i32, 0, .big);
                try xdrEncodeGeneric(PersistedScpStateV0, writer, v);
            },
            .V1 => |v| {
                try writer.writeInt(i32, 1, .big);
                try xdrEncodeGeneric(PersistedScpStateV1, writer, v);
            },
        }
    }
};

/// Thresholds is an XDR Typedef defined as:
///
/// ```text
/// typedef opaque Thresholds[4];
/// ```
///
pub const Thresholds = struct {
    value: [4]u8,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !Thresholds {
        return Thresholds{
            .value = try xdrDecodeGeneric([4]u8, allocator, reader),
        };
    }

    pub fn xdrEncode(self: Thresholds, writer: anytype) !void {
        try xdrEncodeGeneric([4]u8, writer, self.value);
    }

    pub fn asSlice(self: *const Thresholds) []const u8 {
        return &self.value;
    }
};

/// String32 is an XDR Typedef defined as:
///
/// ```text
/// typedef string string32<32>;
/// ```
///
pub const String32 = struct {
    value: BoundedArray(u8, 32),

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !String32 {
        return String32{
            .value = try xdrDecodeGeneric(BoundedArray(u8, 32), allocator, reader),
        };
    }

    pub fn xdrEncode(self: String32, writer: anytype) !void {
        try xdrEncodeGeneric(BoundedArray(u8, 32), writer, self.value);
    }

    pub fn asSlice(self: String32) []const u8 {
        return self.value.data;
    }
};

/// String64 is an XDR Typedef defined as:
///
/// ```text
/// typedef string string64<64>;
/// ```
///
pub const String64 = struct {
    value: BoundedArray(u8, 64),

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !String64 {
        return String64{
            .value = try xdrDecodeGeneric(BoundedArray(u8, 64), allocator, reader),
        };
    }

    pub fn xdrEncode(self: String64, writer: anytype) !void {
        try xdrEncodeGeneric(BoundedArray(u8, 64), writer, self.value);
    }

    pub fn asSlice(self: String64) []const u8 {
        return self.value.data;
    }
};

/// SequenceNumber is an XDR Typedef defined as:
///
/// ```text
/// typedef int64 SequenceNumber;
/// ```
///
pub const SequenceNumber = struct {
    value: i64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SequenceNumber {
        return SequenceNumber{
            .value = try xdrDecodeGeneric(i64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: SequenceNumber, writer: anytype) !void {
        try xdrEncodeGeneric(i64, writer, self.value);
    }
};

/// DataValue is an XDR Typedef defined as:
///
/// ```text
/// typedef opaque DataValue<64>;
/// ```
///
pub const DataValue = struct {
    value: BoundedArray(u8, 64),

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !DataValue {
        return DataValue{
            .value = try xdrDecodeGeneric(BoundedArray(u8, 64), allocator, reader),
        };
    }

    pub fn xdrEncode(self: DataValue, writer: anytype) !void {
        try xdrEncodeGeneric(BoundedArray(u8, 64), writer, self.value);
    }

    pub fn asSlice(self: DataValue) []const u8 {
        return self.value.data;
    }
};

/// AssetCode4 is an XDR Typedef defined as:
///
/// ```text
/// typedef opaque AssetCode4[4];
/// ```
///
pub const AssetCode4 = struct {
    value: [4]u8,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !AssetCode4 {
        return AssetCode4{
            .value = try xdrDecodeGeneric([4]u8, allocator, reader),
        };
    }

    pub fn xdrEncode(self: AssetCode4, writer: anytype) !void {
        try xdrEncodeGeneric([4]u8, writer, self.value);
    }

    pub fn asSlice(self: *const AssetCode4) []const u8 {
        return &self.value;
    }
};

/// AssetCode12 is an XDR Typedef defined as:
///
/// ```text
/// typedef opaque AssetCode12[12];
/// ```
///
pub const AssetCode12 = struct {
    value: [12]u8,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !AssetCode12 {
        return AssetCode12{
            .value = try xdrDecodeGeneric([12]u8, allocator, reader),
        };
    }

    pub fn xdrEncode(self: AssetCode12, writer: anytype) !void {
        try xdrEncodeGeneric([12]u8, writer, self.value);
    }

    pub fn asSlice(self: *const AssetCode12) []const u8 {
        return &self.value;
    }
};

/// AssetType is an XDR Enum defined as:
///
/// ```text
/// enum AssetType
/// {
///     ASSET_TYPE_NATIVE = 0,
///     ASSET_TYPE_CREDIT_ALPHANUM4 = 1,
///     ASSET_TYPE_CREDIT_ALPHANUM12 = 2,
///     ASSET_TYPE_POOL_SHARE = 3
/// };
/// ```
///
pub const AssetType = enum(i32) {
    Native = 0,
    CreditAlphanum4 = 1,
    CreditAlphanum12 = 2,
    PoolShare = 3,
    _,

    pub const variants = [_]AssetType{
        .Native,
        .CreditAlphanum4,
        .CreditAlphanum12,
        .PoolShare,
    };

    pub fn name(self: AssetType) []const u8 {
        return switch (self) {
            .Native => "Native",
            .CreditAlphanum4 => "CreditAlphanum4",
            .CreditAlphanum12 => "CreditAlphanum12",
            .PoolShare => "PoolShare",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !AssetType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: AssetType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// AssetCode is an XDR Union defined as:
///
/// ```text
/// union AssetCode switch (AssetType type)
/// {
/// case ASSET_TYPE_CREDIT_ALPHANUM4:
///     AssetCode4 assetCode4;
///
/// case ASSET_TYPE_CREDIT_ALPHANUM12:
///     AssetCode12 assetCode12;
///
///     // add other asset types here in the future
/// };
/// ```
///
pub const AssetCode = union(enum) {
    CreditAlphanum4: AssetCode4,
    CreditAlphanum12: AssetCode12,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !AssetCode {
        const disc = try AssetType.xdrDecode(allocator, reader);
        return switch (disc) {
            .CreditAlphanum4 => AssetCode{ .CreditAlphanum4 = try xdrDecodeGeneric(AssetCode4, allocator, reader) },
            .CreditAlphanum12 => AssetCode{ .CreditAlphanum12 = try xdrDecodeGeneric(AssetCode12, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: AssetCode, writer: anytype) !void {
        const disc: AssetType = switch (self) {
            .CreditAlphanum4 => .CreditAlphanum4,
            .CreditAlphanum12 => .CreditAlphanum12,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .CreditAlphanum4 => |v| try xdrEncodeGeneric(AssetCode4, writer, v),
            .CreditAlphanum12 => |v| try xdrEncodeGeneric(AssetCode12, writer, v),
        }
    }
};

/// AlphaNum4 is an XDR Struct defined as:
///
/// ```text
/// struct AlphaNum4
/// {
///     AssetCode4 assetCode;
///     AccountID issuer;
/// };
/// ```
///
pub const AlphaNum4 = struct {
    asset_code: AssetCode4,
    issuer: AccountId,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !AlphaNum4 {
        return AlphaNum4{
            .asset_code = try xdrDecodeGeneric(AssetCode4, allocator, reader),
            .issuer = try xdrDecodeGeneric(AccountId, allocator, reader),
        };
    }

    pub fn xdrEncode(self: AlphaNum4, writer: anytype) !void {
        try xdrEncodeGeneric(AssetCode4, writer, self.asset_code);
        try xdrEncodeGeneric(AccountId, writer, self.issuer);
    }
};

/// AlphaNum12 is an XDR Struct defined as:
///
/// ```text
/// struct AlphaNum12
/// {
///     AssetCode12 assetCode;
///     AccountID issuer;
/// };
/// ```
///
pub const AlphaNum12 = struct {
    asset_code: AssetCode12,
    issuer: AccountId,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !AlphaNum12 {
        return AlphaNum12{
            .asset_code = try xdrDecodeGeneric(AssetCode12, allocator, reader),
            .issuer = try xdrDecodeGeneric(AccountId, allocator, reader),
        };
    }

    pub fn xdrEncode(self: AlphaNum12, writer: anytype) !void {
        try xdrEncodeGeneric(AssetCode12, writer, self.asset_code);
        try xdrEncodeGeneric(AccountId, writer, self.issuer);
    }
};

/// Asset is an XDR Union defined as:
///
/// ```text
/// union Asset switch (AssetType type)
/// {
/// case ASSET_TYPE_NATIVE: // Not credit
///     void;
///
/// case ASSET_TYPE_CREDIT_ALPHANUM4:
///     AlphaNum4 alphaNum4;
///
/// case ASSET_TYPE_CREDIT_ALPHANUM12:
///     AlphaNum12 alphaNum12;
///
///     // add other asset types here in the future
/// };
/// ```
///
pub const Asset = union(enum) {
    Native,
    CreditAlphanum4: AlphaNum4,
    CreditAlphanum12: AlphaNum12,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !Asset {
        const disc = try AssetType.xdrDecode(allocator, reader);
        return switch (disc) {
            .Native => Asset{ .Native = {} },
            .CreditAlphanum4 => Asset{ .CreditAlphanum4 = try xdrDecodeGeneric(AlphaNum4, allocator, reader) },
            .CreditAlphanum12 => Asset{ .CreditAlphanum12 = try xdrDecodeGeneric(AlphaNum12, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: Asset, writer: anytype) !void {
        const disc: AssetType = switch (self) {
            .Native => .Native,
            .CreditAlphanum4 => .CreditAlphanum4,
            .CreditAlphanum12 => .CreditAlphanum12,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Native => {},
            .CreditAlphanum4 => |v| try xdrEncodeGeneric(AlphaNum4, writer, v),
            .CreditAlphanum12 => |v| try xdrEncodeGeneric(AlphaNum12, writer, v),
        }
    }
};

/// Price is an XDR Struct defined as:
///
/// ```text
/// struct Price
/// {
///     int32 n; // numerator
///     int32 d; // denominator
/// };
/// ```
///
pub const Price = struct {
    n: i32,
    d: i32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !Price {
        return Price{
            .n = try xdrDecodeGeneric(i32, allocator, reader),
            .d = try xdrDecodeGeneric(i32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: Price, writer: anytype) !void {
        try xdrEncodeGeneric(i32, writer, self.n);
        try xdrEncodeGeneric(i32, writer, self.d);
    }
};

/// Liabilities is an XDR Struct defined as:
///
/// ```text
/// struct Liabilities
/// {
///     int64 buying;
///     int64 selling;
/// };
/// ```
///
pub const Liabilities = struct {
    buying: i64,
    selling: i64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !Liabilities {
        return Liabilities{
            .buying = try xdrDecodeGeneric(i64, allocator, reader),
            .selling = try xdrDecodeGeneric(i64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: Liabilities, writer: anytype) !void {
        try xdrEncodeGeneric(i64, writer, self.buying);
        try xdrEncodeGeneric(i64, writer, self.selling);
    }
};

/// ThresholdIndexes is an XDR Enum defined as:
///
/// ```text
/// enum ThresholdIndexes
/// {
///     THRESHOLD_MASTER_WEIGHT = 0,
///     THRESHOLD_LOW = 1,
///     THRESHOLD_MED = 2,
///     THRESHOLD_HIGH = 3
/// };
/// ```
///
pub const ThresholdIndexes = enum(i32) {
    MasterWeight = 0,
    Low = 1,
    Med = 2,
    High = 3,
    _,

    pub const variants = [_]ThresholdIndexes{
        .MasterWeight,
        .Low,
        .Med,
        .High,
    };

    pub fn name(self: ThresholdIndexes) []const u8 {
        return switch (self) {
            .MasterWeight => "MasterWeight",
            .Low => "Low",
            .Med => "Med",
            .High => "High",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ThresholdIndexes {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ThresholdIndexes, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// LedgerEntryType is an XDR Enum defined as:
///
/// ```text
/// enum LedgerEntryType
/// {
///     ACCOUNT = 0,
///     TRUSTLINE = 1,
///     OFFER = 2,
///     DATA = 3,
///     CLAIMABLE_BALANCE = 4,
///     LIQUIDITY_POOL = 5,
///     CONTRACT_DATA = 6,
///     CONTRACT_CODE = 7,
///     CONFIG_SETTING = 8,
///     TTL = 9
/// };
/// ```
///
pub const LedgerEntryType = enum(i32) {
    Account = 0,
    Trustline = 1,
    Offer = 2,
    Data = 3,
    ClaimableBalance = 4,
    LiquidityPool = 5,
    ContractData = 6,
    ContractCode = 7,
    ConfigSetting = 8,
    Ttl = 9,
    _,

    pub const variants = [_]LedgerEntryType{
        .Account,
        .Trustline,
        .Offer,
        .Data,
        .ClaimableBalance,
        .LiquidityPool,
        .ContractData,
        .ContractCode,
        .ConfigSetting,
        .Ttl,
    };

    pub fn name(self: LedgerEntryType) []const u8 {
        return switch (self) {
            .Account => "Account",
            .Trustline => "Trustline",
            .Offer => "Offer",
            .Data => "Data",
            .ClaimableBalance => "ClaimableBalance",
            .LiquidityPool => "LiquidityPool",
            .ContractData => "ContractData",
            .ContractCode => "ContractCode",
            .ConfigSetting => "ConfigSetting",
            .Ttl => "Ttl",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerEntryType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: LedgerEntryType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// Signer is an XDR Struct defined as:
///
/// ```text
/// struct Signer
/// {
///     SignerKey key;
///     uint32 weight; // really only need 1 byte
/// };
/// ```
///
pub const Signer = struct {
    key: SignerKey,
    weight: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !Signer {
        return Signer{
            .key = try xdrDecodeGeneric(SignerKey, allocator, reader),
            .weight = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: Signer, writer: anytype) !void {
        try xdrEncodeGeneric(SignerKey, writer, self.key);
        try xdrEncodeGeneric(u32, writer, self.weight);
    }
};

/// AccountFlags is an XDR Enum defined as:
///
/// ```text
/// enum AccountFlags
/// { // masks for each flag
///
///     // Flags set on issuer accounts
///     // TrustLines are created with authorized set to "false" requiring
///     // the issuer to set it for each TrustLine
///     AUTH_REQUIRED_FLAG = 0x1,
///     // If set, the authorized flag in TrustLines can be cleared
///     // otherwise, authorization cannot be revoked
///     AUTH_REVOCABLE_FLAG = 0x2,
///     // Once set, causes all AUTH_* flags to be read-only
///     AUTH_IMMUTABLE_FLAG = 0x4,
///     // Trustlines are created with clawback enabled set to "true",
///     // and claimable balances created from those trustlines are created
///     // with clawback enabled set to "true"
///     AUTH_CLAWBACK_ENABLED_FLAG = 0x8
/// };
/// ```
///
pub const AccountFlags = enum(i32) {
    RequiredFlag = 1,
    RevocableFlag = 2,
    ImmutableFlag = 4,
    ClawbackEnabledFlag = 8,
    _,

    pub const variants = [_]AccountFlags{
        .RequiredFlag,
        .RevocableFlag,
        .ImmutableFlag,
        .ClawbackEnabledFlag,
    };

    pub fn name(self: AccountFlags) []const u8 {
        return switch (self) {
            .RequiredFlag => "RequiredFlag",
            .RevocableFlag => "RevocableFlag",
            .ImmutableFlag => "ImmutableFlag",
            .ClawbackEnabledFlag => "ClawbackEnabledFlag",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !AccountFlags {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: AccountFlags, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// MaskAccountFlags is an XDR Const defined as:
///
/// ```text
/// const MASK_ACCOUNT_FLAGS = 0x7;
/// ```
///
pub const MASK_ACCOUNT_FLAGS: u64 = 0x7;

/// MaskAccountFlagsV17 is an XDR Const defined as:
///
/// ```text
/// const MASK_ACCOUNT_FLAGS_V17 = 0xF;
/// ```
///
pub const MASK_ACCOUNT_FLAGS_V17: u64 = 0xF;

/// MaxSigners is an XDR Const defined as:
///
/// ```text
/// const MAX_SIGNERS = 20;
/// ```
///
pub const MAX_SIGNERS: u64 = 20;

/// SponsorshipDescriptor is an XDR Typedef defined as:
///
/// ```text
/// typedef AccountID* SponsorshipDescriptor;
/// ```
///
pub const SponsorshipDescriptor = struct {
    value: ?AccountId,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SponsorshipDescriptor {
        return SponsorshipDescriptor{
            .value = try xdrDecodeGeneric(?AccountId, allocator, reader),
        };
    }

    pub fn xdrEncode(self: SponsorshipDescriptor, writer: anytype) !void {
        try xdrEncodeGeneric(?AccountId, writer, self.value);
    }
};

/// AccountEntryExtensionV3 is an XDR Struct defined as:
///
/// ```text
/// struct AccountEntryExtensionV3
/// {
///     // We can use this to add more fields, or because it is first, to
///     // change AccountEntryExtensionV3 into a union.
///     ExtensionPoint ext;
///
///     // Ledger number at which `seqNum` took on its present value.
///     uint32 seqLedger;
///
///     // Time at which `seqNum` took on its present value.
///     TimePoint seqTime;
/// };
/// ```
///
pub const AccountEntryExtensionV3 = struct {
    ext: ExtensionPoint,
    seq_ledger: u32,
    seq_time: TimePoint,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !AccountEntryExtensionV3 {
        return AccountEntryExtensionV3{
            .ext = try xdrDecodeGeneric(ExtensionPoint, allocator, reader),
            .seq_ledger = try xdrDecodeGeneric(u32, allocator, reader),
            .seq_time = try xdrDecodeGeneric(TimePoint, allocator, reader),
        };
    }

    pub fn xdrEncode(self: AccountEntryExtensionV3, writer: anytype) !void {
        try xdrEncodeGeneric(ExtensionPoint, writer, self.ext);
        try xdrEncodeGeneric(u32, writer, self.seq_ledger);
        try xdrEncodeGeneric(TimePoint, writer, self.seq_time);
    }
};

/// AccountEntryExtensionV2Ext is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (int v)
///     {
///     case 0:
///         void;
///     case 3:
///         AccountEntryExtensionV3 v3;
///     }
/// ```
///
pub const AccountEntryExtensionV2Ext = union(enum) {
    V0,
    V3: AccountEntryExtensionV3,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !AccountEntryExtensionV2Ext {
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => AccountEntryExtensionV2Ext{ .V0 = {} },
            3 => AccountEntryExtensionV2Ext{ .V3 = try xdrDecodeGeneric(AccountEntryExtensionV3, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: AccountEntryExtensionV2Ext, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
            .V3 => |v| {
                try writer.writeInt(i32, 3, .big);
                try xdrEncodeGeneric(AccountEntryExtensionV3, writer, v);
            },
        }
    }
};

/// AccountEntryExtensionV2 is an XDR Struct defined as:
///
/// ```text
/// struct AccountEntryExtensionV2
/// {
///     uint32 numSponsored;
///     uint32 numSponsoring;
///     SponsorshipDescriptor signerSponsoringIDs<MAX_SIGNERS>;
///
///     union switch (int v)
///     {
///     case 0:
///         void;
///     case 3:
///         AccountEntryExtensionV3 v3;
///     }
///     ext;
/// };
/// ```
///
pub const AccountEntryExtensionV2 = struct {
    num_sponsored: u32,
    num_sponsoring: u32,
    signer_sponsoring_i_ds: BoundedArray(SponsorshipDescriptor, 20),
    ext: AccountEntryExtensionV2Ext,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !AccountEntryExtensionV2 {
        return AccountEntryExtensionV2{
            .num_sponsored = try xdrDecodeGeneric(u32, allocator, reader),
            .num_sponsoring = try xdrDecodeGeneric(u32, allocator, reader),
            .signer_sponsoring_i_ds = try xdrDecodeGeneric(BoundedArray(SponsorshipDescriptor, 20), allocator, reader),
            .ext = try xdrDecodeGeneric(AccountEntryExtensionV2Ext, allocator, reader),
        };
    }

    pub fn xdrEncode(self: AccountEntryExtensionV2, writer: anytype) !void {
        try xdrEncodeGeneric(u32, writer, self.num_sponsored);
        try xdrEncodeGeneric(u32, writer, self.num_sponsoring);
        try xdrEncodeGeneric(BoundedArray(SponsorshipDescriptor, 20), writer, self.signer_sponsoring_i_ds);
        try xdrEncodeGeneric(AccountEntryExtensionV2Ext, writer, self.ext);
    }
};

/// AccountEntryExtensionV1Ext is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (int v)
///     {
///     case 0:
///         void;
///     case 2:
///         AccountEntryExtensionV2 v2;
///     }
/// ```
///
pub const AccountEntryExtensionV1Ext = union(enum) {
    V0,
    V2: AccountEntryExtensionV2,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !AccountEntryExtensionV1Ext {
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => AccountEntryExtensionV1Ext{ .V0 = {} },
            2 => AccountEntryExtensionV1Ext{ .V2 = try xdrDecodeGeneric(AccountEntryExtensionV2, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: AccountEntryExtensionV1Ext, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
            .V2 => |v| {
                try writer.writeInt(i32, 2, .big);
                try xdrEncodeGeneric(AccountEntryExtensionV2, writer, v);
            },
        }
    }
};

/// AccountEntryExtensionV1 is an XDR Struct defined as:
///
/// ```text
/// struct AccountEntryExtensionV1
/// {
///     Liabilities liabilities;
///
///     union switch (int v)
///     {
///     case 0:
///         void;
///     case 2:
///         AccountEntryExtensionV2 v2;
///     }
///     ext;
/// };
/// ```
///
pub const AccountEntryExtensionV1 = struct {
    liabilities: Liabilities,
    ext: AccountEntryExtensionV1Ext,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !AccountEntryExtensionV1 {
        return AccountEntryExtensionV1{
            .liabilities = try xdrDecodeGeneric(Liabilities, allocator, reader),
            .ext = try xdrDecodeGeneric(AccountEntryExtensionV1Ext, allocator, reader),
        };
    }

    pub fn xdrEncode(self: AccountEntryExtensionV1, writer: anytype) !void {
        try xdrEncodeGeneric(Liabilities, writer, self.liabilities);
        try xdrEncodeGeneric(AccountEntryExtensionV1Ext, writer, self.ext);
    }
};

/// AccountEntryExt is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (int v)
///     {
///     case 0:
///         void;
///     case 1:
///         AccountEntryExtensionV1 v1;
///     }
/// ```
///
pub const AccountEntryExt = union(enum) {
    V0,
    V1: AccountEntryExtensionV1,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !AccountEntryExt {
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => AccountEntryExt{ .V0 = {} },
            1 => AccountEntryExt{ .V1 = try xdrDecodeGeneric(AccountEntryExtensionV1, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: AccountEntryExt, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
            .V1 => |v| {
                try writer.writeInt(i32, 1, .big);
                try xdrEncodeGeneric(AccountEntryExtensionV1, writer, v);
            },
        }
    }
};

/// AccountEntry is an XDR Struct defined as:
///
/// ```text
/// struct AccountEntry
/// {
///     AccountID accountID;      // master public key for this account
///     int64 balance;            // in stroops
///     SequenceNumber seqNum;    // last sequence number used for this account
///     uint32 numSubEntries;     // number of sub-entries this account has
///                               // drives the reserve
///     AccountID* inflationDest; // Account to vote for during inflation
///     uint32 flags;             // see AccountFlags
///
///     string32 homeDomain; // can be used for reverse federation and memo lookup
///
///     // fields used for signatures
///     // thresholds stores unsigned bytes: [weight of master|low|medium|high]
///     Thresholds thresholds;
///
///     Signer signers<MAX_SIGNERS>; // possible signers for this account
///
///     // reserved for future use
///     union switch (int v)
///     {
///     case 0:
///         void;
///     case 1:
///         AccountEntryExtensionV1 v1;
///     }
///     ext;
/// };
/// ```
///
pub const AccountEntry = struct {
    account_id: AccountId,
    balance: i64,
    seq_num: SequenceNumber,
    num_sub_entries: u32,
    inflation_dest: ?AccountId,
    flags: u32,
    home_domain: String32,
    thresholds: Thresholds,
    signers: BoundedArray(Signer, 20),
    ext: AccountEntryExt,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !AccountEntry {
        return AccountEntry{
            .account_id = try xdrDecodeGeneric(AccountId, allocator, reader),
            .balance = try xdrDecodeGeneric(i64, allocator, reader),
            .seq_num = try xdrDecodeGeneric(SequenceNumber, allocator, reader),
            .num_sub_entries = try xdrDecodeGeneric(u32, allocator, reader),
            .inflation_dest = try xdrDecodeGeneric(?AccountId, allocator, reader),
            .flags = try xdrDecodeGeneric(u32, allocator, reader),
            .home_domain = try xdrDecodeGeneric(String32, allocator, reader),
            .thresholds = try xdrDecodeGeneric(Thresholds, allocator, reader),
            .signers = try xdrDecodeGeneric(BoundedArray(Signer, 20), allocator, reader),
            .ext = try xdrDecodeGeneric(AccountEntryExt, allocator, reader),
        };
    }

    pub fn xdrEncode(self: AccountEntry, writer: anytype) !void {
        try xdrEncodeGeneric(AccountId, writer, self.account_id);
        try xdrEncodeGeneric(i64, writer, self.balance);
        try xdrEncodeGeneric(SequenceNumber, writer, self.seq_num);
        try xdrEncodeGeneric(u32, writer, self.num_sub_entries);
        try xdrEncodeGeneric(?AccountId, writer, self.inflation_dest);
        try xdrEncodeGeneric(u32, writer, self.flags);
        try xdrEncodeGeneric(String32, writer, self.home_domain);
        try xdrEncodeGeneric(Thresholds, writer, self.thresholds);
        try xdrEncodeGeneric(BoundedArray(Signer, 20), writer, self.signers);
        try xdrEncodeGeneric(AccountEntryExt, writer, self.ext);
    }
};

/// TrustLineFlags is an XDR Enum defined as:
///
/// ```text
/// enum TrustLineFlags
/// {
///     // issuer has authorized account to perform transactions with its credit
///     AUTHORIZED_FLAG = 1,
///     // issuer has authorized account to maintain and reduce liabilities for its
///     // credit
///     AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG = 2,
///     // issuer has specified that it may clawback its credit, and that claimable
///     // balances created with its credit may also be clawed back
///     TRUSTLINE_CLAWBACK_ENABLED_FLAG = 4
/// };
/// ```
///
pub const TrustLineFlags = enum(i32) {
    AuthorizedFlag = 1,
    AuthorizedToMaintainLiabilitiesFlag = 2,
    TrustlineClawbackEnabledFlag = 4,
    _,

    pub const variants = [_]TrustLineFlags{
        .AuthorizedFlag,
        .AuthorizedToMaintainLiabilitiesFlag,
        .TrustlineClawbackEnabledFlag,
    };

    pub fn name(self: TrustLineFlags) []const u8 {
        return switch (self) {
            .AuthorizedFlag => "AuthorizedFlag",
            .AuthorizedToMaintainLiabilitiesFlag => "AuthorizedToMaintainLiabilitiesFlag",
            .TrustlineClawbackEnabledFlag => "TrustlineClawbackEnabledFlag",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TrustLineFlags {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: TrustLineFlags, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// MaskTrustlineFlags is an XDR Const defined as:
///
/// ```text
/// const MASK_TRUSTLINE_FLAGS = 1;
/// ```
///
pub const MASK_TRUSTLINE_FLAGS: u64 = 1;

/// MaskTrustlineFlagsV13 is an XDR Const defined as:
///
/// ```text
/// const MASK_TRUSTLINE_FLAGS_V13 = 3;
/// ```
///
pub const MASK_TRUSTLINE_FLAGS_V13: u64 = 3;

/// MaskTrustlineFlagsV17 is an XDR Const defined as:
///
/// ```text
/// const MASK_TRUSTLINE_FLAGS_V17 = 7;
/// ```
///
pub const MASK_TRUSTLINE_FLAGS_V17: u64 = 7;

/// LiquidityPoolType is an XDR Enum defined as:
///
/// ```text
/// enum LiquidityPoolType
/// {
///     LIQUIDITY_POOL_CONSTANT_PRODUCT = 0
/// };
/// ```
///
pub const LiquidityPoolType = enum(i32) {
    LiquidityPoolConstantProduct = 0,
    _,

    pub const variants = [_]LiquidityPoolType{
        .LiquidityPoolConstantProduct,
    };

    pub fn name(self: LiquidityPoolType) []const u8 {
        return switch (self) {
            .LiquidityPoolConstantProduct => "LiquidityPoolConstantProduct",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LiquidityPoolType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: LiquidityPoolType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// TrustLineAsset is an XDR Union defined as:
///
/// ```text
/// union TrustLineAsset switch (AssetType type)
/// {
/// case ASSET_TYPE_NATIVE: // Not credit
///     void;
///
/// case ASSET_TYPE_CREDIT_ALPHANUM4:
///     AlphaNum4 alphaNum4;
///
/// case ASSET_TYPE_CREDIT_ALPHANUM12:
///     AlphaNum12 alphaNum12;
///
/// case ASSET_TYPE_POOL_SHARE:
///     PoolID liquidityPoolID;
///
///     // add other asset types here in the future
/// };
/// ```
///
pub const TrustLineAsset = union(enum) {
    Native,
    CreditAlphanum4: AlphaNum4,
    CreditAlphanum12: AlphaNum12,
    PoolShare: PoolId,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TrustLineAsset {
        const disc = try AssetType.xdrDecode(allocator, reader);
        return switch (disc) {
            .Native => TrustLineAsset{ .Native = {} },
            .CreditAlphanum4 => TrustLineAsset{ .CreditAlphanum4 = try xdrDecodeGeneric(AlphaNum4, allocator, reader) },
            .CreditAlphanum12 => TrustLineAsset{ .CreditAlphanum12 = try xdrDecodeGeneric(AlphaNum12, allocator, reader) },
            .PoolShare => TrustLineAsset{ .PoolShare = try xdrDecodeGeneric(PoolId, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: TrustLineAsset, writer: anytype) !void {
        const disc: AssetType = switch (self) {
            .Native => .Native,
            .CreditAlphanum4 => .CreditAlphanum4,
            .CreditAlphanum12 => .CreditAlphanum12,
            .PoolShare => .PoolShare,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Native => {},
            .CreditAlphanum4 => |v| try xdrEncodeGeneric(AlphaNum4, writer, v),
            .CreditAlphanum12 => |v| try xdrEncodeGeneric(AlphaNum12, writer, v),
            .PoolShare => |v| try xdrEncodeGeneric(PoolId, writer, v),
        }
    }
};

/// TrustLineEntryExtensionV2Ext is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (int v)
///     {
///     case 0:
///         void;
///     }
/// ```
///
pub const TrustLineEntryExtensionV2Ext = union(enum) {
    V0,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TrustLineEntryExtensionV2Ext {
        _ = allocator;
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => TrustLineEntryExtensionV2Ext{ .V0 = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: TrustLineEntryExtensionV2Ext, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
        }
    }
};

/// TrustLineEntryExtensionV2 is an XDR Struct defined as:
///
/// ```text
/// struct TrustLineEntryExtensionV2
/// {
///     int32 liquidityPoolUseCount;
///
///     union switch (int v)
///     {
///     case 0:
///         void;
///     }
///     ext;
/// };
/// ```
///
pub const TrustLineEntryExtensionV2 = struct {
    liquidity_pool_use_count: i32,
    ext: TrustLineEntryExtensionV2Ext,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TrustLineEntryExtensionV2 {
        return TrustLineEntryExtensionV2{
            .liquidity_pool_use_count = try xdrDecodeGeneric(i32, allocator, reader),
            .ext = try xdrDecodeGeneric(TrustLineEntryExtensionV2Ext, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TrustLineEntryExtensionV2, writer: anytype) !void {
        try xdrEncodeGeneric(i32, writer, self.liquidity_pool_use_count);
        try xdrEncodeGeneric(TrustLineEntryExtensionV2Ext, writer, self.ext);
    }
};

/// TrustLineEntryV1Ext is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (int v)
///             {
///             case 0:
///                 void;
///             case 2:
///                 TrustLineEntryExtensionV2 v2;
///             }
/// ```
///
pub const TrustLineEntryV1Ext = union(enum) {
    V0,
    V2: TrustLineEntryExtensionV2,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TrustLineEntryV1Ext {
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => TrustLineEntryV1Ext{ .V0 = {} },
            2 => TrustLineEntryV1Ext{ .V2 = try xdrDecodeGeneric(TrustLineEntryExtensionV2, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: TrustLineEntryV1Ext, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
            .V2 => |v| {
                try writer.writeInt(i32, 2, .big);
                try xdrEncodeGeneric(TrustLineEntryExtensionV2, writer, v);
            },
        }
    }
};

/// TrustLineEntryV1 is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///         {
///             Liabilities liabilities;
///
///             union switch (int v)
///             {
///             case 0:
///                 void;
///             case 2:
///                 TrustLineEntryExtensionV2 v2;
///             }
///             ext;
///         }
/// ```
///
pub const TrustLineEntryV1 = struct {
    liabilities: Liabilities,
    ext: TrustLineEntryV1Ext,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TrustLineEntryV1 {
        return TrustLineEntryV1{
            .liabilities = try xdrDecodeGeneric(Liabilities, allocator, reader),
            .ext = try xdrDecodeGeneric(TrustLineEntryV1Ext, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TrustLineEntryV1, writer: anytype) !void {
        try xdrEncodeGeneric(Liabilities, writer, self.liabilities);
        try xdrEncodeGeneric(TrustLineEntryV1Ext, writer, self.ext);
    }
};

/// TrustLineEntryExt is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (int v)
///     {
///     case 0:
///         void;
///     case 1:
///         struct
///         {
///             Liabilities liabilities;
///
///             union switch (int v)
///             {
///             case 0:
///                 void;
///             case 2:
///                 TrustLineEntryExtensionV2 v2;
///             }
///             ext;
///         } v1;
///     }
/// ```
///
pub const TrustLineEntryExt = union(enum) {
    V0,
    V1: TrustLineEntryV1,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TrustLineEntryExt {
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => TrustLineEntryExt{ .V0 = {} },
            1 => TrustLineEntryExt{ .V1 = try xdrDecodeGeneric(TrustLineEntryV1, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: TrustLineEntryExt, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
            .V1 => |v| {
                try writer.writeInt(i32, 1, .big);
                try xdrEncodeGeneric(TrustLineEntryV1, writer, v);
            },
        }
    }
};

/// TrustLineEntry is an XDR Struct defined as:
///
/// ```text
/// struct TrustLineEntry
/// {
///     AccountID accountID;  // account this trustline belongs to
///     TrustLineAsset asset; // type of asset (with issuer)
///     int64 balance;        // how much of this asset the user has.
///                           // Asset defines the unit for this;
///
///     int64 limit;  // balance cannot be above this
///     uint32 flags; // see TrustLineFlags
///
///     // reserved for future use
///     union switch (int v)
///     {
///     case 0:
///         void;
///     case 1:
///         struct
///         {
///             Liabilities liabilities;
///
///             union switch (int v)
///             {
///             case 0:
///                 void;
///             case 2:
///                 TrustLineEntryExtensionV2 v2;
///             }
///             ext;
///         } v1;
///     }
///     ext;
/// };
/// ```
///
pub const TrustLineEntry = struct {
    account_id: AccountId,
    asset: TrustLineAsset,
    balance: i64,
    limit: i64,
    flags: u32,
    ext: TrustLineEntryExt,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TrustLineEntry {
        return TrustLineEntry{
            .account_id = try xdrDecodeGeneric(AccountId, allocator, reader),
            .asset = try xdrDecodeGeneric(TrustLineAsset, allocator, reader),
            .balance = try xdrDecodeGeneric(i64, allocator, reader),
            .limit = try xdrDecodeGeneric(i64, allocator, reader),
            .flags = try xdrDecodeGeneric(u32, allocator, reader),
            .ext = try xdrDecodeGeneric(TrustLineEntryExt, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TrustLineEntry, writer: anytype) !void {
        try xdrEncodeGeneric(AccountId, writer, self.account_id);
        try xdrEncodeGeneric(TrustLineAsset, writer, self.asset);
        try xdrEncodeGeneric(i64, writer, self.balance);
        try xdrEncodeGeneric(i64, writer, self.limit);
        try xdrEncodeGeneric(u32, writer, self.flags);
        try xdrEncodeGeneric(TrustLineEntryExt, writer, self.ext);
    }
};

/// OfferEntryFlags is an XDR Enum defined as:
///
/// ```text
/// enum OfferEntryFlags
/// {
///     // an offer with this flag will not act on and take a reverse offer of equal
///     // price
///     PASSIVE_FLAG = 1
/// };
/// ```
///
pub const OfferEntryFlags = enum(i32) {
    PassiveFlag = 1,
    _,

    pub const variants = [_]OfferEntryFlags{
        .PassiveFlag,
    };

    pub fn name(self: OfferEntryFlags) []const u8 {
        return switch (self) {
            .PassiveFlag => "PassiveFlag",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !OfferEntryFlags {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: OfferEntryFlags, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// MaskOfferentryFlags is an XDR Const defined as:
///
/// ```text
/// const MASK_OFFERENTRY_FLAGS = 1;
/// ```
///
pub const MASK_OFFERENTRY_FLAGS: u64 = 1;

/// OfferEntryExt is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (int v)
///     {
///     case 0:
///         void;
///     }
/// ```
///
pub const OfferEntryExt = union(enum) {
    V0,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !OfferEntryExt {
        _ = allocator;
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => OfferEntryExt{ .V0 = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: OfferEntryExt, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
        }
    }
};

/// OfferEntry is an XDR Struct defined as:
///
/// ```text
/// struct OfferEntry
/// {
///     AccountID sellerID;
///     int64 offerID;
///     Asset selling; // A
///     Asset buying;  // B
///     int64 amount;  // amount of A
///
///     /* price for this offer:
///         price of A in terms of B
///         price=AmountB/AmountA=priceNumerator/priceDenominator
///         price is after fees
///     */
///     Price price;
///     uint32 flags; // see OfferEntryFlags
///
///     // reserved for future use
///     union switch (int v)
///     {
///     case 0:
///         void;
///     }
///     ext;
/// };
/// ```
///
pub const OfferEntry = struct {
    seller_id: AccountId,
    offer_id: i64,
    selling: Asset,
    buying: Asset,
    amount: i64,
    price: Price,
    flags: u32,
    ext: OfferEntryExt,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !OfferEntry {
        return OfferEntry{
            .seller_id = try xdrDecodeGeneric(AccountId, allocator, reader),
            .offer_id = try xdrDecodeGeneric(i64, allocator, reader),
            .selling = try xdrDecodeGeneric(Asset, allocator, reader),
            .buying = try xdrDecodeGeneric(Asset, allocator, reader),
            .amount = try xdrDecodeGeneric(i64, allocator, reader),
            .price = try xdrDecodeGeneric(Price, allocator, reader),
            .flags = try xdrDecodeGeneric(u32, allocator, reader),
            .ext = try xdrDecodeGeneric(OfferEntryExt, allocator, reader),
        };
    }

    pub fn xdrEncode(self: OfferEntry, writer: anytype) !void {
        try xdrEncodeGeneric(AccountId, writer, self.seller_id);
        try xdrEncodeGeneric(i64, writer, self.offer_id);
        try xdrEncodeGeneric(Asset, writer, self.selling);
        try xdrEncodeGeneric(Asset, writer, self.buying);
        try xdrEncodeGeneric(i64, writer, self.amount);
        try xdrEncodeGeneric(Price, writer, self.price);
        try xdrEncodeGeneric(u32, writer, self.flags);
        try xdrEncodeGeneric(OfferEntryExt, writer, self.ext);
    }
};

/// DataEntryExt is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (int v)
///     {
///     case 0:
///         void;
///     }
/// ```
///
pub const DataEntryExt = union(enum) {
    V0,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !DataEntryExt {
        _ = allocator;
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => DataEntryExt{ .V0 = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: DataEntryExt, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
        }
    }
};

/// DataEntry is an XDR Struct defined as:
///
/// ```text
/// struct DataEntry
/// {
///     AccountID accountID; // account this data belongs to
///     string64 dataName;
///     DataValue dataValue;
///
///     // reserved for future use
///     union switch (int v)
///     {
///     case 0:
///         void;
///     }
///     ext;
/// };
/// ```
///
pub const DataEntry = struct {
    account_id: AccountId,
    data_name: String64,
    data_value: DataValue,
    ext: DataEntryExt,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !DataEntry {
        return DataEntry{
            .account_id = try xdrDecodeGeneric(AccountId, allocator, reader),
            .data_name = try xdrDecodeGeneric(String64, allocator, reader),
            .data_value = try xdrDecodeGeneric(DataValue, allocator, reader),
            .ext = try xdrDecodeGeneric(DataEntryExt, allocator, reader),
        };
    }

    pub fn xdrEncode(self: DataEntry, writer: anytype) !void {
        try xdrEncodeGeneric(AccountId, writer, self.account_id);
        try xdrEncodeGeneric(String64, writer, self.data_name);
        try xdrEncodeGeneric(DataValue, writer, self.data_value);
        try xdrEncodeGeneric(DataEntryExt, writer, self.ext);
    }
};

/// ClaimPredicateType is an XDR Enum defined as:
///
/// ```text
/// enum ClaimPredicateType
/// {
///     CLAIM_PREDICATE_UNCONDITIONAL = 0,
///     CLAIM_PREDICATE_AND = 1,
///     CLAIM_PREDICATE_OR = 2,
///     CLAIM_PREDICATE_NOT = 3,
///     CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME = 4,
///     CLAIM_PREDICATE_BEFORE_RELATIVE_TIME = 5
/// };
/// ```
///
pub const ClaimPredicateType = enum(i32) {
    Unconditional = 0,
    And = 1,
    Or = 2,
    Not = 3,
    BeforeAbsoluteTime = 4,
    BeforeRelativeTime = 5,
    _,

    pub const variants = [_]ClaimPredicateType{
        .Unconditional,
        .And,
        .Or,
        .Not,
        .BeforeAbsoluteTime,
        .BeforeRelativeTime,
    };

    pub fn name(self: ClaimPredicateType) []const u8 {
        return switch (self) {
            .Unconditional => "Unconditional",
            .And => "And",
            .Or => "Or",
            .Not => "Not",
            .BeforeAbsoluteTime => "BeforeAbsoluteTime",
            .BeforeRelativeTime => "BeforeRelativeTime",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ClaimPredicateType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ClaimPredicateType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ClaimPredicate is an XDR Union defined as:
///
/// ```text
/// union ClaimPredicate switch (ClaimPredicateType type)
/// {
/// case CLAIM_PREDICATE_UNCONDITIONAL:
///     void;
/// case CLAIM_PREDICATE_AND:
///     ClaimPredicate andPredicates<2>;
/// case CLAIM_PREDICATE_OR:
///     ClaimPredicate orPredicates<2>;
/// case CLAIM_PREDICATE_NOT:
///     ClaimPredicate* notPredicate;
/// case CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME:
///     int64 absBefore; // Predicate will be true if closeTime < absBefore
/// case CLAIM_PREDICATE_BEFORE_RELATIVE_TIME:
///     int64 relBefore; // Seconds since closeTime of the ledger in which the
///                      // ClaimableBalanceEntry was created
/// };
/// ```
///
pub const ClaimPredicate = union(enum) {
    Unconditional,
    And: BoundedArray(ClaimPredicate, 2),
    Or: BoundedArray(ClaimPredicate, 2),
    Not: ?*ClaimPredicate,
    BeforeAbsoluteTime: i64,
    BeforeRelativeTime: i64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ClaimPredicate {
        const disc = try ClaimPredicateType.xdrDecode(allocator, reader);
        return switch (disc) {
            .Unconditional => ClaimPredicate{ .Unconditional = {} },
            .And => ClaimPredicate{ .And = try xdrDecodeGeneric(BoundedArray(ClaimPredicate, 2), allocator, reader) },
            .Or => ClaimPredicate{ .Or = try xdrDecodeGeneric(BoundedArray(ClaimPredicate, 2), allocator, reader) },
            .Not => ClaimPredicate{ .Not = try xdrDecodeGeneric(?*ClaimPredicate, allocator, reader) },
            .BeforeAbsoluteTime => ClaimPredicate{ .BeforeAbsoluteTime = try xdrDecodeGeneric(i64, allocator, reader) },
            .BeforeRelativeTime => ClaimPredicate{ .BeforeRelativeTime = try xdrDecodeGeneric(i64, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ClaimPredicate, writer: anytype) !void {
        const disc: ClaimPredicateType = switch (self) {
            .Unconditional => .Unconditional,
            .And => .And,
            .Or => .Or,
            .Not => .Not,
            .BeforeAbsoluteTime => .BeforeAbsoluteTime,
            .BeforeRelativeTime => .BeforeRelativeTime,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Unconditional => {},
            .And => |v| try xdrEncodeGeneric(BoundedArray(ClaimPredicate, 2), writer, v),
            .Or => |v| try xdrEncodeGeneric(BoundedArray(ClaimPredicate, 2), writer, v),
            .Not => |v| try xdrEncodeGeneric(?*ClaimPredicate, writer, v),
            .BeforeAbsoluteTime => |v| try xdrEncodeGeneric(i64, writer, v),
            .BeforeRelativeTime => |v| try xdrEncodeGeneric(i64, writer, v),
        }
    }
};

/// ClaimantType is an XDR Enum defined as:
///
/// ```text
/// enum ClaimantType
/// {
///     CLAIMANT_TYPE_V0 = 0
/// };
/// ```
///
pub const ClaimantType = enum(i32) {
    ClaimantTypeV0 = 0,
    _,

    pub const variants = [_]ClaimantType{
        .ClaimantTypeV0,
    };

    pub fn name(self: ClaimantType) []const u8 {
        return switch (self) {
            .ClaimantTypeV0 => "ClaimantTypeV0",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ClaimantType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ClaimantType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ClaimantV0 is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///     {
///         AccountID destination;    // The account that can use this condition
///         ClaimPredicate predicate; // Claimable if predicate is true
///     }
/// ```
///
pub const ClaimantV0 = struct {
    destination: AccountId,
    predicate: ClaimPredicate,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ClaimantV0 {
        return ClaimantV0{
            .destination = try xdrDecodeGeneric(AccountId, allocator, reader),
            .predicate = try xdrDecodeGeneric(ClaimPredicate, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ClaimantV0, writer: anytype) !void {
        try xdrEncodeGeneric(AccountId, writer, self.destination);
        try xdrEncodeGeneric(ClaimPredicate, writer, self.predicate);
    }
};

/// Claimant is an XDR Union defined as:
///
/// ```text
/// union Claimant switch (ClaimantType type)
/// {
/// case CLAIMANT_TYPE_V0:
///     struct
///     {
///         AccountID destination;    // The account that can use this condition
///         ClaimPredicate predicate; // Claimable if predicate is true
///     } v0;
/// };
/// ```
///
pub const Claimant = union(enum) {
    ClaimantTypeV0: ClaimantV0,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !Claimant {
        const disc = try ClaimantType.xdrDecode(allocator, reader);
        return switch (disc) {
            .ClaimantTypeV0 => Claimant{ .ClaimantTypeV0 = try xdrDecodeGeneric(ClaimantV0, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: Claimant, writer: anytype) !void {
        const disc: ClaimantType = switch (self) {
            .ClaimantTypeV0 => .ClaimantTypeV0,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .ClaimantTypeV0 => |v| try xdrEncodeGeneric(ClaimantV0, writer, v),
        }
    }
};

/// ClaimableBalanceFlags is an XDR Enum defined as:
///
/// ```text
/// enum ClaimableBalanceFlags
/// {
///     // If set, the issuer account of the asset held by the claimable balance may
///     // clawback the claimable balance
///     CLAIMABLE_BALANCE_CLAWBACK_ENABLED_FLAG = 0x1
/// };
/// ```
///
pub const ClaimableBalanceFlags = enum(i32) {
    ClaimableBalanceClawbackEnabledFlag = 1,
    _,

    pub const variants = [_]ClaimableBalanceFlags{
        .ClaimableBalanceClawbackEnabledFlag,
    };

    pub fn name(self: ClaimableBalanceFlags) []const u8 {
        return switch (self) {
            .ClaimableBalanceClawbackEnabledFlag => "ClaimableBalanceClawbackEnabledFlag",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ClaimableBalanceFlags {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ClaimableBalanceFlags, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// MaskClaimableBalanceFlags is an XDR Const defined as:
///
/// ```text
/// const MASK_CLAIMABLE_BALANCE_FLAGS = 0x1;
/// ```
///
pub const MASK_CLAIMABLE_BALANCE_FLAGS: u64 = 0x1;

/// ClaimableBalanceEntryExtensionV1Ext is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (int v)
///     {
///     case 0:
///         void;
///     }
/// ```
///
pub const ClaimableBalanceEntryExtensionV1Ext = union(enum) {
    V0,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ClaimableBalanceEntryExtensionV1Ext {
        _ = allocator;
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => ClaimableBalanceEntryExtensionV1Ext{ .V0 = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ClaimableBalanceEntryExtensionV1Ext, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
        }
    }
};

/// ClaimableBalanceEntryExtensionV1 is an XDR Struct defined as:
///
/// ```text
/// struct ClaimableBalanceEntryExtensionV1
/// {
///     union switch (int v)
///     {
///     case 0:
///         void;
///     }
///     ext;
///
///     uint32 flags; // see ClaimableBalanceFlags
/// };
/// ```
///
pub const ClaimableBalanceEntryExtensionV1 = struct {
    ext: ClaimableBalanceEntryExtensionV1Ext,
    flags: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ClaimableBalanceEntryExtensionV1 {
        return ClaimableBalanceEntryExtensionV1{
            .ext = try xdrDecodeGeneric(ClaimableBalanceEntryExtensionV1Ext, allocator, reader),
            .flags = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ClaimableBalanceEntryExtensionV1, writer: anytype) !void {
        try xdrEncodeGeneric(ClaimableBalanceEntryExtensionV1Ext, writer, self.ext);
        try xdrEncodeGeneric(u32, writer, self.flags);
    }
};

/// ClaimableBalanceEntryExt is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (int v)
///     {
///     case 0:
///         void;
///     case 1:
///         ClaimableBalanceEntryExtensionV1 v1;
///     }
/// ```
///
pub const ClaimableBalanceEntryExt = union(enum) {
    V0,
    V1: ClaimableBalanceEntryExtensionV1,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ClaimableBalanceEntryExt {
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => ClaimableBalanceEntryExt{ .V0 = {} },
            1 => ClaimableBalanceEntryExt{ .V1 = try xdrDecodeGeneric(ClaimableBalanceEntryExtensionV1, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ClaimableBalanceEntryExt, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
            .V1 => |v| {
                try writer.writeInt(i32, 1, .big);
                try xdrEncodeGeneric(ClaimableBalanceEntryExtensionV1, writer, v);
            },
        }
    }
};

/// ClaimableBalanceEntry is an XDR Struct defined as:
///
/// ```text
/// struct ClaimableBalanceEntry
/// {
///     // Unique identifier for this ClaimableBalanceEntry
///     ClaimableBalanceID balanceID;
///
///     // List of claimants with associated predicate
///     Claimant claimants<10>;
///
///     // Any asset including native
///     Asset asset;
///
///     // Amount of asset
///     int64 amount;
///
///     // reserved for future use
///     union switch (int v)
///     {
///     case 0:
///         void;
///     case 1:
///         ClaimableBalanceEntryExtensionV1 v1;
///     }
///     ext;
/// };
/// ```
///
pub const ClaimableBalanceEntry = struct {
    balance_id: ClaimableBalanceId,
    claimants: BoundedArray(Claimant, 10),
    asset: Asset,
    amount: i64,
    ext: ClaimableBalanceEntryExt,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ClaimableBalanceEntry {
        return ClaimableBalanceEntry{
            .balance_id = try xdrDecodeGeneric(ClaimableBalanceId, allocator, reader),
            .claimants = try xdrDecodeGeneric(BoundedArray(Claimant, 10), allocator, reader),
            .asset = try xdrDecodeGeneric(Asset, allocator, reader),
            .amount = try xdrDecodeGeneric(i64, allocator, reader),
            .ext = try xdrDecodeGeneric(ClaimableBalanceEntryExt, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ClaimableBalanceEntry, writer: anytype) !void {
        try xdrEncodeGeneric(ClaimableBalanceId, writer, self.balance_id);
        try xdrEncodeGeneric(BoundedArray(Claimant, 10), writer, self.claimants);
        try xdrEncodeGeneric(Asset, writer, self.asset);
        try xdrEncodeGeneric(i64, writer, self.amount);
        try xdrEncodeGeneric(ClaimableBalanceEntryExt, writer, self.ext);
    }
};

/// LiquidityPoolConstantProductParameters is an XDR Struct defined as:
///
/// ```text
/// struct LiquidityPoolConstantProductParameters
/// {
///     Asset assetA; // assetA < assetB
///     Asset assetB;
///     int32 fee; // Fee is in basis points, so the actual rate is (fee/100)%
/// };
/// ```
///
pub const LiquidityPoolConstantProductParameters = struct {
    asset_a: Asset,
    asset_b: Asset,
    fee: i32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LiquidityPoolConstantProductParameters {
        return LiquidityPoolConstantProductParameters{
            .asset_a = try xdrDecodeGeneric(Asset, allocator, reader),
            .asset_b = try xdrDecodeGeneric(Asset, allocator, reader),
            .fee = try xdrDecodeGeneric(i32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LiquidityPoolConstantProductParameters, writer: anytype) !void {
        try xdrEncodeGeneric(Asset, writer, self.asset_a);
        try xdrEncodeGeneric(Asset, writer, self.asset_b);
        try xdrEncodeGeneric(i32, writer, self.fee);
    }
};

/// LiquidityPoolEntryConstantProduct is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///         {
///             LiquidityPoolConstantProductParameters params;
///
///             int64 reserveA;        // amount of A in the pool
///             int64 reserveB;        // amount of B in the pool
///             int64 totalPoolShares; // total number of pool shares issued
///             int64 poolSharesTrustLineCount; // number of trust lines for the
///                                             // associated pool shares
///         }
/// ```
///
pub const LiquidityPoolEntryConstantProduct = struct {
    params: LiquidityPoolConstantProductParameters,
    reserve_a: i64,
    reserve_b: i64,
    total_pool_shares: i64,
    pool_shares_trust_line_count: i64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LiquidityPoolEntryConstantProduct {
        return LiquidityPoolEntryConstantProduct{
            .params = try xdrDecodeGeneric(LiquidityPoolConstantProductParameters, allocator, reader),
            .reserve_a = try xdrDecodeGeneric(i64, allocator, reader),
            .reserve_b = try xdrDecodeGeneric(i64, allocator, reader),
            .total_pool_shares = try xdrDecodeGeneric(i64, allocator, reader),
            .pool_shares_trust_line_count = try xdrDecodeGeneric(i64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LiquidityPoolEntryConstantProduct, writer: anytype) !void {
        try xdrEncodeGeneric(LiquidityPoolConstantProductParameters, writer, self.params);
        try xdrEncodeGeneric(i64, writer, self.reserve_a);
        try xdrEncodeGeneric(i64, writer, self.reserve_b);
        try xdrEncodeGeneric(i64, writer, self.total_pool_shares);
        try xdrEncodeGeneric(i64, writer, self.pool_shares_trust_line_count);
    }
};

/// LiquidityPoolEntryBody is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (LiquidityPoolType type)
///     {
///     case LIQUIDITY_POOL_CONSTANT_PRODUCT:
///         struct
///         {
///             LiquidityPoolConstantProductParameters params;
///
///             int64 reserveA;        // amount of A in the pool
///             int64 reserveB;        // amount of B in the pool
///             int64 totalPoolShares; // total number of pool shares issued
///             int64 poolSharesTrustLineCount; // number of trust lines for the
///                                             // associated pool shares
///         } constantProduct;
///     }
/// ```
///
pub const LiquidityPoolEntryBody = union(enum) {
    LiquidityPoolConstantProduct: LiquidityPoolEntryConstantProduct,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LiquidityPoolEntryBody {
        const disc = try LiquidityPoolType.xdrDecode(allocator, reader);
        return switch (disc) {
            .LiquidityPoolConstantProduct => LiquidityPoolEntryBody{ .LiquidityPoolConstantProduct = try xdrDecodeGeneric(LiquidityPoolEntryConstantProduct, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: LiquidityPoolEntryBody, writer: anytype) !void {
        const disc: LiquidityPoolType = switch (self) {
            .LiquidityPoolConstantProduct => .LiquidityPoolConstantProduct,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .LiquidityPoolConstantProduct => |v| try xdrEncodeGeneric(LiquidityPoolEntryConstantProduct, writer, v),
        }
    }
};

/// LiquidityPoolEntry is an XDR Struct defined as:
///
/// ```text
/// struct LiquidityPoolEntry
/// {
///     PoolID liquidityPoolID;
///
///     union switch (LiquidityPoolType type)
///     {
///     case LIQUIDITY_POOL_CONSTANT_PRODUCT:
///         struct
///         {
///             LiquidityPoolConstantProductParameters params;
///
///             int64 reserveA;        // amount of A in the pool
///             int64 reserveB;        // amount of B in the pool
///             int64 totalPoolShares; // total number of pool shares issued
///             int64 poolSharesTrustLineCount; // number of trust lines for the
///                                             // associated pool shares
///         } constantProduct;
///     }
///     body;
/// };
/// ```
///
pub const LiquidityPoolEntry = struct {
    liquidity_pool_id: PoolId,
    body: LiquidityPoolEntryBody,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LiquidityPoolEntry {
        return LiquidityPoolEntry{
            .liquidity_pool_id = try xdrDecodeGeneric(PoolId, allocator, reader),
            .body = try xdrDecodeGeneric(LiquidityPoolEntryBody, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LiquidityPoolEntry, writer: anytype) !void {
        try xdrEncodeGeneric(PoolId, writer, self.liquidity_pool_id);
        try xdrEncodeGeneric(LiquidityPoolEntryBody, writer, self.body);
    }
};

/// ContractDataDurability is an XDR Enum defined as:
///
/// ```text
/// enum ContractDataDurability {
///     TEMPORARY = 0,
///     PERSISTENT = 1
/// };
/// ```
///
pub const ContractDataDurability = enum(i32) {
    Temporary = 0,
    Persistent = 1,
    _,

    pub const variants = [_]ContractDataDurability{
        .Temporary,
        .Persistent,
    };

    pub fn name(self: ContractDataDurability) []const u8 {
        return switch (self) {
            .Temporary => "Temporary",
            .Persistent => "Persistent",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ContractDataDurability {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ContractDataDurability, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ContractDataEntry is an XDR Struct defined as:
///
/// ```text
/// struct ContractDataEntry {
///     ExtensionPoint ext;
///
///     SCAddress contract;
///     SCVal key;
///     ContractDataDurability durability;
///     SCVal val;
/// };
/// ```
///
pub const ContractDataEntry = struct {
    ext: ExtensionPoint,
    contract: ScAddress,
    key: ScVal,
    durability: ContractDataDurability,
    val: ScVal,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ContractDataEntry {
        return ContractDataEntry{
            .ext = try xdrDecodeGeneric(ExtensionPoint, allocator, reader),
            .contract = try xdrDecodeGeneric(ScAddress, allocator, reader),
            .key = try xdrDecodeGeneric(ScVal, allocator, reader),
            .durability = try xdrDecodeGeneric(ContractDataDurability, allocator, reader),
            .val = try xdrDecodeGeneric(ScVal, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ContractDataEntry, writer: anytype) !void {
        try xdrEncodeGeneric(ExtensionPoint, writer, self.ext);
        try xdrEncodeGeneric(ScAddress, writer, self.contract);
        try xdrEncodeGeneric(ScVal, writer, self.key);
        try xdrEncodeGeneric(ContractDataDurability, writer, self.durability);
        try xdrEncodeGeneric(ScVal, writer, self.val);
    }
};

/// ContractCodeCostInputs is an XDR Struct defined as:
///
/// ```text
/// struct ContractCodeCostInputs {
///     ExtensionPoint ext;
///     uint32 nInstructions;
///     uint32 nFunctions;
///     uint32 nGlobals;
///     uint32 nTableEntries;
///     uint32 nTypes;
///     uint32 nDataSegments;
///     uint32 nElemSegments;
///     uint32 nImports;
///     uint32 nExports;
///     uint32 nDataSegmentBytes;
/// };
/// ```
///
pub const ContractCodeCostInputs = struct {
    ext: ExtensionPoint,
    n_instructions: u32,
    n_functions: u32,
    n_globals: u32,
    n_table_entries: u32,
    n_types: u32,
    n_data_segments: u32,
    n_elem_segments: u32,
    n_imports: u32,
    n_exports: u32,
    n_data_segment_bytes: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ContractCodeCostInputs {
        return ContractCodeCostInputs{
            .ext = try xdrDecodeGeneric(ExtensionPoint, allocator, reader),
            .n_instructions = try xdrDecodeGeneric(u32, allocator, reader),
            .n_functions = try xdrDecodeGeneric(u32, allocator, reader),
            .n_globals = try xdrDecodeGeneric(u32, allocator, reader),
            .n_table_entries = try xdrDecodeGeneric(u32, allocator, reader),
            .n_types = try xdrDecodeGeneric(u32, allocator, reader),
            .n_data_segments = try xdrDecodeGeneric(u32, allocator, reader),
            .n_elem_segments = try xdrDecodeGeneric(u32, allocator, reader),
            .n_imports = try xdrDecodeGeneric(u32, allocator, reader),
            .n_exports = try xdrDecodeGeneric(u32, allocator, reader),
            .n_data_segment_bytes = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ContractCodeCostInputs, writer: anytype) !void {
        try xdrEncodeGeneric(ExtensionPoint, writer, self.ext);
        try xdrEncodeGeneric(u32, writer, self.n_instructions);
        try xdrEncodeGeneric(u32, writer, self.n_functions);
        try xdrEncodeGeneric(u32, writer, self.n_globals);
        try xdrEncodeGeneric(u32, writer, self.n_table_entries);
        try xdrEncodeGeneric(u32, writer, self.n_types);
        try xdrEncodeGeneric(u32, writer, self.n_data_segments);
        try xdrEncodeGeneric(u32, writer, self.n_elem_segments);
        try xdrEncodeGeneric(u32, writer, self.n_imports);
        try xdrEncodeGeneric(u32, writer, self.n_exports);
        try xdrEncodeGeneric(u32, writer, self.n_data_segment_bytes);
    }
};

/// ContractCodeEntryV1 is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///             {
///                 ExtensionPoint ext;
///                 ContractCodeCostInputs costInputs;
///             }
/// ```
///
pub const ContractCodeEntryV1 = struct {
    ext: ExtensionPoint,
    cost_inputs: ContractCodeCostInputs,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ContractCodeEntryV1 {
        return ContractCodeEntryV1{
            .ext = try xdrDecodeGeneric(ExtensionPoint, allocator, reader),
            .cost_inputs = try xdrDecodeGeneric(ContractCodeCostInputs, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ContractCodeEntryV1, writer: anytype) !void {
        try xdrEncodeGeneric(ExtensionPoint, writer, self.ext);
        try xdrEncodeGeneric(ContractCodeCostInputs, writer, self.cost_inputs);
    }
};

/// ContractCodeEntryExt is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (int v)
///     {
///         case 0:
///             void;
///         case 1:
///             struct
///             {
///                 ExtensionPoint ext;
///                 ContractCodeCostInputs costInputs;
///             } v1;
///     }
/// ```
///
pub const ContractCodeEntryExt = union(enum) {
    V0,
    V1: ContractCodeEntryV1,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ContractCodeEntryExt {
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => ContractCodeEntryExt{ .V0 = {} },
            1 => ContractCodeEntryExt{ .V1 = try xdrDecodeGeneric(ContractCodeEntryV1, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ContractCodeEntryExt, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
            .V1 => |v| {
                try writer.writeInt(i32, 1, .big);
                try xdrEncodeGeneric(ContractCodeEntryV1, writer, v);
            },
        }
    }
};

/// ContractCodeEntry is an XDR Struct defined as:
///
/// ```text
/// struct ContractCodeEntry {
///     union switch (int v)
///     {
///         case 0:
///             void;
///         case 1:
///             struct
///             {
///                 ExtensionPoint ext;
///                 ContractCodeCostInputs costInputs;
///             } v1;
///     } ext;
///
///     Hash hash;
///     opaque code<>;
/// };
/// ```
///
pub const ContractCodeEntry = struct {
    ext: ContractCodeEntryExt,
    hash: Hash,
    code: []u8,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ContractCodeEntry {
        return ContractCodeEntry{
            .ext = try xdrDecodeGeneric(ContractCodeEntryExt, allocator, reader),
            .hash = try xdrDecodeGeneric(Hash, allocator, reader),
            .code = try xdrDecodeGeneric([]u8, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ContractCodeEntry, writer: anytype) !void {
        try xdrEncodeGeneric(ContractCodeEntryExt, writer, self.ext);
        try xdrEncodeGeneric(Hash, writer, self.hash);
        try xdrEncodeGeneric([]u8, writer, self.code);
    }
};

/// TtlEntry is an XDR Struct defined as:
///
/// ```text
/// struct TTLEntry {
///     // Hash of the LedgerKey that is associated with this TTLEntry
///     Hash keyHash;
///     uint32 liveUntilLedgerSeq;
/// };
/// ```
///
pub const TtlEntry = struct {
    key_hash: Hash,
    live_until_ledger_seq: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TtlEntry {
        return TtlEntry{
            .key_hash = try xdrDecodeGeneric(Hash, allocator, reader),
            .live_until_ledger_seq = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TtlEntry, writer: anytype) !void {
        try xdrEncodeGeneric(Hash, writer, self.key_hash);
        try xdrEncodeGeneric(u32, writer, self.live_until_ledger_seq);
    }
};

/// LedgerEntryExtensionV1Ext is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (int v)
///     {
///     case 0:
///         void;
///     }
/// ```
///
pub const LedgerEntryExtensionV1Ext = union(enum) {
    V0,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerEntryExtensionV1Ext {
        _ = allocator;
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => LedgerEntryExtensionV1Ext{ .V0 = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: LedgerEntryExtensionV1Ext, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
        }
    }
};

/// LedgerEntryExtensionV1 is an XDR Struct defined as:
///
/// ```text
/// struct LedgerEntryExtensionV1
/// {
///     SponsorshipDescriptor sponsoringID;
///
///     union switch (int v)
///     {
///     case 0:
///         void;
///     }
///     ext;
/// };
/// ```
///
pub const LedgerEntryExtensionV1 = struct {
    sponsoring_id: SponsorshipDescriptor,
    ext: LedgerEntryExtensionV1Ext,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerEntryExtensionV1 {
        return LedgerEntryExtensionV1{
            .sponsoring_id = try xdrDecodeGeneric(SponsorshipDescriptor, allocator, reader),
            .ext = try xdrDecodeGeneric(LedgerEntryExtensionV1Ext, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LedgerEntryExtensionV1, writer: anytype) !void {
        try xdrEncodeGeneric(SponsorshipDescriptor, writer, self.sponsoring_id);
        try xdrEncodeGeneric(LedgerEntryExtensionV1Ext, writer, self.ext);
    }
};

/// LedgerEntryData is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (LedgerEntryType type)
///     {
///     case ACCOUNT:
///         AccountEntry account;
///     case TRUSTLINE:
///         TrustLineEntry trustLine;
///     case OFFER:
///         OfferEntry offer;
///     case DATA:
///         DataEntry data;
///     case CLAIMABLE_BALANCE:
///         ClaimableBalanceEntry claimableBalance;
///     case LIQUIDITY_POOL:
///         LiquidityPoolEntry liquidityPool;
///     case CONTRACT_DATA:
///         ContractDataEntry contractData;
///     case CONTRACT_CODE:
///         ContractCodeEntry contractCode;
///     case CONFIG_SETTING:
///         ConfigSettingEntry configSetting;
///     case TTL:
///         TTLEntry ttl;
///     }
/// ```
///
pub const LedgerEntryData = union(enum) {
    Account: AccountEntry,
    Trustline: TrustLineEntry,
    Offer: OfferEntry,
    Data: DataEntry,
    ClaimableBalance: ClaimableBalanceEntry,
    LiquidityPool: LiquidityPoolEntry,
    ContractData: ContractDataEntry,
    ContractCode: ContractCodeEntry,
    ConfigSetting: ConfigSettingEntry,
    Ttl: TtlEntry,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerEntryData {
        const disc = try LedgerEntryType.xdrDecode(allocator, reader);
        return switch (disc) {
            .Account => LedgerEntryData{ .Account = try xdrDecodeGeneric(AccountEntry, allocator, reader) },
            .Trustline => LedgerEntryData{ .Trustline = try xdrDecodeGeneric(TrustLineEntry, allocator, reader) },
            .Offer => LedgerEntryData{ .Offer = try xdrDecodeGeneric(OfferEntry, allocator, reader) },
            .Data => LedgerEntryData{ .Data = try xdrDecodeGeneric(DataEntry, allocator, reader) },
            .ClaimableBalance => LedgerEntryData{ .ClaimableBalance = try xdrDecodeGeneric(ClaimableBalanceEntry, allocator, reader) },
            .LiquidityPool => LedgerEntryData{ .LiquidityPool = try xdrDecodeGeneric(LiquidityPoolEntry, allocator, reader) },
            .ContractData => LedgerEntryData{ .ContractData = try xdrDecodeGeneric(ContractDataEntry, allocator, reader) },
            .ContractCode => LedgerEntryData{ .ContractCode = try xdrDecodeGeneric(ContractCodeEntry, allocator, reader) },
            .ConfigSetting => LedgerEntryData{ .ConfigSetting = try xdrDecodeGeneric(ConfigSettingEntry, allocator, reader) },
            .Ttl => LedgerEntryData{ .Ttl = try xdrDecodeGeneric(TtlEntry, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: LedgerEntryData, writer: anytype) !void {
        const disc: LedgerEntryType = switch (self) {
            .Account => .Account,
            .Trustline => .Trustline,
            .Offer => .Offer,
            .Data => .Data,
            .ClaimableBalance => .ClaimableBalance,
            .LiquidityPool => .LiquidityPool,
            .ContractData => .ContractData,
            .ContractCode => .ContractCode,
            .ConfigSetting => .ConfigSetting,
            .Ttl => .Ttl,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Account => |v| try xdrEncodeGeneric(AccountEntry, writer, v),
            .Trustline => |v| try xdrEncodeGeneric(TrustLineEntry, writer, v),
            .Offer => |v| try xdrEncodeGeneric(OfferEntry, writer, v),
            .Data => |v| try xdrEncodeGeneric(DataEntry, writer, v),
            .ClaimableBalance => |v| try xdrEncodeGeneric(ClaimableBalanceEntry, writer, v),
            .LiquidityPool => |v| try xdrEncodeGeneric(LiquidityPoolEntry, writer, v),
            .ContractData => |v| try xdrEncodeGeneric(ContractDataEntry, writer, v),
            .ContractCode => |v| try xdrEncodeGeneric(ContractCodeEntry, writer, v),
            .ConfigSetting => |v| try xdrEncodeGeneric(ConfigSettingEntry, writer, v),
            .Ttl => |v| try xdrEncodeGeneric(TtlEntry, writer, v),
        }
    }
};

/// LedgerEntryExt is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (int v)
///     {
///     case 0:
///         void;
///     case 1:
///         LedgerEntryExtensionV1 v1;
///     }
/// ```
///
pub const LedgerEntryExt = union(enum) {
    V0,
    V1: LedgerEntryExtensionV1,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerEntryExt {
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => LedgerEntryExt{ .V0 = {} },
            1 => LedgerEntryExt{ .V1 = try xdrDecodeGeneric(LedgerEntryExtensionV1, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: LedgerEntryExt, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
            .V1 => |v| {
                try writer.writeInt(i32, 1, .big);
                try xdrEncodeGeneric(LedgerEntryExtensionV1, writer, v);
            },
        }
    }
};

/// LedgerEntry is an XDR Struct defined as:
///
/// ```text
/// struct LedgerEntry
/// {
///     uint32 lastModifiedLedgerSeq; // ledger the LedgerEntry was last changed
///
///     union switch (LedgerEntryType type)
///     {
///     case ACCOUNT:
///         AccountEntry account;
///     case TRUSTLINE:
///         TrustLineEntry trustLine;
///     case OFFER:
///         OfferEntry offer;
///     case DATA:
///         DataEntry data;
///     case CLAIMABLE_BALANCE:
///         ClaimableBalanceEntry claimableBalance;
///     case LIQUIDITY_POOL:
///         LiquidityPoolEntry liquidityPool;
///     case CONTRACT_DATA:
///         ContractDataEntry contractData;
///     case CONTRACT_CODE:
///         ContractCodeEntry contractCode;
///     case CONFIG_SETTING:
///         ConfigSettingEntry configSetting;
///     case TTL:
///         TTLEntry ttl;
///     }
///     data;
///
///     // reserved for future use
///     union switch (int v)
///     {
///     case 0:
///         void;
///     case 1:
///         LedgerEntryExtensionV1 v1;
///     }
///     ext;
/// };
/// ```
///
pub const LedgerEntry = struct {
    last_modified_ledger_seq: u32,
    data: LedgerEntryData,
    ext: LedgerEntryExt,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerEntry {
        return LedgerEntry{
            .last_modified_ledger_seq = try xdrDecodeGeneric(u32, allocator, reader),
            .data = try xdrDecodeGeneric(LedgerEntryData, allocator, reader),
            .ext = try xdrDecodeGeneric(LedgerEntryExt, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LedgerEntry, writer: anytype) !void {
        try xdrEncodeGeneric(u32, writer, self.last_modified_ledger_seq);
        try xdrEncodeGeneric(LedgerEntryData, writer, self.data);
        try xdrEncodeGeneric(LedgerEntryExt, writer, self.ext);
    }
};

/// LedgerKeyAccount is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///     {
///         AccountID accountID;
///     }
/// ```
///
pub const LedgerKeyAccount = struct {
    account_id: AccountId,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerKeyAccount {
        return LedgerKeyAccount{
            .account_id = try xdrDecodeGeneric(AccountId, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LedgerKeyAccount, writer: anytype) !void {
        try xdrEncodeGeneric(AccountId, writer, self.account_id);
    }
};

/// LedgerKeyTrustLine is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///     {
///         AccountID accountID;
///         TrustLineAsset asset;
///     }
/// ```
///
pub const LedgerKeyTrustLine = struct {
    account_id: AccountId,
    asset: TrustLineAsset,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerKeyTrustLine {
        return LedgerKeyTrustLine{
            .account_id = try xdrDecodeGeneric(AccountId, allocator, reader),
            .asset = try xdrDecodeGeneric(TrustLineAsset, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LedgerKeyTrustLine, writer: anytype) !void {
        try xdrEncodeGeneric(AccountId, writer, self.account_id);
        try xdrEncodeGeneric(TrustLineAsset, writer, self.asset);
    }
};

/// LedgerKeyOffer is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///     {
///         AccountID sellerID;
///         int64 offerID;
///     }
/// ```
///
pub const LedgerKeyOffer = struct {
    seller_id: AccountId,
    offer_id: i64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerKeyOffer {
        return LedgerKeyOffer{
            .seller_id = try xdrDecodeGeneric(AccountId, allocator, reader),
            .offer_id = try xdrDecodeGeneric(i64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LedgerKeyOffer, writer: anytype) !void {
        try xdrEncodeGeneric(AccountId, writer, self.seller_id);
        try xdrEncodeGeneric(i64, writer, self.offer_id);
    }
};

/// LedgerKeyData is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///     {
///         AccountID accountID;
///         string64 dataName;
///     }
/// ```
///
pub const LedgerKeyData = struct {
    account_id: AccountId,
    data_name: String64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerKeyData {
        return LedgerKeyData{
            .account_id = try xdrDecodeGeneric(AccountId, allocator, reader),
            .data_name = try xdrDecodeGeneric(String64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LedgerKeyData, writer: anytype) !void {
        try xdrEncodeGeneric(AccountId, writer, self.account_id);
        try xdrEncodeGeneric(String64, writer, self.data_name);
    }
};

/// LedgerKeyClaimableBalance is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///     {
///         ClaimableBalanceID balanceID;
///     }
/// ```
///
pub const LedgerKeyClaimableBalance = struct {
    balance_id: ClaimableBalanceId,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerKeyClaimableBalance {
        return LedgerKeyClaimableBalance{
            .balance_id = try xdrDecodeGeneric(ClaimableBalanceId, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LedgerKeyClaimableBalance, writer: anytype) !void {
        try xdrEncodeGeneric(ClaimableBalanceId, writer, self.balance_id);
    }
};

/// LedgerKeyLiquidityPool is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///     {
///         PoolID liquidityPoolID;
///     }
/// ```
///
pub const LedgerKeyLiquidityPool = struct {
    liquidity_pool_id: PoolId,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerKeyLiquidityPool {
        return LedgerKeyLiquidityPool{
            .liquidity_pool_id = try xdrDecodeGeneric(PoolId, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LedgerKeyLiquidityPool, writer: anytype) !void {
        try xdrEncodeGeneric(PoolId, writer, self.liquidity_pool_id);
    }
};

/// LedgerKeyContractData is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///     {
///         SCAddress contract;
///         SCVal key;
///         ContractDataDurability durability;
///     }
/// ```
///
pub const LedgerKeyContractData = struct {
    contract: ScAddress,
    key: ScVal,
    durability: ContractDataDurability,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerKeyContractData {
        return LedgerKeyContractData{
            .contract = try xdrDecodeGeneric(ScAddress, allocator, reader),
            .key = try xdrDecodeGeneric(ScVal, allocator, reader),
            .durability = try xdrDecodeGeneric(ContractDataDurability, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LedgerKeyContractData, writer: anytype) !void {
        try xdrEncodeGeneric(ScAddress, writer, self.contract);
        try xdrEncodeGeneric(ScVal, writer, self.key);
        try xdrEncodeGeneric(ContractDataDurability, writer, self.durability);
    }
};

/// LedgerKeyContractCode is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///     {
///         Hash hash;
///     }
/// ```
///
pub const LedgerKeyContractCode = struct {
    hash: Hash,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerKeyContractCode {
        return LedgerKeyContractCode{
            .hash = try xdrDecodeGeneric(Hash, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LedgerKeyContractCode, writer: anytype) !void {
        try xdrEncodeGeneric(Hash, writer, self.hash);
    }
};

/// LedgerKeyConfigSetting is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///     {
///         ConfigSettingID configSettingID;
///     }
/// ```
///
pub const LedgerKeyConfigSetting = struct {
    config_setting_id: ConfigSettingId,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerKeyConfigSetting {
        return LedgerKeyConfigSetting{
            .config_setting_id = try xdrDecodeGeneric(ConfigSettingId, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LedgerKeyConfigSetting, writer: anytype) !void {
        try xdrEncodeGeneric(ConfigSettingId, writer, self.config_setting_id);
    }
};

/// LedgerKeyTtl is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///     {
///         // Hash of the LedgerKey that is associated with this TTLEntry
///         Hash keyHash;
///     }
/// ```
///
pub const LedgerKeyTtl = struct {
    key_hash: Hash,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerKeyTtl {
        return LedgerKeyTtl{
            .key_hash = try xdrDecodeGeneric(Hash, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LedgerKeyTtl, writer: anytype) !void {
        try xdrEncodeGeneric(Hash, writer, self.key_hash);
    }
};

/// LedgerKey is an XDR Union defined as:
///
/// ```text
/// union LedgerKey switch (LedgerEntryType type)
/// {
/// case ACCOUNT:
///     struct
///     {
///         AccountID accountID;
///     } account;
///
/// case TRUSTLINE:
///     struct
///     {
///         AccountID accountID;
///         TrustLineAsset asset;
///     } trustLine;
///
/// case OFFER:
///     struct
///     {
///         AccountID sellerID;
///         int64 offerID;
///     } offer;
///
/// case DATA:
///     struct
///     {
///         AccountID accountID;
///         string64 dataName;
///     } data;
///
/// case CLAIMABLE_BALANCE:
///     struct
///     {
///         ClaimableBalanceID balanceID;
///     } claimableBalance;
///
/// case LIQUIDITY_POOL:
///     struct
///     {
///         PoolID liquidityPoolID;
///     } liquidityPool;
/// case CONTRACT_DATA:
///     struct
///     {
///         SCAddress contract;
///         SCVal key;
///         ContractDataDurability durability;
///     } contractData;
/// case CONTRACT_CODE:
///     struct
///     {
///         Hash hash;
///     } contractCode;
/// case CONFIG_SETTING:
///     struct
///     {
///         ConfigSettingID configSettingID;
///     } configSetting;
/// case TTL:
///     struct
///     {
///         // Hash of the LedgerKey that is associated with this TTLEntry
///         Hash keyHash;
///     } ttl;
/// };
/// ```
///
pub const LedgerKey = union(enum) {
    Account: LedgerKeyAccount,
    Trustline: LedgerKeyTrustLine,
    Offer: LedgerKeyOffer,
    Data: LedgerKeyData,
    ClaimableBalance: LedgerKeyClaimableBalance,
    LiquidityPool: LedgerKeyLiquidityPool,
    ContractData: LedgerKeyContractData,
    ContractCode: LedgerKeyContractCode,
    ConfigSetting: LedgerKeyConfigSetting,
    Ttl: LedgerKeyTtl,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerKey {
        const disc = try LedgerEntryType.xdrDecode(allocator, reader);
        return switch (disc) {
            .Account => LedgerKey{ .Account = try xdrDecodeGeneric(LedgerKeyAccount, allocator, reader) },
            .Trustline => LedgerKey{ .Trustline = try xdrDecodeGeneric(LedgerKeyTrustLine, allocator, reader) },
            .Offer => LedgerKey{ .Offer = try xdrDecodeGeneric(LedgerKeyOffer, allocator, reader) },
            .Data => LedgerKey{ .Data = try xdrDecodeGeneric(LedgerKeyData, allocator, reader) },
            .ClaimableBalance => LedgerKey{ .ClaimableBalance = try xdrDecodeGeneric(LedgerKeyClaimableBalance, allocator, reader) },
            .LiquidityPool => LedgerKey{ .LiquidityPool = try xdrDecodeGeneric(LedgerKeyLiquidityPool, allocator, reader) },
            .ContractData => LedgerKey{ .ContractData = try xdrDecodeGeneric(LedgerKeyContractData, allocator, reader) },
            .ContractCode => LedgerKey{ .ContractCode = try xdrDecodeGeneric(LedgerKeyContractCode, allocator, reader) },
            .ConfigSetting => LedgerKey{ .ConfigSetting = try xdrDecodeGeneric(LedgerKeyConfigSetting, allocator, reader) },
            .Ttl => LedgerKey{ .Ttl = try xdrDecodeGeneric(LedgerKeyTtl, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: LedgerKey, writer: anytype) !void {
        const disc: LedgerEntryType = switch (self) {
            .Account => .Account,
            .Trustline => .Trustline,
            .Offer => .Offer,
            .Data => .Data,
            .ClaimableBalance => .ClaimableBalance,
            .LiquidityPool => .LiquidityPool,
            .ContractData => .ContractData,
            .ContractCode => .ContractCode,
            .ConfigSetting => .ConfigSetting,
            .Ttl => .Ttl,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Account => |v| try xdrEncodeGeneric(LedgerKeyAccount, writer, v),
            .Trustline => |v| try xdrEncodeGeneric(LedgerKeyTrustLine, writer, v),
            .Offer => |v| try xdrEncodeGeneric(LedgerKeyOffer, writer, v),
            .Data => |v| try xdrEncodeGeneric(LedgerKeyData, writer, v),
            .ClaimableBalance => |v| try xdrEncodeGeneric(LedgerKeyClaimableBalance, writer, v),
            .LiquidityPool => |v| try xdrEncodeGeneric(LedgerKeyLiquidityPool, writer, v),
            .ContractData => |v| try xdrEncodeGeneric(LedgerKeyContractData, writer, v),
            .ContractCode => |v| try xdrEncodeGeneric(LedgerKeyContractCode, writer, v),
            .ConfigSetting => |v| try xdrEncodeGeneric(LedgerKeyConfigSetting, writer, v),
            .Ttl => |v| try xdrEncodeGeneric(LedgerKeyTtl, writer, v),
        }
    }
};

/// EnvelopeType is an XDR Enum defined as:
///
/// ```text
/// enum EnvelopeType
/// {
///     ENVELOPE_TYPE_TX_V0 = 0,
///     ENVELOPE_TYPE_SCP = 1,
///     ENVELOPE_TYPE_TX = 2,
///     ENVELOPE_TYPE_AUTH = 3,
///     ENVELOPE_TYPE_SCPVALUE = 4,
///     ENVELOPE_TYPE_TX_FEE_BUMP = 5,
///     ENVELOPE_TYPE_OP_ID = 6,
///     ENVELOPE_TYPE_POOL_REVOKE_OP_ID = 7,
///     ENVELOPE_TYPE_CONTRACT_ID = 8,
///     ENVELOPE_TYPE_SOROBAN_AUTHORIZATION = 9
/// };
/// ```
///
pub const EnvelopeType = enum(i32) {
    TxV0 = 0,
    Scp = 1,
    Tx = 2,
    Auth = 3,
    Scpvalue = 4,
    TxFeeBump = 5,
    OpId = 6,
    PoolRevokeOpId = 7,
    ContractId = 8,
    SorobanAuthorization = 9,
    _,

    pub const variants = [_]EnvelopeType{
        .TxV0,
        .Scp,
        .Tx,
        .Auth,
        .Scpvalue,
        .TxFeeBump,
        .OpId,
        .PoolRevokeOpId,
        .ContractId,
        .SorobanAuthorization,
    };

    pub fn name(self: EnvelopeType) []const u8 {
        return switch (self) {
            .TxV0 => "TxV0",
            .Scp => "Scp",
            .Tx => "Tx",
            .Auth => "Auth",
            .Scpvalue => "Scpvalue",
            .TxFeeBump => "TxFeeBump",
            .OpId => "OpId",
            .PoolRevokeOpId => "PoolRevokeOpId",
            .ContractId => "ContractId",
            .SorobanAuthorization => "SorobanAuthorization",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !EnvelopeType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: EnvelopeType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// BucketListType is an XDR Enum defined as:
///
/// ```text
/// enum BucketListType
/// {
///     LIVE = 0,
///     HOT_ARCHIVE = 1
/// };
/// ```
///
pub const BucketListType = enum(i32) {
    Live = 0,
    HotArchive = 1,
    _,

    pub const variants = [_]BucketListType{
        .Live,
        .HotArchive,
    };

    pub fn name(self: BucketListType) []const u8 {
        return switch (self) {
            .Live => "Live",
            .HotArchive => "HotArchive",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !BucketListType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: BucketListType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// BucketEntryType is an XDR Enum defined as:
///
/// ```text
/// enum BucketEntryType
/// {
///     METAENTRY =
///         -1, // At-and-after protocol 11: bucket metadata, should come first.
///     LIVEENTRY = 0, // Before protocol 11: created-or-updated;
///                    // At-and-after protocol 11: only updated.
///     DEADENTRY = 1,
///     INITENTRY = 2 // At-and-after protocol 11: only created.
/// };
/// ```
///
pub const BucketEntryType = enum(i32) {
    Metaentry = -1,
    Liveentry = 0,
    Deadentry = 1,
    Initentry = 2,
    _,

    pub const variants = [_]BucketEntryType{
        .Metaentry,
        .Liveentry,
        .Deadentry,
        .Initentry,
    };

    pub fn name(self: BucketEntryType) []const u8 {
        return switch (self) {
            .Metaentry => "Metaentry",
            .Liveentry => "Liveentry",
            .Deadentry => "Deadentry",
            .Initentry => "Initentry",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !BucketEntryType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: BucketEntryType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// HotArchiveBucketEntryType is an XDR Enum defined as:
///
/// ```text
/// enum HotArchiveBucketEntryType
/// {
///     HOT_ARCHIVE_METAENTRY = -1, // Bucket metadata, should come first.
///     HOT_ARCHIVE_ARCHIVED = 0,   // Entry is Archived
///     HOT_ARCHIVE_LIVE = 1        // Entry was previously HOT_ARCHIVE_ARCHIVED, but
///                                 // has been added back to the live BucketList.
///                                 // Does not need to be persisted.
/// };
/// ```
///
pub const HotArchiveBucketEntryType = enum(i32) {
    Metaentry = -1,
    Archived = 0,
    Live = 1,
    _,

    pub const variants = [_]HotArchiveBucketEntryType{
        .Metaentry,
        .Archived,
        .Live,
    };

    pub fn name(self: HotArchiveBucketEntryType) []const u8 {
        return switch (self) {
            .Metaentry => "Metaentry",
            .Archived => "Archived",
            .Live => "Live",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !HotArchiveBucketEntryType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: HotArchiveBucketEntryType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// BucketMetadataExt is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (int v)
///     {
///     case 0:
///         void;
///     case 1:
///         BucketListType bucketListType;
///     }
/// ```
///
pub const BucketMetadataExt = union(enum) {
    V0,
    V1: BucketListType,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !BucketMetadataExt {
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => BucketMetadataExt{ .V0 = {} },
            1 => BucketMetadataExt{ .V1 = try xdrDecodeGeneric(BucketListType, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: BucketMetadataExt, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
            .V1 => |v| {
                try writer.writeInt(i32, 1, .big);
                try xdrEncodeGeneric(BucketListType, writer, v);
            },
        }
    }
};

/// BucketMetadata is an XDR Struct defined as:
///
/// ```text
/// struct BucketMetadata
/// {
///     // Indicates the protocol version used to create / merge this bucket.
///     uint32 ledgerVersion;
///
///     // reserved for future use
///     union switch (int v)
///     {
///     case 0:
///         void;
///     case 1:
///         BucketListType bucketListType;
///     }
///     ext;
/// };
/// ```
///
pub const BucketMetadata = struct {
    ledger_version: u32,
    ext: BucketMetadataExt,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !BucketMetadata {
        return BucketMetadata{
            .ledger_version = try xdrDecodeGeneric(u32, allocator, reader),
            .ext = try xdrDecodeGeneric(BucketMetadataExt, allocator, reader),
        };
    }

    pub fn xdrEncode(self: BucketMetadata, writer: anytype) !void {
        try xdrEncodeGeneric(u32, writer, self.ledger_version);
        try xdrEncodeGeneric(BucketMetadataExt, writer, self.ext);
    }
};

/// BucketEntry is an XDR Union defined as:
///
/// ```text
/// union BucketEntry switch (BucketEntryType type)
/// {
/// case LIVEENTRY:
/// case INITENTRY:
///     LedgerEntry liveEntry;
///
/// case DEADENTRY:
///     LedgerKey deadEntry;
/// case METAENTRY:
///     BucketMetadata metaEntry;
/// };
/// ```
///
pub const BucketEntry = union(enum) {
    Liveentry: LedgerEntry,
    Initentry: LedgerEntry,
    Deadentry: LedgerKey,
    Metaentry: BucketMetadata,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !BucketEntry {
        const disc = try BucketEntryType.xdrDecode(allocator, reader);
        return switch (disc) {
            .Liveentry => BucketEntry{ .Liveentry = try xdrDecodeGeneric(LedgerEntry, allocator, reader) },
            .Initentry => BucketEntry{ .Initentry = try xdrDecodeGeneric(LedgerEntry, allocator, reader) },
            .Deadentry => BucketEntry{ .Deadentry = try xdrDecodeGeneric(LedgerKey, allocator, reader) },
            .Metaentry => BucketEntry{ .Metaentry = try xdrDecodeGeneric(BucketMetadata, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: BucketEntry, writer: anytype) !void {
        const disc: BucketEntryType = switch (self) {
            .Liveentry => .Liveentry,
            .Initentry => .Initentry,
            .Deadentry => .Deadentry,
            .Metaentry => .Metaentry,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Liveentry => |v| try xdrEncodeGeneric(LedgerEntry, writer, v),
            .Initentry => |v| try xdrEncodeGeneric(LedgerEntry, writer, v),
            .Deadentry => |v| try xdrEncodeGeneric(LedgerKey, writer, v),
            .Metaentry => |v| try xdrEncodeGeneric(BucketMetadata, writer, v),
        }
    }
};

/// HotArchiveBucketEntry is an XDR Union defined as:
///
/// ```text
/// union HotArchiveBucketEntry switch (HotArchiveBucketEntryType type)
/// {
/// case HOT_ARCHIVE_ARCHIVED:
///     LedgerEntry archivedEntry;
///
/// case HOT_ARCHIVE_LIVE:
///     LedgerKey key;
/// case HOT_ARCHIVE_METAENTRY:
///     BucketMetadata metaEntry;
/// };
/// ```
///
pub const HotArchiveBucketEntry = union(enum) {
    Archived: LedgerEntry,
    Live: LedgerKey,
    Metaentry: BucketMetadata,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !HotArchiveBucketEntry {
        const disc = try HotArchiveBucketEntryType.xdrDecode(allocator, reader);
        return switch (disc) {
            .Archived => HotArchiveBucketEntry{ .Archived = try xdrDecodeGeneric(LedgerEntry, allocator, reader) },
            .Live => HotArchiveBucketEntry{ .Live = try xdrDecodeGeneric(LedgerKey, allocator, reader) },
            .Metaentry => HotArchiveBucketEntry{ .Metaentry = try xdrDecodeGeneric(BucketMetadata, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: HotArchiveBucketEntry, writer: anytype) !void {
        const disc: HotArchiveBucketEntryType = switch (self) {
            .Archived => .Archived,
            .Live => .Live,
            .Metaentry => .Metaentry,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Archived => |v| try xdrEncodeGeneric(LedgerEntry, writer, v),
            .Live => |v| try xdrEncodeGeneric(LedgerKey, writer, v),
            .Metaentry => |v| try xdrEncodeGeneric(BucketMetadata, writer, v),
        }
    }
};

/// UpgradeType is an XDR Typedef defined as:
///
/// ```text
/// typedef opaque UpgradeType<128>;
/// ```
///
pub const UpgradeType = struct {
    value: BoundedArray(u8, 128),

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !UpgradeType {
        return UpgradeType{
            .value = try xdrDecodeGeneric(BoundedArray(u8, 128), allocator, reader),
        };
    }

    pub fn xdrEncode(self: UpgradeType, writer: anytype) !void {
        try xdrEncodeGeneric(BoundedArray(u8, 128), writer, self.value);
    }

    pub fn asSlice(self: UpgradeType) []const u8 {
        return self.value.data;
    }
};

/// StellarValueType is an XDR Enum defined as:
///
/// ```text
/// enum StellarValueType
/// {
///     STELLAR_VALUE_BASIC = 0,
///     STELLAR_VALUE_SIGNED = 1
/// };
/// ```
///
pub const StellarValueType = enum(i32) {
    Basic = 0,
    Signed = 1,
    _,

    pub const variants = [_]StellarValueType{
        .Basic,
        .Signed,
    };

    pub fn name(self: StellarValueType) []const u8 {
        return switch (self) {
            .Basic => "Basic",
            .Signed => "Signed",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !StellarValueType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: StellarValueType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// LedgerCloseValueSignature is an XDR Struct defined as:
///
/// ```text
/// struct LedgerCloseValueSignature
/// {
///     NodeID nodeID;       // which node introduced the value
///     Signature signature; // nodeID's signature
/// };
/// ```
///
pub const LedgerCloseValueSignature = struct {
    node_id: NodeId,
    signature: Signature,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerCloseValueSignature {
        return LedgerCloseValueSignature{
            .node_id = try xdrDecodeGeneric(NodeId, allocator, reader),
            .signature = try xdrDecodeGeneric(Signature, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LedgerCloseValueSignature, writer: anytype) !void {
        try xdrEncodeGeneric(NodeId, writer, self.node_id);
        try xdrEncodeGeneric(Signature, writer, self.signature);
    }
};

/// StellarValueExt is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (StellarValueType v)
///     {
///     case STELLAR_VALUE_BASIC:
///         void;
///     case STELLAR_VALUE_SIGNED:
///         LedgerCloseValueSignature lcValueSignature;
///     }
/// ```
///
pub const StellarValueExt = union(enum) {
    Basic,
    Signed: LedgerCloseValueSignature,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !StellarValueExt {
        const disc = try StellarValueType.xdrDecode(allocator, reader);
        return switch (disc) {
            .Basic => StellarValueExt{ .Basic = {} },
            .Signed => StellarValueExt{ .Signed = try xdrDecodeGeneric(LedgerCloseValueSignature, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: StellarValueExt, writer: anytype) !void {
        const disc: StellarValueType = switch (self) {
            .Basic => .Basic,
            .Signed => .Signed,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Basic => {},
            .Signed => |v| try xdrEncodeGeneric(LedgerCloseValueSignature, writer, v),
        }
    }
};

/// StellarValue is an XDR Struct defined as:
///
/// ```text
/// struct StellarValue
/// {
///     Hash txSetHash;      // transaction set to apply to previous ledger
///     TimePoint closeTime; // network close time
///
///     // upgrades to apply to the previous ledger (usually empty)
///     // this is a vector of encoded 'LedgerUpgrade' so that nodes can drop
///     // unknown steps during consensus if needed.
///     // see notes below on 'LedgerUpgrade' for more detail
///     // max size is dictated by number of upgrade types (+ room for future)
///     UpgradeType upgrades<6>;
///
///     // reserved for future use
///     union switch (StellarValueType v)
///     {
///     case STELLAR_VALUE_BASIC:
///         void;
///     case STELLAR_VALUE_SIGNED:
///         LedgerCloseValueSignature lcValueSignature;
///     }
///     ext;
/// };
/// ```
///
pub const StellarValue = struct {
    tx_set_hash: Hash,
    close_time: TimePoint,
    upgrades: BoundedArray(UpgradeType, 6),
    ext: StellarValueExt,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !StellarValue {
        return StellarValue{
            .tx_set_hash = try xdrDecodeGeneric(Hash, allocator, reader),
            .close_time = try xdrDecodeGeneric(TimePoint, allocator, reader),
            .upgrades = try xdrDecodeGeneric(BoundedArray(UpgradeType, 6), allocator, reader),
            .ext = try xdrDecodeGeneric(StellarValueExt, allocator, reader),
        };
    }

    pub fn xdrEncode(self: StellarValue, writer: anytype) !void {
        try xdrEncodeGeneric(Hash, writer, self.tx_set_hash);
        try xdrEncodeGeneric(TimePoint, writer, self.close_time);
        try xdrEncodeGeneric(BoundedArray(UpgradeType, 6), writer, self.upgrades);
        try xdrEncodeGeneric(StellarValueExt, writer, self.ext);
    }
};

/// MaskLedgerHeaderFlags is an XDR Const defined as:
///
/// ```text
/// const MASK_LEDGER_HEADER_FLAGS = 0x7;
/// ```
///
pub const MASK_LEDGER_HEADER_FLAGS: u64 = 0x7;

/// LedgerHeaderFlags is an XDR Enum defined as:
///
/// ```text
/// enum LedgerHeaderFlags
/// {
///     DISABLE_LIQUIDITY_POOL_TRADING_FLAG = 0x1,
///     DISABLE_LIQUIDITY_POOL_DEPOSIT_FLAG = 0x2,
///     DISABLE_LIQUIDITY_POOL_WITHDRAWAL_FLAG = 0x4
/// };
/// ```
///
pub const LedgerHeaderFlags = enum(i32) {
    TradingFlag = 1,
    DepositFlag = 2,
    WithdrawalFlag = 4,
    _,

    pub const variants = [_]LedgerHeaderFlags{
        .TradingFlag,
        .DepositFlag,
        .WithdrawalFlag,
    };

    pub fn name(self: LedgerHeaderFlags) []const u8 {
        return switch (self) {
            .TradingFlag => "TradingFlag",
            .DepositFlag => "DepositFlag",
            .WithdrawalFlag => "WithdrawalFlag",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerHeaderFlags {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: LedgerHeaderFlags, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// LedgerHeaderExtensionV1Ext is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (int v)
///     {
///     case 0:
///         void;
///     }
/// ```
///
pub const LedgerHeaderExtensionV1Ext = union(enum) {
    V0,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerHeaderExtensionV1Ext {
        _ = allocator;
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => LedgerHeaderExtensionV1Ext{ .V0 = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: LedgerHeaderExtensionV1Ext, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
        }
    }
};

/// LedgerHeaderExtensionV1 is an XDR Struct defined as:
///
/// ```text
/// struct LedgerHeaderExtensionV1
/// {
///     uint32 flags; // LedgerHeaderFlags
///
///     union switch (int v)
///     {
///     case 0:
///         void;
///     }
///     ext;
/// };
/// ```
///
pub const LedgerHeaderExtensionV1 = struct {
    flags: u32,
    ext: LedgerHeaderExtensionV1Ext,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerHeaderExtensionV1 {
        return LedgerHeaderExtensionV1{
            .flags = try xdrDecodeGeneric(u32, allocator, reader),
            .ext = try xdrDecodeGeneric(LedgerHeaderExtensionV1Ext, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LedgerHeaderExtensionV1, writer: anytype) !void {
        try xdrEncodeGeneric(u32, writer, self.flags);
        try xdrEncodeGeneric(LedgerHeaderExtensionV1Ext, writer, self.ext);
    }
};

/// LedgerHeaderExt is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (int v)
///     {
///     case 0:
///         void;
///     case 1:
///         LedgerHeaderExtensionV1 v1;
///     }
/// ```
///
pub const LedgerHeaderExt = union(enum) {
    V0,
    V1: LedgerHeaderExtensionV1,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerHeaderExt {
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => LedgerHeaderExt{ .V0 = {} },
            1 => LedgerHeaderExt{ .V1 = try xdrDecodeGeneric(LedgerHeaderExtensionV1, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: LedgerHeaderExt, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
            .V1 => |v| {
                try writer.writeInt(i32, 1, .big);
                try xdrEncodeGeneric(LedgerHeaderExtensionV1, writer, v);
            },
        }
    }
};

/// LedgerHeader is an XDR Struct defined as:
///
/// ```text
/// struct LedgerHeader
/// {
///     uint32 ledgerVersion;    // the protocol version of the ledger
///     Hash previousLedgerHash; // hash of the previous ledger header
///     StellarValue scpValue;   // what consensus agreed to
///     Hash txSetResultHash;    // the TransactionResultSet that led to this ledger
///     Hash bucketListHash;     // hash of the ledger state
///
///     uint32 ledgerSeq; // sequence number of this ledger
///
///     int64 totalCoins; // total number of stroops in existence.
///                       // 10,000,000 stroops in 1 XLM
///
///     int64 feePool;       // fees burned since last inflation run
///     uint32 inflationSeq; // inflation sequence number
///
///     uint64 idPool; // last used global ID, used for generating objects
///
///     uint32 baseFee;     // base fee per operation in stroops
///     uint32 baseReserve; // account base reserve in stroops
///
///     uint32 maxTxSetSize; // maximum size a transaction set can be
///
///     Hash skipList[4]; // hashes of ledgers in the past. allows you to jump back
///                       // in time without walking the chain back ledger by ledger
///                       // each slot contains the oldest ledger that is mod of
///                       // either 50  5000  50000 or 500000 depending on index
///                       // skipList[0] mod(50), skipList[1] mod(5000), etc
///
///     // reserved for future use
///     union switch (int v)
///     {
///     case 0:
///         void;
///     case 1:
///         LedgerHeaderExtensionV1 v1;
///     }
///     ext;
/// };
/// ```
///
pub const LedgerHeader = struct {
    ledger_version: u32,
    previous_ledger_hash: Hash,
    scp_value: StellarValue,
    tx_set_result_hash: Hash,
    bucket_list_hash: Hash,
    ledger_seq: u32,
    total_coins: i64,
    fee_pool: i64,
    inflation_seq: u32,
    id_pool: u64,
    base_fee: u32,
    base_reserve: u32,
    max_tx_set_size: u32,
    skip_list: [4]Hash,
    ext: LedgerHeaderExt,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerHeader {
        return LedgerHeader{
            .ledger_version = try xdrDecodeGeneric(u32, allocator, reader),
            .previous_ledger_hash = try xdrDecodeGeneric(Hash, allocator, reader),
            .scp_value = try xdrDecodeGeneric(StellarValue, allocator, reader),
            .tx_set_result_hash = try xdrDecodeGeneric(Hash, allocator, reader),
            .bucket_list_hash = try xdrDecodeGeneric(Hash, allocator, reader),
            .ledger_seq = try xdrDecodeGeneric(u32, allocator, reader),
            .total_coins = try xdrDecodeGeneric(i64, allocator, reader),
            .fee_pool = try xdrDecodeGeneric(i64, allocator, reader),
            .inflation_seq = try xdrDecodeGeneric(u32, allocator, reader),
            .id_pool = try xdrDecodeGeneric(u64, allocator, reader),
            .base_fee = try xdrDecodeGeneric(u32, allocator, reader),
            .base_reserve = try xdrDecodeGeneric(u32, allocator, reader),
            .max_tx_set_size = try xdrDecodeGeneric(u32, allocator, reader),
            .skip_list = try xdrDecodeGeneric([4]Hash, allocator, reader),
            .ext = try xdrDecodeGeneric(LedgerHeaderExt, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LedgerHeader, writer: anytype) !void {
        try xdrEncodeGeneric(u32, writer, self.ledger_version);
        try xdrEncodeGeneric(Hash, writer, self.previous_ledger_hash);
        try xdrEncodeGeneric(StellarValue, writer, self.scp_value);
        try xdrEncodeGeneric(Hash, writer, self.tx_set_result_hash);
        try xdrEncodeGeneric(Hash, writer, self.bucket_list_hash);
        try xdrEncodeGeneric(u32, writer, self.ledger_seq);
        try xdrEncodeGeneric(i64, writer, self.total_coins);
        try xdrEncodeGeneric(i64, writer, self.fee_pool);
        try xdrEncodeGeneric(u32, writer, self.inflation_seq);
        try xdrEncodeGeneric(u64, writer, self.id_pool);
        try xdrEncodeGeneric(u32, writer, self.base_fee);
        try xdrEncodeGeneric(u32, writer, self.base_reserve);
        try xdrEncodeGeneric(u32, writer, self.max_tx_set_size);
        try xdrEncodeGeneric([4]Hash, writer, self.skip_list);
        try xdrEncodeGeneric(LedgerHeaderExt, writer, self.ext);
    }
};

/// LedgerUpgradeType is an XDR Enum defined as:
///
/// ```text
/// enum LedgerUpgradeType
/// {
///     LEDGER_UPGRADE_VERSION = 1,
///     LEDGER_UPGRADE_BASE_FEE = 2,
///     LEDGER_UPGRADE_MAX_TX_SET_SIZE = 3,
///     LEDGER_UPGRADE_BASE_RESERVE = 4,
///     LEDGER_UPGRADE_FLAGS = 5,
///     LEDGER_UPGRADE_CONFIG = 6,
///     LEDGER_UPGRADE_MAX_SOROBAN_TX_SET_SIZE = 7
/// };
/// ```
///
pub const LedgerUpgradeType = enum(i32) {
    Version = 1,
    BaseFee = 2,
    MaxTxSetSize = 3,
    BaseReserve = 4,
    Flags = 5,
    Config = 6,
    MaxSorobanTxSetSize = 7,
    _,

    pub const variants = [_]LedgerUpgradeType{
        .Version,
        .BaseFee,
        .MaxTxSetSize,
        .BaseReserve,
        .Flags,
        .Config,
        .MaxSorobanTxSetSize,
    };

    pub fn name(self: LedgerUpgradeType) []const u8 {
        return switch (self) {
            .Version => "Version",
            .BaseFee => "BaseFee",
            .MaxTxSetSize => "MaxTxSetSize",
            .BaseReserve => "BaseReserve",
            .Flags => "Flags",
            .Config => "Config",
            .MaxSorobanTxSetSize => "MaxSorobanTxSetSize",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerUpgradeType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: LedgerUpgradeType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ConfigUpgradeSetKey is an XDR Struct defined as:
///
/// ```text
/// struct ConfigUpgradeSetKey {
///     ContractID contractID;
///     Hash contentHash;
/// };
/// ```
///
pub const ConfigUpgradeSetKey = struct {
    contract_id: ContractId,
    content_hash: Hash,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ConfigUpgradeSetKey {
        return ConfigUpgradeSetKey{
            .contract_id = try xdrDecodeGeneric(ContractId, allocator, reader),
            .content_hash = try xdrDecodeGeneric(Hash, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ConfigUpgradeSetKey, writer: anytype) !void {
        try xdrEncodeGeneric(ContractId, writer, self.contract_id);
        try xdrEncodeGeneric(Hash, writer, self.content_hash);
    }
};

/// LedgerUpgrade is an XDR Union defined as:
///
/// ```text
/// union LedgerUpgrade switch (LedgerUpgradeType type)
/// {
/// case LEDGER_UPGRADE_VERSION:
///     uint32 newLedgerVersion; // update ledgerVersion
/// case LEDGER_UPGRADE_BASE_FEE:
///     uint32 newBaseFee; // update baseFee
/// case LEDGER_UPGRADE_MAX_TX_SET_SIZE:
///     uint32 newMaxTxSetSize; // update maxTxSetSize
/// case LEDGER_UPGRADE_BASE_RESERVE:
///     uint32 newBaseReserve; // update baseReserve
/// case LEDGER_UPGRADE_FLAGS:
///     uint32 newFlags; // update flags
/// case LEDGER_UPGRADE_CONFIG:
///     // Update arbitrary `ConfigSetting` entries identified by the key.
///     ConfigUpgradeSetKey newConfig;
/// case LEDGER_UPGRADE_MAX_SOROBAN_TX_SET_SIZE:
///     // Update ConfigSettingContractExecutionLanesV0.ledgerMaxTxCount without
///     // using `LEDGER_UPGRADE_CONFIG`.
///     uint32 newMaxSorobanTxSetSize;
/// };
/// ```
///
pub const LedgerUpgrade = union(enum) {
    Version: u32,
    BaseFee: u32,
    MaxTxSetSize: u32,
    BaseReserve: u32,
    Flags: u32,
    Config: ConfigUpgradeSetKey,
    MaxSorobanTxSetSize: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerUpgrade {
        const disc = try LedgerUpgradeType.xdrDecode(allocator, reader);
        return switch (disc) {
            .Version => LedgerUpgrade{ .Version = try xdrDecodeGeneric(u32, allocator, reader) },
            .BaseFee => LedgerUpgrade{ .BaseFee = try xdrDecodeGeneric(u32, allocator, reader) },
            .MaxTxSetSize => LedgerUpgrade{ .MaxTxSetSize = try xdrDecodeGeneric(u32, allocator, reader) },
            .BaseReserve => LedgerUpgrade{ .BaseReserve = try xdrDecodeGeneric(u32, allocator, reader) },
            .Flags => LedgerUpgrade{ .Flags = try xdrDecodeGeneric(u32, allocator, reader) },
            .Config => LedgerUpgrade{ .Config = try xdrDecodeGeneric(ConfigUpgradeSetKey, allocator, reader) },
            .MaxSorobanTxSetSize => LedgerUpgrade{ .MaxSorobanTxSetSize = try xdrDecodeGeneric(u32, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: LedgerUpgrade, writer: anytype) !void {
        const disc: LedgerUpgradeType = switch (self) {
            .Version => .Version,
            .BaseFee => .BaseFee,
            .MaxTxSetSize => .MaxTxSetSize,
            .BaseReserve => .BaseReserve,
            .Flags => .Flags,
            .Config => .Config,
            .MaxSorobanTxSetSize => .MaxSorobanTxSetSize,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Version => |v| try xdrEncodeGeneric(u32, writer, v),
            .BaseFee => |v| try xdrEncodeGeneric(u32, writer, v),
            .MaxTxSetSize => |v| try xdrEncodeGeneric(u32, writer, v),
            .BaseReserve => |v| try xdrEncodeGeneric(u32, writer, v),
            .Flags => |v| try xdrEncodeGeneric(u32, writer, v),
            .Config => |v| try xdrEncodeGeneric(ConfigUpgradeSetKey, writer, v),
            .MaxSorobanTxSetSize => |v| try xdrEncodeGeneric(u32, writer, v),
        }
    }
};

/// ConfigUpgradeSet is an XDR Struct defined as:
///
/// ```text
/// struct ConfigUpgradeSet {
///     ConfigSettingEntry updatedEntry<>;
/// };
/// ```
///
pub const ConfigUpgradeSet = struct {
    updated_entry: []ConfigSettingEntry,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ConfigUpgradeSet {
        return ConfigUpgradeSet{
            .updated_entry = try xdrDecodeGeneric([]ConfigSettingEntry, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ConfigUpgradeSet, writer: anytype) !void {
        try xdrEncodeGeneric([]ConfigSettingEntry, writer, self.updated_entry);
    }
};

/// TxSetComponentType is an XDR Enum defined as:
///
/// ```text
/// enum TxSetComponentType
/// {
///   // txs with effective fee <= bid derived from a base fee (if any).
///   // If base fee is not specified, no discount is applied.
///   TXSET_COMP_TXS_MAYBE_DISCOUNTED_FEE = 0
/// };
/// ```
///
pub const TxSetComponentType = enum(i32) {
    TxsetCompTxsMaybeDiscountedFee = 0,
    _,

    pub const variants = [_]TxSetComponentType{
        .TxsetCompTxsMaybeDiscountedFee,
    };

    pub fn name(self: TxSetComponentType) []const u8 {
        return switch (self) {
            .TxsetCompTxsMaybeDiscountedFee => "TxsetCompTxsMaybeDiscountedFee",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TxSetComponentType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: TxSetComponentType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// DependentTxCluster is an XDR Typedef defined as:
///
/// ```text
/// typedef TransactionEnvelope DependentTxCluster<>;
/// ```
///
pub const DependentTxCluster = struct {
    value: []TransactionEnvelope,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !DependentTxCluster {
        return DependentTxCluster{
            .value = try xdrDecodeGeneric([]TransactionEnvelope, allocator, reader),
        };
    }

    pub fn xdrEncode(self: DependentTxCluster, writer: anytype) !void {
        try xdrEncodeGeneric([]TransactionEnvelope, writer, self.value);
    }

    pub fn asSlice(self: DependentTxCluster) []const TransactionEnvelope {
        return self.value.data;
    }
};

/// ParallelTxExecutionStage is an XDR Typedef defined as:
///
/// ```text
/// typedef DependentTxCluster ParallelTxExecutionStage<>;
/// ```
///
pub const ParallelTxExecutionStage = struct {
    value: []DependentTxCluster,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ParallelTxExecutionStage {
        return ParallelTxExecutionStage{
            .value = try xdrDecodeGeneric([]DependentTxCluster, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ParallelTxExecutionStage, writer: anytype) !void {
        try xdrEncodeGeneric([]DependentTxCluster, writer, self.value);
    }

    pub fn asSlice(self: ParallelTxExecutionStage) []const DependentTxCluster {
        return self.value.data;
    }
};

/// ParallelTxsComponent is an XDR Struct defined as:
///
/// ```text
/// struct ParallelTxsComponent
/// {
///   int64* baseFee;
///   // A sequence of stages that *may* have arbitrary data dependencies between
///   // each other, i.e. in a general case the stage execution order may not be
///   // arbitrarily shuffled without affecting the end result.
///   ParallelTxExecutionStage executionStages<>;
/// };
/// ```
///
pub const ParallelTxsComponent = struct {
    base_fee: ?i64,
    execution_stages: []ParallelTxExecutionStage,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ParallelTxsComponent {
        return ParallelTxsComponent{
            .base_fee = try xdrDecodeGeneric(?i64, allocator, reader),
            .execution_stages = try xdrDecodeGeneric([]ParallelTxExecutionStage, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ParallelTxsComponent, writer: anytype) !void {
        try xdrEncodeGeneric(?i64, writer, self.base_fee);
        try xdrEncodeGeneric([]ParallelTxExecutionStage, writer, self.execution_stages);
    }
};

/// TxSetComponentTxsMaybeDiscountedFee is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///   {
///     int64* baseFee;
///     TransactionEnvelope txs<>;
///   }
/// ```
///
pub const TxSetComponentTxsMaybeDiscountedFee = struct {
    base_fee: ?i64,
    txs: []TransactionEnvelope,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TxSetComponentTxsMaybeDiscountedFee {
        return TxSetComponentTxsMaybeDiscountedFee{
            .base_fee = try xdrDecodeGeneric(?i64, allocator, reader),
            .txs = try xdrDecodeGeneric([]TransactionEnvelope, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TxSetComponentTxsMaybeDiscountedFee, writer: anytype) !void {
        try xdrEncodeGeneric(?i64, writer, self.base_fee);
        try xdrEncodeGeneric([]TransactionEnvelope, writer, self.txs);
    }
};

/// TxSetComponent is an XDR Union defined as:
///
/// ```text
/// union TxSetComponent switch (TxSetComponentType type)
/// {
/// case TXSET_COMP_TXS_MAYBE_DISCOUNTED_FEE:
///   struct
///   {
///     int64* baseFee;
///     TransactionEnvelope txs<>;
///   } txsMaybeDiscountedFee;
/// };
/// ```
///
pub const TxSetComponent = union(enum) {
    TxsetCompTxsMaybeDiscountedFee: TxSetComponentTxsMaybeDiscountedFee,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TxSetComponent {
        const disc = try TxSetComponentType.xdrDecode(allocator, reader);
        return switch (disc) {
            .TxsetCompTxsMaybeDiscountedFee => TxSetComponent{ .TxsetCompTxsMaybeDiscountedFee = try xdrDecodeGeneric(TxSetComponentTxsMaybeDiscountedFee, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: TxSetComponent, writer: anytype) !void {
        const disc: TxSetComponentType = switch (self) {
            .TxsetCompTxsMaybeDiscountedFee => .TxsetCompTxsMaybeDiscountedFee,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .TxsetCompTxsMaybeDiscountedFee => |v| try xdrEncodeGeneric(TxSetComponentTxsMaybeDiscountedFee, writer, v),
        }
    }
};

/// TransactionPhase is an XDR Union defined as:
///
/// ```text
/// union TransactionPhase switch (int v)
/// {
/// case 0:
///     TxSetComponent v0Components<>;
/// case 1:
///     ParallelTxsComponent parallelTxsComponent;
/// };
/// ```
///
pub const TransactionPhase = union(enum) {
    V0: []TxSetComponent,
    V1: ParallelTxsComponent,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionPhase {
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => TransactionPhase{ .V0 = try xdrDecodeGeneric([]TxSetComponent, allocator, reader) },
            1 => TransactionPhase{ .V1 = try xdrDecodeGeneric(ParallelTxsComponent, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: TransactionPhase, writer: anytype) !void {
        switch (self) {
            .V0 => |v| {
                try writer.writeInt(i32, 0, .big);
                try xdrEncodeGeneric([]TxSetComponent, writer, v);
            },
            .V1 => |v| {
                try writer.writeInt(i32, 1, .big);
                try xdrEncodeGeneric(ParallelTxsComponent, writer, v);
            },
        }
    }
};

/// TransactionSet is an XDR Struct defined as:
///
/// ```text
/// struct TransactionSet
/// {
///     Hash previousLedgerHash;
///     TransactionEnvelope txs<>;
/// };
/// ```
///
pub const TransactionSet = struct {
    previous_ledger_hash: Hash,
    txs: []TransactionEnvelope,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionSet {
        return TransactionSet{
            .previous_ledger_hash = try xdrDecodeGeneric(Hash, allocator, reader),
            .txs = try xdrDecodeGeneric([]TransactionEnvelope, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TransactionSet, writer: anytype) !void {
        try xdrEncodeGeneric(Hash, writer, self.previous_ledger_hash);
        try xdrEncodeGeneric([]TransactionEnvelope, writer, self.txs);
    }
};

/// TransactionSetV1 is an XDR Struct defined as:
///
/// ```text
/// struct TransactionSetV1
/// {
///     Hash previousLedgerHash;
///     TransactionPhase phases<>;
/// };
/// ```
///
pub const TransactionSetV1 = struct {
    previous_ledger_hash: Hash,
    phases: []TransactionPhase,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionSetV1 {
        return TransactionSetV1{
            .previous_ledger_hash = try xdrDecodeGeneric(Hash, allocator, reader),
            .phases = try xdrDecodeGeneric([]TransactionPhase, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TransactionSetV1, writer: anytype) !void {
        try xdrEncodeGeneric(Hash, writer, self.previous_ledger_hash);
        try xdrEncodeGeneric([]TransactionPhase, writer, self.phases);
    }
};

/// GeneralizedTransactionSet is an XDR Union defined as:
///
/// ```text
/// union GeneralizedTransactionSet switch (int v)
/// {
/// // We consider the legacy TransactionSet to be v0.
/// case 1:
///     TransactionSetV1 v1TxSet;
/// };
/// ```
///
pub const GeneralizedTransactionSet = union(enum) {
    V1: TransactionSetV1,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !GeneralizedTransactionSet {
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            1 => GeneralizedTransactionSet{ .V1 = try xdrDecodeGeneric(TransactionSetV1, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: GeneralizedTransactionSet, writer: anytype) !void {
        switch (self) {
            .V1 => |v| {
                try writer.writeInt(i32, 1, .big);
                try xdrEncodeGeneric(TransactionSetV1, writer, v);
            },
        }
    }
};

/// TransactionResultPair is an XDR Struct defined as:
///
/// ```text
/// struct TransactionResultPair
/// {
///     Hash transactionHash;
///     TransactionResult result; // result for the transaction
/// };
/// ```
///
pub const TransactionResultPair = struct {
    transaction_hash: Hash,
    result: TransactionResult,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionResultPair {
        return TransactionResultPair{
            .transaction_hash = try xdrDecodeGeneric(Hash, allocator, reader),
            .result = try xdrDecodeGeneric(TransactionResult, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TransactionResultPair, writer: anytype) !void {
        try xdrEncodeGeneric(Hash, writer, self.transaction_hash);
        try xdrEncodeGeneric(TransactionResult, writer, self.result);
    }
};

/// TransactionResultSet is an XDR Struct defined as:
///
/// ```text
/// struct TransactionResultSet
/// {
///     TransactionResultPair results<>;
/// };
/// ```
///
pub const TransactionResultSet = struct {
    results: []TransactionResultPair,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionResultSet {
        return TransactionResultSet{
            .results = try xdrDecodeGeneric([]TransactionResultPair, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TransactionResultSet, writer: anytype) !void {
        try xdrEncodeGeneric([]TransactionResultPair, writer, self.results);
    }
};

/// TransactionHistoryEntryExt is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (int v)
///     {
///     case 0:
///         void;
///     case 1:
///         GeneralizedTransactionSet generalizedTxSet;
///     }
/// ```
///
pub const TransactionHistoryEntryExt = union(enum) {
    V0,
    V1: GeneralizedTransactionSet,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionHistoryEntryExt {
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => TransactionHistoryEntryExt{ .V0 = {} },
            1 => TransactionHistoryEntryExt{ .V1 = try xdrDecodeGeneric(GeneralizedTransactionSet, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: TransactionHistoryEntryExt, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
            .V1 => |v| {
                try writer.writeInt(i32, 1, .big);
                try xdrEncodeGeneric(GeneralizedTransactionSet, writer, v);
            },
        }
    }
};

/// TransactionHistoryEntry is an XDR Struct defined as:
///
/// ```text
/// struct TransactionHistoryEntry
/// {
///     uint32 ledgerSeq;
///     TransactionSet txSet;
///
///     // when v != 0, txSet must be empty
///     union switch (int v)
///     {
///     case 0:
///         void;
///     case 1:
///         GeneralizedTransactionSet generalizedTxSet;
///     }
///     ext;
/// };
/// ```
///
pub const TransactionHistoryEntry = struct {
    ledger_seq: u32,
    tx_set: TransactionSet,
    ext: TransactionHistoryEntryExt,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionHistoryEntry {
        return TransactionHistoryEntry{
            .ledger_seq = try xdrDecodeGeneric(u32, allocator, reader),
            .tx_set = try xdrDecodeGeneric(TransactionSet, allocator, reader),
            .ext = try xdrDecodeGeneric(TransactionHistoryEntryExt, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TransactionHistoryEntry, writer: anytype) !void {
        try xdrEncodeGeneric(u32, writer, self.ledger_seq);
        try xdrEncodeGeneric(TransactionSet, writer, self.tx_set);
        try xdrEncodeGeneric(TransactionHistoryEntryExt, writer, self.ext);
    }
};

/// TransactionHistoryResultEntryExt is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (int v)
///     {
///     case 0:
///         void;
///     }
/// ```
///
pub const TransactionHistoryResultEntryExt = union(enum) {
    V0,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionHistoryResultEntryExt {
        _ = allocator;
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => TransactionHistoryResultEntryExt{ .V0 = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: TransactionHistoryResultEntryExt, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
        }
    }
};

/// TransactionHistoryResultEntry is an XDR Struct defined as:
///
/// ```text
/// struct TransactionHistoryResultEntry
/// {
///     uint32 ledgerSeq;
///     TransactionResultSet txResultSet;
///
///     // reserved for future use
///     union switch (int v)
///     {
///     case 0:
///         void;
///     }
///     ext;
/// };
/// ```
///
pub const TransactionHistoryResultEntry = struct {
    ledger_seq: u32,
    tx_result_set: TransactionResultSet,
    ext: TransactionHistoryResultEntryExt,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionHistoryResultEntry {
        return TransactionHistoryResultEntry{
            .ledger_seq = try xdrDecodeGeneric(u32, allocator, reader),
            .tx_result_set = try xdrDecodeGeneric(TransactionResultSet, allocator, reader),
            .ext = try xdrDecodeGeneric(TransactionHistoryResultEntryExt, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TransactionHistoryResultEntry, writer: anytype) !void {
        try xdrEncodeGeneric(u32, writer, self.ledger_seq);
        try xdrEncodeGeneric(TransactionResultSet, writer, self.tx_result_set);
        try xdrEncodeGeneric(TransactionHistoryResultEntryExt, writer, self.ext);
    }
};

/// LedgerHeaderHistoryEntryExt is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (int v)
///     {
///     case 0:
///         void;
///     }
/// ```
///
pub const LedgerHeaderHistoryEntryExt = union(enum) {
    V0,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerHeaderHistoryEntryExt {
        _ = allocator;
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => LedgerHeaderHistoryEntryExt{ .V0 = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: LedgerHeaderHistoryEntryExt, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
        }
    }
};

/// LedgerHeaderHistoryEntry is an XDR Struct defined as:
///
/// ```text
/// struct LedgerHeaderHistoryEntry
/// {
///     Hash hash;
///     LedgerHeader header;
///
///     // reserved for future use
///     union switch (int v)
///     {
///     case 0:
///         void;
///     }
///     ext;
/// };
/// ```
///
pub const LedgerHeaderHistoryEntry = struct {
    hash: Hash,
    header: LedgerHeader,
    ext: LedgerHeaderHistoryEntryExt,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerHeaderHistoryEntry {
        return LedgerHeaderHistoryEntry{
            .hash = try xdrDecodeGeneric(Hash, allocator, reader),
            .header = try xdrDecodeGeneric(LedgerHeader, allocator, reader),
            .ext = try xdrDecodeGeneric(LedgerHeaderHistoryEntryExt, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LedgerHeaderHistoryEntry, writer: anytype) !void {
        try xdrEncodeGeneric(Hash, writer, self.hash);
        try xdrEncodeGeneric(LedgerHeader, writer, self.header);
        try xdrEncodeGeneric(LedgerHeaderHistoryEntryExt, writer, self.ext);
    }
};

/// LedgerScpMessages is an XDR Struct defined as:
///
/// ```text
/// struct LedgerSCPMessages
/// {
///     uint32 ledgerSeq;
///     SCPEnvelope messages<>;
/// };
/// ```
///
pub const LedgerScpMessages = struct {
    ledger_seq: u32,
    messages: []ScpEnvelope,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerScpMessages {
        return LedgerScpMessages{
            .ledger_seq = try xdrDecodeGeneric(u32, allocator, reader),
            .messages = try xdrDecodeGeneric([]ScpEnvelope, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LedgerScpMessages, writer: anytype) !void {
        try xdrEncodeGeneric(u32, writer, self.ledger_seq);
        try xdrEncodeGeneric([]ScpEnvelope, writer, self.messages);
    }
};

/// ScpHistoryEntryV0 is an XDR Struct defined as:
///
/// ```text
/// struct SCPHistoryEntryV0
/// {
///     SCPQuorumSet quorumSets<>; // additional quorum sets used by ledgerMessages
///     LedgerSCPMessages ledgerMessages;
/// };
/// ```
///
pub const ScpHistoryEntryV0 = struct {
    quorum_sets: []ScpQuorumSet,
    ledger_messages: LedgerScpMessages,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScpHistoryEntryV0 {
        return ScpHistoryEntryV0{
            .quorum_sets = try xdrDecodeGeneric([]ScpQuorumSet, allocator, reader),
            .ledger_messages = try xdrDecodeGeneric(LedgerScpMessages, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ScpHistoryEntryV0, writer: anytype) !void {
        try xdrEncodeGeneric([]ScpQuorumSet, writer, self.quorum_sets);
        try xdrEncodeGeneric(LedgerScpMessages, writer, self.ledger_messages);
    }
};

/// ScpHistoryEntry is an XDR Union defined as:
///
/// ```text
/// union SCPHistoryEntry switch (int v)
/// {
/// case 0:
///     SCPHistoryEntryV0 v0;
/// };
/// ```
///
pub const ScpHistoryEntry = union(enum) {
    V0: ScpHistoryEntryV0,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ScpHistoryEntry {
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => ScpHistoryEntry{ .V0 = try xdrDecodeGeneric(ScpHistoryEntryV0, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ScpHistoryEntry, writer: anytype) !void {
        switch (self) {
            .V0 => |v| {
                try writer.writeInt(i32, 0, .big);
                try xdrEncodeGeneric(ScpHistoryEntryV0, writer, v);
            },
        }
    }
};

/// LedgerEntryChangeType is an XDR Enum defined as:
///
/// ```text
/// enum LedgerEntryChangeType
/// {
///     LEDGER_ENTRY_CREATED = 0, // entry was added to the ledger
///     LEDGER_ENTRY_UPDATED = 1, // entry was modified in the ledger
///     LEDGER_ENTRY_REMOVED = 2, // entry was removed from the ledger
///     LEDGER_ENTRY_STATE    = 3, // value of the entry
///     LEDGER_ENTRY_RESTORED = 4  // archived entry was restored in the ledger
/// };
/// ```
///
pub const LedgerEntryChangeType = enum(i32) {
    Created = 0,
    Updated = 1,
    Removed = 2,
    State = 3,
    Restored = 4,
    _,

    pub const variants = [_]LedgerEntryChangeType{
        .Created,
        .Updated,
        .Removed,
        .State,
        .Restored,
    };

    pub fn name(self: LedgerEntryChangeType) []const u8 {
        return switch (self) {
            .Created => "Created",
            .Updated => "Updated",
            .Removed => "Removed",
            .State => "State",
            .Restored => "Restored",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerEntryChangeType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: LedgerEntryChangeType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// LedgerEntryChange is an XDR Union defined as:
///
/// ```text
/// union LedgerEntryChange switch (LedgerEntryChangeType type)
/// {
/// case LEDGER_ENTRY_CREATED:
///     LedgerEntry created;
/// case LEDGER_ENTRY_UPDATED:
///     LedgerEntry updated;
/// case LEDGER_ENTRY_REMOVED:
///     LedgerKey removed;
/// case LEDGER_ENTRY_STATE:
///     LedgerEntry state;
/// case LEDGER_ENTRY_RESTORED:
///     LedgerEntry restored;
/// };
/// ```
///
pub const LedgerEntryChange = union(enum) {
    Created: LedgerEntry,
    Updated: LedgerEntry,
    Removed: LedgerKey,
    State: LedgerEntry,
    Restored: LedgerEntry,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerEntryChange {
        const disc = try LedgerEntryChangeType.xdrDecode(allocator, reader);
        return switch (disc) {
            .Created => LedgerEntryChange{ .Created = try xdrDecodeGeneric(LedgerEntry, allocator, reader) },
            .Updated => LedgerEntryChange{ .Updated = try xdrDecodeGeneric(LedgerEntry, allocator, reader) },
            .Removed => LedgerEntryChange{ .Removed = try xdrDecodeGeneric(LedgerKey, allocator, reader) },
            .State => LedgerEntryChange{ .State = try xdrDecodeGeneric(LedgerEntry, allocator, reader) },
            .Restored => LedgerEntryChange{ .Restored = try xdrDecodeGeneric(LedgerEntry, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: LedgerEntryChange, writer: anytype) !void {
        const disc: LedgerEntryChangeType = switch (self) {
            .Created => .Created,
            .Updated => .Updated,
            .Removed => .Removed,
            .State => .State,
            .Restored => .Restored,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Created => |v| try xdrEncodeGeneric(LedgerEntry, writer, v),
            .Updated => |v| try xdrEncodeGeneric(LedgerEntry, writer, v),
            .Removed => |v| try xdrEncodeGeneric(LedgerKey, writer, v),
            .State => |v| try xdrEncodeGeneric(LedgerEntry, writer, v),
            .Restored => |v| try xdrEncodeGeneric(LedgerEntry, writer, v),
        }
    }
};

/// LedgerEntryChanges is an XDR Typedef defined as:
///
/// ```text
/// typedef LedgerEntryChange LedgerEntryChanges<>;
/// ```
///
pub const LedgerEntryChanges = struct {
    value: []LedgerEntryChange,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerEntryChanges {
        return LedgerEntryChanges{
            .value = try xdrDecodeGeneric([]LedgerEntryChange, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LedgerEntryChanges, writer: anytype) !void {
        try xdrEncodeGeneric([]LedgerEntryChange, writer, self.value);
    }

    pub fn asSlice(self: LedgerEntryChanges) []const LedgerEntryChange {
        return self.value.data;
    }
};

/// OperationMeta is an XDR Struct defined as:
///
/// ```text
/// struct OperationMeta
/// {
///     LedgerEntryChanges changes;
/// };
/// ```
///
pub const OperationMeta = struct {
    changes: LedgerEntryChanges,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !OperationMeta {
        return OperationMeta{
            .changes = try xdrDecodeGeneric(LedgerEntryChanges, allocator, reader),
        };
    }

    pub fn xdrEncode(self: OperationMeta, writer: anytype) !void {
        try xdrEncodeGeneric(LedgerEntryChanges, writer, self.changes);
    }
};

/// TransactionMetaV1 is an XDR Struct defined as:
///
/// ```text
/// struct TransactionMetaV1
/// {
///     LedgerEntryChanges txChanges; // tx level changes if any
///     OperationMeta operations<>;   // meta for each operation
/// };
/// ```
///
pub const TransactionMetaV1 = struct {
    tx_changes: LedgerEntryChanges,
    operations: []OperationMeta,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionMetaV1 {
        return TransactionMetaV1{
            .tx_changes = try xdrDecodeGeneric(LedgerEntryChanges, allocator, reader),
            .operations = try xdrDecodeGeneric([]OperationMeta, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TransactionMetaV1, writer: anytype) !void {
        try xdrEncodeGeneric(LedgerEntryChanges, writer, self.tx_changes);
        try xdrEncodeGeneric([]OperationMeta, writer, self.operations);
    }
};

/// TransactionMetaV2 is an XDR Struct defined as:
///
/// ```text
/// struct TransactionMetaV2
/// {
///     LedgerEntryChanges txChangesBefore; // tx level changes before operations
///                                         // are applied if any
///     OperationMeta operations<>;         // meta for each operation
///     LedgerEntryChanges txChangesAfter;  // tx level changes after operations are
///                                         // applied if any
/// };
/// ```
///
pub const TransactionMetaV2 = struct {
    tx_changes_before: LedgerEntryChanges,
    operations: []OperationMeta,
    tx_changes_after: LedgerEntryChanges,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionMetaV2 {
        return TransactionMetaV2{
            .tx_changes_before = try xdrDecodeGeneric(LedgerEntryChanges, allocator, reader),
            .operations = try xdrDecodeGeneric([]OperationMeta, allocator, reader),
            .tx_changes_after = try xdrDecodeGeneric(LedgerEntryChanges, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TransactionMetaV2, writer: anytype) !void {
        try xdrEncodeGeneric(LedgerEntryChanges, writer, self.tx_changes_before);
        try xdrEncodeGeneric([]OperationMeta, writer, self.operations);
        try xdrEncodeGeneric(LedgerEntryChanges, writer, self.tx_changes_after);
    }
};

/// ContractEventType is an XDR Enum defined as:
///
/// ```text
/// enum ContractEventType
/// {
///     SYSTEM = 0,
///     CONTRACT = 1,
///     DIAGNOSTIC = 2
/// };
/// ```
///
pub const ContractEventType = enum(i32) {
    System = 0,
    Contract = 1,
    Diagnostic = 2,
    _,

    pub const variants = [_]ContractEventType{
        .System,
        .Contract,
        .Diagnostic,
    };

    pub fn name(self: ContractEventType) []const u8 {
        return switch (self) {
            .System => "System",
            .Contract => "Contract",
            .Diagnostic => "Diagnostic",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ContractEventType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ContractEventType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ContractEventV0 is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///         {
///             SCVal topics<>;
///             SCVal data;
///         }
/// ```
///
pub const ContractEventV0 = struct {
    topics: []ScVal,
    data: ScVal,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ContractEventV0 {
        return ContractEventV0{
            .topics = try xdrDecodeGeneric([]ScVal, allocator, reader),
            .data = try xdrDecodeGeneric(ScVal, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ContractEventV0, writer: anytype) !void {
        try xdrEncodeGeneric([]ScVal, writer, self.topics);
        try xdrEncodeGeneric(ScVal, writer, self.data);
    }
};

/// ContractEventBody is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (int v)
///     {
///     case 0:
///         struct
///         {
///             SCVal topics<>;
///             SCVal data;
///         } v0;
///     }
/// ```
///
pub const ContractEventBody = union(enum) {
    V0: ContractEventV0,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ContractEventBody {
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => ContractEventBody{ .V0 = try xdrDecodeGeneric(ContractEventV0, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ContractEventBody, writer: anytype) !void {
        switch (self) {
            .V0 => |v| {
                try writer.writeInt(i32, 0, .big);
                try xdrEncodeGeneric(ContractEventV0, writer, v);
            },
        }
    }
};

/// ContractEvent is an XDR Struct defined as:
///
/// ```text
/// struct ContractEvent
/// {
///     // We can use this to add more fields, or because it
///     // is first, to change ContractEvent into a union.
///     ExtensionPoint ext;
///
///     ContractID* contractID;
///     ContractEventType type;
///
///     union switch (int v)
///     {
///     case 0:
///         struct
///         {
///             SCVal topics<>;
///             SCVal data;
///         } v0;
///     }
///     body;
/// };
/// ```
///
pub const ContractEvent = struct {
    ext: ExtensionPoint,
    contract_id: ?ContractId,
    type: ContractEventType,
    body: ContractEventBody,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ContractEvent {
        return ContractEvent{
            .ext = try xdrDecodeGeneric(ExtensionPoint, allocator, reader),
            .contract_id = try xdrDecodeGeneric(?ContractId, allocator, reader),
            .type = try xdrDecodeGeneric(ContractEventType, allocator, reader),
            .body = try xdrDecodeGeneric(ContractEventBody, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ContractEvent, writer: anytype) !void {
        try xdrEncodeGeneric(ExtensionPoint, writer, self.ext);
        try xdrEncodeGeneric(?ContractId, writer, self.contract_id);
        try xdrEncodeGeneric(ContractEventType, writer, self.type);
        try xdrEncodeGeneric(ContractEventBody, writer, self.body);
    }
};

/// DiagnosticEvent is an XDR Struct defined as:
///
/// ```text
/// struct DiagnosticEvent
/// {
///     bool inSuccessfulContractCall;
///     ContractEvent event;
/// };
/// ```
///
pub const DiagnosticEvent = struct {
    in_successful_contract_call: bool,
    event: ContractEvent,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !DiagnosticEvent {
        return DiagnosticEvent{
            .in_successful_contract_call = try xdrDecodeGeneric(bool, allocator, reader),
            .event = try xdrDecodeGeneric(ContractEvent, allocator, reader),
        };
    }

    pub fn xdrEncode(self: DiagnosticEvent, writer: anytype) !void {
        try xdrEncodeGeneric(bool, writer, self.in_successful_contract_call);
        try xdrEncodeGeneric(ContractEvent, writer, self.event);
    }
};

/// SorobanTransactionMetaExtV1 is an XDR Struct defined as:
///
/// ```text
/// struct SorobanTransactionMetaExtV1
/// {
///     ExtensionPoint ext;
///
///     // The following are the components of the overall Soroban resource fee
///     // charged for the transaction.
///     // The following relation holds:
///     // `resourceFeeCharged = totalNonRefundableResourceFeeCharged + totalRefundableResourceFeeCharged`
///     // where `resourceFeeCharged` is the overall fee charged for the
///     // transaction. Also, `resourceFeeCharged` <= `sorobanData.resourceFee`
///     // i.e.we never charge more than the declared resource fee.
///     // The inclusion fee for charged the Soroban transaction can be found using
///     // the following equation:
///     // `result.feeCharged = resourceFeeCharged + inclusionFeeCharged`.
///
///     // Total amount (in stroops) that has been charged for non-refundable
///     // Soroban resources.
///     // Non-refundable resources are charged based on the usage declared in
///     // the transaction envelope (such as `instructions`, `readBytes` etc.) and
///     // is charged regardless of the success of the transaction.
///     int64 totalNonRefundableResourceFeeCharged;
///     // Total amount (in stroops) that has been charged for refundable
///     // Soroban resource fees.
///     // Currently this comprises the rent fee (`rentFeeCharged`) and the
///     // fee for the events and return value.
///     // Refundable resources are charged based on the actual resources usage.
///     // Since currently refundable resources are only used for the successful
///     // transactions, this will be `0` for failed transactions.
///     int64 totalRefundableResourceFeeCharged;
///     // Amount (in stroops) that has been charged for rent.
///     // This is a part of `totalNonRefundableResourceFeeCharged`.
///     int64 rentFeeCharged;
/// };
/// ```
///
pub const SorobanTransactionMetaExtV1 = struct {
    ext: ExtensionPoint,
    total_non_refundable_resource_fee_charged: i64,
    total_refundable_resource_fee_charged: i64,
    rent_fee_charged: i64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SorobanTransactionMetaExtV1 {
        return SorobanTransactionMetaExtV1{
            .ext = try xdrDecodeGeneric(ExtensionPoint, allocator, reader),
            .total_non_refundable_resource_fee_charged = try xdrDecodeGeneric(i64, allocator, reader),
            .total_refundable_resource_fee_charged = try xdrDecodeGeneric(i64, allocator, reader),
            .rent_fee_charged = try xdrDecodeGeneric(i64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: SorobanTransactionMetaExtV1, writer: anytype) !void {
        try xdrEncodeGeneric(ExtensionPoint, writer, self.ext);
        try xdrEncodeGeneric(i64, writer, self.total_non_refundable_resource_fee_charged);
        try xdrEncodeGeneric(i64, writer, self.total_refundable_resource_fee_charged);
        try xdrEncodeGeneric(i64, writer, self.rent_fee_charged);
    }
};

/// SorobanTransactionMetaExt is an XDR Union defined as:
///
/// ```text
/// union SorobanTransactionMetaExt switch (int v)
/// {
/// case 0:
///     void;
/// case 1:
///     SorobanTransactionMetaExtV1 v1;
/// };
/// ```
///
pub const SorobanTransactionMetaExt = union(enum) {
    V0,
    V1: SorobanTransactionMetaExtV1,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SorobanTransactionMetaExt {
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => SorobanTransactionMetaExt{ .V0 = {} },
            1 => SorobanTransactionMetaExt{ .V1 = try xdrDecodeGeneric(SorobanTransactionMetaExtV1, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: SorobanTransactionMetaExt, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
            .V1 => |v| {
                try writer.writeInt(i32, 1, .big);
                try xdrEncodeGeneric(SorobanTransactionMetaExtV1, writer, v);
            },
        }
    }
};

/// SorobanTransactionMeta is an XDR Struct defined as:
///
/// ```text
/// struct SorobanTransactionMeta
/// {
///     SorobanTransactionMetaExt ext;
///
///     ContractEvent events<>;             // custom events populated by the
///                                         // contracts themselves.
///     SCVal returnValue;                  // return value of the host fn invocation
///
///     // Diagnostics events that are not hashed.
///     // This will contain all contract and diagnostic events. Even ones
///     // that were emitted in a failed contract call.
///     DiagnosticEvent diagnosticEvents<>;
/// };
/// ```
///
pub const SorobanTransactionMeta = struct {
    ext: SorobanTransactionMetaExt,
    events: []ContractEvent,
    return_value: ScVal,
    diagnostic_events: []DiagnosticEvent,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SorobanTransactionMeta {
        return SorobanTransactionMeta{
            .ext = try xdrDecodeGeneric(SorobanTransactionMetaExt, allocator, reader),
            .events = try xdrDecodeGeneric([]ContractEvent, allocator, reader),
            .return_value = try xdrDecodeGeneric(ScVal, allocator, reader),
            .diagnostic_events = try xdrDecodeGeneric([]DiagnosticEvent, allocator, reader),
        };
    }

    pub fn xdrEncode(self: SorobanTransactionMeta, writer: anytype) !void {
        try xdrEncodeGeneric(SorobanTransactionMetaExt, writer, self.ext);
        try xdrEncodeGeneric([]ContractEvent, writer, self.events);
        try xdrEncodeGeneric(ScVal, writer, self.return_value);
        try xdrEncodeGeneric([]DiagnosticEvent, writer, self.diagnostic_events);
    }
};

/// TransactionMetaV3 is an XDR Struct defined as:
///
/// ```text
/// struct TransactionMetaV3
/// {
///     ExtensionPoint ext;
///
///     LedgerEntryChanges txChangesBefore;  // tx level changes before operations
///                                          // are applied if any
///     OperationMeta operations<>;          // meta for each operation
///     LedgerEntryChanges txChangesAfter;   // tx level changes after operations are
///                                          // applied if any
///     SorobanTransactionMeta* sorobanMeta; // Soroban-specific meta (only for
///                                          // Soroban transactions).
/// };
/// ```
///
pub const TransactionMetaV3 = struct {
    ext: ExtensionPoint,
    tx_changes_before: LedgerEntryChanges,
    operations: []OperationMeta,
    tx_changes_after: LedgerEntryChanges,
    soroban_meta: ?SorobanTransactionMeta,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionMetaV3 {
        return TransactionMetaV3{
            .ext = try xdrDecodeGeneric(ExtensionPoint, allocator, reader),
            .tx_changes_before = try xdrDecodeGeneric(LedgerEntryChanges, allocator, reader),
            .operations = try xdrDecodeGeneric([]OperationMeta, allocator, reader),
            .tx_changes_after = try xdrDecodeGeneric(LedgerEntryChanges, allocator, reader),
            .soroban_meta = try xdrDecodeGeneric(?SorobanTransactionMeta, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TransactionMetaV3, writer: anytype) !void {
        try xdrEncodeGeneric(ExtensionPoint, writer, self.ext);
        try xdrEncodeGeneric(LedgerEntryChanges, writer, self.tx_changes_before);
        try xdrEncodeGeneric([]OperationMeta, writer, self.operations);
        try xdrEncodeGeneric(LedgerEntryChanges, writer, self.tx_changes_after);
        try xdrEncodeGeneric(?SorobanTransactionMeta, writer, self.soroban_meta);
    }
};

/// OperationMetaV2 is an XDR Struct defined as:
///
/// ```text
/// struct OperationMetaV2
/// {
///     ExtensionPoint ext;
///
///     LedgerEntryChanges changes;
///
///     ContractEvent events<>;
/// };
/// ```
///
pub const OperationMetaV2 = struct {
    ext: ExtensionPoint,
    changes: LedgerEntryChanges,
    events: []ContractEvent,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !OperationMetaV2 {
        return OperationMetaV2{
            .ext = try xdrDecodeGeneric(ExtensionPoint, allocator, reader),
            .changes = try xdrDecodeGeneric(LedgerEntryChanges, allocator, reader),
            .events = try xdrDecodeGeneric([]ContractEvent, allocator, reader),
        };
    }

    pub fn xdrEncode(self: OperationMetaV2, writer: anytype) !void {
        try xdrEncodeGeneric(ExtensionPoint, writer, self.ext);
        try xdrEncodeGeneric(LedgerEntryChanges, writer, self.changes);
        try xdrEncodeGeneric([]ContractEvent, writer, self.events);
    }
};

/// SorobanTransactionMetaV2 is an XDR Struct defined as:
///
/// ```text
/// struct SorobanTransactionMetaV2
/// {
///     SorobanTransactionMetaExt ext;
///
///     SCVal* returnValue;
/// };
/// ```
///
pub const SorobanTransactionMetaV2 = struct {
    ext: SorobanTransactionMetaExt,
    return_value: ?ScVal,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SorobanTransactionMetaV2 {
        return SorobanTransactionMetaV2{
            .ext = try xdrDecodeGeneric(SorobanTransactionMetaExt, allocator, reader),
            .return_value = try xdrDecodeGeneric(?ScVal, allocator, reader),
        };
    }

    pub fn xdrEncode(self: SorobanTransactionMetaV2, writer: anytype) !void {
        try xdrEncodeGeneric(SorobanTransactionMetaExt, writer, self.ext);
        try xdrEncodeGeneric(?ScVal, writer, self.return_value);
    }
};

/// TransactionEventStage is an XDR Enum defined as:
///
/// ```text
/// enum TransactionEventStage {
///     // The event has happened before any one of the transactions has its
///     // operations applied.
///     TRANSACTION_EVENT_STAGE_BEFORE_ALL_TXS = 0,
///     // The event has happened immediately after operations of the transaction
///     // have been applied.
///     TRANSACTION_EVENT_STAGE_AFTER_TX = 1,
///     // The event has happened after every transaction had its operations
///     // applied.
///     TRANSACTION_EVENT_STAGE_AFTER_ALL_TXS = 2
/// };
/// ```
///
pub const TransactionEventStage = enum(i32) {
    BeforeAllTxs = 0,
    AfterTx = 1,
    AfterAllTxs = 2,
    _,

    pub const variants = [_]TransactionEventStage{
        .BeforeAllTxs,
        .AfterTx,
        .AfterAllTxs,
    };

    pub fn name(self: TransactionEventStage) []const u8 {
        return switch (self) {
            .BeforeAllTxs => "BeforeAllTxs",
            .AfterTx => "AfterTx",
            .AfterAllTxs => "AfterAllTxs",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionEventStage {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: TransactionEventStage, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// TransactionEvent is an XDR Struct defined as:
///
/// ```text
/// struct TransactionEvent {
///     TransactionEventStage stage;  // Stage at which an event has occurred.
///     ContractEvent event;  // The contract event that has occurred.
/// };
/// ```
///
pub const TransactionEvent = struct {
    stage: TransactionEventStage,
    event: ContractEvent,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionEvent {
        return TransactionEvent{
            .stage = try xdrDecodeGeneric(TransactionEventStage, allocator, reader),
            .event = try xdrDecodeGeneric(ContractEvent, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TransactionEvent, writer: anytype) !void {
        try xdrEncodeGeneric(TransactionEventStage, writer, self.stage);
        try xdrEncodeGeneric(ContractEvent, writer, self.event);
    }
};

/// TransactionMetaV4 is an XDR Struct defined as:
///
/// ```text
/// struct TransactionMetaV4
/// {
///     ExtensionPoint ext;
///
///     LedgerEntryChanges txChangesBefore;  // tx level changes before operations
///                                          // are applied if any
///     OperationMetaV2 operations<>;        // meta for each operation
///     LedgerEntryChanges txChangesAfter;   // tx level changes after operations are
///                                          // applied if any
///     SorobanTransactionMetaV2* sorobanMeta; // Soroban-specific meta (only for
///                                            // Soroban transactions).
///
///     TransactionEvent events<>; // Used for transaction-level events (like fee payment)
///     DiagnosticEvent diagnosticEvents<>; // Used for all diagnostic information
/// };
/// ```
///
pub const TransactionMetaV4 = struct {
    ext: ExtensionPoint,
    tx_changes_before: LedgerEntryChanges,
    operations: []OperationMetaV2,
    tx_changes_after: LedgerEntryChanges,
    soroban_meta: ?SorobanTransactionMetaV2,
    events: []TransactionEvent,
    diagnostic_events: []DiagnosticEvent,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionMetaV4 {
        return TransactionMetaV4{
            .ext = try xdrDecodeGeneric(ExtensionPoint, allocator, reader),
            .tx_changes_before = try xdrDecodeGeneric(LedgerEntryChanges, allocator, reader),
            .operations = try xdrDecodeGeneric([]OperationMetaV2, allocator, reader),
            .tx_changes_after = try xdrDecodeGeneric(LedgerEntryChanges, allocator, reader),
            .soroban_meta = try xdrDecodeGeneric(?SorobanTransactionMetaV2, allocator, reader),
            .events = try xdrDecodeGeneric([]TransactionEvent, allocator, reader),
            .diagnostic_events = try xdrDecodeGeneric([]DiagnosticEvent, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TransactionMetaV4, writer: anytype) !void {
        try xdrEncodeGeneric(ExtensionPoint, writer, self.ext);
        try xdrEncodeGeneric(LedgerEntryChanges, writer, self.tx_changes_before);
        try xdrEncodeGeneric([]OperationMetaV2, writer, self.operations);
        try xdrEncodeGeneric(LedgerEntryChanges, writer, self.tx_changes_after);
        try xdrEncodeGeneric(?SorobanTransactionMetaV2, writer, self.soroban_meta);
        try xdrEncodeGeneric([]TransactionEvent, writer, self.events);
        try xdrEncodeGeneric([]DiagnosticEvent, writer, self.diagnostic_events);
    }
};

/// InvokeHostFunctionSuccessPreImage is an XDR Struct defined as:
///
/// ```text
/// struct InvokeHostFunctionSuccessPreImage
/// {
///     SCVal returnValue;
///     ContractEvent events<>;
/// };
/// ```
///
pub const InvokeHostFunctionSuccessPreImage = struct {
    return_value: ScVal,
    events: []ContractEvent,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !InvokeHostFunctionSuccessPreImage {
        return InvokeHostFunctionSuccessPreImage{
            .return_value = try xdrDecodeGeneric(ScVal, allocator, reader),
            .events = try xdrDecodeGeneric([]ContractEvent, allocator, reader),
        };
    }

    pub fn xdrEncode(self: InvokeHostFunctionSuccessPreImage, writer: anytype) !void {
        try xdrEncodeGeneric(ScVal, writer, self.return_value);
        try xdrEncodeGeneric([]ContractEvent, writer, self.events);
    }
};

/// TransactionMeta is an XDR Union defined as:
///
/// ```text
/// union TransactionMeta switch (int v)
/// {
/// case 0:
///     OperationMeta operations<>;
/// case 1:
///     TransactionMetaV1 v1;
/// case 2:
///     TransactionMetaV2 v2;
/// case 3:
///     TransactionMetaV3 v3;
/// case 4:
///     TransactionMetaV4 v4;
/// };
/// ```
///
pub const TransactionMeta = union(enum) {
    V0: []OperationMeta,
    V1: TransactionMetaV1,
    V2: TransactionMetaV2,
    V3: TransactionMetaV3,
    V4: TransactionMetaV4,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionMeta {
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => TransactionMeta{ .V0 = try xdrDecodeGeneric([]OperationMeta, allocator, reader) },
            1 => TransactionMeta{ .V1 = try xdrDecodeGeneric(TransactionMetaV1, allocator, reader) },
            2 => TransactionMeta{ .V2 = try xdrDecodeGeneric(TransactionMetaV2, allocator, reader) },
            3 => TransactionMeta{ .V3 = try xdrDecodeGeneric(TransactionMetaV3, allocator, reader) },
            4 => TransactionMeta{ .V4 = try xdrDecodeGeneric(TransactionMetaV4, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: TransactionMeta, writer: anytype) !void {
        switch (self) {
            .V0 => |v| {
                try writer.writeInt(i32, 0, .big);
                try xdrEncodeGeneric([]OperationMeta, writer, v);
            },
            .V1 => |v| {
                try writer.writeInt(i32, 1, .big);
                try xdrEncodeGeneric(TransactionMetaV1, writer, v);
            },
            .V2 => |v| {
                try writer.writeInt(i32, 2, .big);
                try xdrEncodeGeneric(TransactionMetaV2, writer, v);
            },
            .V3 => |v| {
                try writer.writeInt(i32, 3, .big);
                try xdrEncodeGeneric(TransactionMetaV3, writer, v);
            },
            .V4 => |v| {
                try writer.writeInt(i32, 4, .big);
                try xdrEncodeGeneric(TransactionMetaV4, writer, v);
            },
        }
    }
};

/// TransactionResultMeta is an XDR Struct defined as:
///
/// ```text
/// struct TransactionResultMeta
/// {
///     TransactionResultPair result;
///     LedgerEntryChanges feeProcessing;
///     TransactionMeta txApplyProcessing;
/// };
/// ```
///
pub const TransactionResultMeta = struct {
    result: TransactionResultPair,
    fee_processing: LedgerEntryChanges,
    tx_apply_processing: TransactionMeta,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionResultMeta {
        return TransactionResultMeta{
            .result = try xdrDecodeGeneric(TransactionResultPair, allocator, reader),
            .fee_processing = try xdrDecodeGeneric(LedgerEntryChanges, allocator, reader),
            .tx_apply_processing = try xdrDecodeGeneric(TransactionMeta, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TransactionResultMeta, writer: anytype) !void {
        try xdrEncodeGeneric(TransactionResultPair, writer, self.result);
        try xdrEncodeGeneric(LedgerEntryChanges, writer, self.fee_processing);
        try xdrEncodeGeneric(TransactionMeta, writer, self.tx_apply_processing);
    }
};

/// TransactionResultMetaV1 is an XDR Struct defined as:
///
/// ```text
/// struct TransactionResultMetaV1
/// {
///     ExtensionPoint ext;
///
///     TransactionResultPair result;
///     LedgerEntryChanges feeProcessing;
///     TransactionMeta txApplyProcessing;
///
///     LedgerEntryChanges postTxApplyFeeProcessing;
/// };
/// ```
///
pub const TransactionResultMetaV1 = struct {
    ext: ExtensionPoint,
    result: TransactionResultPair,
    fee_processing: LedgerEntryChanges,
    tx_apply_processing: TransactionMeta,
    post_tx_apply_fee_processing: LedgerEntryChanges,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionResultMetaV1 {
        return TransactionResultMetaV1{
            .ext = try xdrDecodeGeneric(ExtensionPoint, allocator, reader),
            .result = try xdrDecodeGeneric(TransactionResultPair, allocator, reader),
            .fee_processing = try xdrDecodeGeneric(LedgerEntryChanges, allocator, reader),
            .tx_apply_processing = try xdrDecodeGeneric(TransactionMeta, allocator, reader),
            .post_tx_apply_fee_processing = try xdrDecodeGeneric(LedgerEntryChanges, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TransactionResultMetaV1, writer: anytype) !void {
        try xdrEncodeGeneric(ExtensionPoint, writer, self.ext);
        try xdrEncodeGeneric(TransactionResultPair, writer, self.result);
        try xdrEncodeGeneric(LedgerEntryChanges, writer, self.fee_processing);
        try xdrEncodeGeneric(TransactionMeta, writer, self.tx_apply_processing);
        try xdrEncodeGeneric(LedgerEntryChanges, writer, self.post_tx_apply_fee_processing);
    }
};

/// UpgradeEntryMeta is an XDR Struct defined as:
///
/// ```text
/// struct UpgradeEntryMeta
/// {
///     LedgerUpgrade upgrade;
///     LedgerEntryChanges changes;
/// };
/// ```
///
pub const UpgradeEntryMeta = struct {
    upgrade: LedgerUpgrade,
    changes: LedgerEntryChanges,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !UpgradeEntryMeta {
        return UpgradeEntryMeta{
            .upgrade = try xdrDecodeGeneric(LedgerUpgrade, allocator, reader),
            .changes = try xdrDecodeGeneric(LedgerEntryChanges, allocator, reader),
        };
    }

    pub fn xdrEncode(self: UpgradeEntryMeta, writer: anytype) !void {
        try xdrEncodeGeneric(LedgerUpgrade, writer, self.upgrade);
        try xdrEncodeGeneric(LedgerEntryChanges, writer, self.changes);
    }
};

/// LedgerCloseMetaV0 is an XDR Struct defined as:
///
/// ```text
/// struct LedgerCloseMetaV0
/// {
///     LedgerHeaderHistoryEntry ledgerHeader;
///     // NB: txSet is sorted in "Hash order"
///     TransactionSet txSet;
///
///     // NB: transactions are sorted in apply order here
///     // fees for all transactions are processed first
///     // followed by applying transactions
///     TransactionResultMeta txProcessing<>;
///
///     // upgrades are applied last
///     UpgradeEntryMeta upgradesProcessing<>;
///
///     // other misc information attached to the ledger close
///     SCPHistoryEntry scpInfo<>;
/// };
/// ```
///
pub const LedgerCloseMetaV0 = struct {
    ledger_header: LedgerHeaderHistoryEntry,
    tx_set: TransactionSet,
    tx_processing: []TransactionResultMeta,
    upgrades_processing: []UpgradeEntryMeta,
    scp_info: []ScpHistoryEntry,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerCloseMetaV0 {
        return LedgerCloseMetaV0{
            .ledger_header = try xdrDecodeGeneric(LedgerHeaderHistoryEntry, allocator, reader),
            .tx_set = try xdrDecodeGeneric(TransactionSet, allocator, reader),
            .tx_processing = try xdrDecodeGeneric([]TransactionResultMeta, allocator, reader),
            .upgrades_processing = try xdrDecodeGeneric([]UpgradeEntryMeta, allocator, reader),
            .scp_info = try xdrDecodeGeneric([]ScpHistoryEntry, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LedgerCloseMetaV0, writer: anytype) !void {
        try xdrEncodeGeneric(LedgerHeaderHistoryEntry, writer, self.ledger_header);
        try xdrEncodeGeneric(TransactionSet, writer, self.tx_set);
        try xdrEncodeGeneric([]TransactionResultMeta, writer, self.tx_processing);
        try xdrEncodeGeneric([]UpgradeEntryMeta, writer, self.upgrades_processing);
        try xdrEncodeGeneric([]ScpHistoryEntry, writer, self.scp_info);
    }
};

/// LedgerCloseMetaExtV1 is an XDR Struct defined as:
///
/// ```text
/// struct LedgerCloseMetaExtV1
/// {
///     ExtensionPoint ext;
///     int64 sorobanFeeWrite1KB;
/// };
/// ```
///
pub const LedgerCloseMetaExtV1 = struct {
    ext: ExtensionPoint,
    soroban_fee_write1_kb: i64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerCloseMetaExtV1 {
        return LedgerCloseMetaExtV1{
            .ext = try xdrDecodeGeneric(ExtensionPoint, allocator, reader),
            .soroban_fee_write1_kb = try xdrDecodeGeneric(i64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LedgerCloseMetaExtV1, writer: anytype) !void {
        try xdrEncodeGeneric(ExtensionPoint, writer, self.ext);
        try xdrEncodeGeneric(i64, writer, self.soroban_fee_write1_kb);
    }
};

/// LedgerCloseMetaExt is an XDR Union defined as:
///
/// ```text
/// union LedgerCloseMetaExt switch (int v)
/// {
/// case 0:
///     void;
/// case 1:
///     LedgerCloseMetaExtV1 v1;
/// };
/// ```
///
pub const LedgerCloseMetaExt = union(enum) {
    V0,
    V1: LedgerCloseMetaExtV1,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerCloseMetaExt {
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => LedgerCloseMetaExt{ .V0 = {} },
            1 => LedgerCloseMetaExt{ .V1 = try xdrDecodeGeneric(LedgerCloseMetaExtV1, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: LedgerCloseMetaExt, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
            .V1 => |v| {
                try writer.writeInt(i32, 1, .big);
                try xdrEncodeGeneric(LedgerCloseMetaExtV1, writer, v);
            },
        }
    }
};

/// LedgerCloseMetaV1 is an XDR Struct defined as:
///
/// ```text
/// struct LedgerCloseMetaV1
/// {
///     LedgerCloseMetaExt ext;
///
///     LedgerHeaderHistoryEntry ledgerHeader;
///
///     GeneralizedTransactionSet txSet;
///
///     // NB: transactions are sorted in apply order here
///     // fees for all transactions are processed first
///     // followed by applying transactions
///     TransactionResultMeta txProcessing<>;
///
///     // upgrades are applied last
///     UpgradeEntryMeta upgradesProcessing<>;
///
///     // other misc information attached to the ledger close
///     SCPHistoryEntry scpInfo<>;
///
///     // Size in bytes of live Soroban state, to support downstream
///     // systems calculating storage fees correctly.
///     uint64 totalByteSizeOfLiveSorobanState;
///
///     // TTL and data/code keys that have been evicted at this ledger.
///     LedgerKey evictedKeys<>;
///
///     // Maintained for backwards compatibility, should never be populated.
///     LedgerEntry unused<>;
/// };
/// ```
///
pub const LedgerCloseMetaV1 = struct {
    ext: LedgerCloseMetaExt,
    ledger_header: LedgerHeaderHistoryEntry,
    tx_set: GeneralizedTransactionSet,
    tx_processing: []TransactionResultMeta,
    upgrades_processing: []UpgradeEntryMeta,
    scp_info: []ScpHistoryEntry,
    total_byte_size_of_live_soroban_state: u64,
    evicted_keys: []LedgerKey,
    unused: []LedgerEntry,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerCloseMetaV1 {
        return LedgerCloseMetaV1{
            .ext = try xdrDecodeGeneric(LedgerCloseMetaExt, allocator, reader),
            .ledger_header = try xdrDecodeGeneric(LedgerHeaderHistoryEntry, allocator, reader),
            .tx_set = try xdrDecodeGeneric(GeneralizedTransactionSet, allocator, reader),
            .tx_processing = try xdrDecodeGeneric([]TransactionResultMeta, allocator, reader),
            .upgrades_processing = try xdrDecodeGeneric([]UpgradeEntryMeta, allocator, reader),
            .scp_info = try xdrDecodeGeneric([]ScpHistoryEntry, allocator, reader),
            .total_byte_size_of_live_soroban_state = try xdrDecodeGeneric(u64, allocator, reader),
            .evicted_keys = try xdrDecodeGeneric([]LedgerKey, allocator, reader),
            .unused = try xdrDecodeGeneric([]LedgerEntry, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LedgerCloseMetaV1, writer: anytype) !void {
        try xdrEncodeGeneric(LedgerCloseMetaExt, writer, self.ext);
        try xdrEncodeGeneric(LedgerHeaderHistoryEntry, writer, self.ledger_header);
        try xdrEncodeGeneric(GeneralizedTransactionSet, writer, self.tx_set);
        try xdrEncodeGeneric([]TransactionResultMeta, writer, self.tx_processing);
        try xdrEncodeGeneric([]UpgradeEntryMeta, writer, self.upgrades_processing);
        try xdrEncodeGeneric([]ScpHistoryEntry, writer, self.scp_info);
        try xdrEncodeGeneric(u64, writer, self.total_byte_size_of_live_soroban_state);
        try xdrEncodeGeneric([]LedgerKey, writer, self.evicted_keys);
        try xdrEncodeGeneric([]LedgerEntry, writer, self.unused);
    }
};

/// LedgerCloseMetaV2 is an XDR Struct defined as:
///
/// ```text
/// struct LedgerCloseMetaV2
/// {
///     LedgerCloseMetaExt ext;
///
///     LedgerHeaderHistoryEntry ledgerHeader;
///
///     GeneralizedTransactionSet txSet;
///
///     // NB: transactions are sorted in apply order here
///     // fees for all transactions are processed first
///     // followed by applying transactions
///     TransactionResultMetaV1 txProcessing<>;
///
///     // upgrades are applied last
///     UpgradeEntryMeta upgradesProcessing<>;
///
///     // other misc information attached to the ledger close
///     SCPHistoryEntry scpInfo<>;
///
///     // Size in bytes of live Soroban state, to support downstream
///     // systems calculating storage fees correctly.
///     uint64 totalByteSizeOfLiveSorobanState;
///
///     // TTL and data/code keys that have been evicted at this ledger.
///     LedgerKey evictedKeys<>;
/// };
/// ```
///
pub const LedgerCloseMetaV2 = struct {
    ext: LedgerCloseMetaExt,
    ledger_header: LedgerHeaderHistoryEntry,
    tx_set: GeneralizedTransactionSet,
    tx_processing: []TransactionResultMetaV1,
    upgrades_processing: []UpgradeEntryMeta,
    scp_info: []ScpHistoryEntry,
    total_byte_size_of_live_soroban_state: u64,
    evicted_keys: []LedgerKey,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerCloseMetaV2 {
        return LedgerCloseMetaV2{
            .ext = try xdrDecodeGeneric(LedgerCloseMetaExt, allocator, reader),
            .ledger_header = try xdrDecodeGeneric(LedgerHeaderHistoryEntry, allocator, reader),
            .tx_set = try xdrDecodeGeneric(GeneralizedTransactionSet, allocator, reader),
            .tx_processing = try xdrDecodeGeneric([]TransactionResultMetaV1, allocator, reader),
            .upgrades_processing = try xdrDecodeGeneric([]UpgradeEntryMeta, allocator, reader),
            .scp_info = try xdrDecodeGeneric([]ScpHistoryEntry, allocator, reader),
            .total_byte_size_of_live_soroban_state = try xdrDecodeGeneric(u64, allocator, reader),
            .evicted_keys = try xdrDecodeGeneric([]LedgerKey, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LedgerCloseMetaV2, writer: anytype) !void {
        try xdrEncodeGeneric(LedgerCloseMetaExt, writer, self.ext);
        try xdrEncodeGeneric(LedgerHeaderHistoryEntry, writer, self.ledger_header);
        try xdrEncodeGeneric(GeneralizedTransactionSet, writer, self.tx_set);
        try xdrEncodeGeneric([]TransactionResultMetaV1, writer, self.tx_processing);
        try xdrEncodeGeneric([]UpgradeEntryMeta, writer, self.upgrades_processing);
        try xdrEncodeGeneric([]ScpHistoryEntry, writer, self.scp_info);
        try xdrEncodeGeneric(u64, writer, self.total_byte_size_of_live_soroban_state);
        try xdrEncodeGeneric([]LedgerKey, writer, self.evicted_keys);
    }
};

/// LedgerCloseMeta is an XDR Union defined as:
///
/// ```text
/// union LedgerCloseMeta switch (int v)
/// {
/// case 0:
///     LedgerCloseMetaV0 v0;
/// case 1:
///     LedgerCloseMetaV1 v1;
/// case 2:
///     LedgerCloseMetaV2 v2;
/// };
/// ```
///
pub const LedgerCloseMeta = union(enum) {
    V0: LedgerCloseMetaV0,
    V1: LedgerCloseMetaV1,
    V2: LedgerCloseMetaV2,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerCloseMeta {
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => LedgerCloseMeta{ .V0 = try xdrDecodeGeneric(LedgerCloseMetaV0, allocator, reader) },
            1 => LedgerCloseMeta{ .V1 = try xdrDecodeGeneric(LedgerCloseMetaV1, allocator, reader) },
            2 => LedgerCloseMeta{ .V2 = try xdrDecodeGeneric(LedgerCloseMetaV2, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: LedgerCloseMeta, writer: anytype) !void {
        switch (self) {
            .V0 => |v| {
                try writer.writeInt(i32, 0, .big);
                try xdrEncodeGeneric(LedgerCloseMetaV0, writer, v);
            },
            .V1 => |v| {
                try writer.writeInt(i32, 1, .big);
                try xdrEncodeGeneric(LedgerCloseMetaV1, writer, v);
            },
            .V2 => |v| {
                try writer.writeInt(i32, 2, .big);
                try xdrEncodeGeneric(LedgerCloseMetaV2, writer, v);
            },
        }
    }
};

/// ErrorCode is an XDR Enum defined as:
///
/// ```text
/// enum ErrorCode
/// {
///     ERR_MISC = 0, // Unspecific error
///     ERR_DATA = 1, // Malformed data
///     ERR_CONF = 2, // Misconfiguration error
///     ERR_AUTH = 3, // Authentication failure
///     ERR_LOAD = 4  // System overloaded
/// };
/// ```
///
pub const ErrorCode = enum(i32) {
    Misc = 0,
    Data = 1,
    Conf = 2,
    Auth = 3,
    Load = 4,
    _,

    pub const variants = [_]ErrorCode{
        .Misc,
        .Data,
        .Conf,
        .Auth,
        .Load,
    };

    pub fn name(self: ErrorCode) []const u8 {
        return switch (self) {
            .Misc => "Misc",
            .Data => "Data",
            .Conf => "Conf",
            .Auth => "Auth",
            .Load => "Load",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ErrorCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ErrorCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// SError is an XDR Struct defined as:
///
/// ```text
/// struct Error
/// {
///     ErrorCode code;
///     string msg<100>;
/// };
/// ```
///
pub const SError = struct {
    code: ErrorCode,
    msg: BoundedArray(u8, 100),

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SError {
        return SError{
            .code = try xdrDecodeGeneric(ErrorCode, allocator, reader),
            .msg = try xdrDecodeGeneric(BoundedArray(u8, 100), allocator, reader),
        };
    }

    pub fn xdrEncode(self: SError, writer: anytype) !void {
        try xdrEncodeGeneric(ErrorCode, writer, self.code);
        try xdrEncodeGeneric(BoundedArray(u8, 100), writer, self.msg);
    }
};

/// SendMore is an XDR Struct defined as:
///
/// ```text
/// struct SendMore
/// {
///     uint32 numMessages;
/// };
/// ```
///
pub const SendMore = struct {
    num_messages: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SendMore {
        return SendMore{
            .num_messages = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: SendMore, writer: anytype) !void {
        try xdrEncodeGeneric(u32, writer, self.num_messages);
    }
};

/// SendMoreExtended is an XDR Struct defined as:
///
/// ```text
/// struct SendMoreExtended
/// {
///     uint32 numMessages;
///     uint32 numBytes;
/// };
/// ```
///
pub const SendMoreExtended = struct {
    num_messages: u32,
    num_bytes: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SendMoreExtended {
        return SendMoreExtended{
            .num_messages = try xdrDecodeGeneric(u32, allocator, reader),
            .num_bytes = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: SendMoreExtended, writer: anytype) !void {
        try xdrEncodeGeneric(u32, writer, self.num_messages);
        try xdrEncodeGeneric(u32, writer, self.num_bytes);
    }
};

/// AuthCert is an XDR Struct defined as:
///
/// ```text
/// struct AuthCert
/// {
///     Curve25519Public pubkey;
///     uint64 expiration;
///     Signature sig;
/// };
/// ```
///
pub const AuthCert = struct {
    pubkey: Curve25519Public,
    expiration: u64,
    sig: Signature,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !AuthCert {
        return AuthCert{
            .pubkey = try xdrDecodeGeneric(Curve25519Public, allocator, reader),
            .expiration = try xdrDecodeGeneric(u64, allocator, reader),
            .sig = try xdrDecodeGeneric(Signature, allocator, reader),
        };
    }

    pub fn xdrEncode(self: AuthCert, writer: anytype) !void {
        try xdrEncodeGeneric(Curve25519Public, writer, self.pubkey);
        try xdrEncodeGeneric(u64, writer, self.expiration);
        try xdrEncodeGeneric(Signature, writer, self.sig);
    }
};

/// Hello is an XDR Struct defined as:
///
/// ```text
/// struct Hello
/// {
///     uint32 ledgerVersion;
///     uint32 overlayVersion;
///     uint32 overlayMinVersion;
///     Hash networkID;
///     string versionStr<100>;
///     int listeningPort;
///     NodeID peerID;
///     AuthCert cert;
///     uint256 nonce;
/// };
/// ```
///
pub const Hello = struct {
    ledger_version: u32,
    overlay_version: u32,
    overlay_min_version: u32,
    network_id: Hash,
    version_str: BoundedArray(u8, 100),
    listening_port: i32,
    peer_id: NodeId,
    cert: AuthCert,
    nonce: Uint256,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !Hello {
        return Hello{
            .ledger_version = try xdrDecodeGeneric(u32, allocator, reader),
            .overlay_version = try xdrDecodeGeneric(u32, allocator, reader),
            .overlay_min_version = try xdrDecodeGeneric(u32, allocator, reader),
            .network_id = try xdrDecodeGeneric(Hash, allocator, reader),
            .version_str = try xdrDecodeGeneric(BoundedArray(u8, 100), allocator, reader),
            .listening_port = try xdrDecodeGeneric(i32, allocator, reader),
            .peer_id = try xdrDecodeGeneric(NodeId, allocator, reader),
            .cert = try xdrDecodeGeneric(AuthCert, allocator, reader),
            .nonce = try xdrDecodeGeneric(Uint256, allocator, reader),
        };
    }

    pub fn xdrEncode(self: Hello, writer: anytype) !void {
        try xdrEncodeGeneric(u32, writer, self.ledger_version);
        try xdrEncodeGeneric(u32, writer, self.overlay_version);
        try xdrEncodeGeneric(u32, writer, self.overlay_min_version);
        try xdrEncodeGeneric(Hash, writer, self.network_id);
        try xdrEncodeGeneric(BoundedArray(u8, 100), writer, self.version_str);
        try xdrEncodeGeneric(i32, writer, self.listening_port);
        try xdrEncodeGeneric(NodeId, writer, self.peer_id);
        try xdrEncodeGeneric(AuthCert, writer, self.cert);
        try xdrEncodeGeneric(Uint256, writer, self.nonce);
    }
};

/// AuthMsgFlagFlowControlBytesRequested is an XDR Const defined as:
///
/// ```text
/// const AUTH_MSG_FLAG_FLOW_CONTROL_BYTES_REQUESTED = 200;
/// ```
///
pub const AUTH_MSG_FLAG_FLOW_CONTROL_BYTES_REQUESTED: u64 = 200;

/// Auth is an XDR Struct defined as:
///
/// ```text
/// struct Auth
/// {
///     int flags;
/// };
/// ```
///
pub const Auth = struct {
    flags: i32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !Auth {
        return Auth{
            .flags = try xdrDecodeGeneric(i32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: Auth, writer: anytype) !void {
        try xdrEncodeGeneric(i32, writer, self.flags);
    }
};

/// IpAddrType is an XDR Enum defined as:
///
/// ```text
/// enum IPAddrType
/// {
///     IPv4 = 0,
///     IPv6 = 1
/// };
/// ```
///
pub const IpAddrType = enum(i32) {
    IPv4 = 0,
    IPv6 = 1,
    _,

    pub const variants = [_]IpAddrType{
        .IPv4,
        .IPv6,
    };

    pub fn name(self: IpAddrType) []const u8 {
        return switch (self) {
            .IPv4 => "IPv4",
            .IPv6 => "IPv6",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !IpAddrType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: IpAddrType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// PeerAddressIp is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (IPAddrType type)
///     {
///     case IPv4:
///         opaque ipv4[4];
///     case IPv6:
///         opaque ipv6[16];
///     }
/// ```
///
pub const PeerAddressIp = union(enum) {
    IPv4: [4]u8,
    IPv6: [16]u8,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !PeerAddressIp {
        const disc = try IpAddrType.xdrDecode(allocator, reader);
        return switch (disc) {
            .IPv4 => PeerAddressIp{ .IPv4 = try xdrDecodeGeneric([4]u8, allocator, reader) },
            .IPv6 => PeerAddressIp{ .IPv6 = try xdrDecodeGeneric([16]u8, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: PeerAddressIp, writer: anytype) !void {
        const disc: IpAddrType = switch (self) {
            .IPv4 => .IPv4,
            .IPv6 => .IPv6,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .IPv4 => |v| try xdrEncodeGeneric([4]u8, writer, v),
            .IPv6 => |v| try xdrEncodeGeneric([16]u8, writer, v),
        }
    }
};

/// PeerAddress is an XDR Struct defined as:
///
/// ```text
/// struct PeerAddress
/// {
///     union switch (IPAddrType type)
///     {
///     case IPv4:
///         opaque ipv4[4];
///     case IPv6:
///         opaque ipv6[16];
///     }
///     ip;
///     uint32 port;
///     uint32 numFailures;
/// };
/// ```
///
pub const PeerAddress = struct {
    ip: PeerAddressIp,
    port: u32,
    num_failures: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !PeerAddress {
        return PeerAddress{
            .ip = try xdrDecodeGeneric(PeerAddressIp, allocator, reader),
            .port = try xdrDecodeGeneric(u32, allocator, reader),
            .num_failures = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: PeerAddress, writer: anytype) !void {
        try xdrEncodeGeneric(PeerAddressIp, writer, self.ip);
        try xdrEncodeGeneric(u32, writer, self.port);
        try xdrEncodeGeneric(u32, writer, self.num_failures);
    }
};

/// MessageType is an XDR Enum defined as:
///
/// ```text
/// enum MessageType
/// {
///     ERROR_MSG = 0,
///     AUTH = 2,
///     DONT_HAVE = 3,
///     // GET_PEERS (4) is deprecated
///
///     PEERS = 5,
///
///     GET_TX_SET = 6, // gets a particular txset by hash
///     TX_SET = 7,
///     GENERALIZED_TX_SET = 17,
///
///     TRANSACTION = 8, // pass on a tx you have heard about
///
///     // SCP
///     GET_SCP_QUORUMSET = 9,
///     SCP_QUORUMSET = 10,
///     SCP_MESSAGE = 11,
///     GET_SCP_STATE = 12,
///
///     // new messages
///     HELLO = 13,
///
///     // SURVEY_REQUEST (14) removed and replaced by TIME_SLICED_SURVEY_REQUEST
///     // SURVEY_RESPONSE (15) removed and replaced by TIME_SLICED_SURVEY_RESPONSE
///
///     SEND_MORE = 16,
///     SEND_MORE_EXTENDED = 20,
///
///     FLOOD_ADVERT = 18,
///     FLOOD_DEMAND = 19,
///
///     TIME_SLICED_SURVEY_REQUEST = 21,
///     TIME_SLICED_SURVEY_RESPONSE = 22,
///     TIME_SLICED_SURVEY_START_COLLECTING = 23,
///     TIME_SLICED_SURVEY_STOP_COLLECTING = 24
/// };
/// ```
///
pub const MessageType = enum(i32) {
    ErrorMsg = 0,
    Auth = 2,
    DontHave = 3,
    Peers = 5,
    GetTxSet = 6,
    TxSet = 7,
    GeneralizedTxSet = 17,
    Transaction = 8,
    GetScpQuorumset = 9,
    ScpQuorumset = 10,
    ScpMessage = 11,
    GetScpState = 12,
    Hello = 13,
    SendMore = 16,
    SendMoreExtended = 20,
    FloodAdvert = 18,
    FloodDemand = 19,
    TimeSlicedSurveyRequest = 21,
    TimeSlicedSurveyResponse = 22,
    TimeSlicedSurveyStartCollecting = 23,
    TimeSlicedSurveyStopCollecting = 24,
    _,

    pub const variants = [_]MessageType{
        .ErrorMsg,
        .Auth,
        .DontHave,
        .Peers,
        .GetTxSet,
        .TxSet,
        .GeneralizedTxSet,
        .Transaction,
        .GetScpQuorumset,
        .ScpQuorumset,
        .ScpMessage,
        .GetScpState,
        .Hello,
        .SendMore,
        .SendMoreExtended,
        .FloodAdvert,
        .FloodDemand,
        .TimeSlicedSurveyRequest,
        .TimeSlicedSurveyResponse,
        .TimeSlicedSurveyStartCollecting,
        .TimeSlicedSurveyStopCollecting,
    };

    pub fn name(self: MessageType) []const u8 {
        return switch (self) {
            .ErrorMsg => "ErrorMsg",
            .Auth => "Auth",
            .DontHave => "DontHave",
            .Peers => "Peers",
            .GetTxSet => "GetTxSet",
            .TxSet => "TxSet",
            .GeneralizedTxSet => "GeneralizedTxSet",
            .Transaction => "Transaction",
            .GetScpQuorumset => "GetScpQuorumset",
            .ScpQuorumset => "ScpQuorumset",
            .ScpMessage => "ScpMessage",
            .GetScpState => "GetScpState",
            .Hello => "Hello",
            .SendMore => "SendMore",
            .SendMoreExtended => "SendMoreExtended",
            .FloodAdvert => "FloodAdvert",
            .FloodDemand => "FloodDemand",
            .TimeSlicedSurveyRequest => "TimeSlicedSurveyRequest",
            .TimeSlicedSurveyResponse => "TimeSlicedSurveyResponse",
            .TimeSlicedSurveyStartCollecting => "TimeSlicedSurveyStartCollecting",
            .TimeSlicedSurveyStopCollecting => "TimeSlicedSurveyStopCollecting",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !MessageType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: MessageType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// DontHave is an XDR Struct defined as:
///
/// ```text
/// struct DontHave
/// {
///     MessageType type;
///     uint256 reqHash;
/// };
/// ```
///
pub const DontHave = struct {
    type: MessageType,
    req_hash: Uint256,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !DontHave {
        return DontHave{
            .type = try xdrDecodeGeneric(MessageType, allocator, reader),
            .req_hash = try xdrDecodeGeneric(Uint256, allocator, reader),
        };
    }

    pub fn xdrEncode(self: DontHave, writer: anytype) !void {
        try xdrEncodeGeneric(MessageType, writer, self.type);
        try xdrEncodeGeneric(Uint256, writer, self.req_hash);
    }
};

/// SurveyMessageCommandType is an XDR Enum defined as:
///
/// ```text
/// enum SurveyMessageCommandType
/// {
///     TIME_SLICED_SURVEY_TOPOLOGY = 1
/// };
/// ```
///
pub const SurveyMessageCommandType = enum(i32) {
    TimeSlicedSurveyTopology = 1,
    _,

    pub const variants = [_]SurveyMessageCommandType{
        .TimeSlicedSurveyTopology,
    };

    pub fn name(self: SurveyMessageCommandType) []const u8 {
        return switch (self) {
            .TimeSlicedSurveyTopology => "TimeSlicedSurveyTopology",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SurveyMessageCommandType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: SurveyMessageCommandType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// SurveyMessageResponseType is an XDR Enum defined as:
///
/// ```text
/// enum SurveyMessageResponseType
/// {
///     SURVEY_TOPOLOGY_RESPONSE_V2 = 2
/// };
/// ```
///
pub const SurveyMessageResponseType = enum(i32) {
    SurveyTopologyResponseV2 = 2,
    _,

    pub const variants = [_]SurveyMessageResponseType{
        .SurveyTopologyResponseV2,
    };

    pub fn name(self: SurveyMessageResponseType) []const u8 {
        return switch (self) {
            .SurveyTopologyResponseV2 => "SurveyTopologyResponseV2",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SurveyMessageResponseType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: SurveyMessageResponseType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// TimeSlicedSurveyStartCollectingMessage is an XDR Struct defined as:
///
/// ```text
/// struct TimeSlicedSurveyStartCollectingMessage
/// {
///     NodeID surveyorID;
///     uint32 nonce;
///     uint32 ledgerNum;
/// };
/// ```
///
pub const TimeSlicedSurveyStartCollectingMessage = struct {
    surveyor_id: NodeId,
    nonce: u32,
    ledger_num: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TimeSlicedSurveyStartCollectingMessage {
        return TimeSlicedSurveyStartCollectingMessage{
            .surveyor_id = try xdrDecodeGeneric(NodeId, allocator, reader),
            .nonce = try xdrDecodeGeneric(u32, allocator, reader),
            .ledger_num = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TimeSlicedSurveyStartCollectingMessage, writer: anytype) !void {
        try xdrEncodeGeneric(NodeId, writer, self.surveyor_id);
        try xdrEncodeGeneric(u32, writer, self.nonce);
        try xdrEncodeGeneric(u32, writer, self.ledger_num);
    }
};

/// SignedTimeSlicedSurveyStartCollectingMessage is an XDR Struct defined as:
///
/// ```text
/// struct SignedTimeSlicedSurveyStartCollectingMessage
/// {
///     Signature signature;
///     TimeSlicedSurveyStartCollectingMessage startCollecting;
/// };
/// ```
///
pub const SignedTimeSlicedSurveyStartCollectingMessage = struct {
    signature: Signature,
    start_collecting: TimeSlicedSurveyStartCollectingMessage,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SignedTimeSlicedSurveyStartCollectingMessage {
        return SignedTimeSlicedSurveyStartCollectingMessage{
            .signature = try xdrDecodeGeneric(Signature, allocator, reader),
            .start_collecting = try xdrDecodeGeneric(TimeSlicedSurveyStartCollectingMessage, allocator, reader),
        };
    }

    pub fn xdrEncode(self: SignedTimeSlicedSurveyStartCollectingMessage, writer: anytype) !void {
        try xdrEncodeGeneric(Signature, writer, self.signature);
        try xdrEncodeGeneric(TimeSlicedSurveyStartCollectingMessage, writer, self.start_collecting);
    }
};

/// TimeSlicedSurveyStopCollectingMessage is an XDR Struct defined as:
///
/// ```text
/// struct TimeSlicedSurveyStopCollectingMessage
/// {
///     NodeID surveyorID;
///     uint32 nonce;
///     uint32 ledgerNum;
/// };
/// ```
///
pub const TimeSlicedSurveyStopCollectingMessage = struct {
    surveyor_id: NodeId,
    nonce: u32,
    ledger_num: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TimeSlicedSurveyStopCollectingMessage {
        return TimeSlicedSurveyStopCollectingMessage{
            .surveyor_id = try xdrDecodeGeneric(NodeId, allocator, reader),
            .nonce = try xdrDecodeGeneric(u32, allocator, reader),
            .ledger_num = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TimeSlicedSurveyStopCollectingMessage, writer: anytype) !void {
        try xdrEncodeGeneric(NodeId, writer, self.surveyor_id);
        try xdrEncodeGeneric(u32, writer, self.nonce);
        try xdrEncodeGeneric(u32, writer, self.ledger_num);
    }
};

/// SignedTimeSlicedSurveyStopCollectingMessage is an XDR Struct defined as:
///
/// ```text
/// struct SignedTimeSlicedSurveyStopCollectingMessage
/// {
///     Signature signature;
///     TimeSlicedSurveyStopCollectingMessage stopCollecting;
/// };
/// ```
///
pub const SignedTimeSlicedSurveyStopCollectingMessage = struct {
    signature: Signature,
    stop_collecting: TimeSlicedSurveyStopCollectingMessage,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SignedTimeSlicedSurveyStopCollectingMessage {
        return SignedTimeSlicedSurveyStopCollectingMessage{
            .signature = try xdrDecodeGeneric(Signature, allocator, reader),
            .stop_collecting = try xdrDecodeGeneric(TimeSlicedSurveyStopCollectingMessage, allocator, reader),
        };
    }

    pub fn xdrEncode(self: SignedTimeSlicedSurveyStopCollectingMessage, writer: anytype) !void {
        try xdrEncodeGeneric(Signature, writer, self.signature);
        try xdrEncodeGeneric(TimeSlicedSurveyStopCollectingMessage, writer, self.stop_collecting);
    }
};

/// SurveyRequestMessage is an XDR Struct defined as:
///
/// ```text
/// struct SurveyRequestMessage
/// {
///     NodeID surveyorPeerID;
///     NodeID surveyedPeerID;
///     uint32 ledgerNum;
///     Curve25519Public encryptionKey;
///     SurveyMessageCommandType commandType;
/// };
/// ```
///
pub const SurveyRequestMessage = struct {
    surveyor_peer_id: NodeId,
    surveyed_peer_id: NodeId,
    ledger_num: u32,
    encryption_key: Curve25519Public,
    command_type: SurveyMessageCommandType,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SurveyRequestMessage {
        return SurveyRequestMessage{
            .surveyor_peer_id = try xdrDecodeGeneric(NodeId, allocator, reader),
            .surveyed_peer_id = try xdrDecodeGeneric(NodeId, allocator, reader),
            .ledger_num = try xdrDecodeGeneric(u32, allocator, reader),
            .encryption_key = try xdrDecodeGeneric(Curve25519Public, allocator, reader),
            .command_type = try xdrDecodeGeneric(SurveyMessageCommandType, allocator, reader),
        };
    }

    pub fn xdrEncode(self: SurveyRequestMessage, writer: anytype) !void {
        try xdrEncodeGeneric(NodeId, writer, self.surveyor_peer_id);
        try xdrEncodeGeneric(NodeId, writer, self.surveyed_peer_id);
        try xdrEncodeGeneric(u32, writer, self.ledger_num);
        try xdrEncodeGeneric(Curve25519Public, writer, self.encryption_key);
        try xdrEncodeGeneric(SurveyMessageCommandType, writer, self.command_type);
    }
};

/// TimeSlicedSurveyRequestMessage is an XDR Struct defined as:
///
/// ```text
/// struct TimeSlicedSurveyRequestMessage
/// {
///     SurveyRequestMessage request;
///     uint32 nonce;
///     uint32 inboundPeersIndex;
///     uint32 outboundPeersIndex;
/// };
/// ```
///
pub const TimeSlicedSurveyRequestMessage = struct {
    request: SurveyRequestMessage,
    nonce: u32,
    inbound_peers_index: u32,
    outbound_peers_index: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TimeSlicedSurveyRequestMessage {
        return TimeSlicedSurveyRequestMessage{
            .request = try xdrDecodeGeneric(SurveyRequestMessage, allocator, reader),
            .nonce = try xdrDecodeGeneric(u32, allocator, reader),
            .inbound_peers_index = try xdrDecodeGeneric(u32, allocator, reader),
            .outbound_peers_index = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TimeSlicedSurveyRequestMessage, writer: anytype) !void {
        try xdrEncodeGeneric(SurveyRequestMessage, writer, self.request);
        try xdrEncodeGeneric(u32, writer, self.nonce);
        try xdrEncodeGeneric(u32, writer, self.inbound_peers_index);
        try xdrEncodeGeneric(u32, writer, self.outbound_peers_index);
    }
};

/// SignedTimeSlicedSurveyRequestMessage is an XDR Struct defined as:
///
/// ```text
/// struct SignedTimeSlicedSurveyRequestMessage
/// {
///     Signature requestSignature;
///     TimeSlicedSurveyRequestMessage request;
/// };
/// ```
///
pub const SignedTimeSlicedSurveyRequestMessage = struct {
    request_signature: Signature,
    request: TimeSlicedSurveyRequestMessage,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SignedTimeSlicedSurveyRequestMessage {
        return SignedTimeSlicedSurveyRequestMessage{
            .request_signature = try xdrDecodeGeneric(Signature, allocator, reader),
            .request = try xdrDecodeGeneric(TimeSlicedSurveyRequestMessage, allocator, reader),
        };
    }

    pub fn xdrEncode(self: SignedTimeSlicedSurveyRequestMessage, writer: anytype) !void {
        try xdrEncodeGeneric(Signature, writer, self.request_signature);
        try xdrEncodeGeneric(TimeSlicedSurveyRequestMessage, writer, self.request);
    }
};

/// EncryptedBody is an XDR Typedef defined as:
///
/// ```text
/// typedef opaque EncryptedBody<64000>;
/// ```
///
pub const EncryptedBody = struct {
    value: BoundedArray(u8, 64000),

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !EncryptedBody {
        return EncryptedBody{
            .value = try xdrDecodeGeneric(BoundedArray(u8, 64000), allocator, reader),
        };
    }

    pub fn xdrEncode(self: EncryptedBody, writer: anytype) !void {
        try xdrEncodeGeneric(BoundedArray(u8, 64000), writer, self.value);
    }

    pub fn asSlice(self: EncryptedBody) []const u8 {
        return self.value.data;
    }
};

/// SurveyResponseMessage is an XDR Struct defined as:
///
/// ```text
/// struct SurveyResponseMessage
/// {
///     NodeID surveyorPeerID;
///     NodeID surveyedPeerID;
///     uint32 ledgerNum;
///     SurveyMessageCommandType commandType;
///     EncryptedBody encryptedBody;
/// };
/// ```
///
pub const SurveyResponseMessage = struct {
    surveyor_peer_id: NodeId,
    surveyed_peer_id: NodeId,
    ledger_num: u32,
    command_type: SurveyMessageCommandType,
    encrypted_body: EncryptedBody,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SurveyResponseMessage {
        return SurveyResponseMessage{
            .surveyor_peer_id = try xdrDecodeGeneric(NodeId, allocator, reader),
            .surveyed_peer_id = try xdrDecodeGeneric(NodeId, allocator, reader),
            .ledger_num = try xdrDecodeGeneric(u32, allocator, reader),
            .command_type = try xdrDecodeGeneric(SurveyMessageCommandType, allocator, reader),
            .encrypted_body = try xdrDecodeGeneric(EncryptedBody, allocator, reader),
        };
    }

    pub fn xdrEncode(self: SurveyResponseMessage, writer: anytype) !void {
        try xdrEncodeGeneric(NodeId, writer, self.surveyor_peer_id);
        try xdrEncodeGeneric(NodeId, writer, self.surveyed_peer_id);
        try xdrEncodeGeneric(u32, writer, self.ledger_num);
        try xdrEncodeGeneric(SurveyMessageCommandType, writer, self.command_type);
        try xdrEncodeGeneric(EncryptedBody, writer, self.encrypted_body);
    }
};

/// TimeSlicedSurveyResponseMessage is an XDR Struct defined as:
///
/// ```text
/// struct TimeSlicedSurveyResponseMessage
/// {
///     SurveyResponseMessage response;
///     uint32 nonce;
/// };
/// ```
///
pub const TimeSlicedSurveyResponseMessage = struct {
    response: SurveyResponseMessage,
    nonce: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TimeSlicedSurveyResponseMessage {
        return TimeSlicedSurveyResponseMessage{
            .response = try xdrDecodeGeneric(SurveyResponseMessage, allocator, reader),
            .nonce = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TimeSlicedSurveyResponseMessage, writer: anytype) !void {
        try xdrEncodeGeneric(SurveyResponseMessage, writer, self.response);
        try xdrEncodeGeneric(u32, writer, self.nonce);
    }
};

/// SignedTimeSlicedSurveyResponseMessage is an XDR Struct defined as:
///
/// ```text
/// struct SignedTimeSlicedSurveyResponseMessage
/// {
///     Signature responseSignature;
///     TimeSlicedSurveyResponseMessage response;
/// };
/// ```
///
pub const SignedTimeSlicedSurveyResponseMessage = struct {
    response_signature: Signature,
    response: TimeSlicedSurveyResponseMessage,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SignedTimeSlicedSurveyResponseMessage {
        return SignedTimeSlicedSurveyResponseMessage{
            .response_signature = try xdrDecodeGeneric(Signature, allocator, reader),
            .response = try xdrDecodeGeneric(TimeSlicedSurveyResponseMessage, allocator, reader),
        };
    }

    pub fn xdrEncode(self: SignedTimeSlicedSurveyResponseMessage, writer: anytype) !void {
        try xdrEncodeGeneric(Signature, writer, self.response_signature);
        try xdrEncodeGeneric(TimeSlicedSurveyResponseMessage, writer, self.response);
    }
};

/// PeerStats is an XDR Struct defined as:
///
/// ```text
/// struct PeerStats
/// {
///     NodeID id;
///     string versionStr<100>;
///     uint64 messagesRead;
///     uint64 messagesWritten;
///     uint64 bytesRead;
///     uint64 bytesWritten;
///     uint64 secondsConnected;
///
///     uint64 uniqueFloodBytesRecv;
///     uint64 duplicateFloodBytesRecv;
///     uint64 uniqueFetchBytesRecv;
///     uint64 duplicateFetchBytesRecv;
///
///     uint64 uniqueFloodMessageRecv;
///     uint64 duplicateFloodMessageRecv;
///     uint64 uniqueFetchMessageRecv;
///     uint64 duplicateFetchMessageRecv;
/// };
/// ```
///
pub const PeerStats = struct {
    id: NodeId,
    version_str: BoundedArray(u8, 100),
    messages_read: u64,
    messages_written: u64,
    bytes_read: u64,
    bytes_written: u64,
    seconds_connected: u64,
    unique_flood_bytes_recv: u64,
    duplicate_flood_bytes_recv: u64,
    unique_fetch_bytes_recv: u64,
    duplicate_fetch_bytes_recv: u64,
    unique_flood_message_recv: u64,
    duplicate_flood_message_recv: u64,
    unique_fetch_message_recv: u64,
    duplicate_fetch_message_recv: u64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !PeerStats {
        return PeerStats{
            .id = try xdrDecodeGeneric(NodeId, allocator, reader),
            .version_str = try xdrDecodeGeneric(BoundedArray(u8, 100), allocator, reader),
            .messages_read = try xdrDecodeGeneric(u64, allocator, reader),
            .messages_written = try xdrDecodeGeneric(u64, allocator, reader),
            .bytes_read = try xdrDecodeGeneric(u64, allocator, reader),
            .bytes_written = try xdrDecodeGeneric(u64, allocator, reader),
            .seconds_connected = try xdrDecodeGeneric(u64, allocator, reader),
            .unique_flood_bytes_recv = try xdrDecodeGeneric(u64, allocator, reader),
            .duplicate_flood_bytes_recv = try xdrDecodeGeneric(u64, allocator, reader),
            .unique_fetch_bytes_recv = try xdrDecodeGeneric(u64, allocator, reader),
            .duplicate_fetch_bytes_recv = try xdrDecodeGeneric(u64, allocator, reader),
            .unique_flood_message_recv = try xdrDecodeGeneric(u64, allocator, reader),
            .duplicate_flood_message_recv = try xdrDecodeGeneric(u64, allocator, reader),
            .unique_fetch_message_recv = try xdrDecodeGeneric(u64, allocator, reader),
            .duplicate_fetch_message_recv = try xdrDecodeGeneric(u64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: PeerStats, writer: anytype) !void {
        try xdrEncodeGeneric(NodeId, writer, self.id);
        try xdrEncodeGeneric(BoundedArray(u8, 100), writer, self.version_str);
        try xdrEncodeGeneric(u64, writer, self.messages_read);
        try xdrEncodeGeneric(u64, writer, self.messages_written);
        try xdrEncodeGeneric(u64, writer, self.bytes_read);
        try xdrEncodeGeneric(u64, writer, self.bytes_written);
        try xdrEncodeGeneric(u64, writer, self.seconds_connected);
        try xdrEncodeGeneric(u64, writer, self.unique_flood_bytes_recv);
        try xdrEncodeGeneric(u64, writer, self.duplicate_flood_bytes_recv);
        try xdrEncodeGeneric(u64, writer, self.unique_fetch_bytes_recv);
        try xdrEncodeGeneric(u64, writer, self.duplicate_fetch_bytes_recv);
        try xdrEncodeGeneric(u64, writer, self.unique_flood_message_recv);
        try xdrEncodeGeneric(u64, writer, self.duplicate_flood_message_recv);
        try xdrEncodeGeneric(u64, writer, self.unique_fetch_message_recv);
        try xdrEncodeGeneric(u64, writer, self.duplicate_fetch_message_recv);
    }
};

/// TimeSlicedNodeData is an XDR Struct defined as:
///
/// ```text
/// struct TimeSlicedNodeData
/// {
///     uint32 addedAuthenticatedPeers;
///     uint32 droppedAuthenticatedPeers;
///     uint32 totalInboundPeerCount;
///     uint32 totalOutboundPeerCount;
///
///     // SCP stats
///     uint32 p75SCPFirstToSelfLatencyMs;
///     uint32 p75SCPSelfToOtherLatencyMs;
///
///     // How many times the node lost sync in the time slice
///     uint32 lostSyncCount;
///
///     // Config data
///     bool isValidator;
///     uint32 maxInboundPeerCount;
///     uint32 maxOutboundPeerCount;
/// };
/// ```
///
pub const TimeSlicedNodeData = struct {
    added_authenticated_peers: u32,
    dropped_authenticated_peers: u32,
    total_inbound_peer_count: u32,
    total_outbound_peer_count: u32,
    p75_scp_first_to_self_latency_ms: u32,
    p75_scp_self_to_other_latency_ms: u32,
    lost_sync_count: u32,
    is_validator: bool,
    max_inbound_peer_count: u32,
    max_outbound_peer_count: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TimeSlicedNodeData {
        return TimeSlicedNodeData{
            .added_authenticated_peers = try xdrDecodeGeneric(u32, allocator, reader),
            .dropped_authenticated_peers = try xdrDecodeGeneric(u32, allocator, reader),
            .total_inbound_peer_count = try xdrDecodeGeneric(u32, allocator, reader),
            .total_outbound_peer_count = try xdrDecodeGeneric(u32, allocator, reader),
            .p75_scp_first_to_self_latency_ms = try xdrDecodeGeneric(u32, allocator, reader),
            .p75_scp_self_to_other_latency_ms = try xdrDecodeGeneric(u32, allocator, reader),
            .lost_sync_count = try xdrDecodeGeneric(u32, allocator, reader),
            .is_validator = try xdrDecodeGeneric(bool, allocator, reader),
            .max_inbound_peer_count = try xdrDecodeGeneric(u32, allocator, reader),
            .max_outbound_peer_count = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TimeSlicedNodeData, writer: anytype) !void {
        try xdrEncodeGeneric(u32, writer, self.added_authenticated_peers);
        try xdrEncodeGeneric(u32, writer, self.dropped_authenticated_peers);
        try xdrEncodeGeneric(u32, writer, self.total_inbound_peer_count);
        try xdrEncodeGeneric(u32, writer, self.total_outbound_peer_count);
        try xdrEncodeGeneric(u32, writer, self.p75_scp_first_to_self_latency_ms);
        try xdrEncodeGeneric(u32, writer, self.p75_scp_self_to_other_latency_ms);
        try xdrEncodeGeneric(u32, writer, self.lost_sync_count);
        try xdrEncodeGeneric(bool, writer, self.is_validator);
        try xdrEncodeGeneric(u32, writer, self.max_inbound_peer_count);
        try xdrEncodeGeneric(u32, writer, self.max_outbound_peer_count);
    }
};

/// TimeSlicedPeerData is an XDR Struct defined as:
///
/// ```text
/// struct TimeSlicedPeerData
/// {
///     PeerStats peerStats;
///     uint32 averageLatencyMs;
/// };
/// ```
///
pub const TimeSlicedPeerData = struct {
    peer_stats: PeerStats,
    average_latency_ms: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TimeSlicedPeerData {
        return TimeSlicedPeerData{
            .peer_stats = try xdrDecodeGeneric(PeerStats, allocator, reader),
            .average_latency_ms = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TimeSlicedPeerData, writer: anytype) !void {
        try xdrEncodeGeneric(PeerStats, writer, self.peer_stats);
        try xdrEncodeGeneric(u32, writer, self.average_latency_ms);
    }
};

/// TimeSlicedPeerDataList is an XDR Typedef defined as:
///
/// ```text
/// typedef TimeSlicedPeerData TimeSlicedPeerDataList<25>;
/// ```
///
pub const TimeSlicedPeerDataList = struct {
    value: BoundedArray(TimeSlicedPeerData, 25),

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TimeSlicedPeerDataList {
        return TimeSlicedPeerDataList{
            .value = try xdrDecodeGeneric(BoundedArray(TimeSlicedPeerData, 25), allocator, reader),
        };
    }

    pub fn xdrEncode(self: TimeSlicedPeerDataList, writer: anytype) !void {
        try xdrEncodeGeneric(BoundedArray(TimeSlicedPeerData, 25), writer, self.value);
    }

    pub fn asSlice(self: TimeSlicedPeerDataList) []const TimeSlicedPeerData {
        return self.value.data;
    }
};

/// TopologyResponseBodyV2 is an XDR Struct defined as:
///
/// ```text
/// struct TopologyResponseBodyV2
/// {
///     TimeSlicedPeerDataList inboundPeers;
///     TimeSlicedPeerDataList outboundPeers;
///     TimeSlicedNodeData nodeData;
/// };
/// ```
///
pub const TopologyResponseBodyV2 = struct {
    inbound_peers: TimeSlicedPeerDataList,
    outbound_peers: TimeSlicedPeerDataList,
    node_data: TimeSlicedNodeData,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TopologyResponseBodyV2 {
        return TopologyResponseBodyV2{
            .inbound_peers = try xdrDecodeGeneric(TimeSlicedPeerDataList, allocator, reader),
            .outbound_peers = try xdrDecodeGeneric(TimeSlicedPeerDataList, allocator, reader),
            .node_data = try xdrDecodeGeneric(TimeSlicedNodeData, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TopologyResponseBodyV2, writer: anytype) !void {
        try xdrEncodeGeneric(TimeSlicedPeerDataList, writer, self.inbound_peers);
        try xdrEncodeGeneric(TimeSlicedPeerDataList, writer, self.outbound_peers);
        try xdrEncodeGeneric(TimeSlicedNodeData, writer, self.node_data);
    }
};

/// SurveyResponseBody is an XDR Union defined as:
///
/// ```text
/// union SurveyResponseBody switch (SurveyMessageResponseType type)
/// {
/// case SURVEY_TOPOLOGY_RESPONSE_V2:
///     TopologyResponseBodyV2 topologyResponseBodyV2;
/// };
/// ```
///
pub const SurveyResponseBody = union(enum) {
    SurveyTopologyResponseV2: TopologyResponseBodyV2,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SurveyResponseBody {
        const disc = try SurveyMessageResponseType.xdrDecode(allocator, reader);
        return switch (disc) {
            .SurveyTopologyResponseV2 => SurveyResponseBody{ .SurveyTopologyResponseV2 = try xdrDecodeGeneric(TopologyResponseBodyV2, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: SurveyResponseBody, writer: anytype) !void {
        const disc: SurveyMessageResponseType = switch (self) {
            .SurveyTopologyResponseV2 => .SurveyTopologyResponseV2,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .SurveyTopologyResponseV2 => |v| try xdrEncodeGeneric(TopologyResponseBodyV2, writer, v),
        }
    }
};

/// TxAdvertVectorMaxSize is an XDR Const defined as:
///
/// ```text
/// const TX_ADVERT_VECTOR_MAX_SIZE = 1000;
/// ```
///
pub const TX_ADVERT_VECTOR_MAX_SIZE: u64 = 1000;

/// TxAdvertVector is an XDR Typedef defined as:
///
/// ```text
/// typedef Hash TxAdvertVector<TX_ADVERT_VECTOR_MAX_SIZE>;
/// ```
///
pub const TxAdvertVector = struct {
    value: BoundedArray(Hash, 1000),

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TxAdvertVector {
        return TxAdvertVector{
            .value = try xdrDecodeGeneric(BoundedArray(Hash, 1000), allocator, reader),
        };
    }

    pub fn xdrEncode(self: TxAdvertVector, writer: anytype) !void {
        try xdrEncodeGeneric(BoundedArray(Hash, 1000), writer, self.value);
    }

    pub fn asSlice(self: TxAdvertVector) []const Hash {
        return self.value.data;
    }
};

/// FloodAdvert is an XDR Struct defined as:
///
/// ```text
/// struct FloodAdvert
/// {
///     TxAdvertVector txHashes;
/// };
/// ```
///
pub const FloodAdvert = struct {
    tx_hashes: TxAdvertVector,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !FloodAdvert {
        return FloodAdvert{
            .tx_hashes = try xdrDecodeGeneric(TxAdvertVector, allocator, reader),
        };
    }

    pub fn xdrEncode(self: FloodAdvert, writer: anytype) !void {
        try xdrEncodeGeneric(TxAdvertVector, writer, self.tx_hashes);
    }
};

/// TxDemandVectorMaxSize is an XDR Const defined as:
///
/// ```text
/// const TX_DEMAND_VECTOR_MAX_SIZE = 1000;
/// ```
///
pub const TX_DEMAND_VECTOR_MAX_SIZE: u64 = 1000;

/// TxDemandVector is an XDR Typedef defined as:
///
/// ```text
/// typedef Hash TxDemandVector<TX_DEMAND_VECTOR_MAX_SIZE>;
/// ```
///
pub const TxDemandVector = struct {
    value: BoundedArray(Hash, 1000),

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TxDemandVector {
        return TxDemandVector{
            .value = try xdrDecodeGeneric(BoundedArray(Hash, 1000), allocator, reader),
        };
    }

    pub fn xdrEncode(self: TxDemandVector, writer: anytype) !void {
        try xdrEncodeGeneric(BoundedArray(Hash, 1000), writer, self.value);
    }

    pub fn asSlice(self: TxDemandVector) []const Hash {
        return self.value.data;
    }
};

/// FloodDemand is an XDR Struct defined as:
///
/// ```text
/// struct FloodDemand
/// {
///     TxDemandVector txHashes;
/// };
/// ```
///
pub const FloodDemand = struct {
    tx_hashes: TxDemandVector,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !FloodDemand {
        return FloodDemand{
            .tx_hashes = try xdrDecodeGeneric(TxDemandVector, allocator, reader),
        };
    }

    pub fn xdrEncode(self: FloodDemand, writer: anytype) !void {
        try xdrEncodeGeneric(TxDemandVector, writer, self.tx_hashes);
    }
};

/// StellarMessage is an XDR Union defined as:
///
/// ```text
/// union StellarMessage switch (MessageType type)
/// {
/// case ERROR_MSG:
///     Error error;
/// case HELLO:
///     Hello hello;
/// case AUTH:
///     Auth auth;
/// case DONT_HAVE:
///     DontHave dontHave;
/// case PEERS:
///     PeerAddress peers<100>;
///
/// case GET_TX_SET:
///     uint256 txSetHash;
/// case TX_SET:
///     TransactionSet txSet;
/// case GENERALIZED_TX_SET:
///     GeneralizedTransactionSet generalizedTxSet;
///
/// case TRANSACTION:
///     TransactionEnvelope transaction;
///
/// case TIME_SLICED_SURVEY_REQUEST:
///     SignedTimeSlicedSurveyRequestMessage signedTimeSlicedSurveyRequestMessage;
///
/// case TIME_SLICED_SURVEY_RESPONSE:
///     SignedTimeSlicedSurveyResponseMessage signedTimeSlicedSurveyResponseMessage;
///
/// case TIME_SLICED_SURVEY_START_COLLECTING:
///     SignedTimeSlicedSurveyStartCollectingMessage
///         signedTimeSlicedSurveyStartCollectingMessage;
///
/// case TIME_SLICED_SURVEY_STOP_COLLECTING:
///     SignedTimeSlicedSurveyStopCollectingMessage
///         signedTimeSlicedSurveyStopCollectingMessage;
///
/// // SCP
/// case GET_SCP_QUORUMSET:
///     uint256 qSetHash;
/// case SCP_QUORUMSET:
///     SCPQuorumSet qSet;
/// case SCP_MESSAGE:
///     SCPEnvelope envelope;
/// case GET_SCP_STATE:
///     uint32 getSCPLedgerSeq; // ledger seq requested ; if 0, requests the latest
/// case SEND_MORE:
///     SendMore sendMoreMessage;
/// case SEND_MORE_EXTENDED:
///     SendMoreExtended sendMoreExtendedMessage;
/// // Pull mode
/// case FLOOD_ADVERT:
///      FloodAdvert floodAdvert;
/// case FLOOD_DEMAND:
///      FloodDemand floodDemand;
/// };
/// ```
///
pub const StellarMessage = union(enum) {
    ErrorMsg: SError,
    Hello: Hello,
    Auth: Auth,
    DontHave: DontHave,
    Peers: BoundedArray(PeerAddress, 100),
    GetTxSet: Uint256,
    TxSet: TransactionSet,
    GeneralizedTxSet: GeneralizedTransactionSet,
    Transaction: TransactionEnvelope,
    TimeSlicedSurveyRequest: SignedTimeSlicedSurveyRequestMessage,
    TimeSlicedSurveyResponse: SignedTimeSlicedSurveyResponseMessage,
    TimeSlicedSurveyStartCollecting: SignedTimeSlicedSurveyStartCollectingMessage,
    TimeSlicedSurveyStopCollecting: SignedTimeSlicedSurveyStopCollectingMessage,
    GetScpQuorumset: Uint256,
    ScpQuorumset: ScpQuorumSet,
    ScpMessage: ScpEnvelope,
    GetScpState: u32,
    SendMore: SendMore,
    SendMoreExtended: SendMoreExtended,
    FloodAdvert: FloodAdvert,
    FloodDemand: FloodDemand,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !StellarMessage {
        const disc = try MessageType.xdrDecode(allocator, reader);
        return switch (disc) {
            .ErrorMsg => StellarMessage{ .ErrorMsg = try xdrDecodeGeneric(SError, allocator, reader) },
            .Hello => StellarMessage{ .Hello = try xdrDecodeGeneric(Hello, allocator, reader) },
            .Auth => StellarMessage{ .Auth = try xdrDecodeGeneric(Auth, allocator, reader) },
            .DontHave => StellarMessage{ .DontHave = try xdrDecodeGeneric(DontHave, allocator, reader) },
            .Peers => StellarMessage{ .Peers = try xdrDecodeGeneric(BoundedArray(PeerAddress, 100), allocator, reader) },
            .GetTxSet => StellarMessage{ .GetTxSet = try xdrDecodeGeneric(Uint256, allocator, reader) },
            .TxSet => StellarMessage{ .TxSet = try xdrDecodeGeneric(TransactionSet, allocator, reader) },
            .GeneralizedTxSet => StellarMessage{ .GeneralizedTxSet = try xdrDecodeGeneric(GeneralizedTransactionSet, allocator, reader) },
            .Transaction => StellarMessage{ .Transaction = try xdrDecodeGeneric(TransactionEnvelope, allocator, reader) },
            .TimeSlicedSurveyRequest => StellarMessage{ .TimeSlicedSurveyRequest = try xdrDecodeGeneric(SignedTimeSlicedSurveyRequestMessage, allocator, reader) },
            .TimeSlicedSurveyResponse => StellarMessage{ .TimeSlicedSurveyResponse = try xdrDecodeGeneric(SignedTimeSlicedSurveyResponseMessage, allocator, reader) },
            .TimeSlicedSurveyStartCollecting => StellarMessage{ .TimeSlicedSurveyStartCollecting = try xdrDecodeGeneric(SignedTimeSlicedSurveyStartCollectingMessage, allocator, reader) },
            .TimeSlicedSurveyStopCollecting => StellarMessage{ .TimeSlicedSurveyStopCollecting = try xdrDecodeGeneric(SignedTimeSlicedSurveyStopCollectingMessage, allocator, reader) },
            .GetScpQuorumset => StellarMessage{ .GetScpQuorumset = try xdrDecodeGeneric(Uint256, allocator, reader) },
            .ScpQuorumset => StellarMessage{ .ScpQuorumset = try xdrDecodeGeneric(ScpQuorumSet, allocator, reader) },
            .ScpMessage => StellarMessage{ .ScpMessage = try xdrDecodeGeneric(ScpEnvelope, allocator, reader) },
            .GetScpState => StellarMessage{ .GetScpState = try xdrDecodeGeneric(u32, allocator, reader) },
            .SendMore => StellarMessage{ .SendMore = try xdrDecodeGeneric(SendMore, allocator, reader) },
            .SendMoreExtended => StellarMessage{ .SendMoreExtended = try xdrDecodeGeneric(SendMoreExtended, allocator, reader) },
            .FloodAdvert => StellarMessage{ .FloodAdvert = try xdrDecodeGeneric(FloodAdvert, allocator, reader) },
            .FloodDemand => StellarMessage{ .FloodDemand = try xdrDecodeGeneric(FloodDemand, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: StellarMessage, writer: anytype) !void {
        const disc: MessageType = switch (self) {
            .ErrorMsg => .ErrorMsg,
            .Hello => .Hello,
            .Auth => .Auth,
            .DontHave => .DontHave,
            .Peers => .Peers,
            .GetTxSet => .GetTxSet,
            .TxSet => .TxSet,
            .GeneralizedTxSet => .GeneralizedTxSet,
            .Transaction => .Transaction,
            .TimeSlicedSurveyRequest => .TimeSlicedSurveyRequest,
            .TimeSlicedSurveyResponse => .TimeSlicedSurveyResponse,
            .TimeSlicedSurveyStartCollecting => .TimeSlicedSurveyStartCollecting,
            .TimeSlicedSurveyStopCollecting => .TimeSlicedSurveyStopCollecting,
            .GetScpQuorumset => .GetScpQuorumset,
            .ScpQuorumset => .ScpQuorumset,
            .ScpMessage => .ScpMessage,
            .GetScpState => .GetScpState,
            .SendMore => .SendMore,
            .SendMoreExtended => .SendMoreExtended,
            .FloodAdvert => .FloodAdvert,
            .FloodDemand => .FloodDemand,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .ErrorMsg => |v| try xdrEncodeGeneric(SError, writer, v),
            .Hello => |v| try xdrEncodeGeneric(Hello, writer, v),
            .Auth => |v| try xdrEncodeGeneric(Auth, writer, v),
            .DontHave => |v| try xdrEncodeGeneric(DontHave, writer, v),
            .Peers => |v| try xdrEncodeGeneric(BoundedArray(PeerAddress, 100), writer, v),
            .GetTxSet => |v| try xdrEncodeGeneric(Uint256, writer, v),
            .TxSet => |v| try xdrEncodeGeneric(TransactionSet, writer, v),
            .GeneralizedTxSet => |v| try xdrEncodeGeneric(GeneralizedTransactionSet, writer, v),
            .Transaction => |v| try xdrEncodeGeneric(TransactionEnvelope, writer, v),
            .TimeSlicedSurveyRequest => |v| try xdrEncodeGeneric(SignedTimeSlicedSurveyRequestMessage, writer, v),
            .TimeSlicedSurveyResponse => |v| try xdrEncodeGeneric(SignedTimeSlicedSurveyResponseMessage, writer, v),
            .TimeSlicedSurveyStartCollecting => |v| try xdrEncodeGeneric(SignedTimeSlicedSurveyStartCollectingMessage, writer, v),
            .TimeSlicedSurveyStopCollecting => |v| try xdrEncodeGeneric(SignedTimeSlicedSurveyStopCollectingMessage, writer, v),
            .GetScpQuorumset => |v| try xdrEncodeGeneric(Uint256, writer, v),
            .ScpQuorumset => |v| try xdrEncodeGeneric(ScpQuorumSet, writer, v),
            .ScpMessage => |v| try xdrEncodeGeneric(ScpEnvelope, writer, v),
            .GetScpState => |v| try xdrEncodeGeneric(u32, writer, v),
            .SendMore => |v| try xdrEncodeGeneric(SendMore, writer, v),
            .SendMoreExtended => |v| try xdrEncodeGeneric(SendMoreExtended, writer, v),
            .FloodAdvert => |v| try xdrEncodeGeneric(FloodAdvert, writer, v),
            .FloodDemand => |v| try xdrEncodeGeneric(FloodDemand, writer, v),
        }
    }
};

/// AuthenticatedMessageV0 is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///     {
///         uint64 sequence;
///         StellarMessage message;
///         HmacSha256Mac mac;
///     }
/// ```
///
pub const AuthenticatedMessageV0 = struct {
    sequence: u64,
    message: StellarMessage,
    mac: HmacSha256Mac,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !AuthenticatedMessageV0 {
        return AuthenticatedMessageV0{
            .sequence = try xdrDecodeGeneric(u64, allocator, reader),
            .message = try xdrDecodeGeneric(StellarMessage, allocator, reader),
            .mac = try xdrDecodeGeneric(HmacSha256Mac, allocator, reader),
        };
    }

    pub fn xdrEncode(self: AuthenticatedMessageV0, writer: anytype) !void {
        try xdrEncodeGeneric(u64, writer, self.sequence);
        try xdrEncodeGeneric(StellarMessage, writer, self.message);
        try xdrEncodeGeneric(HmacSha256Mac, writer, self.mac);
    }
};

/// AuthenticatedMessage is an XDR Union defined as:
///
/// ```text
/// union AuthenticatedMessage switch (uint32 v)
/// {
/// case 0:
///     struct
///     {
///         uint64 sequence;
///         StellarMessage message;
///         HmacSha256Mac mac;
///     } v0;
/// };
/// ```
///
pub const AuthenticatedMessage = union(enum) {
    V0: AuthenticatedMessageV0,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !AuthenticatedMessage {
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => AuthenticatedMessage{ .V0 = try xdrDecodeGeneric(AuthenticatedMessageV0, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: AuthenticatedMessage, writer: anytype) !void {
        switch (self) {
            .V0 => |v| {
                try writer.writeInt(i32, 0, .big);
                try xdrEncodeGeneric(AuthenticatedMessageV0, writer, v);
            },
        }
    }
};

/// MaxOpsPerTx is an XDR Const defined as:
///
/// ```text
/// const MAX_OPS_PER_TX = 100;
/// ```
///
pub const MAX_OPS_PER_TX: u64 = 100;

/// LiquidityPoolParameters is an XDR Union defined as:
///
/// ```text
/// union LiquidityPoolParameters switch (LiquidityPoolType type)
/// {
/// case LIQUIDITY_POOL_CONSTANT_PRODUCT:
///     LiquidityPoolConstantProductParameters constantProduct;
/// };
/// ```
///
pub const LiquidityPoolParameters = union(enum) {
    LiquidityPoolConstantProduct: LiquidityPoolConstantProductParameters,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LiquidityPoolParameters {
        const disc = try LiquidityPoolType.xdrDecode(allocator, reader);
        return switch (disc) {
            .LiquidityPoolConstantProduct => LiquidityPoolParameters{ .LiquidityPoolConstantProduct = try xdrDecodeGeneric(LiquidityPoolConstantProductParameters, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: LiquidityPoolParameters, writer: anytype) !void {
        const disc: LiquidityPoolType = switch (self) {
            .LiquidityPoolConstantProduct => .LiquidityPoolConstantProduct,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .LiquidityPoolConstantProduct => |v| try xdrEncodeGeneric(LiquidityPoolConstantProductParameters, writer, v),
        }
    }
};

/// MuxedAccountMed25519 is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///     {
///         uint64 id;
///         uint256 ed25519;
///     }
/// ```
///
pub const MuxedAccountMed25519 = struct {
    id: u64,
    ed25519: Uint256,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !MuxedAccountMed25519 {
        return MuxedAccountMed25519{
            .id = try xdrDecodeGeneric(u64, allocator, reader),
            .ed25519 = try xdrDecodeGeneric(Uint256, allocator, reader),
        };
    }

    pub fn xdrEncode(self: MuxedAccountMed25519, writer: anytype) !void {
        try xdrEncodeGeneric(u64, writer, self.id);
        try xdrEncodeGeneric(Uint256, writer, self.ed25519);
    }
};

/// MuxedAccount is an XDR Union defined as:
///
/// ```text
/// union MuxedAccount switch (CryptoKeyType type)
/// {
/// case KEY_TYPE_ED25519:
///     uint256 ed25519;
/// case KEY_TYPE_MUXED_ED25519:
///     struct
///     {
///         uint64 id;
///         uint256 ed25519;
///     } med25519;
/// };
/// ```
///
pub const MuxedAccount = union(enum) {
    Ed25519: Uint256,
    MuxedEd25519: MuxedAccountMed25519,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !MuxedAccount {
        const disc = try CryptoKeyType.xdrDecode(allocator, reader);
        return switch (disc) {
            .Ed25519 => MuxedAccount{ .Ed25519 = try xdrDecodeGeneric(Uint256, allocator, reader) },
            .MuxedEd25519 => MuxedAccount{ .MuxedEd25519 = try xdrDecodeGeneric(MuxedAccountMed25519, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: MuxedAccount, writer: anytype) !void {
        const disc: CryptoKeyType = switch (self) {
            .Ed25519 => .Ed25519,
            .MuxedEd25519 => .MuxedEd25519,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Ed25519 => |v| try xdrEncodeGeneric(Uint256, writer, v),
            .MuxedEd25519 => |v| try xdrEncodeGeneric(MuxedAccountMed25519, writer, v),
        }
    }
};

/// DecoratedSignature is an XDR Struct defined as:
///
/// ```text
/// struct DecoratedSignature
/// {
///     SignatureHint hint;  // last 4 bytes of the public key, used as a hint
///     Signature signature; // actual signature
/// };
/// ```
///
pub const DecoratedSignature = struct {
    hint: SignatureHint,
    signature: Signature,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !DecoratedSignature {
        return DecoratedSignature{
            .hint = try xdrDecodeGeneric(SignatureHint, allocator, reader),
            .signature = try xdrDecodeGeneric(Signature, allocator, reader),
        };
    }

    pub fn xdrEncode(self: DecoratedSignature, writer: anytype) !void {
        try xdrEncodeGeneric(SignatureHint, writer, self.hint);
        try xdrEncodeGeneric(Signature, writer, self.signature);
    }
};

/// OperationType is an XDR Enum defined as:
///
/// ```text
/// enum OperationType
/// {
///     CREATE_ACCOUNT = 0,
///     PAYMENT = 1,
///     PATH_PAYMENT_STRICT_RECEIVE = 2,
///     MANAGE_SELL_OFFER = 3,
///     CREATE_PASSIVE_SELL_OFFER = 4,
///     SET_OPTIONS = 5,
///     CHANGE_TRUST = 6,
///     ALLOW_TRUST = 7,
///     ACCOUNT_MERGE = 8,
///     INFLATION = 9,
///     MANAGE_DATA = 10,
///     BUMP_SEQUENCE = 11,
///     MANAGE_BUY_OFFER = 12,
///     PATH_PAYMENT_STRICT_SEND = 13,
///     CREATE_CLAIMABLE_BALANCE = 14,
///     CLAIM_CLAIMABLE_BALANCE = 15,
///     BEGIN_SPONSORING_FUTURE_RESERVES = 16,
///     END_SPONSORING_FUTURE_RESERVES = 17,
///     REVOKE_SPONSORSHIP = 18,
///     CLAWBACK = 19,
///     CLAWBACK_CLAIMABLE_BALANCE = 20,
///     SET_TRUST_LINE_FLAGS = 21,
///     LIQUIDITY_POOL_DEPOSIT = 22,
///     LIQUIDITY_POOL_WITHDRAW = 23,
///     INVOKE_HOST_FUNCTION = 24,
///     EXTEND_FOOTPRINT_TTL = 25,
///     RESTORE_FOOTPRINT = 26
/// };
/// ```
///
pub const OperationType = enum(i32) {
    CreateAccount = 0,
    Payment = 1,
    PathPaymentStrictReceive = 2,
    ManageSellOffer = 3,
    CreatePassiveSellOffer = 4,
    SetOptions = 5,
    ChangeTrust = 6,
    AllowTrust = 7,
    AccountMerge = 8,
    Inflation = 9,
    ManageData = 10,
    BumpSequence = 11,
    ManageBuyOffer = 12,
    PathPaymentStrictSend = 13,
    CreateClaimableBalance = 14,
    ClaimClaimableBalance = 15,
    BeginSponsoringFutureReserves = 16,
    EndSponsoringFutureReserves = 17,
    RevokeSponsorship = 18,
    Clawback = 19,
    ClawbackClaimableBalance = 20,
    SetTrustLineFlags = 21,
    LiquidityPoolDeposit = 22,
    LiquidityPoolWithdraw = 23,
    InvokeHostFunction = 24,
    ExtendFootprintTtl = 25,
    RestoreFootprint = 26,
    _,

    pub const variants = [_]OperationType{
        .CreateAccount,
        .Payment,
        .PathPaymentStrictReceive,
        .ManageSellOffer,
        .CreatePassiveSellOffer,
        .SetOptions,
        .ChangeTrust,
        .AllowTrust,
        .AccountMerge,
        .Inflation,
        .ManageData,
        .BumpSequence,
        .ManageBuyOffer,
        .PathPaymentStrictSend,
        .CreateClaimableBalance,
        .ClaimClaimableBalance,
        .BeginSponsoringFutureReserves,
        .EndSponsoringFutureReserves,
        .RevokeSponsorship,
        .Clawback,
        .ClawbackClaimableBalance,
        .SetTrustLineFlags,
        .LiquidityPoolDeposit,
        .LiquidityPoolWithdraw,
        .InvokeHostFunction,
        .ExtendFootprintTtl,
        .RestoreFootprint,
    };

    pub fn name(self: OperationType) []const u8 {
        return switch (self) {
            .CreateAccount => "CreateAccount",
            .Payment => "Payment",
            .PathPaymentStrictReceive => "PathPaymentStrictReceive",
            .ManageSellOffer => "ManageSellOffer",
            .CreatePassiveSellOffer => "CreatePassiveSellOffer",
            .SetOptions => "SetOptions",
            .ChangeTrust => "ChangeTrust",
            .AllowTrust => "AllowTrust",
            .AccountMerge => "AccountMerge",
            .Inflation => "Inflation",
            .ManageData => "ManageData",
            .BumpSequence => "BumpSequence",
            .ManageBuyOffer => "ManageBuyOffer",
            .PathPaymentStrictSend => "PathPaymentStrictSend",
            .CreateClaimableBalance => "CreateClaimableBalance",
            .ClaimClaimableBalance => "ClaimClaimableBalance",
            .BeginSponsoringFutureReserves => "BeginSponsoringFutureReserves",
            .EndSponsoringFutureReserves => "EndSponsoringFutureReserves",
            .RevokeSponsorship => "RevokeSponsorship",
            .Clawback => "Clawback",
            .ClawbackClaimableBalance => "ClawbackClaimableBalance",
            .SetTrustLineFlags => "SetTrustLineFlags",
            .LiquidityPoolDeposit => "LiquidityPoolDeposit",
            .LiquidityPoolWithdraw => "LiquidityPoolWithdraw",
            .InvokeHostFunction => "InvokeHostFunction",
            .ExtendFootprintTtl => "ExtendFootprintTtl",
            .RestoreFootprint => "RestoreFootprint",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !OperationType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: OperationType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// CreateAccountOp is an XDR Struct defined as:
///
/// ```text
/// struct CreateAccountOp
/// {
///     AccountID destination; // account to create
///     int64 startingBalance; // amount they end up with
/// };
/// ```
///
pub const CreateAccountOp = struct {
    destination: AccountId,
    starting_balance: i64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !CreateAccountOp {
        return CreateAccountOp{
            .destination = try xdrDecodeGeneric(AccountId, allocator, reader),
            .starting_balance = try xdrDecodeGeneric(i64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: CreateAccountOp, writer: anytype) !void {
        try xdrEncodeGeneric(AccountId, writer, self.destination);
        try xdrEncodeGeneric(i64, writer, self.starting_balance);
    }
};

/// PaymentOp is an XDR Struct defined as:
///
/// ```text
/// struct PaymentOp
/// {
///     MuxedAccount destination; // recipient of the payment
///     Asset asset;              // what they end up with
///     int64 amount;             // amount they end up with
/// };
/// ```
///
pub const PaymentOp = struct {
    destination: MuxedAccount,
    asset: Asset,
    amount: i64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !PaymentOp {
        return PaymentOp{
            .destination = try xdrDecodeGeneric(MuxedAccount, allocator, reader),
            .asset = try xdrDecodeGeneric(Asset, allocator, reader),
            .amount = try xdrDecodeGeneric(i64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: PaymentOp, writer: anytype) !void {
        try xdrEncodeGeneric(MuxedAccount, writer, self.destination);
        try xdrEncodeGeneric(Asset, writer, self.asset);
        try xdrEncodeGeneric(i64, writer, self.amount);
    }
};

/// PathPaymentStrictReceiveOp is an XDR Struct defined as:
///
/// ```text
/// struct PathPaymentStrictReceiveOp
/// {
///     Asset sendAsset; // asset we pay with
///     int64 sendMax;   // the maximum amount of sendAsset to
///                      // send (excluding fees).
///                      // The operation will fail if can't be met
///
///     MuxedAccount destination; // recipient of the payment
///     Asset destAsset;          // what they end up with
///     int64 destAmount;         // amount they end up with
///
///     Asset path<5>; // additional hops it must go through to get there
/// };
/// ```
///
pub const PathPaymentStrictReceiveOp = struct {
    send_asset: Asset,
    send_max: i64,
    destination: MuxedAccount,
    dest_asset: Asset,
    dest_amount: i64,
    path: BoundedArray(Asset, 5),

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !PathPaymentStrictReceiveOp {
        return PathPaymentStrictReceiveOp{
            .send_asset = try xdrDecodeGeneric(Asset, allocator, reader),
            .send_max = try xdrDecodeGeneric(i64, allocator, reader),
            .destination = try xdrDecodeGeneric(MuxedAccount, allocator, reader),
            .dest_asset = try xdrDecodeGeneric(Asset, allocator, reader),
            .dest_amount = try xdrDecodeGeneric(i64, allocator, reader),
            .path = try xdrDecodeGeneric(BoundedArray(Asset, 5), allocator, reader),
        };
    }

    pub fn xdrEncode(self: PathPaymentStrictReceiveOp, writer: anytype) !void {
        try xdrEncodeGeneric(Asset, writer, self.send_asset);
        try xdrEncodeGeneric(i64, writer, self.send_max);
        try xdrEncodeGeneric(MuxedAccount, writer, self.destination);
        try xdrEncodeGeneric(Asset, writer, self.dest_asset);
        try xdrEncodeGeneric(i64, writer, self.dest_amount);
        try xdrEncodeGeneric(BoundedArray(Asset, 5), writer, self.path);
    }
};

/// PathPaymentStrictSendOp is an XDR Struct defined as:
///
/// ```text
/// struct PathPaymentStrictSendOp
/// {
///     Asset sendAsset;  // asset we pay with
///     int64 sendAmount; // amount of sendAsset to send (excluding fees)
///
///     MuxedAccount destination; // recipient of the payment
///     Asset destAsset;          // what they end up with
///     int64 destMin;            // the minimum amount of dest asset to
///                               // be received
///                               // The operation will fail if it can't be met
///
///     Asset path<5>; // additional hops it must go through to get there
/// };
/// ```
///
pub const PathPaymentStrictSendOp = struct {
    send_asset: Asset,
    send_amount: i64,
    destination: MuxedAccount,
    dest_asset: Asset,
    dest_min: i64,
    path: BoundedArray(Asset, 5),

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !PathPaymentStrictSendOp {
        return PathPaymentStrictSendOp{
            .send_asset = try xdrDecodeGeneric(Asset, allocator, reader),
            .send_amount = try xdrDecodeGeneric(i64, allocator, reader),
            .destination = try xdrDecodeGeneric(MuxedAccount, allocator, reader),
            .dest_asset = try xdrDecodeGeneric(Asset, allocator, reader),
            .dest_min = try xdrDecodeGeneric(i64, allocator, reader),
            .path = try xdrDecodeGeneric(BoundedArray(Asset, 5), allocator, reader),
        };
    }

    pub fn xdrEncode(self: PathPaymentStrictSendOp, writer: anytype) !void {
        try xdrEncodeGeneric(Asset, writer, self.send_asset);
        try xdrEncodeGeneric(i64, writer, self.send_amount);
        try xdrEncodeGeneric(MuxedAccount, writer, self.destination);
        try xdrEncodeGeneric(Asset, writer, self.dest_asset);
        try xdrEncodeGeneric(i64, writer, self.dest_min);
        try xdrEncodeGeneric(BoundedArray(Asset, 5), writer, self.path);
    }
};

/// ManageSellOfferOp is an XDR Struct defined as:
///
/// ```text
/// struct ManageSellOfferOp
/// {
///     Asset selling;
///     Asset buying;
///     int64 amount; // amount being sold. if set to 0, delete the offer
///     Price price;  // price of thing being sold in terms of what you are buying
///
///     // 0=create a new offer, otherwise edit an existing offer
///     int64 offerID;
/// };
/// ```
///
pub const ManageSellOfferOp = struct {
    selling: Asset,
    buying: Asset,
    amount: i64,
    price: Price,
    offer_id: i64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ManageSellOfferOp {
        return ManageSellOfferOp{
            .selling = try xdrDecodeGeneric(Asset, allocator, reader),
            .buying = try xdrDecodeGeneric(Asset, allocator, reader),
            .amount = try xdrDecodeGeneric(i64, allocator, reader),
            .price = try xdrDecodeGeneric(Price, allocator, reader),
            .offer_id = try xdrDecodeGeneric(i64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ManageSellOfferOp, writer: anytype) !void {
        try xdrEncodeGeneric(Asset, writer, self.selling);
        try xdrEncodeGeneric(Asset, writer, self.buying);
        try xdrEncodeGeneric(i64, writer, self.amount);
        try xdrEncodeGeneric(Price, writer, self.price);
        try xdrEncodeGeneric(i64, writer, self.offer_id);
    }
};

/// ManageBuyOfferOp is an XDR Struct defined as:
///
/// ```text
/// struct ManageBuyOfferOp
/// {
///     Asset selling;
///     Asset buying;
///     int64 buyAmount; // amount being bought. if set to 0, delete the offer
///     Price price;     // price of thing being bought in terms of what you are
///                      // selling
///
///     // 0=create a new offer, otherwise edit an existing offer
///     int64 offerID;
/// };
/// ```
///
pub const ManageBuyOfferOp = struct {
    selling: Asset,
    buying: Asset,
    buy_amount: i64,
    price: Price,
    offer_id: i64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ManageBuyOfferOp {
        return ManageBuyOfferOp{
            .selling = try xdrDecodeGeneric(Asset, allocator, reader),
            .buying = try xdrDecodeGeneric(Asset, allocator, reader),
            .buy_amount = try xdrDecodeGeneric(i64, allocator, reader),
            .price = try xdrDecodeGeneric(Price, allocator, reader),
            .offer_id = try xdrDecodeGeneric(i64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ManageBuyOfferOp, writer: anytype) !void {
        try xdrEncodeGeneric(Asset, writer, self.selling);
        try xdrEncodeGeneric(Asset, writer, self.buying);
        try xdrEncodeGeneric(i64, writer, self.buy_amount);
        try xdrEncodeGeneric(Price, writer, self.price);
        try xdrEncodeGeneric(i64, writer, self.offer_id);
    }
};

/// CreatePassiveSellOfferOp is an XDR Struct defined as:
///
/// ```text
/// struct CreatePassiveSellOfferOp
/// {
///     Asset selling; // A
///     Asset buying;  // B
///     int64 amount;  // amount taker gets
///     Price price;   // cost of A in terms of B
/// };
/// ```
///
pub const CreatePassiveSellOfferOp = struct {
    selling: Asset,
    buying: Asset,
    amount: i64,
    price: Price,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !CreatePassiveSellOfferOp {
        return CreatePassiveSellOfferOp{
            .selling = try xdrDecodeGeneric(Asset, allocator, reader),
            .buying = try xdrDecodeGeneric(Asset, allocator, reader),
            .amount = try xdrDecodeGeneric(i64, allocator, reader),
            .price = try xdrDecodeGeneric(Price, allocator, reader),
        };
    }

    pub fn xdrEncode(self: CreatePassiveSellOfferOp, writer: anytype) !void {
        try xdrEncodeGeneric(Asset, writer, self.selling);
        try xdrEncodeGeneric(Asset, writer, self.buying);
        try xdrEncodeGeneric(i64, writer, self.amount);
        try xdrEncodeGeneric(Price, writer, self.price);
    }
};

/// SetOptionsOp is an XDR Struct defined as:
///
/// ```text
/// struct SetOptionsOp
/// {
///     AccountID* inflationDest; // sets the inflation destination
///
///     uint32* clearFlags; // which flags to clear
///     uint32* setFlags;   // which flags to set
///
///     // account threshold manipulation
///     uint32* masterWeight; // weight of the master account
///     uint32* lowThreshold;
///     uint32* medThreshold;
///     uint32* highThreshold;
///
///     string32* homeDomain; // sets the home domain
///
///     // Add, update or remove a signer for the account
///     // signer is deleted if the weight is 0
///     Signer* signer;
/// };
/// ```
///
pub const SetOptionsOp = struct {
    inflation_dest: ?AccountId,
    clear_flags: ?u32,
    set_flags: ?u32,
    master_weight: ?u32,
    low_threshold: ?u32,
    med_threshold: ?u32,
    high_threshold: ?u32,
    home_domain: ?String32,
    signer: ?Signer,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SetOptionsOp {
        return SetOptionsOp{
            .inflation_dest = try xdrDecodeGeneric(?AccountId, allocator, reader),
            .clear_flags = try xdrDecodeGeneric(?u32, allocator, reader),
            .set_flags = try xdrDecodeGeneric(?u32, allocator, reader),
            .master_weight = try xdrDecodeGeneric(?u32, allocator, reader),
            .low_threshold = try xdrDecodeGeneric(?u32, allocator, reader),
            .med_threshold = try xdrDecodeGeneric(?u32, allocator, reader),
            .high_threshold = try xdrDecodeGeneric(?u32, allocator, reader),
            .home_domain = try xdrDecodeGeneric(?String32, allocator, reader),
            .signer = try xdrDecodeGeneric(?Signer, allocator, reader),
        };
    }

    pub fn xdrEncode(self: SetOptionsOp, writer: anytype) !void {
        try xdrEncodeGeneric(?AccountId, writer, self.inflation_dest);
        try xdrEncodeGeneric(?u32, writer, self.clear_flags);
        try xdrEncodeGeneric(?u32, writer, self.set_flags);
        try xdrEncodeGeneric(?u32, writer, self.master_weight);
        try xdrEncodeGeneric(?u32, writer, self.low_threshold);
        try xdrEncodeGeneric(?u32, writer, self.med_threshold);
        try xdrEncodeGeneric(?u32, writer, self.high_threshold);
        try xdrEncodeGeneric(?String32, writer, self.home_domain);
        try xdrEncodeGeneric(?Signer, writer, self.signer);
    }
};

/// ChangeTrustAsset is an XDR Union defined as:
///
/// ```text
/// union ChangeTrustAsset switch (AssetType type)
/// {
/// case ASSET_TYPE_NATIVE: // Not credit
///     void;
///
/// case ASSET_TYPE_CREDIT_ALPHANUM4:
///     AlphaNum4 alphaNum4;
///
/// case ASSET_TYPE_CREDIT_ALPHANUM12:
///     AlphaNum12 alphaNum12;
///
/// case ASSET_TYPE_POOL_SHARE:
///     LiquidityPoolParameters liquidityPool;
///
///     // add other asset types here in the future
/// };
/// ```
///
pub const ChangeTrustAsset = union(enum) {
    Native,
    CreditAlphanum4: AlphaNum4,
    CreditAlphanum12: AlphaNum12,
    PoolShare: LiquidityPoolParameters,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ChangeTrustAsset {
        const disc = try AssetType.xdrDecode(allocator, reader);
        return switch (disc) {
            .Native => ChangeTrustAsset{ .Native = {} },
            .CreditAlphanum4 => ChangeTrustAsset{ .CreditAlphanum4 = try xdrDecodeGeneric(AlphaNum4, allocator, reader) },
            .CreditAlphanum12 => ChangeTrustAsset{ .CreditAlphanum12 = try xdrDecodeGeneric(AlphaNum12, allocator, reader) },
            .PoolShare => ChangeTrustAsset{ .PoolShare = try xdrDecodeGeneric(LiquidityPoolParameters, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ChangeTrustAsset, writer: anytype) !void {
        const disc: AssetType = switch (self) {
            .Native => .Native,
            .CreditAlphanum4 => .CreditAlphanum4,
            .CreditAlphanum12 => .CreditAlphanum12,
            .PoolShare => .PoolShare,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Native => {},
            .CreditAlphanum4 => |v| try xdrEncodeGeneric(AlphaNum4, writer, v),
            .CreditAlphanum12 => |v| try xdrEncodeGeneric(AlphaNum12, writer, v),
            .PoolShare => |v| try xdrEncodeGeneric(LiquidityPoolParameters, writer, v),
        }
    }
};

/// ChangeTrustOp is an XDR Struct defined as:
///
/// ```text
/// struct ChangeTrustOp
/// {
///     ChangeTrustAsset line;
///
///     // if limit is set to 0, deletes the trust line
///     int64 limit;
/// };
/// ```
///
pub const ChangeTrustOp = struct {
    line: ChangeTrustAsset,
    limit: i64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ChangeTrustOp {
        return ChangeTrustOp{
            .line = try xdrDecodeGeneric(ChangeTrustAsset, allocator, reader),
            .limit = try xdrDecodeGeneric(i64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ChangeTrustOp, writer: anytype) !void {
        try xdrEncodeGeneric(ChangeTrustAsset, writer, self.line);
        try xdrEncodeGeneric(i64, writer, self.limit);
    }
};

/// AllowTrustOp is an XDR Struct defined as:
///
/// ```text
/// struct AllowTrustOp
/// {
///     AccountID trustor;
///     AssetCode asset;
///
///     // One of 0, AUTHORIZED_FLAG, or AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG
///     uint32 authorize;
/// };
/// ```
///
pub const AllowTrustOp = struct {
    trustor: AccountId,
    asset: AssetCode,
    authorize: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !AllowTrustOp {
        return AllowTrustOp{
            .trustor = try xdrDecodeGeneric(AccountId, allocator, reader),
            .asset = try xdrDecodeGeneric(AssetCode, allocator, reader),
            .authorize = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: AllowTrustOp, writer: anytype) !void {
        try xdrEncodeGeneric(AccountId, writer, self.trustor);
        try xdrEncodeGeneric(AssetCode, writer, self.asset);
        try xdrEncodeGeneric(u32, writer, self.authorize);
    }
};

/// ManageDataOp is an XDR Struct defined as:
///
/// ```text
/// struct ManageDataOp
/// {
///     string64 dataName;
///     DataValue* dataValue; // set to null to clear
/// };
/// ```
///
pub const ManageDataOp = struct {
    data_name: String64,
    data_value: ?DataValue,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ManageDataOp {
        return ManageDataOp{
            .data_name = try xdrDecodeGeneric(String64, allocator, reader),
            .data_value = try xdrDecodeGeneric(?DataValue, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ManageDataOp, writer: anytype) !void {
        try xdrEncodeGeneric(String64, writer, self.data_name);
        try xdrEncodeGeneric(?DataValue, writer, self.data_value);
    }
};

/// BumpSequenceOp is an XDR Struct defined as:
///
/// ```text
/// struct BumpSequenceOp
/// {
///     SequenceNumber bumpTo;
/// };
/// ```
///
pub const BumpSequenceOp = struct {
    bump_to: SequenceNumber,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !BumpSequenceOp {
        return BumpSequenceOp{
            .bump_to = try xdrDecodeGeneric(SequenceNumber, allocator, reader),
        };
    }

    pub fn xdrEncode(self: BumpSequenceOp, writer: anytype) !void {
        try xdrEncodeGeneric(SequenceNumber, writer, self.bump_to);
    }
};

/// CreateClaimableBalanceOp is an XDR Struct defined as:
///
/// ```text
/// struct CreateClaimableBalanceOp
/// {
///     Asset asset;
///     int64 amount;
///     Claimant claimants<10>;
/// };
/// ```
///
pub const CreateClaimableBalanceOp = struct {
    asset: Asset,
    amount: i64,
    claimants: BoundedArray(Claimant, 10),

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !CreateClaimableBalanceOp {
        return CreateClaimableBalanceOp{
            .asset = try xdrDecodeGeneric(Asset, allocator, reader),
            .amount = try xdrDecodeGeneric(i64, allocator, reader),
            .claimants = try xdrDecodeGeneric(BoundedArray(Claimant, 10), allocator, reader),
        };
    }

    pub fn xdrEncode(self: CreateClaimableBalanceOp, writer: anytype) !void {
        try xdrEncodeGeneric(Asset, writer, self.asset);
        try xdrEncodeGeneric(i64, writer, self.amount);
        try xdrEncodeGeneric(BoundedArray(Claimant, 10), writer, self.claimants);
    }
};

/// ClaimClaimableBalanceOp is an XDR Struct defined as:
///
/// ```text
/// struct ClaimClaimableBalanceOp
/// {
///     ClaimableBalanceID balanceID;
/// };
/// ```
///
pub const ClaimClaimableBalanceOp = struct {
    balance_id: ClaimableBalanceId,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ClaimClaimableBalanceOp {
        return ClaimClaimableBalanceOp{
            .balance_id = try xdrDecodeGeneric(ClaimableBalanceId, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ClaimClaimableBalanceOp, writer: anytype) !void {
        try xdrEncodeGeneric(ClaimableBalanceId, writer, self.balance_id);
    }
};

/// BeginSponsoringFutureReservesOp is an XDR Struct defined as:
///
/// ```text
/// struct BeginSponsoringFutureReservesOp
/// {
///     AccountID sponsoredID;
/// };
/// ```
///
pub const BeginSponsoringFutureReservesOp = struct {
    sponsored_id: AccountId,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !BeginSponsoringFutureReservesOp {
        return BeginSponsoringFutureReservesOp{
            .sponsored_id = try xdrDecodeGeneric(AccountId, allocator, reader),
        };
    }

    pub fn xdrEncode(self: BeginSponsoringFutureReservesOp, writer: anytype) !void {
        try xdrEncodeGeneric(AccountId, writer, self.sponsored_id);
    }
};

/// RevokeSponsorshipType is an XDR Enum defined as:
///
/// ```text
/// enum RevokeSponsorshipType
/// {
///     REVOKE_SPONSORSHIP_LEDGER_ENTRY = 0,
///     REVOKE_SPONSORSHIP_SIGNER = 1
/// };
/// ```
///
pub const RevokeSponsorshipType = enum(i32) {
    LedgerEntry = 0,
    Signer = 1,
    _,

    pub const variants = [_]RevokeSponsorshipType{
        .LedgerEntry,
        .Signer,
    };

    pub fn name(self: RevokeSponsorshipType) []const u8 {
        return switch (self) {
            .LedgerEntry => "LedgerEntry",
            .Signer => "Signer",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !RevokeSponsorshipType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: RevokeSponsorshipType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// RevokeSponsorshipOpSigner is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///     {
///         AccountID accountID;
///         SignerKey signerKey;
///     }
/// ```
///
pub const RevokeSponsorshipOpSigner = struct {
    account_id: AccountId,
    signer_key: SignerKey,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !RevokeSponsorshipOpSigner {
        return RevokeSponsorshipOpSigner{
            .account_id = try xdrDecodeGeneric(AccountId, allocator, reader),
            .signer_key = try xdrDecodeGeneric(SignerKey, allocator, reader),
        };
    }

    pub fn xdrEncode(self: RevokeSponsorshipOpSigner, writer: anytype) !void {
        try xdrEncodeGeneric(AccountId, writer, self.account_id);
        try xdrEncodeGeneric(SignerKey, writer, self.signer_key);
    }
};

/// RevokeSponsorshipOp is an XDR Union defined as:
///
/// ```text
/// union RevokeSponsorshipOp switch (RevokeSponsorshipType type)
/// {
/// case REVOKE_SPONSORSHIP_LEDGER_ENTRY:
///     LedgerKey ledgerKey;
/// case REVOKE_SPONSORSHIP_SIGNER:
///     struct
///     {
///         AccountID accountID;
///         SignerKey signerKey;
///     } signer;
/// };
/// ```
///
pub const RevokeSponsorshipOp = union(enum) {
    LedgerEntry: LedgerKey,
    Signer: RevokeSponsorshipOpSigner,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !RevokeSponsorshipOp {
        const disc = try RevokeSponsorshipType.xdrDecode(allocator, reader);
        return switch (disc) {
            .LedgerEntry => RevokeSponsorshipOp{ .LedgerEntry = try xdrDecodeGeneric(LedgerKey, allocator, reader) },
            .Signer => RevokeSponsorshipOp{ .Signer = try xdrDecodeGeneric(RevokeSponsorshipOpSigner, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: RevokeSponsorshipOp, writer: anytype) !void {
        const disc: RevokeSponsorshipType = switch (self) {
            .LedgerEntry => .LedgerEntry,
            .Signer => .Signer,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .LedgerEntry => |v| try xdrEncodeGeneric(LedgerKey, writer, v),
            .Signer => |v| try xdrEncodeGeneric(RevokeSponsorshipOpSigner, writer, v),
        }
    }
};

/// ClawbackOp is an XDR Struct defined as:
///
/// ```text
/// struct ClawbackOp
/// {
///     Asset asset;
///     MuxedAccount from;
///     int64 amount;
/// };
/// ```
///
pub const ClawbackOp = struct {
    asset: Asset,
    from: MuxedAccount,
    amount: i64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ClawbackOp {
        return ClawbackOp{
            .asset = try xdrDecodeGeneric(Asset, allocator, reader),
            .from = try xdrDecodeGeneric(MuxedAccount, allocator, reader),
            .amount = try xdrDecodeGeneric(i64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ClawbackOp, writer: anytype) !void {
        try xdrEncodeGeneric(Asset, writer, self.asset);
        try xdrEncodeGeneric(MuxedAccount, writer, self.from);
        try xdrEncodeGeneric(i64, writer, self.amount);
    }
};

/// ClawbackClaimableBalanceOp is an XDR Struct defined as:
///
/// ```text
/// struct ClawbackClaimableBalanceOp
/// {
///     ClaimableBalanceID balanceID;
/// };
/// ```
///
pub const ClawbackClaimableBalanceOp = struct {
    balance_id: ClaimableBalanceId,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ClawbackClaimableBalanceOp {
        return ClawbackClaimableBalanceOp{
            .balance_id = try xdrDecodeGeneric(ClaimableBalanceId, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ClawbackClaimableBalanceOp, writer: anytype) !void {
        try xdrEncodeGeneric(ClaimableBalanceId, writer, self.balance_id);
    }
};

/// SetTrustLineFlagsOp is an XDR Struct defined as:
///
/// ```text
/// struct SetTrustLineFlagsOp
/// {
///     AccountID trustor;
///     Asset asset;
///
///     uint32 clearFlags; // which flags to clear
///     uint32 setFlags;   // which flags to set
/// };
/// ```
///
pub const SetTrustLineFlagsOp = struct {
    trustor: AccountId,
    asset: Asset,
    clear_flags: u32,
    set_flags: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SetTrustLineFlagsOp {
        return SetTrustLineFlagsOp{
            .trustor = try xdrDecodeGeneric(AccountId, allocator, reader),
            .asset = try xdrDecodeGeneric(Asset, allocator, reader),
            .clear_flags = try xdrDecodeGeneric(u32, allocator, reader),
            .set_flags = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: SetTrustLineFlagsOp, writer: anytype) !void {
        try xdrEncodeGeneric(AccountId, writer, self.trustor);
        try xdrEncodeGeneric(Asset, writer, self.asset);
        try xdrEncodeGeneric(u32, writer, self.clear_flags);
        try xdrEncodeGeneric(u32, writer, self.set_flags);
    }
};

/// LiquidityPoolFeeV18 is an XDR Const defined as:
///
/// ```text
/// const LIQUIDITY_POOL_FEE_V18 = 30;
/// ```
///
pub const LIQUIDITY_POOL_FEE_V18: u64 = 30;

/// LiquidityPoolDepositOp is an XDR Struct defined as:
///
/// ```text
/// struct LiquidityPoolDepositOp
/// {
///     PoolID liquidityPoolID;
///     int64 maxAmountA; // maximum amount of first asset to deposit
///     int64 maxAmountB; // maximum amount of second asset to deposit
///     Price minPrice;   // minimum depositA/depositB
///     Price maxPrice;   // maximum depositA/depositB
/// };
/// ```
///
pub const LiquidityPoolDepositOp = struct {
    liquidity_pool_id: PoolId,
    max_amount_a: i64,
    max_amount_b: i64,
    min_price: Price,
    max_price: Price,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LiquidityPoolDepositOp {
        return LiquidityPoolDepositOp{
            .liquidity_pool_id = try xdrDecodeGeneric(PoolId, allocator, reader),
            .max_amount_a = try xdrDecodeGeneric(i64, allocator, reader),
            .max_amount_b = try xdrDecodeGeneric(i64, allocator, reader),
            .min_price = try xdrDecodeGeneric(Price, allocator, reader),
            .max_price = try xdrDecodeGeneric(Price, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LiquidityPoolDepositOp, writer: anytype) !void {
        try xdrEncodeGeneric(PoolId, writer, self.liquidity_pool_id);
        try xdrEncodeGeneric(i64, writer, self.max_amount_a);
        try xdrEncodeGeneric(i64, writer, self.max_amount_b);
        try xdrEncodeGeneric(Price, writer, self.min_price);
        try xdrEncodeGeneric(Price, writer, self.max_price);
    }
};

/// LiquidityPoolWithdrawOp is an XDR Struct defined as:
///
/// ```text
/// struct LiquidityPoolWithdrawOp
/// {
///     PoolID liquidityPoolID;
///     int64 amount;     // amount of pool shares to withdraw
///     int64 minAmountA; // minimum amount of first asset to withdraw
///     int64 minAmountB; // minimum amount of second asset to withdraw
/// };
/// ```
///
pub const LiquidityPoolWithdrawOp = struct {
    liquidity_pool_id: PoolId,
    amount: i64,
    min_amount_a: i64,
    min_amount_b: i64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LiquidityPoolWithdrawOp {
        return LiquidityPoolWithdrawOp{
            .liquidity_pool_id = try xdrDecodeGeneric(PoolId, allocator, reader),
            .amount = try xdrDecodeGeneric(i64, allocator, reader),
            .min_amount_a = try xdrDecodeGeneric(i64, allocator, reader),
            .min_amount_b = try xdrDecodeGeneric(i64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LiquidityPoolWithdrawOp, writer: anytype) !void {
        try xdrEncodeGeneric(PoolId, writer, self.liquidity_pool_id);
        try xdrEncodeGeneric(i64, writer, self.amount);
        try xdrEncodeGeneric(i64, writer, self.min_amount_a);
        try xdrEncodeGeneric(i64, writer, self.min_amount_b);
    }
};

/// HostFunctionType is an XDR Enum defined as:
///
/// ```text
/// enum HostFunctionType
/// {
///     HOST_FUNCTION_TYPE_INVOKE_CONTRACT = 0,
///     HOST_FUNCTION_TYPE_CREATE_CONTRACT = 1,
///     HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM = 2,
///     HOST_FUNCTION_TYPE_CREATE_CONTRACT_V2 = 3
/// };
/// ```
///
pub const HostFunctionType = enum(i32) {
    InvokeContract = 0,
    CreateContract = 1,
    UploadContractWasm = 2,
    CreateContractV2 = 3,
    _,

    pub const variants = [_]HostFunctionType{
        .InvokeContract,
        .CreateContract,
        .UploadContractWasm,
        .CreateContractV2,
    };

    pub fn name(self: HostFunctionType) []const u8 {
        return switch (self) {
            .InvokeContract => "InvokeContract",
            .CreateContract => "CreateContract",
            .UploadContractWasm => "UploadContractWasm",
            .CreateContractV2 => "CreateContractV2",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !HostFunctionType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: HostFunctionType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ContractIdPreimageType is an XDR Enum defined as:
///
/// ```text
/// enum ContractIDPreimageType
/// {
///     CONTRACT_ID_PREIMAGE_FROM_ADDRESS = 0,
///     CONTRACT_ID_PREIMAGE_FROM_ASSET = 1
/// };
/// ```
///
pub const ContractIdPreimageType = enum(i32) {
    Address = 0,
    Asset = 1,
    _,

    pub const variants = [_]ContractIdPreimageType{
        .Address,
        .Asset,
    };

    pub fn name(self: ContractIdPreimageType) []const u8 {
        return switch (self) {
            .Address => "Address",
            .Asset => "Asset",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ContractIdPreimageType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ContractIdPreimageType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ContractIdPreimageFromAddress is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///     {
///         SCAddress address;
///         uint256 salt;
///     }
/// ```
///
pub const ContractIdPreimageFromAddress = struct {
    address: ScAddress,
    salt: Uint256,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ContractIdPreimageFromAddress {
        return ContractIdPreimageFromAddress{
            .address = try xdrDecodeGeneric(ScAddress, allocator, reader),
            .salt = try xdrDecodeGeneric(Uint256, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ContractIdPreimageFromAddress, writer: anytype) !void {
        try xdrEncodeGeneric(ScAddress, writer, self.address);
        try xdrEncodeGeneric(Uint256, writer, self.salt);
    }
};

/// ContractIdPreimage is an XDR Union defined as:
///
/// ```text
/// union ContractIDPreimage switch (ContractIDPreimageType type)
/// {
/// case CONTRACT_ID_PREIMAGE_FROM_ADDRESS:
///     struct
///     {
///         SCAddress address;
///         uint256 salt;
///     } fromAddress;
/// case CONTRACT_ID_PREIMAGE_FROM_ASSET:
///     Asset fromAsset;
/// };
/// ```
///
pub const ContractIdPreimage = union(enum) {
    Address: ContractIdPreimageFromAddress,
    Asset: Asset,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ContractIdPreimage {
        const disc = try ContractIdPreimageType.xdrDecode(allocator, reader);
        return switch (disc) {
            .Address => ContractIdPreimage{ .Address = try xdrDecodeGeneric(ContractIdPreimageFromAddress, allocator, reader) },
            .Asset => ContractIdPreimage{ .Asset = try xdrDecodeGeneric(Asset, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ContractIdPreimage, writer: anytype) !void {
        const disc: ContractIdPreimageType = switch (self) {
            .Address => .Address,
            .Asset => .Asset,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Address => |v| try xdrEncodeGeneric(ContractIdPreimageFromAddress, writer, v),
            .Asset => |v| try xdrEncodeGeneric(Asset, writer, v),
        }
    }
};

/// CreateContractArgs is an XDR Struct defined as:
///
/// ```text
/// struct CreateContractArgs
/// {
///     ContractIDPreimage contractIDPreimage;
///     ContractExecutable executable;
/// };
/// ```
///
pub const CreateContractArgs = struct {
    contract_id_preimage: ContractIdPreimage,
    executable: ContractExecutable,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !CreateContractArgs {
        return CreateContractArgs{
            .contract_id_preimage = try xdrDecodeGeneric(ContractIdPreimage, allocator, reader),
            .executable = try xdrDecodeGeneric(ContractExecutable, allocator, reader),
        };
    }

    pub fn xdrEncode(self: CreateContractArgs, writer: anytype) !void {
        try xdrEncodeGeneric(ContractIdPreimage, writer, self.contract_id_preimage);
        try xdrEncodeGeneric(ContractExecutable, writer, self.executable);
    }
};

/// CreateContractArgsV2 is an XDR Struct defined as:
///
/// ```text
/// struct CreateContractArgsV2
/// {
///     ContractIDPreimage contractIDPreimage;
///     ContractExecutable executable;
///     // Arguments of the contract's constructor.
///     SCVal constructorArgs<>;
/// };
/// ```
///
pub const CreateContractArgsV2 = struct {
    contract_id_preimage: ContractIdPreimage,
    executable: ContractExecutable,
    constructor_args: []ScVal,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !CreateContractArgsV2 {
        return CreateContractArgsV2{
            .contract_id_preimage = try xdrDecodeGeneric(ContractIdPreimage, allocator, reader),
            .executable = try xdrDecodeGeneric(ContractExecutable, allocator, reader),
            .constructor_args = try xdrDecodeGeneric([]ScVal, allocator, reader),
        };
    }

    pub fn xdrEncode(self: CreateContractArgsV2, writer: anytype) !void {
        try xdrEncodeGeneric(ContractIdPreimage, writer, self.contract_id_preimage);
        try xdrEncodeGeneric(ContractExecutable, writer, self.executable);
        try xdrEncodeGeneric([]ScVal, writer, self.constructor_args);
    }
};

/// InvokeContractArgs is an XDR Struct defined as:
///
/// ```text
/// struct InvokeContractArgs {
///     SCAddress contractAddress;
///     SCSymbol functionName;
///     SCVal args<>;
/// };
/// ```
///
pub const InvokeContractArgs = struct {
    contract_address: ScAddress,
    function_name: ScSymbol,
    args: []ScVal,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !InvokeContractArgs {
        return InvokeContractArgs{
            .contract_address = try xdrDecodeGeneric(ScAddress, allocator, reader),
            .function_name = try xdrDecodeGeneric(ScSymbol, allocator, reader),
            .args = try xdrDecodeGeneric([]ScVal, allocator, reader),
        };
    }

    pub fn xdrEncode(self: InvokeContractArgs, writer: anytype) !void {
        try xdrEncodeGeneric(ScAddress, writer, self.contract_address);
        try xdrEncodeGeneric(ScSymbol, writer, self.function_name);
        try xdrEncodeGeneric([]ScVal, writer, self.args);
    }
};

/// HostFunction is an XDR Union defined as:
///
/// ```text
/// union HostFunction switch (HostFunctionType type)
/// {
/// case HOST_FUNCTION_TYPE_INVOKE_CONTRACT:
///     InvokeContractArgs invokeContract;
/// case HOST_FUNCTION_TYPE_CREATE_CONTRACT:
///     CreateContractArgs createContract;
/// case HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM:
///     opaque wasm<>;
/// case HOST_FUNCTION_TYPE_CREATE_CONTRACT_V2:
///     CreateContractArgsV2 createContractV2;
/// };
/// ```
///
pub const HostFunction = union(enum) {
    InvokeContract: InvokeContractArgs,
    CreateContract: CreateContractArgs,
    UploadContractWasm: []u8,
    CreateContractV2: CreateContractArgsV2,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !HostFunction {
        const disc = try HostFunctionType.xdrDecode(allocator, reader);
        return switch (disc) {
            .InvokeContract => HostFunction{ .InvokeContract = try xdrDecodeGeneric(InvokeContractArgs, allocator, reader) },
            .CreateContract => HostFunction{ .CreateContract = try xdrDecodeGeneric(CreateContractArgs, allocator, reader) },
            .UploadContractWasm => HostFunction{ .UploadContractWasm = try xdrDecodeGeneric([]u8, allocator, reader) },
            .CreateContractV2 => HostFunction{ .CreateContractV2 = try xdrDecodeGeneric(CreateContractArgsV2, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: HostFunction, writer: anytype) !void {
        const disc: HostFunctionType = switch (self) {
            .InvokeContract => .InvokeContract,
            .CreateContract => .CreateContract,
            .UploadContractWasm => .UploadContractWasm,
            .CreateContractV2 => .CreateContractV2,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .InvokeContract => |v| try xdrEncodeGeneric(InvokeContractArgs, writer, v),
            .CreateContract => |v| try xdrEncodeGeneric(CreateContractArgs, writer, v),
            .UploadContractWasm => |v| try xdrEncodeGeneric([]u8, writer, v),
            .CreateContractV2 => |v| try xdrEncodeGeneric(CreateContractArgsV2, writer, v),
        }
    }
};

/// SorobanAuthorizedFunctionType is an XDR Enum defined as:
///
/// ```text
/// enum SorobanAuthorizedFunctionType
/// {
///     SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN = 0,
///     SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_HOST_FN = 1,
///     SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_V2_HOST_FN = 2
/// };
/// ```
///
pub const SorobanAuthorizedFunctionType = enum(i32) {
    ContractFn = 0,
    CreateContractHostFn = 1,
    CreateContractV2HostFn = 2,
    _,

    pub const variants = [_]SorobanAuthorizedFunctionType{
        .ContractFn,
        .CreateContractHostFn,
        .CreateContractV2HostFn,
    };

    pub fn name(self: SorobanAuthorizedFunctionType) []const u8 {
        return switch (self) {
            .ContractFn => "ContractFn",
            .CreateContractHostFn => "CreateContractHostFn",
            .CreateContractV2HostFn => "CreateContractV2HostFn",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SorobanAuthorizedFunctionType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: SorobanAuthorizedFunctionType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// SorobanAuthorizedFunction is an XDR Union defined as:
///
/// ```text
/// union SorobanAuthorizedFunction switch (SorobanAuthorizedFunctionType type)
/// {
/// case SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN:
///     InvokeContractArgs contractFn;
/// // This variant of auth payload for creating new contract instances
/// // doesn't allow specifying the constructor arguments, creating contracts
/// // with constructors that take arguments is only possible by authorizing
/// // `SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_V2_HOST_FN`
/// // (protocol 22+).
/// case SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_HOST_FN:
///     CreateContractArgs createContractHostFn;
/// // This variant of auth payload for creating new contract instances
/// // is only accepted in and after protocol 22. It allows authorizing the
/// // contract constructor arguments.
/// case SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_V2_HOST_FN:
///     CreateContractArgsV2 createContractV2HostFn;
/// };
/// ```
///
pub const SorobanAuthorizedFunction = union(enum) {
    ContractFn: InvokeContractArgs,
    CreateContractHostFn: CreateContractArgs,
    CreateContractV2HostFn: CreateContractArgsV2,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SorobanAuthorizedFunction {
        const disc = try SorobanAuthorizedFunctionType.xdrDecode(allocator, reader);
        return switch (disc) {
            .ContractFn => SorobanAuthorizedFunction{ .ContractFn = try xdrDecodeGeneric(InvokeContractArgs, allocator, reader) },
            .CreateContractHostFn => SorobanAuthorizedFunction{ .CreateContractHostFn = try xdrDecodeGeneric(CreateContractArgs, allocator, reader) },
            .CreateContractV2HostFn => SorobanAuthorizedFunction{ .CreateContractV2HostFn = try xdrDecodeGeneric(CreateContractArgsV2, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: SorobanAuthorizedFunction, writer: anytype) !void {
        const disc: SorobanAuthorizedFunctionType = switch (self) {
            .ContractFn => .ContractFn,
            .CreateContractHostFn => .CreateContractHostFn,
            .CreateContractV2HostFn => .CreateContractV2HostFn,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .ContractFn => |v| try xdrEncodeGeneric(InvokeContractArgs, writer, v),
            .CreateContractHostFn => |v| try xdrEncodeGeneric(CreateContractArgs, writer, v),
            .CreateContractV2HostFn => |v| try xdrEncodeGeneric(CreateContractArgsV2, writer, v),
        }
    }
};

/// SorobanAuthorizedInvocation is an XDR Struct defined as:
///
/// ```text
/// struct SorobanAuthorizedInvocation
/// {
///     SorobanAuthorizedFunction function;
///     SorobanAuthorizedInvocation subInvocations<>;
/// };
/// ```
///
pub const SorobanAuthorizedInvocation = struct {
    function: SorobanAuthorizedFunction,
    sub_invocations: []SorobanAuthorizedInvocation,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SorobanAuthorizedInvocation {
        return SorobanAuthorizedInvocation{
            .function = try xdrDecodeGeneric(SorobanAuthorizedFunction, allocator, reader),
            .sub_invocations = try xdrDecodeGeneric([]SorobanAuthorizedInvocation, allocator, reader),
        };
    }

    pub fn xdrEncode(self: SorobanAuthorizedInvocation, writer: anytype) !void {
        try xdrEncodeGeneric(SorobanAuthorizedFunction, writer, self.function);
        try xdrEncodeGeneric([]SorobanAuthorizedInvocation, writer, self.sub_invocations);
    }
};

/// SorobanAddressCredentials is an XDR Struct defined as:
///
/// ```text
/// struct SorobanAddressCredentials
/// {
///     SCAddress address;
///     int64 nonce;
///     uint32 signatureExpirationLedger;
///     SCVal signature;
/// };
/// ```
///
pub const SorobanAddressCredentials = struct {
    address: ScAddress,
    nonce: i64,
    signature_expiration_ledger: u32,
    signature: ScVal,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SorobanAddressCredentials {
        return SorobanAddressCredentials{
            .address = try xdrDecodeGeneric(ScAddress, allocator, reader),
            .nonce = try xdrDecodeGeneric(i64, allocator, reader),
            .signature_expiration_ledger = try xdrDecodeGeneric(u32, allocator, reader),
            .signature = try xdrDecodeGeneric(ScVal, allocator, reader),
        };
    }

    pub fn xdrEncode(self: SorobanAddressCredentials, writer: anytype) !void {
        try xdrEncodeGeneric(ScAddress, writer, self.address);
        try xdrEncodeGeneric(i64, writer, self.nonce);
        try xdrEncodeGeneric(u32, writer, self.signature_expiration_ledger);
        try xdrEncodeGeneric(ScVal, writer, self.signature);
    }
};

/// SorobanCredentialsType is an XDR Enum defined as:
///
/// ```text
/// enum SorobanCredentialsType
/// {
///     SOROBAN_CREDENTIALS_SOURCE_ACCOUNT = 0,
///     SOROBAN_CREDENTIALS_ADDRESS = 1
/// };
/// ```
///
pub const SorobanCredentialsType = enum(i32) {
    SourceAccount = 0,
    Address = 1,
    _,

    pub const variants = [_]SorobanCredentialsType{
        .SourceAccount,
        .Address,
    };

    pub fn name(self: SorobanCredentialsType) []const u8 {
        return switch (self) {
            .SourceAccount => "SourceAccount",
            .Address => "Address",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SorobanCredentialsType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: SorobanCredentialsType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// SorobanCredentials is an XDR Union defined as:
///
/// ```text
/// union SorobanCredentials switch (SorobanCredentialsType type)
/// {
/// case SOROBAN_CREDENTIALS_SOURCE_ACCOUNT:
///     void;
/// case SOROBAN_CREDENTIALS_ADDRESS:
///     SorobanAddressCredentials address;
/// };
/// ```
///
pub const SorobanCredentials = union(enum) {
    SourceAccount,
    Address: SorobanAddressCredentials,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SorobanCredentials {
        const disc = try SorobanCredentialsType.xdrDecode(allocator, reader);
        return switch (disc) {
            .SourceAccount => SorobanCredentials{ .SourceAccount = {} },
            .Address => SorobanCredentials{ .Address = try xdrDecodeGeneric(SorobanAddressCredentials, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: SorobanCredentials, writer: anytype) !void {
        const disc: SorobanCredentialsType = switch (self) {
            .SourceAccount => .SourceAccount,
            .Address => .Address,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .SourceAccount => {},
            .Address => |v| try xdrEncodeGeneric(SorobanAddressCredentials, writer, v),
        }
    }
};

/// SorobanAuthorizationEntry is an XDR Struct defined as:
///
/// ```text
/// struct SorobanAuthorizationEntry
/// {
///     SorobanCredentials credentials;
///     SorobanAuthorizedInvocation rootInvocation;
/// };
/// ```
///
pub const SorobanAuthorizationEntry = struct {
    credentials: SorobanCredentials,
    root_invocation: SorobanAuthorizedInvocation,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SorobanAuthorizationEntry {
        return SorobanAuthorizationEntry{
            .credentials = try xdrDecodeGeneric(SorobanCredentials, allocator, reader),
            .root_invocation = try xdrDecodeGeneric(SorobanAuthorizedInvocation, allocator, reader),
        };
    }

    pub fn xdrEncode(self: SorobanAuthorizationEntry, writer: anytype) !void {
        try xdrEncodeGeneric(SorobanCredentials, writer, self.credentials);
        try xdrEncodeGeneric(SorobanAuthorizedInvocation, writer, self.root_invocation);
    }
};

/// SorobanAuthorizationEntries is an XDR Typedef defined as:
///
/// ```text
/// typedef SorobanAuthorizationEntry SorobanAuthorizationEntries<>;
/// ```
///
pub const SorobanAuthorizationEntries = struct {
    value: []SorobanAuthorizationEntry,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SorobanAuthorizationEntries {
        return SorobanAuthorizationEntries{
            .value = try xdrDecodeGeneric([]SorobanAuthorizationEntry, allocator, reader),
        };
    }

    pub fn xdrEncode(self: SorobanAuthorizationEntries, writer: anytype) !void {
        try xdrEncodeGeneric([]SorobanAuthorizationEntry, writer, self.value);
    }

    pub fn asSlice(self: SorobanAuthorizationEntries) []const SorobanAuthorizationEntry {
        return self.value.data;
    }
};

/// InvokeHostFunctionOp is an XDR Struct defined as:
///
/// ```text
/// struct InvokeHostFunctionOp
/// {
///     // Host function to invoke.
///     HostFunction hostFunction;
///     // Per-address authorizations for this host function.
///     SorobanAuthorizationEntry auth<>;
/// };
/// ```
///
pub const InvokeHostFunctionOp = struct {
    host_function: HostFunction,
    auth: []SorobanAuthorizationEntry,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !InvokeHostFunctionOp {
        return InvokeHostFunctionOp{
            .host_function = try xdrDecodeGeneric(HostFunction, allocator, reader),
            .auth = try xdrDecodeGeneric([]SorobanAuthorizationEntry, allocator, reader),
        };
    }

    pub fn xdrEncode(self: InvokeHostFunctionOp, writer: anytype) !void {
        try xdrEncodeGeneric(HostFunction, writer, self.host_function);
        try xdrEncodeGeneric([]SorobanAuthorizationEntry, writer, self.auth);
    }
};

/// ExtendFootprintTtlOp is an XDR Struct defined as:
///
/// ```text
/// struct ExtendFootprintTTLOp
/// {
///     ExtensionPoint ext;
///     uint32 extendTo;
/// };
/// ```
///
pub const ExtendFootprintTtlOp = struct {
    ext: ExtensionPoint,
    extend_to: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ExtendFootprintTtlOp {
        return ExtendFootprintTtlOp{
            .ext = try xdrDecodeGeneric(ExtensionPoint, allocator, reader),
            .extend_to = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ExtendFootprintTtlOp, writer: anytype) !void {
        try xdrEncodeGeneric(ExtensionPoint, writer, self.ext);
        try xdrEncodeGeneric(u32, writer, self.extend_to);
    }
};

/// RestoreFootprintOp is an XDR Struct defined as:
///
/// ```text
/// struct RestoreFootprintOp
/// {
///     ExtensionPoint ext;
/// };
/// ```
///
pub const RestoreFootprintOp = struct {
    ext: ExtensionPoint,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !RestoreFootprintOp {
        return RestoreFootprintOp{
            .ext = try xdrDecodeGeneric(ExtensionPoint, allocator, reader),
        };
    }

    pub fn xdrEncode(self: RestoreFootprintOp, writer: anytype) !void {
        try xdrEncodeGeneric(ExtensionPoint, writer, self.ext);
    }
};

/// OperationBody is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (OperationType type)
///     {
///     case CREATE_ACCOUNT:
///         CreateAccountOp createAccountOp;
///     case PAYMENT:
///         PaymentOp paymentOp;
///     case PATH_PAYMENT_STRICT_RECEIVE:
///         PathPaymentStrictReceiveOp pathPaymentStrictReceiveOp;
///     case MANAGE_SELL_OFFER:
///         ManageSellOfferOp manageSellOfferOp;
///     case CREATE_PASSIVE_SELL_OFFER:
///         CreatePassiveSellOfferOp createPassiveSellOfferOp;
///     case SET_OPTIONS:
///         SetOptionsOp setOptionsOp;
///     case CHANGE_TRUST:
///         ChangeTrustOp changeTrustOp;
///     case ALLOW_TRUST:
///         AllowTrustOp allowTrustOp;
///     case ACCOUNT_MERGE:
///         MuxedAccount destination;
///     case INFLATION:
///         void;
///     case MANAGE_DATA:
///         ManageDataOp manageDataOp;
///     case BUMP_SEQUENCE:
///         BumpSequenceOp bumpSequenceOp;
///     case MANAGE_BUY_OFFER:
///         ManageBuyOfferOp manageBuyOfferOp;
///     case PATH_PAYMENT_STRICT_SEND:
///         PathPaymentStrictSendOp pathPaymentStrictSendOp;
///     case CREATE_CLAIMABLE_BALANCE:
///         CreateClaimableBalanceOp createClaimableBalanceOp;
///     case CLAIM_CLAIMABLE_BALANCE:
///         ClaimClaimableBalanceOp claimClaimableBalanceOp;
///     case BEGIN_SPONSORING_FUTURE_RESERVES:
///         BeginSponsoringFutureReservesOp beginSponsoringFutureReservesOp;
///     case END_SPONSORING_FUTURE_RESERVES:
///         void;
///     case REVOKE_SPONSORSHIP:
///         RevokeSponsorshipOp revokeSponsorshipOp;
///     case CLAWBACK:
///         ClawbackOp clawbackOp;
///     case CLAWBACK_CLAIMABLE_BALANCE:
///         ClawbackClaimableBalanceOp clawbackClaimableBalanceOp;
///     case SET_TRUST_LINE_FLAGS:
///         SetTrustLineFlagsOp setTrustLineFlagsOp;
///     case LIQUIDITY_POOL_DEPOSIT:
///         LiquidityPoolDepositOp liquidityPoolDepositOp;
///     case LIQUIDITY_POOL_WITHDRAW:
///         LiquidityPoolWithdrawOp liquidityPoolWithdrawOp;
///     case INVOKE_HOST_FUNCTION:
///         InvokeHostFunctionOp invokeHostFunctionOp;
///     case EXTEND_FOOTPRINT_TTL:
///         ExtendFootprintTTLOp extendFootprintTTLOp;
///     case RESTORE_FOOTPRINT:
///         RestoreFootprintOp restoreFootprintOp;
///     }
/// ```
///
pub const OperationBody = union(enum) {
    CreateAccount: CreateAccountOp,
    Payment: PaymentOp,
    PathPaymentStrictReceive: PathPaymentStrictReceiveOp,
    ManageSellOffer: ManageSellOfferOp,
    CreatePassiveSellOffer: CreatePassiveSellOfferOp,
    SetOptions: SetOptionsOp,
    ChangeTrust: ChangeTrustOp,
    AllowTrust: AllowTrustOp,
    AccountMerge: MuxedAccount,
    Inflation,
    ManageData: ManageDataOp,
    BumpSequence: BumpSequenceOp,
    ManageBuyOffer: ManageBuyOfferOp,
    PathPaymentStrictSend: PathPaymentStrictSendOp,
    CreateClaimableBalance: CreateClaimableBalanceOp,
    ClaimClaimableBalance: ClaimClaimableBalanceOp,
    BeginSponsoringFutureReserves: BeginSponsoringFutureReservesOp,
    EndSponsoringFutureReserves,
    RevokeSponsorship: RevokeSponsorshipOp,
    Clawback: ClawbackOp,
    ClawbackClaimableBalance: ClawbackClaimableBalanceOp,
    SetTrustLineFlags: SetTrustLineFlagsOp,
    LiquidityPoolDeposit: LiquidityPoolDepositOp,
    LiquidityPoolWithdraw: LiquidityPoolWithdrawOp,
    InvokeHostFunction: InvokeHostFunctionOp,
    ExtendFootprintTtl: ExtendFootprintTtlOp,
    RestoreFootprint: RestoreFootprintOp,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !OperationBody {
        const disc = try OperationType.xdrDecode(allocator, reader);
        return switch (disc) {
            .CreateAccount => OperationBody{ .CreateAccount = try xdrDecodeGeneric(CreateAccountOp, allocator, reader) },
            .Payment => OperationBody{ .Payment = try xdrDecodeGeneric(PaymentOp, allocator, reader) },
            .PathPaymentStrictReceive => OperationBody{ .PathPaymentStrictReceive = try xdrDecodeGeneric(PathPaymentStrictReceiveOp, allocator, reader) },
            .ManageSellOffer => OperationBody{ .ManageSellOffer = try xdrDecodeGeneric(ManageSellOfferOp, allocator, reader) },
            .CreatePassiveSellOffer => OperationBody{ .CreatePassiveSellOffer = try xdrDecodeGeneric(CreatePassiveSellOfferOp, allocator, reader) },
            .SetOptions => OperationBody{ .SetOptions = try xdrDecodeGeneric(SetOptionsOp, allocator, reader) },
            .ChangeTrust => OperationBody{ .ChangeTrust = try xdrDecodeGeneric(ChangeTrustOp, allocator, reader) },
            .AllowTrust => OperationBody{ .AllowTrust = try xdrDecodeGeneric(AllowTrustOp, allocator, reader) },
            .AccountMerge => OperationBody{ .AccountMerge = try xdrDecodeGeneric(MuxedAccount, allocator, reader) },
            .Inflation => OperationBody{ .Inflation = {} },
            .ManageData => OperationBody{ .ManageData = try xdrDecodeGeneric(ManageDataOp, allocator, reader) },
            .BumpSequence => OperationBody{ .BumpSequence = try xdrDecodeGeneric(BumpSequenceOp, allocator, reader) },
            .ManageBuyOffer => OperationBody{ .ManageBuyOffer = try xdrDecodeGeneric(ManageBuyOfferOp, allocator, reader) },
            .PathPaymentStrictSend => OperationBody{ .PathPaymentStrictSend = try xdrDecodeGeneric(PathPaymentStrictSendOp, allocator, reader) },
            .CreateClaimableBalance => OperationBody{ .CreateClaimableBalance = try xdrDecodeGeneric(CreateClaimableBalanceOp, allocator, reader) },
            .ClaimClaimableBalance => OperationBody{ .ClaimClaimableBalance = try xdrDecodeGeneric(ClaimClaimableBalanceOp, allocator, reader) },
            .BeginSponsoringFutureReserves => OperationBody{ .BeginSponsoringFutureReserves = try xdrDecodeGeneric(BeginSponsoringFutureReservesOp, allocator, reader) },
            .EndSponsoringFutureReserves => OperationBody{ .EndSponsoringFutureReserves = {} },
            .RevokeSponsorship => OperationBody{ .RevokeSponsorship = try xdrDecodeGeneric(RevokeSponsorshipOp, allocator, reader) },
            .Clawback => OperationBody{ .Clawback = try xdrDecodeGeneric(ClawbackOp, allocator, reader) },
            .ClawbackClaimableBalance => OperationBody{ .ClawbackClaimableBalance = try xdrDecodeGeneric(ClawbackClaimableBalanceOp, allocator, reader) },
            .SetTrustLineFlags => OperationBody{ .SetTrustLineFlags = try xdrDecodeGeneric(SetTrustLineFlagsOp, allocator, reader) },
            .LiquidityPoolDeposit => OperationBody{ .LiquidityPoolDeposit = try xdrDecodeGeneric(LiquidityPoolDepositOp, allocator, reader) },
            .LiquidityPoolWithdraw => OperationBody{ .LiquidityPoolWithdraw = try xdrDecodeGeneric(LiquidityPoolWithdrawOp, allocator, reader) },
            .InvokeHostFunction => OperationBody{ .InvokeHostFunction = try xdrDecodeGeneric(InvokeHostFunctionOp, allocator, reader) },
            .ExtendFootprintTtl => OperationBody{ .ExtendFootprintTtl = try xdrDecodeGeneric(ExtendFootprintTtlOp, allocator, reader) },
            .RestoreFootprint => OperationBody{ .RestoreFootprint = try xdrDecodeGeneric(RestoreFootprintOp, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: OperationBody, writer: anytype) !void {
        const disc: OperationType = switch (self) {
            .CreateAccount => .CreateAccount,
            .Payment => .Payment,
            .PathPaymentStrictReceive => .PathPaymentStrictReceive,
            .ManageSellOffer => .ManageSellOffer,
            .CreatePassiveSellOffer => .CreatePassiveSellOffer,
            .SetOptions => .SetOptions,
            .ChangeTrust => .ChangeTrust,
            .AllowTrust => .AllowTrust,
            .AccountMerge => .AccountMerge,
            .Inflation => .Inflation,
            .ManageData => .ManageData,
            .BumpSequence => .BumpSequence,
            .ManageBuyOffer => .ManageBuyOffer,
            .PathPaymentStrictSend => .PathPaymentStrictSend,
            .CreateClaimableBalance => .CreateClaimableBalance,
            .ClaimClaimableBalance => .ClaimClaimableBalance,
            .BeginSponsoringFutureReserves => .BeginSponsoringFutureReserves,
            .EndSponsoringFutureReserves => .EndSponsoringFutureReserves,
            .RevokeSponsorship => .RevokeSponsorship,
            .Clawback => .Clawback,
            .ClawbackClaimableBalance => .ClawbackClaimableBalance,
            .SetTrustLineFlags => .SetTrustLineFlags,
            .LiquidityPoolDeposit => .LiquidityPoolDeposit,
            .LiquidityPoolWithdraw => .LiquidityPoolWithdraw,
            .InvokeHostFunction => .InvokeHostFunction,
            .ExtendFootprintTtl => .ExtendFootprintTtl,
            .RestoreFootprint => .RestoreFootprint,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .CreateAccount => |v| try xdrEncodeGeneric(CreateAccountOp, writer, v),
            .Payment => |v| try xdrEncodeGeneric(PaymentOp, writer, v),
            .PathPaymentStrictReceive => |v| try xdrEncodeGeneric(PathPaymentStrictReceiveOp, writer, v),
            .ManageSellOffer => |v| try xdrEncodeGeneric(ManageSellOfferOp, writer, v),
            .CreatePassiveSellOffer => |v| try xdrEncodeGeneric(CreatePassiveSellOfferOp, writer, v),
            .SetOptions => |v| try xdrEncodeGeneric(SetOptionsOp, writer, v),
            .ChangeTrust => |v| try xdrEncodeGeneric(ChangeTrustOp, writer, v),
            .AllowTrust => |v| try xdrEncodeGeneric(AllowTrustOp, writer, v),
            .AccountMerge => |v| try xdrEncodeGeneric(MuxedAccount, writer, v),
            .Inflation => {},
            .ManageData => |v| try xdrEncodeGeneric(ManageDataOp, writer, v),
            .BumpSequence => |v| try xdrEncodeGeneric(BumpSequenceOp, writer, v),
            .ManageBuyOffer => |v| try xdrEncodeGeneric(ManageBuyOfferOp, writer, v),
            .PathPaymentStrictSend => |v| try xdrEncodeGeneric(PathPaymentStrictSendOp, writer, v),
            .CreateClaimableBalance => |v| try xdrEncodeGeneric(CreateClaimableBalanceOp, writer, v),
            .ClaimClaimableBalance => |v| try xdrEncodeGeneric(ClaimClaimableBalanceOp, writer, v),
            .BeginSponsoringFutureReserves => |v| try xdrEncodeGeneric(BeginSponsoringFutureReservesOp, writer, v),
            .EndSponsoringFutureReserves => {},
            .RevokeSponsorship => |v| try xdrEncodeGeneric(RevokeSponsorshipOp, writer, v),
            .Clawback => |v| try xdrEncodeGeneric(ClawbackOp, writer, v),
            .ClawbackClaimableBalance => |v| try xdrEncodeGeneric(ClawbackClaimableBalanceOp, writer, v),
            .SetTrustLineFlags => |v| try xdrEncodeGeneric(SetTrustLineFlagsOp, writer, v),
            .LiquidityPoolDeposit => |v| try xdrEncodeGeneric(LiquidityPoolDepositOp, writer, v),
            .LiquidityPoolWithdraw => |v| try xdrEncodeGeneric(LiquidityPoolWithdrawOp, writer, v),
            .InvokeHostFunction => |v| try xdrEncodeGeneric(InvokeHostFunctionOp, writer, v),
            .ExtendFootprintTtl => |v| try xdrEncodeGeneric(ExtendFootprintTtlOp, writer, v),
            .RestoreFootprint => |v| try xdrEncodeGeneric(RestoreFootprintOp, writer, v),
        }
    }
};

/// Operation is an XDR Struct defined as:
///
/// ```text
/// struct Operation
/// {
///     // sourceAccount is the account used to run the operation
///     // if not set, the runtime defaults to "sourceAccount" specified at
///     // the transaction level
///     MuxedAccount* sourceAccount;
///
///     union switch (OperationType type)
///     {
///     case CREATE_ACCOUNT:
///         CreateAccountOp createAccountOp;
///     case PAYMENT:
///         PaymentOp paymentOp;
///     case PATH_PAYMENT_STRICT_RECEIVE:
///         PathPaymentStrictReceiveOp pathPaymentStrictReceiveOp;
///     case MANAGE_SELL_OFFER:
///         ManageSellOfferOp manageSellOfferOp;
///     case CREATE_PASSIVE_SELL_OFFER:
///         CreatePassiveSellOfferOp createPassiveSellOfferOp;
///     case SET_OPTIONS:
///         SetOptionsOp setOptionsOp;
///     case CHANGE_TRUST:
///         ChangeTrustOp changeTrustOp;
///     case ALLOW_TRUST:
///         AllowTrustOp allowTrustOp;
///     case ACCOUNT_MERGE:
///         MuxedAccount destination;
///     case INFLATION:
///         void;
///     case MANAGE_DATA:
///         ManageDataOp manageDataOp;
///     case BUMP_SEQUENCE:
///         BumpSequenceOp bumpSequenceOp;
///     case MANAGE_BUY_OFFER:
///         ManageBuyOfferOp manageBuyOfferOp;
///     case PATH_PAYMENT_STRICT_SEND:
///         PathPaymentStrictSendOp pathPaymentStrictSendOp;
///     case CREATE_CLAIMABLE_BALANCE:
///         CreateClaimableBalanceOp createClaimableBalanceOp;
///     case CLAIM_CLAIMABLE_BALANCE:
///         ClaimClaimableBalanceOp claimClaimableBalanceOp;
///     case BEGIN_SPONSORING_FUTURE_RESERVES:
///         BeginSponsoringFutureReservesOp beginSponsoringFutureReservesOp;
///     case END_SPONSORING_FUTURE_RESERVES:
///         void;
///     case REVOKE_SPONSORSHIP:
///         RevokeSponsorshipOp revokeSponsorshipOp;
///     case CLAWBACK:
///         ClawbackOp clawbackOp;
///     case CLAWBACK_CLAIMABLE_BALANCE:
///         ClawbackClaimableBalanceOp clawbackClaimableBalanceOp;
///     case SET_TRUST_LINE_FLAGS:
///         SetTrustLineFlagsOp setTrustLineFlagsOp;
///     case LIQUIDITY_POOL_DEPOSIT:
///         LiquidityPoolDepositOp liquidityPoolDepositOp;
///     case LIQUIDITY_POOL_WITHDRAW:
///         LiquidityPoolWithdrawOp liquidityPoolWithdrawOp;
///     case INVOKE_HOST_FUNCTION:
///         InvokeHostFunctionOp invokeHostFunctionOp;
///     case EXTEND_FOOTPRINT_TTL:
///         ExtendFootprintTTLOp extendFootprintTTLOp;
///     case RESTORE_FOOTPRINT:
///         RestoreFootprintOp restoreFootprintOp;
///     }
///     body;
/// };
/// ```
///
pub const Operation = struct {
    source_account: ?MuxedAccount,
    body: OperationBody,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !Operation {
        return Operation{
            .source_account = try xdrDecodeGeneric(?MuxedAccount, allocator, reader),
            .body = try xdrDecodeGeneric(OperationBody, allocator, reader),
        };
    }

    pub fn xdrEncode(self: Operation, writer: anytype) !void {
        try xdrEncodeGeneric(?MuxedAccount, writer, self.source_account);
        try xdrEncodeGeneric(OperationBody, writer, self.body);
    }
};

/// HashIdPreimageOperationId is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///     {
///         AccountID sourceAccount;
///         SequenceNumber seqNum;
///         uint32 opNum;
///     }
/// ```
///
pub const HashIdPreimageOperationId = struct {
    source_account: AccountId,
    seq_num: SequenceNumber,
    op_num: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !HashIdPreimageOperationId {
        return HashIdPreimageOperationId{
            .source_account = try xdrDecodeGeneric(AccountId, allocator, reader),
            .seq_num = try xdrDecodeGeneric(SequenceNumber, allocator, reader),
            .op_num = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: HashIdPreimageOperationId, writer: anytype) !void {
        try xdrEncodeGeneric(AccountId, writer, self.source_account);
        try xdrEncodeGeneric(SequenceNumber, writer, self.seq_num);
        try xdrEncodeGeneric(u32, writer, self.op_num);
    }
};

/// HashIdPreimageRevokeId is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///     {
///         AccountID sourceAccount;
///         SequenceNumber seqNum;
///         uint32 opNum;
///         PoolID liquidityPoolID;
///         Asset asset;
///     }
/// ```
///
pub const HashIdPreimageRevokeId = struct {
    source_account: AccountId,
    seq_num: SequenceNumber,
    op_num: u32,
    liquidity_pool_id: PoolId,
    asset: Asset,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !HashIdPreimageRevokeId {
        return HashIdPreimageRevokeId{
            .source_account = try xdrDecodeGeneric(AccountId, allocator, reader),
            .seq_num = try xdrDecodeGeneric(SequenceNumber, allocator, reader),
            .op_num = try xdrDecodeGeneric(u32, allocator, reader),
            .liquidity_pool_id = try xdrDecodeGeneric(PoolId, allocator, reader),
            .asset = try xdrDecodeGeneric(Asset, allocator, reader),
        };
    }

    pub fn xdrEncode(self: HashIdPreimageRevokeId, writer: anytype) !void {
        try xdrEncodeGeneric(AccountId, writer, self.source_account);
        try xdrEncodeGeneric(SequenceNumber, writer, self.seq_num);
        try xdrEncodeGeneric(u32, writer, self.op_num);
        try xdrEncodeGeneric(PoolId, writer, self.liquidity_pool_id);
        try xdrEncodeGeneric(Asset, writer, self.asset);
    }
};

/// HashIdPreimageContractId is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///     {
///         Hash networkID;
///         ContractIDPreimage contractIDPreimage;
///     }
/// ```
///
pub const HashIdPreimageContractId = struct {
    network_id: Hash,
    contract_id_preimage: ContractIdPreimage,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !HashIdPreimageContractId {
        return HashIdPreimageContractId{
            .network_id = try xdrDecodeGeneric(Hash, allocator, reader),
            .contract_id_preimage = try xdrDecodeGeneric(ContractIdPreimage, allocator, reader),
        };
    }

    pub fn xdrEncode(self: HashIdPreimageContractId, writer: anytype) !void {
        try xdrEncodeGeneric(Hash, writer, self.network_id);
        try xdrEncodeGeneric(ContractIdPreimage, writer, self.contract_id_preimage);
    }
};

/// HashIdPreimageSorobanAuthorization is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///     {
///         Hash networkID;
///         int64 nonce;
///         uint32 signatureExpirationLedger;
///         SorobanAuthorizedInvocation invocation;
///     }
/// ```
///
pub const HashIdPreimageSorobanAuthorization = struct {
    network_id: Hash,
    nonce: i64,
    signature_expiration_ledger: u32,
    invocation: SorobanAuthorizedInvocation,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !HashIdPreimageSorobanAuthorization {
        return HashIdPreimageSorobanAuthorization{
            .network_id = try xdrDecodeGeneric(Hash, allocator, reader),
            .nonce = try xdrDecodeGeneric(i64, allocator, reader),
            .signature_expiration_ledger = try xdrDecodeGeneric(u32, allocator, reader),
            .invocation = try xdrDecodeGeneric(SorobanAuthorizedInvocation, allocator, reader),
        };
    }

    pub fn xdrEncode(self: HashIdPreimageSorobanAuthorization, writer: anytype) !void {
        try xdrEncodeGeneric(Hash, writer, self.network_id);
        try xdrEncodeGeneric(i64, writer, self.nonce);
        try xdrEncodeGeneric(u32, writer, self.signature_expiration_ledger);
        try xdrEncodeGeneric(SorobanAuthorizedInvocation, writer, self.invocation);
    }
};

/// HashIdPreimage is an XDR Union defined as:
///
/// ```text
/// union HashIDPreimage switch (EnvelopeType type)
/// {
/// case ENVELOPE_TYPE_OP_ID:
///     struct
///     {
///         AccountID sourceAccount;
///         SequenceNumber seqNum;
///         uint32 opNum;
///     } operationID;
/// case ENVELOPE_TYPE_POOL_REVOKE_OP_ID:
///     struct
///     {
///         AccountID sourceAccount;
///         SequenceNumber seqNum;
///         uint32 opNum;
///         PoolID liquidityPoolID;
///         Asset asset;
///     } revokeID;
/// case ENVELOPE_TYPE_CONTRACT_ID:
///     struct
///     {
///         Hash networkID;
///         ContractIDPreimage contractIDPreimage;
///     } contractID;
/// case ENVELOPE_TYPE_SOROBAN_AUTHORIZATION:
///     struct
///     {
///         Hash networkID;
///         int64 nonce;
///         uint32 signatureExpirationLedger;
///         SorobanAuthorizedInvocation invocation;
///     } sorobanAuthorization;
/// };
/// ```
///
pub const HashIdPreimage = union(enum) {
    OpId: HashIdPreimageOperationId,
    PoolRevokeOpId: HashIdPreimageRevokeId,
    ContractId: HashIdPreimageContractId,
    SorobanAuthorization: HashIdPreimageSorobanAuthorization,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !HashIdPreimage {
        const disc = try EnvelopeType.xdrDecode(allocator, reader);
        return switch (disc) {
            .OpId => HashIdPreimage{ .OpId = try xdrDecodeGeneric(HashIdPreimageOperationId, allocator, reader) },
            .PoolRevokeOpId => HashIdPreimage{ .PoolRevokeOpId = try xdrDecodeGeneric(HashIdPreimageRevokeId, allocator, reader) },
            .ContractId => HashIdPreimage{ .ContractId = try xdrDecodeGeneric(HashIdPreimageContractId, allocator, reader) },
            .SorobanAuthorization => HashIdPreimage{ .SorobanAuthorization = try xdrDecodeGeneric(HashIdPreimageSorobanAuthorization, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: HashIdPreimage, writer: anytype) !void {
        const disc: EnvelopeType = switch (self) {
            .OpId => .OpId,
            .PoolRevokeOpId => .PoolRevokeOpId,
            .ContractId => .ContractId,
            .SorobanAuthorization => .SorobanAuthorization,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .OpId => |v| try xdrEncodeGeneric(HashIdPreimageOperationId, writer, v),
            .PoolRevokeOpId => |v| try xdrEncodeGeneric(HashIdPreimageRevokeId, writer, v),
            .ContractId => |v| try xdrEncodeGeneric(HashIdPreimageContractId, writer, v),
            .SorobanAuthorization => |v| try xdrEncodeGeneric(HashIdPreimageSorobanAuthorization, writer, v),
        }
    }
};

/// MemoType is an XDR Enum defined as:
///
/// ```text
/// enum MemoType
/// {
///     MEMO_NONE = 0,
///     MEMO_TEXT = 1,
///     MEMO_ID = 2,
///     MEMO_HASH = 3,
///     MEMO_RETURN = 4
/// };
/// ```
///
pub const MemoType = enum(i32) {
    None = 0,
    Text = 1,
    Id = 2,
    Hash = 3,
    Return = 4,
    _,

    pub const variants = [_]MemoType{
        .None,
        .Text,
        .Id,
        .Hash,
        .Return,
    };

    pub fn name(self: MemoType) []const u8 {
        return switch (self) {
            .None => "None",
            .Text => "Text",
            .Id => "Id",
            .Hash => "Hash",
            .Return => "Return",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !MemoType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: MemoType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// Memo is an XDR Union defined as:
///
/// ```text
/// union Memo switch (MemoType type)
/// {
/// case MEMO_NONE:
///     void;
/// case MEMO_TEXT:
///     string text<28>;
/// case MEMO_ID:
///     uint64 id;
/// case MEMO_HASH:
///     Hash hash; // the hash of what to pull from the content server
/// case MEMO_RETURN:
///     Hash retHash; // the hash of the tx you are rejecting
/// };
/// ```
///
pub const Memo = union(enum) {
    None,
    Text: BoundedArray(u8, 28),
    Id: u64,
    Hash: Hash,
    Return: Hash,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !Memo {
        const disc = try MemoType.xdrDecode(allocator, reader);
        return switch (disc) {
            .None => Memo{ .None = {} },
            .Text => Memo{ .Text = try xdrDecodeGeneric(BoundedArray(u8, 28), allocator, reader) },
            .Id => Memo{ .Id = try xdrDecodeGeneric(u64, allocator, reader) },
            .Hash => Memo{ .Hash = try xdrDecodeGeneric(Hash, allocator, reader) },
            .Return => Memo{ .Return = try xdrDecodeGeneric(Hash, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: Memo, writer: anytype) !void {
        const disc: MemoType = switch (self) {
            .None => .None,
            .Text => .Text,
            .Id => .Id,
            .Hash => .Hash,
            .Return => .Return,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .None => {},
            .Text => |v| try xdrEncodeGeneric(BoundedArray(u8, 28), writer, v),
            .Id => |v| try xdrEncodeGeneric(u64, writer, v),
            .Hash => |v| try xdrEncodeGeneric(Hash, writer, v),
            .Return => |v| try xdrEncodeGeneric(Hash, writer, v),
        }
    }
};

/// TimeBounds is an XDR Struct defined as:
///
/// ```text
/// struct TimeBounds
/// {
///     TimePoint minTime;
///     TimePoint maxTime; // 0 here means no maxTime
/// };
/// ```
///
pub const TimeBounds = struct {
    min_time: TimePoint,
    max_time: TimePoint,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TimeBounds {
        return TimeBounds{
            .min_time = try xdrDecodeGeneric(TimePoint, allocator, reader),
            .max_time = try xdrDecodeGeneric(TimePoint, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TimeBounds, writer: anytype) !void {
        try xdrEncodeGeneric(TimePoint, writer, self.min_time);
        try xdrEncodeGeneric(TimePoint, writer, self.max_time);
    }
};

/// LedgerBounds is an XDR Struct defined as:
///
/// ```text
/// struct LedgerBounds
/// {
///     uint32 minLedger;
///     uint32 maxLedger; // 0 here means no maxLedger
/// };
/// ```
///
pub const LedgerBounds = struct {
    min_ledger: u32,
    max_ledger: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerBounds {
        return LedgerBounds{
            .min_ledger = try xdrDecodeGeneric(u32, allocator, reader),
            .max_ledger = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LedgerBounds, writer: anytype) !void {
        try xdrEncodeGeneric(u32, writer, self.min_ledger);
        try xdrEncodeGeneric(u32, writer, self.max_ledger);
    }
};

/// PreconditionsV2 is an XDR Struct defined as:
///
/// ```text
/// struct PreconditionsV2
/// {
///     TimeBounds* timeBounds;
///
///     // Transaction only valid for ledger numbers n such that
///     // minLedger <= n < maxLedger (if maxLedger == 0, then
///     // only minLedger is checked)
///     LedgerBounds* ledgerBounds;
///
///     // If NULL, only valid when sourceAccount's sequence number
///     // is seqNum - 1.  Otherwise, valid when sourceAccount's
///     // sequence number n satisfies minSeqNum <= n < tx.seqNum.
///     // Note that after execution the account's sequence number
///     // is always raised to tx.seqNum, and a transaction is not
///     // valid if tx.seqNum is too high to ensure replay protection.
///     SequenceNumber* minSeqNum;
///
///     // For the transaction to be valid, the current ledger time must
///     // be at least minSeqAge greater than sourceAccount's seqTime.
///     Duration minSeqAge;
///
///     // For the transaction to be valid, the current ledger number
///     // must be at least minSeqLedgerGap greater than sourceAccount's
///     // seqLedger.
///     uint32 minSeqLedgerGap;
///
///     // For the transaction to be valid, there must be a signature
///     // corresponding to every Signer in this array, even if the
///     // signature is not otherwise required by the sourceAccount or
///     // operations.
///     SignerKey extraSigners<2>;
/// };
/// ```
///
pub const PreconditionsV2 = struct {
    time_bounds: ?TimeBounds,
    ledger_bounds: ?LedgerBounds,
    min_seq_num: ?SequenceNumber,
    min_seq_age: Duration,
    min_seq_ledger_gap: u32,
    extra_signers: BoundedArray(SignerKey, 2),

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !PreconditionsV2 {
        return PreconditionsV2{
            .time_bounds = try xdrDecodeGeneric(?TimeBounds, allocator, reader),
            .ledger_bounds = try xdrDecodeGeneric(?LedgerBounds, allocator, reader),
            .min_seq_num = try xdrDecodeGeneric(?SequenceNumber, allocator, reader),
            .min_seq_age = try xdrDecodeGeneric(Duration, allocator, reader),
            .min_seq_ledger_gap = try xdrDecodeGeneric(u32, allocator, reader),
            .extra_signers = try xdrDecodeGeneric(BoundedArray(SignerKey, 2), allocator, reader),
        };
    }

    pub fn xdrEncode(self: PreconditionsV2, writer: anytype) !void {
        try xdrEncodeGeneric(?TimeBounds, writer, self.time_bounds);
        try xdrEncodeGeneric(?LedgerBounds, writer, self.ledger_bounds);
        try xdrEncodeGeneric(?SequenceNumber, writer, self.min_seq_num);
        try xdrEncodeGeneric(Duration, writer, self.min_seq_age);
        try xdrEncodeGeneric(u32, writer, self.min_seq_ledger_gap);
        try xdrEncodeGeneric(BoundedArray(SignerKey, 2), writer, self.extra_signers);
    }
};

/// PreconditionType is an XDR Enum defined as:
///
/// ```text
/// enum PreconditionType
/// {
///     PRECOND_NONE = 0,
///     PRECOND_TIME = 1,
///     PRECOND_V2 = 2
/// };
/// ```
///
pub const PreconditionType = enum(i32) {
    None = 0,
    Time = 1,
    V2 = 2,
    _,

    pub const variants = [_]PreconditionType{
        .None,
        .Time,
        .V2,
    };

    pub fn name(self: PreconditionType) []const u8 {
        return switch (self) {
            .None => "None",
            .Time => "Time",
            .V2 => "V2",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !PreconditionType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: PreconditionType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// Preconditions is an XDR Union defined as:
///
/// ```text
/// union Preconditions switch (PreconditionType type)
/// {
/// case PRECOND_NONE:
///     void;
/// case PRECOND_TIME:
///     TimeBounds timeBounds;
/// case PRECOND_V2:
///     PreconditionsV2 v2;
/// };
/// ```
///
pub const Preconditions = union(enum) {
    None,
    Time: TimeBounds,
    V2: PreconditionsV2,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !Preconditions {
        const disc = try PreconditionType.xdrDecode(allocator, reader);
        return switch (disc) {
            .None => Preconditions{ .None = {} },
            .Time => Preconditions{ .Time = try xdrDecodeGeneric(TimeBounds, allocator, reader) },
            .V2 => Preconditions{ .V2 = try xdrDecodeGeneric(PreconditionsV2, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: Preconditions, writer: anytype) !void {
        const disc: PreconditionType = switch (self) {
            .None => .None,
            .Time => .Time,
            .V2 => .V2,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .None => {},
            .Time => |v| try xdrEncodeGeneric(TimeBounds, writer, v),
            .V2 => |v| try xdrEncodeGeneric(PreconditionsV2, writer, v),
        }
    }
};

/// LedgerFootprint is an XDR Struct defined as:
///
/// ```text
/// struct LedgerFootprint
/// {
///     LedgerKey readOnly<>;
///     LedgerKey readWrite<>;
/// };
/// ```
///
pub const LedgerFootprint = struct {
    read_only: []LedgerKey,
    read_write: []LedgerKey,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LedgerFootprint {
        return LedgerFootprint{
            .read_only = try xdrDecodeGeneric([]LedgerKey, allocator, reader),
            .read_write = try xdrDecodeGeneric([]LedgerKey, allocator, reader),
        };
    }

    pub fn xdrEncode(self: LedgerFootprint, writer: anytype) !void {
        try xdrEncodeGeneric([]LedgerKey, writer, self.read_only);
        try xdrEncodeGeneric([]LedgerKey, writer, self.read_write);
    }
};

/// SorobanResources is an XDR Struct defined as:
///
/// ```text
/// struct SorobanResources
/// {
///     // The ledger footprint of the transaction.
///     LedgerFootprint footprint;
///     // The maximum number of instructions this transaction can use
///     uint32 instructions;
///
///     // The maximum number of bytes this transaction can read from disk backed entries
///     uint32 diskReadBytes;
///     // The maximum number of bytes this transaction can write to ledger
///     uint32 writeBytes;
/// };
/// ```
///
pub const SorobanResources = struct {
    footprint: LedgerFootprint,
    instructions: u32,
    disk_read_bytes: u32,
    write_bytes: u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SorobanResources {
        return SorobanResources{
            .footprint = try xdrDecodeGeneric(LedgerFootprint, allocator, reader),
            .instructions = try xdrDecodeGeneric(u32, allocator, reader),
            .disk_read_bytes = try xdrDecodeGeneric(u32, allocator, reader),
            .write_bytes = try xdrDecodeGeneric(u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: SorobanResources, writer: anytype) !void {
        try xdrEncodeGeneric(LedgerFootprint, writer, self.footprint);
        try xdrEncodeGeneric(u32, writer, self.instructions);
        try xdrEncodeGeneric(u32, writer, self.disk_read_bytes);
        try xdrEncodeGeneric(u32, writer, self.write_bytes);
    }
};

/// SorobanResourcesExtV0 is an XDR Struct defined as:
///
/// ```text
/// struct SorobanResourcesExtV0
/// {
///     // Vector of indices representing what Soroban
///     // entries in the footprint are archived, based on the
///     // order of keys provided in the readWrite footprint.
///     uint32 archivedSorobanEntries<>;
/// };
/// ```
///
pub const SorobanResourcesExtV0 = struct {
    archived_soroban_entries: []u32,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SorobanResourcesExtV0 {
        return SorobanResourcesExtV0{
            .archived_soroban_entries = try xdrDecodeGeneric([]u32, allocator, reader),
        };
    }

    pub fn xdrEncode(self: SorobanResourcesExtV0, writer: anytype) !void {
        try xdrEncodeGeneric([]u32, writer, self.archived_soroban_entries);
    }
};

/// SorobanTransactionDataExt is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (int v)
///     {
///     case 0:
///         void;
///     case 1:
///         SorobanResourcesExtV0 resourceExt;
///     }
/// ```
///
pub const SorobanTransactionDataExt = union(enum) {
    V0,
    V1: SorobanResourcesExtV0,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SorobanTransactionDataExt {
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => SorobanTransactionDataExt{ .V0 = {} },
            1 => SorobanTransactionDataExt{ .V1 = try xdrDecodeGeneric(SorobanResourcesExtV0, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: SorobanTransactionDataExt, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
            .V1 => |v| {
                try writer.writeInt(i32, 1, .big);
                try xdrEncodeGeneric(SorobanResourcesExtV0, writer, v);
            },
        }
    }
};

/// SorobanTransactionData is an XDR Struct defined as:
///
/// ```text
/// struct SorobanTransactionData
/// {
///     union switch (int v)
///     {
///     case 0:
///         void;
///     case 1:
///         SorobanResourcesExtV0 resourceExt;
///     } ext;
///     SorobanResources resources;
///     // Amount of the transaction `fee` allocated to the Soroban resource fees.
///     // The fraction of `resourceFee` corresponding to `resources` specified
///     // above is *not* refundable (i.e. fees for instructions, ledger I/O), as
///     // well as fees for the transaction size.
///     // The remaining part of the fee is refundable and the charged value is
///     // based on the actual consumption of refundable resources (events, ledger
///     // rent bumps).
///     // The `inclusionFee` used for prioritization of the transaction is defined
///     // as `tx.fee - resourceFee`.
///     int64 resourceFee;
/// };
/// ```
///
pub const SorobanTransactionData = struct {
    ext: SorobanTransactionDataExt,
    resources: SorobanResources,
    resource_fee: i64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SorobanTransactionData {
        return SorobanTransactionData{
            .ext = try xdrDecodeGeneric(SorobanTransactionDataExt, allocator, reader),
            .resources = try xdrDecodeGeneric(SorobanResources, allocator, reader),
            .resource_fee = try xdrDecodeGeneric(i64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: SorobanTransactionData, writer: anytype) !void {
        try xdrEncodeGeneric(SorobanTransactionDataExt, writer, self.ext);
        try xdrEncodeGeneric(SorobanResources, writer, self.resources);
        try xdrEncodeGeneric(i64, writer, self.resource_fee);
    }
};

/// TransactionV0Ext is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (int v)
///     {
///     case 0:
///         void;
///     }
/// ```
///
pub const TransactionV0Ext = union(enum) {
    V0,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionV0Ext {
        _ = allocator;
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => TransactionV0Ext{ .V0 = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: TransactionV0Ext, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
        }
    }
};

/// TransactionV0 is an XDR Struct defined as:
///
/// ```text
/// struct TransactionV0
/// {
///     uint256 sourceAccountEd25519;
///     uint32 fee;
///     SequenceNumber seqNum;
///     TimeBounds* timeBounds;
///     Memo memo;
///     Operation operations<MAX_OPS_PER_TX>;
///     union switch (int v)
///     {
///     case 0:
///         void;
///     }
///     ext;
/// };
/// ```
///
pub const TransactionV0 = struct {
    source_account_ed25519: Uint256,
    fee: u32,
    seq_num: SequenceNumber,
    time_bounds: ?TimeBounds,
    memo: Memo,
    operations: BoundedArray(Operation, 100),
    ext: TransactionV0Ext,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionV0 {
        return TransactionV0{
            .source_account_ed25519 = try xdrDecodeGeneric(Uint256, allocator, reader),
            .fee = try xdrDecodeGeneric(u32, allocator, reader),
            .seq_num = try xdrDecodeGeneric(SequenceNumber, allocator, reader),
            .time_bounds = try xdrDecodeGeneric(?TimeBounds, allocator, reader),
            .memo = try xdrDecodeGeneric(Memo, allocator, reader),
            .operations = try xdrDecodeGeneric(BoundedArray(Operation, 100), allocator, reader),
            .ext = try xdrDecodeGeneric(TransactionV0Ext, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TransactionV0, writer: anytype) !void {
        try xdrEncodeGeneric(Uint256, writer, self.source_account_ed25519);
        try xdrEncodeGeneric(u32, writer, self.fee);
        try xdrEncodeGeneric(SequenceNumber, writer, self.seq_num);
        try xdrEncodeGeneric(?TimeBounds, writer, self.time_bounds);
        try xdrEncodeGeneric(Memo, writer, self.memo);
        try xdrEncodeGeneric(BoundedArray(Operation, 100), writer, self.operations);
        try xdrEncodeGeneric(TransactionV0Ext, writer, self.ext);
    }
};

/// TransactionV0Envelope is an XDR Struct defined as:
///
/// ```text
/// struct TransactionV0Envelope
/// {
///     TransactionV0 tx;
///     /* Each decorated signature is a signature over the SHA256 hash of
///      * a TransactionSignaturePayload */
///     DecoratedSignature signatures<20>;
/// };
/// ```
///
pub const TransactionV0Envelope = struct {
    tx: TransactionV0,
    signatures: BoundedArray(DecoratedSignature, 20),

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionV0Envelope {
        return TransactionV0Envelope{
            .tx = try xdrDecodeGeneric(TransactionV0, allocator, reader),
            .signatures = try xdrDecodeGeneric(BoundedArray(DecoratedSignature, 20), allocator, reader),
        };
    }

    pub fn xdrEncode(self: TransactionV0Envelope, writer: anytype) !void {
        try xdrEncodeGeneric(TransactionV0, writer, self.tx);
        try xdrEncodeGeneric(BoundedArray(DecoratedSignature, 20), writer, self.signatures);
    }
};

/// TransactionExt is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (int v)
///     {
///     case 0:
///         void;
///     case 1:
///         SorobanTransactionData sorobanData;
///     }
/// ```
///
pub const TransactionExt = union(enum) {
    V0,
    V1: SorobanTransactionData,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionExt {
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => TransactionExt{ .V0 = {} },
            1 => TransactionExt{ .V1 = try xdrDecodeGeneric(SorobanTransactionData, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: TransactionExt, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
            .V1 => |v| {
                try writer.writeInt(i32, 1, .big);
                try xdrEncodeGeneric(SorobanTransactionData, writer, v);
            },
        }
    }
};

/// Transaction is an XDR Struct defined as:
///
/// ```text
/// struct Transaction
/// {
///     // account used to run the transaction
///     MuxedAccount sourceAccount;
///
///     // the fee the sourceAccount will pay
///     uint32 fee;
///
///     // sequence number to consume in the account
///     SequenceNumber seqNum;
///
///     // validity conditions
///     Preconditions cond;
///
///     Memo memo;
///
///     Operation operations<MAX_OPS_PER_TX>;
///
///     union switch (int v)
///     {
///     case 0:
///         void;
///     case 1:
///         SorobanTransactionData sorobanData;
///     }
///     ext;
/// };
/// ```
///
pub const Transaction = struct {
    source_account: MuxedAccount,
    fee: u32,
    seq_num: SequenceNumber,
    cond: Preconditions,
    memo: Memo,
    operations: BoundedArray(Operation, 100),
    ext: TransactionExt,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !Transaction {
        return Transaction{
            .source_account = try xdrDecodeGeneric(MuxedAccount, allocator, reader),
            .fee = try xdrDecodeGeneric(u32, allocator, reader),
            .seq_num = try xdrDecodeGeneric(SequenceNumber, allocator, reader),
            .cond = try xdrDecodeGeneric(Preconditions, allocator, reader),
            .memo = try xdrDecodeGeneric(Memo, allocator, reader),
            .operations = try xdrDecodeGeneric(BoundedArray(Operation, 100), allocator, reader),
            .ext = try xdrDecodeGeneric(TransactionExt, allocator, reader),
        };
    }

    pub fn xdrEncode(self: Transaction, writer: anytype) !void {
        try xdrEncodeGeneric(MuxedAccount, writer, self.source_account);
        try xdrEncodeGeneric(u32, writer, self.fee);
        try xdrEncodeGeneric(SequenceNumber, writer, self.seq_num);
        try xdrEncodeGeneric(Preconditions, writer, self.cond);
        try xdrEncodeGeneric(Memo, writer, self.memo);
        try xdrEncodeGeneric(BoundedArray(Operation, 100), writer, self.operations);
        try xdrEncodeGeneric(TransactionExt, writer, self.ext);
    }
};

/// TransactionV1Envelope is an XDR Struct defined as:
///
/// ```text
/// struct TransactionV1Envelope
/// {
///     Transaction tx;
///     /* Each decorated signature is a signature over the SHA256 hash of
///      * a TransactionSignaturePayload */
///     DecoratedSignature signatures<20>;
/// };
/// ```
///
pub const TransactionV1Envelope = struct {
    tx: Transaction,
    signatures: BoundedArray(DecoratedSignature, 20),

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionV1Envelope {
        return TransactionV1Envelope{
            .tx = try xdrDecodeGeneric(Transaction, allocator, reader),
            .signatures = try xdrDecodeGeneric(BoundedArray(DecoratedSignature, 20), allocator, reader),
        };
    }

    pub fn xdrEncode(self: TransactionV1Envelope, writer: anytype) !void {
        try xdrEncodeGeneric(Transaction, writer, self.tx);
        try xdrEncodeGeneric(BoundedArray(DecoratedSignature, 20), writer, self.signatures);
    }
};

/// FeeBumpTransactionInnerTx is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (EnvelopeType type)
///     {
///     case ENVELOPE_TYPE_TX:
///         TransactionV1Envelope v1;
///     }
/// ```
///
pub const FeeBumpTransactionInnerTx = union(enum) {
    Tx: TransactionV1Envelope,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !FeeBumpTransactionInnerTx {
        const disc = try EnvelopeType.xdrDecode(allocator, reader);
        return switch (disc) {
            .Tx => FeeBumpTransactionInnerTx{ .Tx = try xdrDecodeGeneric(TransactionV1Envelope, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: FeeBumpTransactionInnerTx, writer: anytype) !void {
        const disc: EnvelopeType = switch (self) {
            .Tx => .Tx,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Tx => |v| try xdrEncodeGeneric(TransactionV1Envelope, writer, v),
        }
    }
};

/// FeeBumpTransactionExt is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (int v)
///     {
///     case 0:
///         void;
///     }
/// ```
///
pub const FeeBumpTransactionExt = union(enum) {
    V0,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !FeeBumpTransactionExt {
        _ = allocator;
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => FeeBumpTransactionExt{ .V0 = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: FeeBumpTransactionExt, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
        }
    }
};

/// FeeBumpTransaction is an XDR Struct defined as:
///
/// ```text
/// struct FeeBumpTransaction
/// {
///     MuxedAccount feeSource;
///     int64 fee;
///     union switch (EnvelopeType type)
///     {
///     case ENVELOPE_TYPE_TX:
///         TransactionV1Envelope v1;
///     }
///     innerTx;
///     union switch (int v)
///     {
///     case 0:
///         void;
///     }
///     ext;
/// };
/// ```
///
pub const FeeBumpTransaction = struct {
    fee_source: MuxedAccount,
    fee: i64,
    inner_tx: FeeBumpTransactionInnerTx,
    ext: FeeBumpTransactionExt,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !FeeBumpTransaction {
        return FeeBumpTransaction{
            .fee_source = try xdrDecodeGeneric(MuxedAccount, allocator, reader),
            .fee = try xdrDecodeGeneric(i64, allocator, reader),
            .inner_tx = try xdrDecodeGeneric(FeeBumpTransactionInnerTx, allocator, reader),
            .ext = try xdrDecodeGeneric(FeeBumpTransactionExt, allocator, reader),
        };
    }

    pub fn xdrEncode(self: FeeBumpTransaction, writer: anytype) !void {
        try xdrEncodeGeneric(MuxedAccount, writer, self.fee_source);
        try xdrEncodeGeneric(i64, writer, self.fee);
        try xdrEncodeGeneric(FeeBumpTransactionInnerTx, writer, self.inner_tx);
        try xdrEncodeGeneric(FeeBumpTransactionExt, writer, self.ext);
    }
};

/// FeeBumpTransactionEnvelope is an XDR Struct defined as:
///
/// ```text
/// struct FeeBumpTransactionEnvelope
/// {
///     FeeBumpTransaction tx;
///     /* Each decorated signature is a signature over the SHA256 hash of
///      * a TransactionSignaturePayload */
///     DecoratedSignature signatures<20>;
/// };
/// ```
///
pub const FeeBumpTransactionEnvelope = struct {
    tx: FeeBumpTransaction,
    signatures: BoundedArray(DecoratedSignature, 20),

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !FeeBumpTransactionEnvelope {
        return FeeBumpTransactionEnvelope{
            .tx = try xdrDecodeGeneric(FeeBumpTransaction, allocator, reader),
            .signatures = try xdrDecodeGeneric(BoundedArray(DecoratedSignature, 20), allocator, reader),
        };
    }

    pub fn xdrEncode(self: FeeBumpTransactionEnvelope, writer: anytype) !void {
        try xdrEncodeGeneric(FeeBumpTransaction, writer, self.tx);
        try xdrEncodeGeneric(BoundedArray(DecoratedSignature, 20), writer, self.signatures);
    }
};

/// TransactionEnvelope is an XDR Union defined as:
///
/// ```text
/// union TransactionEnvelope switch (EnvelopeType type)
/// {
/// case ENVELOPE_TYPE_TX_V0:
///     TransactionV0Envelope v0;
/// case ENVELOPE_TYPE_TX:
///     TransactionV1Envelope v1;
/// case ENVELOPE_TYPE_TX_FEE_BUMP:
///     FeeBumpTransactionEnvelope feeBump;
/// };
/// ```
///
pub const TransactionEnvelope = union(enum) {
    TxV0: TransactionV0Envelope,
    Tx: TransactionV1Envelope,
    TxFeeBump: FeeBumpTransactionEnvelope,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionEnvelope {
        const disc = try EnvelopeType.xdrDecode(allocator, reader);
        return switch (disc) {
            .TxV0 => TransactionEnvelope{ .TxV0 = try xdrDecodeGeneric(TransactionV0Envelope, allocator, reader) },
            .Tx => TransactionEnvelope{ .Tx = try xdrDecodeGeneric(TransactionV1Envelope, allocator, reader) },
            .TxFeeBump => TransactionEnvelope{ .TxFeeBump = try xdrDecodeGeneric(FeeBumpTransactionEnvelope, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: TransactionEnvelope, writer: anytype) !void {
        const disc: EnvelopeType = switch (self) {
            .TxV0 => .TxV0,
            .Tx => .Tx,
            .TxFeeBump => .TxFeeBump,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .TxV0 => |v| try xdrEncodeGeneric(TransactionV0Envelope, writer, v),
            .Tx => |v| try xdrEncodeGeneric(TransactionV1Envelope, writer, v),
            .TxFeeBump => |v| try xdrEncodeGeneric(FeeBumpTransactionEnvelope, writer, v),
        }
    }
};

/// TransactionSignaturePayloadTaggedTransaction is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (EnvelopeType type)
///     {
///     // Backwards Compatibility: Use ENVELOPE_TYPE_TX to sign ENVELOPE_TYPE_TX_V0
///     case ENVELOPE_TYPE_TX:
///         Transaction tx;
///     case ENVELOPE_TYPE_TX_FEE_BUMP:
///         FeeBumpTransaction feeBump;
///     }
/// ```
///
pub const TransactionSignaturePayloadTaggedTransaction = union(enum) {
    Tx: Transaction,
    TxFeeBump: FeeBumpTransaction,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionSignaturePayloadTaggedTransaction {
        const disc = try EnvelopeType.xdrDecode(allocator, reader);
        return switch (disc) {
            .Tx => TransactionSignaturePayloadTaggedTransaction{ .Tx = try xdrDecodeGeneric(Transaction, allocator, reader) },
            .TxFeeBump => TransactionSignaturePayloadTaggedTransaction{ .TxFeeBump = try xdrDecodeGeneric(FeeBumpTransaction, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: TransactionSignaturePayloadTaggedTransaction, writer: anytype) !void {
        const disc: EnvelopeType = switch (self) {
            .Tx => .Tx,
            .TxFeeBump => .TxFeeBump,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Tx => |v| try xdrEncodeGeneric(Transaction, writer, v),
            .TxFeeBump => |v| try xdrEncodeGeneric(FeeBumpTransaction, writer, v),
        }
    }
};

/// TransactionSignaturePayload is an XDR Struct defined as:
///
/// ```text
/// struct TransactionSignaturePayload
/// {
///     Hash networkId;
///     union switch (EnvelopeType type)
///     {
///     // Backwards Compatibility: Use ENVELOPE_TYPE_TX to sign ENVELOPE_TYPE_TX_V0
///     case ENVELOPE_TYPE_TX:
///         Transaction tx;
///     case ENVELOPE_TYPE_TX_FEE_BUMP:
///         FeeBumpTransaction feeBump;
///     }
///     taggedTransaction;
/// };
/// ```
///
pub const TransactionSignaturePayload = struct {
    network_id: Hash,
    tagged_transaction: TransactionSignaturePayloadTaggedTransaction,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionSignaturePayload {
        return TransactionSignaturePayload{
            .network_id = try xdrDecodeGeneric(Hash, allocator, reader),
            .tagged_transaction = try xdrDecodeGeneric(TransactionSignaturePayloadTaggedTransaction, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TransactionSignaturePayload, writer: anytype) !void {
        try xdrEncodeGeneric(Hash, writer, self.network_id);
        try xdrEncodeGeneric(TransactionSignaturePayloadTaggedTransaction, writer, self.tagged_transaction);
    }
};

/// ClaimAtomType is an XDR Enum defined as:
///
/// ```text
/// enum ClaimAtomType
/// {
///     CLAIM_ATOM_TYPE_V0 = 0,
///     CLAIM_ATOM_TYPE_ORDER_BOOK = 1,
///     CLAIM_ATOM_TYPE_LIQUIDITY_POOL = 2
/// };
/// ```
///
pub const ClaimAtomType = enum(i32) {
    V0 = 0,
    OrderBook = 1,
    LiquidityPool = 2,
    _,

    pub const variants = [_]ClaimAtomType{
        .V0,
        .OrderBook,
        .LiquidityPool,
    };

    pub fn name(self: ClaimAtomType) []const u8 {
        return switch (self) {
            .V0 => "V0",
            .OrderBook => "OrderBook",
            .LiquidityPool => "LiquidityPool",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ClaimAtomType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ClaimAtomType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ClaimOfferAtomV0 is an XDR Struct defined as:
///
/// ```text
/// struct ClaimOfferAtomV0
/// {
///     // emitted to identify the offer
///     uint256 sellerEd25519; // Account that owns the offer
///     int64 offerID;
///
///     // amount and asset taken from the owner
///     Asset assetSold;
///     int64 amountSold;
///
///     // amount and asset sent to the owner
///     Asset assetBought;
///     int64 amountBought;
/// };
/// ```
///
pub const ClaimOfferAtomV0 = struct {
    seller_ed25519: Uint256,
    offer_id: i64,
    asset_sold: Asset,
    amount_sold: i64,
    asset_bought: Asset,
    amount_bought: i64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ClaimOfferAtomV0 {
        return ClaimOfferAtomV0{
            .seller_ed25519 = try xdrDecodeGeneric(Uint256, allocator, reader),
            .offer_id = try xdrDecodeGeneric(i64, allocator, reader),
            .asset_sold = try xdrDecodeGeneric(Asset, allocator, reader),
            .amount_sold = try xdrDecodeGeneric(i64, allocator, reader),
            .asset_bought = try xdrDecodeGeneric(Asset, allocator, reader),
            .amount_bought = try xdrDecodeGeneric(i64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ClaimOfferAtomV0, writer: anytype) !void {
        try xdrEncodeGeneric(Uint256, writer, self.seller_ed25519);
        try xdrEncodeGeneric(i64, writer, self.offer_id);
        try xdrEncodeGeneric(Asset, writer, self.asset_sold);
        try xdrEncodeGeneric(i64, writer, self.amount_sold);
        try xdrEncodeGeneric(Asset, writer, self.asset_bought);
        try xdrEncodeGeneric(i64, writer, self.amount_bought);
    }
};

/// ClaimOfferAtom is an XDR Struct defined as:
///
/// ```text
/// struct ClaimOfferAtom
/// {
///     // emitted to identify the offer
///     AccountID sellerID; // Account that owns the offer
///     int64 offerID;
///
///     // amount and asset taken from the owner
///     Asset assetSold;
///     int64 amountSold;
///
///     // amount and asset sent to the owner
///     Asset assetBought;
///     int64 amountBought;
/// };
/// ```
///
pub const ClaimOfferAtom = struct {
    seller_id: AccountId,
    offer_id: i64,
    asset_sold: Asset,
    amount_sold: i64,
    asset_bought: Asset,
    amount_bought: i64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ClaimOfferAtom {
        return ClaimOfferAtom{
            .seller_id = try xdrDecodeGeneric(AccountId, allocator, reader),
            .offer_id = try xdrDecodeGeneric(i64, allocator, reader),
            .asset_sold = try xdrDecodeGeneric(Asset, allocator, reader),
            .amount_sold = try xdrDecodeGeneric(i64, allocator, reader),
            .asset_bought = try xdrDecodeGeneric(Asset, allocator, reader),
            .amount_bought = try xdrDecodeGeneric(i64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ClaimOfferAtom, writer: anytype) !void {
        try xdrEncodeGeneric(AccountId, writer, self.seller_id);
        try xdrEncodeGeneric(i64, writer, self.offer_id);
        try xdrEncodeGeneric(Asset, writer, self.asset_sold);
        try xdrEncodeGeneric(i64, writer, self.amount_sold);
        try xdrEncodeGeneric(Asset, writer, self.asset_bought);
        try xdrEncodeGeneric(i64, writer, self.amount_bought);
    }
};

/// ClaimLiquidityAtom is an XDR Struct defined as:
///
/// ```text
/// struct ClaimLiquidityAtom
/// {
///     PoolID liquidityPoolID;
///
///     // amount and asset taken from the pool
///     Asset assetSold;
///     int64 amountSold;
///
///     // amount and asset sent to the pool
///     Asset assetBought;
///     int64 amountBought;
/// };
/// ```
///
pub const ClaimLiquidityAtom = struct {
    liquidity_pool_id: PoolId,
    asset_sold: Asset,
    amount_sold: i64,
    asset_bought: Asset,
    amount_bought: i64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ClaimLiquidityAtom {
        return ClaimLiquidityAtom{
            .liquidity_pool_id = try xdrDecodeGeneric(PoolId, allocator, reader),
            .asset_sold = try xdrDecodeGeneric(Asset, allocator, reader),
            .amount_sold = try xdrDecodeGeneric(i64, allocator, reader),
            .asset_bought = try xdrDecodeGeneric(Asset, allocator, reader),
            .amount_bought = try xdrDecodeGeneric(i64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ClaimLiquidityAtom, writer: anytype) !void {
        try xdrEncodeGeneric(PoolId, writer, self.liquidity_pool_id);
        try xdrEncodeGeneric(Asset, writer, self.asset_sold);
        try xdrEncodeGeneric(i64, writer, self.amount_sold);
        try xdrEncodeGeneric(Asset, writer, self.asset_bought);
        try xdrEncodeGeneric(i64, writer, self.amount_bought);
    }
};

/// ClaimAtom is an XDR Union defined as:
///
/// ```text
/// union ClaimAtom switch (ClaimAtomType type)
/// {
/// case CLAIM_ATOM_TYPE_V0:
///     ClaimOfferAtomV0 v0;
/// case CLAIM_ATOM_TYPE_ORDER_BOOK:
///     ClaimOfferAtom orderBook;
/// case CLAIM_ATOM_TYPE_LIQUIDITY_POOL:
///     ClaimLiquidityAtom liquidityPool;
/// };
/// ```
///
pub const ClaimAtom = union(enum) {
    V0: ClaimOfferAtomV0,
    OrderBook: ClaimOfferAtom,
    LiquidityPool: ClaimLiquidityAtom,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ClaimAtom {
        const disc = try ClaimAtomType.xdrDecode(allocator, reader);
        return switch (disc) {
            .V0 => ClaimAtom{ .V0 = try xdrDecodeGeneric(ClaimOfferAtomV0, allocator, reader) },
            .OrderBook => ClaimAtom{ .OrderBook = try xdrDecodeGeneric(ClaimOfferAtom, allocator, reader) },
            .LiquidityPool => ClaimAtom{ .LiquidityPool = try xdrDecodeGeneric(ClaimLiquidityAtom, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ClaimAtom, writer: anytype) !void {
        const disc: ClaimAtomType = switch (self) {
            .V0 => .V0,
            .OrderBook => .OrderBook,
            .LiquidityPool => .LiquidityPool,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .V0 => |v| try xdrEncodeGeneric(ClaimOfferAtomV0, writer, v),
            .OrderBook => |v| try xdrEncodeGeneric(ClaimOfferAtom, writer, v),
            .LiquidityPool => |v| try xdrEncodeGeneric(ClaimLiquidityAtom, writer, v),
        }
    }
};

/// CreateAccountResultCode is an XDR Enum defined as:
///
/// ```text
/// enum CreateAccountResultCode
/// {
///     // codes considered as "success" for the operation
///     CREATE_ACCOUNT_SUCCESS = 0, // account was created
///
///     // codes considered as "failure" for the operation
///     CREATE_ACCOUNT_MALFORMED = -1,   // invalid destination
///     CREATE_ACCOUNT_UNDERFUNDED = -2, // not enough funds in source account
///     CREATE_ACCOUNT_LOW_RESERVE =
///         -3, // would create an account below the min reserve
///     CREATE_ACCOUNT_ALREADY_EXIST = -4 // account already exists
/// };
/// ```
///
pub const CreateAccountResultCode = enum(i32) {
    Success = 0,
    Malformed = -1,
    Underfunded = -2,
    LowReserve = -3,
    AlreadyExist = -4,
    _,

    pub const variants = [_]CreateAccountResultCode{
        .Success,
        .Malformed,
        .Underfunded,
        .LowReserve,
        .AlreadyExist,
    };

    pub fn name(self: CreateAccountResultCode) []const u8 {
        return switch (self) {
            .Success => "Success",
            .Malformed => "Malformed",
            .Underfunded => "Underfunded",
            .LowReserve => "LowReserve",
            .AlreadyExist => "AlreadyExist",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !CreateAccountResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: CreateAccountResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// CreateAccountResult is an XDR Union defined as:
///
/// ```text
/// union CreateAccountResult switch (CreateAccountResultCode code)
/// {
/// case CREATE_ACCOUNT_SUCCESS:
///     void;
/// case CREATE_ACCOUNT_MALFORMED:
/// case CREATE_ACCOUNT_UNDERFUNDED:
/// case CREATE_ACCOUNT_LOW_RESERVE:
/// case CREATE_ACCOUNT_ALREADY_EXIST:
///     void;
/// };
/// ```
///
pub const CreateAccountResult = union(enum) {
    Success,
    Malformed,
    Underfunded,
    LowReserve,
    AlreadyExist,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !CreateAccountResult {
        const disc = try CreateAccountResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .Success => CreateAccountResult{ .Success = {} },
            .Malformed => CreateAccountResult{ .Malformed = {} },
            .Underfunded => CreateAccountResult{ .Underfunded = {} },
            .LowReserve => CreateAccountResult{ .LowReserve = {} },
            .AlreadyExist => CreateAccountResult{ .AlreadyExist = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: CreateAccountResult, writer: anytype) !void {
        const disc: CreateAccountResultCode = switch (self) {
            .Success => .Success,
            .Malformed => .Malformed,
            .Underfunded => .Underfunded,
            .LowReserve => .LowReserve,
            .AlreadyExist => .AlreadyExist,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Success => {},
            .Malformed => {},
            .Underfunded => {},
            .LowReserve => {},
            .AlreadyExist => {},
        }
    }
};

/// PaymentResultCode is an XDR Enum defined as:
///
/// ```text
/// enum PaymentResultCode
/// {
///     // codes considered as "success" for the operation
///     PAYMENT_SUCCESS = 0, // payment successfully completed
///
///     // codes considered as "failure" for the operation
///     PAYMENT_MALFORMED = -1,          // bad input
///     PAYMENT_UNDERFUNDED = -2,        // not enough funds in source account
///     PAYMENT_SRC_NO_TRUST = -3,       // no trust line on source account
///     PAYMENT_SRC_NOT_AUTHORIZED = -4, // source not authorized to transfer
///     PAYMENT_NO_DESTINATION = -5,     // destination account does not exist
///     PAYMENT_NO_TRUST = -6,       // destination missing a trust line for asset
///     PAYMENT_NOT_AUTHORIZED = -7, // destination not authorized to hold asset
///     PAYMENT_LINE_FULL = -8,      // destination would go above their limit
///     PAYMENT_NO_ISSUER = -9       // missing issuer on asset
/// };
/// ```
///
pub const PaymentResultCode = enum(i32) {
    Success = 0,
    Malformed = -1,
    Underfunded = -2,
    SrcNoTrust = -3,
    SrcNotAuthorized = -4,
    NoDestination = -5,
    NoTrust = -6,
    NotAuthorized = -7,
    LineFull = -8,
    NoIssuer = -9,
    _,

    pub const variants = [_]PaymentResultCode{
        .Success,
        .Malformed,
        .Underfunded,
        .SrcNoTrust,
        .SrcNotAuthorized,
        .NoDestination,
        .NoTrust,
        .NotAuthorized,
        .LineFull,
        .NoIssuer,
    };

    pub fn name(self: PaymentResultCode) []const u8 {
        return switch (self) {
            .Success => "Success",
            .Malformed => "Malformed",
            .Underfunded => "Underfunded",
            .SrcNoTrust => "SrcNoTrust",
            .SrcNotAuthorized => "SrcNotAuthorized",
            .NoDestination => "NoDestination",
            .NoTrust => "NoTrust",
            .NotAuthorized => "NotAuthorized",
            .LineFull => "LineFull",
            .NoIssuer => "NoIssuer",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !PaymentResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: PaymentResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// PaymentResult is an XDR Union defined as:
///
/// ```text
/// union PaymentResult switch (PaymentResultCode code)
/// {
/// case PAYMENT_SUCCESS:
///     void;
/// case PAYMENT_MALFORMED:
/// case PAYMENT_UNDERFUNDED:
/// case PAYMENT_SRC_NO_TRUST:
/// case PAYMENT_SRC_NOT_AUTHORIZED:
/// case PAYMENT_NO_DESTINATION:
/// case PAYMENT_NO_TRUST:
/// case PAYMENT_NOT_AUTHORIZED:
/// case PAYMENT_LINE_FULL:
/// case PAYMENT_NO_ISSUER:
///     void;
/// };
/// ```
///
pub const PaymentResult = union(enum) {
    Success,
    Malformed,
    Underfunded,
    SrcNoTrust,
    SrcNotAuthorized,
    NoDestination,
    NoTrust,
    NotAuthorized,
    LineFull,
    NoIssuer,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !PaymentResult {
        const disc = try PaymentResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .Success => PaymentResult{ .Success = {} },
            .Malformed => PaymentResult{ .Malformed = {} },
            .Underfunded => PaymentResult{ .Underfunded = {} },
            .SrcNoTrust => PaymentResult{ .SrcNoTrust = {} },
            .SrcNotAuthorized => PaymentResult{ .SrcNotAuthorized = {} },
            .NoDestination => PaymentResult{ .NoDestination = {} },
            .NoTrust => PaymentResult{ .NoTrust = {} },
            .NotAuthorized => PaymentResult{ .NotAuthorized = {} },
            .LineFull => PaymentResult{ .LineFull = {} },
            .NoIssuer => PaymentResult{ .NoIssuer = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: PaymentResult, writer: anytype) !void {
        const disc: PaymentResultCode = switch (self) {
            .Success => .Success,
            .Malformed => .Malformed,
            .Underfunded => .Underfunded,
            .SrcNoTrust => .SrcNoTrust,
            .SrcNotAuthorized => .SrcNotAuthorized,
            .NoDestination => .NoDestination,
            .NoTrust => .NoTrust,
            .NotAuthorized => .NotAuthorized,
            .LineFull => .LineFull,
            .NoIssuer => .NoIssuer,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Success => {},
            .Malformed => {},
            .Underfunded => {},
            .SrcNoTrust => {},
            .SrcNotAuthorized => {},
            .NoDestination => {},
            .NoTrust => {},
            .NotAuthorized => {},
            .LineFull => {},
            .NoIssuer => {},
        }
    }
};

/// PathPaymentStrictReceiveResultCode is an XDR Enum defined as:
///
/// ```text
/// enum PathPaymentStrictReceiveResultCode
/// {
///     // codes considered as "success" for the operation
///     PATH_PAYMENT_STRICT_RECEIVE_SUCCESS = 0, // success
///
///     // codes considered as "failure" for the operation
///     PATH_PAYMENT_STRICT_RECEIVE_MALFORMED = -1, // bad input
///     PATH_PAYMENT_STRICT_RECEIVE_UNDERFUNDED =
///         -2, // not enough funds in source account
///     PATH_PAYMENT_STRICT_RECEIVE_SRC_NO_TRUST =
///         -3, // no trust line on source account
///     PATH_PAYMENT_STRICT_RECEIVE_SRC_NOT_AUTHORIZED =
///         -4, // source not authorized to transfer
///     PATH_PAYMENT_STRICT_RECEIVE_NO_DESTINATION =
///         -5, // destination account does not exist
///     PATH_PAYMENT_STRICT_RECEIVE_NO_TRUST =
///         -6, // dest missing a trust line for asset
///     PATH_PAYMENT_STRICT_RECEIVE_NOT_AUTHORIZED =
///         -7, // dest not authorized to hold asset
///     PATH_PAYMENT_STRICT_RECEIVE_LINE_FULL =
///         -8, // dest would go above their limit
///     PATH_PAYMENT_STRICT_RECEIVE_NO_ISSUER = -9, // missing issuer on one asset
///     PATH_PAYMENT_STRICT_RECEIVE_TOO_FEW_OFFERS =
///         -10, // not enough offers to satisfy path
///     PATH_PAYMENT_STRICT_RECEIVE_OFFER_CROSS_SELF =
///         -11, // would cross one of its own offers
///     PATH_PAYMENT_STRICT_RECEIVE_OVER_SENDMAX = -12 // could not satisfy sendmax
/// };
/// ```
///
pub const PathPaymentStrictReceiveResultCode = enum(i32) {
    Success = 0,
    Malformed = -1,
    Underfunded = -2,
    SrcNoTrust = -3,
    SrcNotAuthorized = -4,
    NoDestination = -5,
    NoTrust = -6,
    NotAuthorized = -7,
    LineFull = -8,
    NoIssuer = -9,
    TooFewOffers = -10,
    OfferCrossSelf = -11,
    OverSendmax = -12,
    _,

    pub const variants = [_]PathPaymentStrictReceiveResultCode{
        .Success,
        .Malformed,
        .Underfunded,
        .SrcNoTrust,
        .SrcNotAuthorized,
        .NoDestination,
        .NoTrust,
        .NotAuthorized,
        .LineFull,
        .NoIssuer,
        .TooFewOffers,
        .OfferCrossSelf,
        .OverSendmax,
    };

    pub fn name(self: PathPaymentStrictReceiveResultCode) []const u8 {
        return switch (self) {
            .Success => "Success",
            .Malformed => "Malformed",
            .Underfunded => "Underfunded",
            .SrcNoTrust => "SrcNoTrust",
            .SrcNotAuthorized => "SrcNotAuthorized",
            .NoDestination => "NoDestination",
            .NoTrust => "NoTrust",
            .NotAuthorized => "NotAuthorized",
            .LineFull => "LineFull",
            .NoIssuer => "NoIssuer",
            .TooFewOffers => "TooFewOffers",
            .OfferCrossSelf => "OfferCrossSelf",
            .OverSendmax => "OverSendmax",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !PathPaymentStrictReceiveResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: PathPaymentStrictReceiveResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// SimplePaymentResult is an XDR Struct defined as:
///
/// ```text
/// struct SimplePaymentResult
/// {
///     AccountID destination;
///     Asset asset;
///     int64 amount;
/// };
/// ```
///
pub const SimplePaymentResult = struct {
    destination: AccountId,
    asset: Asset,
    amount: i64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SimplePaymentResult {
        return SimplePaymentResult{
            .destination = try xdrDecodeGeneric(AccountId, allocator, reader),
            .asset = try xdrDecodeGeneric(Asset, allocator, reader),
            .amount = try xdrDecodeGeneric(i64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: SimplePaymentResult, writer: anytype) !void {
        try xdrEncodeGeneric(AccountId, writer, self.destination);
        try xdrEncodeGeneric(Asset, writer, self.asset);
        try xdrEncodeGeneric(i64, writer, self.amount);
    }
};

/// PathPaymentStrictReceiveResultSuccess is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///     {
///         ClaimAtom offers<>;
///         SimplePaymentResult last;
///     }
/// ```
///
pub const PathPaymentStrictReceiveResultSuccess = struct {
    offers: []ClaimAtom,
    last: SimplePaymentResult,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !PathPaymentStrictReceiveResultSuccess {
        return PathPaymentStrictReceiveResultSuccess{
            .offers = try xdrDecodeGeneric([]ClaimAtom, allocator, reader),
            .last = try xdrDecodeGeneric(SimplePaymentResult, allocator, reader),
        };
    }

    pub fn xdrEncode(self: PathPaymentStrictReceiveResultSuccess, writer: anytype) !void {
        try xdrEncodeGeneric([]ClaimAtom, writer, self.offers);
        try xdrEncodeGeneric(SimplePaymentResult, writer, self.last);
    }
};

/// PathPaymentStrictReceiveResult is an XDR Union defined as:
///
/// ```text
/// union PathPaymentStrictReceiveResult switch (
///     PathPaymentStrictReceiveResultCode code)
/// {
/// case PATH_PAYMENT_STRICT_RECEIVE_SUCCESS:
///     struct
///     {
///         ClaimAtom offers<>;
///         SimplePaymentResult last;
///     } success;
/// case PATH_PAYMENT_STRICT_RECEIVE_MALFORMED:
/// case PATH_PAYMENT_STRICT_RECEIVE_UNDERFUNDED:
/// case PATH_PAYMENT_STRICT_RECEIVE_SRC_NO_TRUST:
/// case PATH_PAYMENT_STRICT_RECEIVE_SRC_NOT_AUTHORIZED:
/// case PATH_PAYMENT_STRICT_RECEIVE_NO_DESTINATION:
/// case PATH_PAYMENT_STRICT_RECEIVE_NO_TRUST:
/// case PATH_PAYMENT_STRICT_RECEIVE_NOT_AUTHORIZED:
/// case PATH_PAYMENT_STRICT_RECEIVE_LINE_FULL:
///     void;
/// case PATH_PAYMENT_STRICT_RECEIVE_NO_ISSUER:
///     Asset noIssuer; // the asset that caused the error
/// case PATH_PAYMENT_STRICT_RECEIVE_TOO_FEW_OFFERS:
/// case PATH_PAYMENT_STRICT_RECEIVE_OFFER_CROSS_SELF:
/// case PATH_PAYMENT_STRICT_RECEIVE_OVER_SENDMAX:
///     void;
/// };
/// ```
///
pub const PathPaymentStrictReceiveResult = union(enum) {
    Success: PathPaymentStrictReceiveResultSuccess,
    Malformed,
    Underfunded,
    SrcNoTrust,
    SrcNotAuthorized,
    NoDestination,
    NoTrust,
    NotAuthorized,
    LineFull,
    NoIssuer: Asset,
    TooFewOffers,
    OfferCrossSelf,
    OverSendmax,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !PathPaymentStrictReceiveResult {
        const disc = try PathPaymentStrictReceiveResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .Success => PathPaymentStrictReceiveResult{ .Success = try xdrDecodeGeneric(PathPaymentStrictReceiveResultSuccess, allocator, reader) },
            .Malformed => PathPaymentStrictReceiveResult{ .Malformed = {} },
            .Underfunded => PathPaymentStrictReceiveResult{ .Underfunded = {} },
            .SrcNoTrust => PathPaymentStrictReceiveResult{ .SrcNoTrust = {} },
            .SrcNotAuthorized => PathPaymentStrictReceiveResult{ .SrcNotAuthorized = {} },
            .NoDestination => PathPaymentStrictReceiveResult{ .NoDestination = {} },
            .NoTrust => PathPaymentStrictReceiveResult{ .NoTrust = {} },
            .NotAuthorized => PathPaymentStrictReceiveResult{ .NotAuthorized = {} },
            .LineFull => PathPaymentStrictReceiveResult{ .LineFull = {} },
            .NoIssuer => PathPaymentStrictReceiveResult{ .NoIssuer = try xdrDecodeGeneric(Asset, allocator, reader) },
            .TooFewOffers => PathPaymentStrictReceiveResult{ .TooFewOffers = {} },
            .OfferCrossSelf => PathPaymentStrictReceiveResult{ .OfferCrossSelf = {} },
            .OverSendmax => PathPaymentStrictReceiveResult{ .OverSendmax = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: PathPaymentStrictReceiveResult, writer: anytype) !void {
        const disc: PathPaymentStrictReceiveResultCode = switch (self) {
            .Success => .Success,
            .Malformed => .Malformed,
            .Underfunded => .Underfunded,
            .SrcNoTrust => .SrcNoTrust,
            .SrcNotAuthorized => .SrcNotAuthorized,
            .NoDestination => .NoDestination,
            .NoTrust => .NoTrust,
            .NotAuthorized => .NotAuthorized,
            .LineFull => .LineFull,
            .NoIssuer => .NoIssuer,
            .TooFewOffers => .TooFewOffers,
            .OfferCrossSelf => .OfferCrossSelf,
            .OverSendmax => .OverSendmax,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Success => |v| try xdrEncodeGeneric(PathPaymentStrictReceiveResultSuccess, writer, v),
            .Malformed => {},
            .Underfunded => {},
            .SrcNoTrust => {},
            .SrcNotAuthorized => {},
            .NoDestination => {},
            .NoTrust => {},
            .NotAuthorized => {},
            .LineFull => {},
            .NoIssuer => |v| try xdrEncodeGeneric(Asset, writer, v),
            .TooFewOffers => {},
            .OfferCrossSelf => {},
            .OverSendmax => {},
        }
    }
};

/// PathPaymentStrictSendResultCode is an XDR Enum defined as:
///
/// ```text
/// enum PathPaymentStrictSendResultCode
/// {
///     // codes considered as "success" for the operation
///     PATH_PAYMENT_STRICT_SEND_SUCCESS = 0, // success
///
///     // codes considered as "failure" for the operation
///     PATH_PAYMENT_STRICT_SEND_MALFORMED = -1, // bad input
///     PATH_PAYMENT_STRICT_SEND_UNDERFUNDED =
///         -2, // not enough funds in source account
///     PATH_PAYMENT_STRICT_SEND_SRC_NO_TRUST =
///         -3, // no trust line on source account
///     PATH_PAYMENT_STRICT_SEND_SRC_NOT_AUTHORIZED =
///         -4, // source not authorized to transfer
///     PATH_PAYMENT_STRICT_SEND_NO_DESTINATION =
///         -5, // destination account does not exist
///     PATH_PAYMENT_STRICT_SEND_NO_TRUST =
///         -6, // dest missing a trust line for asset
///     PATH_PAYMENT_STRICT_SEND_NOT_AUTHORIZED =
///         -7, // dest not authorized to hold asset
///     PATH_PAYMENT_STRICT_SEND_LINE_FULL = -8, // dest would go above their limit
///     PATH_PAYMENT_STRICT_SEND_NO_ISSUER = -9, // missing issuer on one asset
///     PATH_PAYMENT_STRICT_SEND_TOO_FEW_OFFERS =
///         -10, // not enough offers to satisfy path
///     PATH_PAYMENT_STRICT_SEND_OFFER_CROSS_SELF =
///         -11, // would cross one of its own offers
///     PATH_PAYMENT_STRICT_SEND_UNDER_DESTMIN = -12 // could not satisfy destMin
/// };
/// ```
///
pub const PathPaymentStrictSendResultCode = enum(i32) {
    Success = 0,
    Malformed = -1,
    Underfunded = -2,
    SrcNoTrust = -3,
    SrcNotAuthorized = -4,
    NoDestination = -5,
    NoTrust = -6,
    NotAuthorized = -7,
    LineFull = -8,
    NoIssuer = -9,
    TooFewOffers = -10,
    OfferCrossSelf = -11,
    UnderDestmin = -12,
    _,

    pub const variants = [_]PathPaymentStrictSendResultCode{
        .Success,
        .Malformed,
        .Underfunded,
        .SrcNoTrust,
        .SrcNotAuthorized,
        .NoDestination,
        .NoTrust,
        .NotAuthorized,
        .LineFull,
        .NoIssuer,
        .TooFewOffers,
        .OfferCrossSelf,
        .UnderDestmin,
    };

    pub fn name(self: PathPaymentStrictSendResultCode) []const u8 {
        return switch (self) {
            .Success => "Success",
            .Malformed => "Malformed",
            .Underfunded => "Underfunded",
            .SrcNoTrust => "SrcNoTrust",
            .SrcNotAuthorized => "SrcNotAuthorized",
            .NoDestination => "NoDestination",
            .NoTrust => "NoTrust",
            .NotAuthorized => "NotAuthorized",
            .LineFull => "LineFull",
            .NoIssuer => "NoIssuer",
            .TooFewOffers => "TooFewOffers",
            .OfferCrossSelf => "OfferCrossSelf",
            .UnderDestmin => "UnderDestmin",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !PathPaymentStrictSendResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: PathPaymentStrictSendResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// PathPaymentStrictSendResultSuccess is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///     {
///         ClaimAtom offers<>;
///         SimplePaymentResult last;
///     }
/// ```
///
pub const PathPaymentStrictSendResultSuccess = struct {
    offers: []ClaimAtom,
    last: SimplePaymentResult,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !PathPaymentStrictSendResultSuccess {
        return PathPaymentStrictSendResultSuccess{
            .offers = try xdrDecodeGeneric([]ClaimAtom, allocator, reader),
            .last = try xdrDecodeGeneric(SimplePaymentResult, allocator, reader),
        };
    }

    pub fn xdrEncode(self: PathPaymentStrictSendResultSuccess, writer: anytype) !void {
        try xdrEncodeGeneric([]ClaimAtom, writer, self.offers);
        try xdrEncodeGeneric(SimplePaymentResult, writer, self.last);
    }
};

/// PathPaymentStrictSendResult is an XDR Union defined as:
///
/// ```text
/// union PathPaymentStrictSendResult switch (PathPaymentStrictSendResultCode code)
/// {
/// case PATH_PAYMENT_STRICT_SEND_SUCCESS:
///     struct
///     {
///         ClaimAtom offers<>;
///         SimplePaymentResult last;
///     } success;
/// case PATH_PAYMENT_STRICT_SEND_MALFORMED:
/// case PATH_PAYMENT_STRICT_SEND_UNDERFUNDED:
/// case PATH_PAYMENT_STRICT_SEND_SRC_NO_TRUST:
/// case PATH_PAYMENT_STRICT_SEND_SRC_NOT_AUTHORIZED:
/// case PATH_PAYMENT_STRICT_SEND_NO_DESTINATION:
/// case PATH_PAYMENT_STRICT_SEND_NO_TRUST:
/// case PATH_PAYMENT_STRICT_SEND_NOT_AUTHORIZED:
/// case PATH_PAYMENT_STRICT_SEND_LINE_FULL:
///     void;
/// case PATH_PAYMENT_STRICT_SEND_NO_ISSUER:
///     Asset noIssuer; // the asset that caused the error
/// case PATH_PAYMENT_STRICT_SEND_TOO_FEW_OFFERS:
/// case PATH_PAYMENT_STRICT_SEND_OFFER_CROSS_SELF:
/// case PATH_PAYMENT_STRICT_SEND_UNDER_DESTMIN:
///     void;
/// };
/// ```
///
pub const PathPaymentStrictSendResult = union(enum) {
    Success: PathPaymentStrictSendResultSuccess,
    Malformed,
    Underfunded,
    SrcNoTrust,
    SrcNotAuthorized,
    NoDestination,
    NoTrust,
    NotAuthorized,
    LineFull,
    NoIssuer: Asset,
    TooFewOffers,
    OfferCrossSelf,
    UnderDestmin,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !PathPaymentStrictSendResult {
        const disc = try PathPaymentStrictSendResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .Success => PathPaymentStrictSendResult{ .Success = try xdrDecodeGeneric(PathPaymentStrictSendResultSuccess, allocator, reader) },
            .Malformed => PathPaymentStrictSendResult{ .Malformed = {} },
            .Underfunded => PathPaymentStrictSendResult{ .Underfunded = {} },
            .SrcNoTrust => PathPaymentStrictSendResult{ .SrcNoTrust = {} },
            .SrcNotAuthorized => PathPaymentStrictSendResult{ .SrcNotAuthorized = {} },
            .NoDestination => PathPaymentStrictSendResult{ .NoDestination = {} },
            .NoTrust => PathPaymentStrictSendResult{ .NoTrust = {} },
            .NotAuthorized => PathPaymentStrictSendResult{ .NotAuthorized = {} },
            .LineFull => PathPaymentStrictSendResult{ .LineFull = {} },
            .NoIssuer => PathPaymentStrictSendResult{ .NoIssuer = try xdrDecodeGeneric(Asset, allocator, reader) },
            .TooFewOffers => PathPaymentStrictSendResult{ .TooFewOffers = {} },
            .OfferCrossSelf => PathPaymentStrictSendResult{ .OfferCrossSelf = {} },
            .UnderDestmin => PathPaymentStrictSendResult{ .UnderDestmin = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: PathPaymentStrictSendResult, writer: anytype) !void {
        const disc: PathPaymentStrictSendResultCode = switch (self) {
            .Success => .Success,
            .Malformed => .Malformed,
            .Underfunded => .Underfunded,
            .SrcNoTrust => .SrcNoTrust,
            .SrcNotAuthorized => .SrcNotAuthorized,
            .NoDestination => .NoDestination,
            .NoTrust => .NoTrust,
            .NotAuthorized => .NotAuthorized,
            .LineFull => .LineFull,
            .NoIssuer => .NoIssuer,
            .TooFewOffers => .TooFewOffers,
            .OfferCrossSelf => .OfferCrossSelf,
            .UnderDestmin => .UnderDestmin,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Success => |v| try xdrEncodeGeneric(PathPaymentStrictSendResultSuccess, writer, v),
            .Malformed => {},
            .Underfunded => {},
            .SrcNoTrust => {},
            .SrcNotAuthorized => {},
            .NoDestination => {},
            .NoTrust => {},
            .NotAuthorized => {},
            .LineFull => {},
            .NoIssuer => |v| try xdrEncodeGeneric(Asset, writer, v),
            .TooFewOffers => {},
            .OfferCrossSelf => {},
            .UnderDestmin => {},
        }
    }
};

/// ManageSellOfferResultCode is an XDR Enum defined as:
///
/// ```text
/// enum ManageSellOfferResultCode
/// {
///     // codes considered as "success" for the operation
///     MANAGE_SELL_OFFER_SUCCESS = 0,
///
///     // codes considered as "failure" for the operation
///     MANAGE_SELL_OFFER_MALFORMED = -1, // generated offer would be invalid
///     MANAGE_SELL_OFFER_SELL_NO_TRUST =
///         -2,                              // no trust line for what we're selling
///     MANAGE_SELL_OFFER_BUY_NO_TRUST = -3, // no trust line for what we're buying
///     MANAGE_SELL_OFFER_SELL_NOT_AUTHORIZED = -4, // not authorized to sell
///     MANAGE_SELL_OFFER_BUY_NOT_AUTHORIZED = -5,  // not authorized to buy
///     MANAGE_SELL_OFFER_LINE_FULL = -6, // can't receive more of what it's buying
///     MANAGE_SELL_OFFER_UNDERFUNDED = -7, // doesn't hold what it's trying to sell
///     MANAGE_SELL_OFFER_CROSS_SELF =
///         -8, // would cross an offer from the same user
///     MANAGE_SELL_OFFER_SELL_NO_ISSUER = -9, // no issuer for what we're selling
///     MANAGE_SELL_OFFER_BUY_NO_ISSUER = -10, // no issuer for what we're buying
///
///     // update errors
///     MANAGE_SELL_OFFER_NOT_FOUND =
///         -11, // offerID does not match an existing offer
///
///     MANAGE_SELL_OFFER_LOW_RESERVE =
///         -12 // not enough funds to create a new Offer
/// };
/// ```
///
pub const ManageSellOfferResultCode = enum(i32) {
    Success = 0,
    Malformed = -1,
    SellNoTrust = -2,
    BuyNoTrust = -3,
    SellNotAuthorized = -4,
    BuyNotAuthorized = -5,
    LineFull = -6,
    Underfunded = -7,
    CrossSelf = -8,
    SellNoIssuer = -9,
    BuyNoIssuer = -10,
    NotFound = -11,
    LowReserve = -12,
    _,

    pub const variants = [_]ManageSellOfferResultCode{
        .Success,
        .Malformed,
        .SellNoTrust,
        .BuyNoTrust,
        .SellNotAuthorized,
        .BuyNotAuthorized,
        .LineFull,
        .Underfunded,
        .CrossSelf,
        .SellNoIssuer,
        .BuyNoIssuer,
        .NotFound,
        .LowReserve,
    };

    pub fn name(self: ManageSellOfferResultCode) []const u8 {
        return switch (self) {
            .Success => "Success",
            .Malformed => "Malformed",
            .SellNoTrust => "SellNoTrust",
            .BuyNoTrust => "BuyNoTrust",
            .SellNotAuthorized => "SellNotAuthorized",
            .BuyNotAuthorized => "BuyNotAuthorized",
            .LineFull => "LineFull",
            .Underfunded => "Underfunded",
            .CrossSelf => "CrossSelf",
            .SellNoIssuer => "SellNoIssuer",
            .BuyNoIssuer => "BuyNoIssuer",
            .NotFound => "NotFound",
            .LowReserve => "LowReserve",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ManageSellOfferResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ManageSellOfferResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ManageOfferEffect is an XDR Enum defined as:
///
/// ```text
/// enum ManageOfferEffect
/// {
///     MANAGE_OFFER_CREATED = 0,
///     MANAGE_OFFER_UPDATED = 1,
///     MANAGE_OFFER_DELETED = 2
/// };
/// ```
///
pub const ManageOfferEffect = enum(i32) {
    Created = 0,
    Updated = 1,
    Deleted = 2,
    _,

    pub const variants = [_]ManageOfferEffect{
        .Created,
        .Updated,
        .Deleted,
    };

    pub fn name(self: ManageOfferEffect) []const u8 {
        return switch (self) {
            .Created => "Created",
            .Updated => "Updated",
            .Deleted => "Deleted",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ManageOfferEffect {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ManageOfferEffect, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ManageOfferSuccessResultOffer is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (ManageOfferEffect effect)
///     {
///     case MANAGE_OFFER_CREATED:
///     case MANAGE_OFFER_UPDATED:
///         OfferEntry offer;
///     case MANAGE_OFFER_DELETED:
///         void;
///     }
/// ```
///
pub const ManageOfferSuccessResultOffer = union(enum) {
    Created: OfferEntry,
    Updated: OfferEntry,
    Deleted,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ManageOfferSuccessResultOffer {
        const disc = try ManageOfferEffect.xdrDecode(allocator, reader);
        return switch (disc) {
            .Created => ManageOfferSuccessResultOffer{ .Created = try xdrDecodeGeneric(OfferEntry, allocator, reader) },
            .Updated => ManageOfferSuccessResultOffer{ .Updated = try xdrDecodeGeneric(OfferEntry, allocator, reader) },
            .Deleted => ManageOfferSuccessResultOffer{ .Deleted = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ManageOfferSuccessResultOffer, writer: anytype) !void {
        const disc: ManageOfferEffect = switch (self) {
            .Created => .Created,
            .Updated => .Updated,
            .Deleted => .Deleted,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Created => |v| try xdrEncodeGeneric(OfferEntry, writer, v),
            .Updated => |v| try xdrEncodeGeneric(OfferEntry, writer, v),
            .Deleted => {},
        }
    }
};

/// ManageOfferSuccessResult is an XDR Struct defined as:
///
/// ```text
/// struct ManageOfferSuccessResult
/// {
///     // offers that got claimed while creating this offer
///     ClaimAtom offersClaimed<>;
///
///     union switch (ManageOfferEffect effect)
///     {
///     case MANAGE_OFFER_CREATED:
///     case MANAGE_OFFER_UPDATED:
///         OfferEntry offer;
///     case MANAGE_OFFER_DELETED:
///         void;
///     }
///     offer;
/// };
/// ```
///
pub const ManageOfferSuccessResult = struct {
    offers_claimed: []ClaimAtom,
    offer: ManageOfferSuccessResultOffer,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ManageOfferSuccessResult {
        return ManageOfferSuccessResult{
            .offers_claimed = try xdrDecodeGeneric([]ClaimAtom, allocator, reader),
            .offer = try xdrDecodeGeneric(ManageOfferSuccessResultOffer, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ManageOfferSuccessResult, writer: anytype) !void {
        try xdrEncodeGeneric([]ClaimAtom, writer, self.offers_claimed);
        try xdrEncodeGeneric(ManageOfferSuccessResultOffer, writer, self.offer);
    }
};

/// ManageSellOfferResult is an XDR Union defined as:
///
/// ```text
/// union ManageSellOfferResult switch (ManageSellOfferResultCode code)
/// {
/// case MANAGE_SELL_OFFER_SUCCESS:
///     ManageOfferSuccessResult success;
/// case MANAGE_SELL_OFFER_MALFORMED:
/// case MANAGE_SELL_OFFER_SELL_NO_TRUST:
/// case MANAGE_SELL_OFFER_BUY_NO_TRUST:
/// case MANAGE_SELL_OFFER_SELL_NOT_AUTHORIZED:
/// case MANAGE_SELL_OFFER_BUY_NOT_AUTHORIZED:
/// case MANAGE_SELL_OFFER_LINE_FULL:
/// case MANAGE_SELL_OFFER_UNDERFUNDED:
/// case MANAGE_SELL_OFFER_CROSS_SELF:
/// case MANAGE_SELL_OFFER_SELL_NO_ISSUER:
/// case MANAGE_SELL_OFFER_BUY_NO_ISSUER:
/// case MANAGE_SELL_OFFER_NOT_FOUND:
/// case MANAGE_SELL_OFFER_LOW_RESERVE:
///     void;
/// };
/// ```
///
pub const ManageSellOfferResult = union(enum) {
    Success: ManageOfferSuccessResult,
    Malformed,
    SellNoTrust,
    BuyNoTrust,
    SellNotAuthorized,
    BuyNotAuthorized,
    LineFull,
    Underfunded,
    CrossSelf,
    SellNoIssuer,
    BuyNoIssuer,
    NotFound,
    LowReserve,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ManageSellOfferResult {
        const disc = try ManageSellOfferResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .Success => ManageSellOfferResult{ .Success = try xdrDecodeGeneric(ManageOfferSuccessResult, allocator, reader) },
            .Malformed => ManageSellOfferResult{ .Malformed = {} },
            .SellNoTrust => ManageSellOfferResult{ .SellNoTrust = {} },
            .BuyNoTrust => ManageSellOfferResult{ .BuyNoTrust = {} },
            .SellNotAuthorized => ManageSellOfferResult{ .SellNotAuthorized = {} },
            .BuyNotAuthorized => ManageSellOfferResult{ .BuyNotAuthorized = {} },
            .LineFull => ManageSellOfferResult{ .LineFull = {} },
            .Underfunded => ManageSellOfferResult{ .Underfunded = {} },
            .CrossSelf => ManageSellOfferResult{ .CrossSelf = {} },
            .SellNoIssuer => ManageSellOfferResult{ .SellNoIssuer = {} },
            .BuyNoIssuer => ManageSellOfferResult{ .BuyNoIssuer = {} },
            .NotFound => ManageSellOfferResult{ .NotFound = {} },
            .LowReserve => ManageSellOfferResult{ .LowReserve = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ManageSellOfferResult, writer: anytype) !void {
        const disc: ManageSellOfferResultCode = switch (self) {
            .Success => .Success,
            .Malformed => .Malformed,
            .SellNoTrust => .SellNoTrust,
            .BuyNoTrust => .BuyNoTrust,
            .SellNotAuthorized => .SellNotAuthorized,
            .BuyNotAuthorized => .BuyNotAuthorized,
            .LineFull => .LineFull,
            .Underfunded => .Underfunded,
            .CrossSelf => .CrossSelf,
            .SellNoIssuer => .SellNoIssuer,
            .BuyNoIssuer => .BuyNoIssuer,
            .NotFound => .NotFound,
            .LowReserve => .LowReserve,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Success => |v| try xdrEncodeGeneric(ManageOfferSuccessResult, writer, v),
            .Malformed => {},
            .SellNoTrust => {},
            .BuyNoTrust => {},
            .SellNotAuthorized => {},
            .BuyNotAuthorized => {},
            .LineFull => {},
            .Underfunded => {},
            .CrossSelf => {},
            .SellNoIssuer => {},
            .BuyNoIssuer => {},
            .NotFound => {},
            .LowReserve => {},
        }
    }
};

/// ManageBuyOfferResultCode is an XDR Enum defined as:
///
/// ```text
/// enum ManageBuyOfferResultCode
/// {
///     // codes considered as "success" for the operation
///     MANAGE_BUY_OFFER_SUCCESS = 0,
///
///     // codes considered as "failure" for the operation
///     MANAGE_BUY_OFFER_MALFORMED = -1,     // generated offer would be invalid
///     MANAGE_BUY_OFFER_SELL_NO_TRUST = -2, // no trust line for what we're selling
///     MANAGE_BUY_OFFER_BUY_NO_TRUST = -3,  // no trust line for what we're buying
///     MANAGE_BUY_OFFER_SELL_NOT_AUTHORIZED = -4, // not authorized to sell
///     MANAGE_BUY_OFFER_BUY_NOT_AUTHORIZED = -5,  // not authorized to buy
///     MANAGE_BUY_OFFER_LINE_FULL = -6,   // can't receive more of what it's buying
///     MANAGE_BUY_OFFER_UNDERFUNDED = -7, // doesn't hold what it's trying to sell
///     MANAGE_BUY_OFFER_CROSS_SELF = -8, // would cross an offer from the same user
///     MANAGE_BUY_OFFER_SELL_NO_ISSUER = -9, // no issuer for what we're selling
///     MANAGE_BUY_OFFER_BUY_NO_ISSUER = -10, // no issuer for what we're buying
///
///     // update errors
///     MANAGE_BUY_OFFER_NOT_FOUND =
///         -11, // offerID does not match an existing offer
///
///     MANAGE_BUY_OFFER_LOW_RESERVE = -12 // not enough funds to create a new Offer
/// };
/// ```
///
pub const ManageBuyOfferResultCode = enum(i32) {
    Success = 0,
    Malformed = -1,
    SellNoTrust = -2,
    BuyNoTrust = -3,
    SellNotAuthorized = -4,
    BuyNotAuthorized = -5,
    LineFull = -6,
    Underfunded = -7,
    CrossSelf = -8,
    SellNoIssuer = -9,
    BuyNoIssuer = -10,
    NotFound = -11,
    LowReserve = -12,
    _,

    pub const variants = [_]ManageBuyOfferResultCode{
        .Success,
        .Malformed,
        .SellNoTrust,
        .BuyNoTrust,
        .SellNotAuthorized,
        .BuyNotAuthorized,
        .LineFull,
        .Underfunded,
        .CrossSelf,
        .SellNoIssuer,
        .BuyNoIssuer,
        .NotFound,
        .LowReserve,
    };

    pub fn name(self: ManageBuyOfferResultCode) []const u8 {
        return switch (self) {
            .Success => "Success",
            .Malformed => "Malformed",
            .SellNoTrust => "SellNoTrust",
            .BuyNoTrust => "BuyNoTrust",
            .SellNotAuthorized => "SellNotAuthorized",
            .BuyNotAuthorized => "BuyNotAuthorized",
            .LineFull => "LineFull",
            .Underfunded => "Underfunded",
            .CrossSelf => "CrossSelf",
            .SellNoIssuer => "SellNoIssuer",
            .BuyNoIssuer => "BuyNoIssuer",
            .NotFound => "NotFound",
            .LowReserve => "LowReserve",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ManageBuyOfferResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ManageBuyOfferResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ManageBuyOfferResult is an XDR Union defined as:
///
/// ```text
/// union ManageBuyOfferResult switch (ManageBuyOfferResultCode code)
/// {
/// case MANAGE_BUY_OFFER_SUCCESS:
///     ManageOfferSuccessResult success;
/// case MANAGE_BUY_OFFER_MALFORMED:
/// case MANAGE_BUY_OFFER_SELL_NO_TRUST:
/// case MANAGE_BUY_OFFER_BUY_NO_TRUST:
/// case MANAGE_BUY_OFFER_SELL_NOT_AUTHORIZED:
/// case MANAGE_BUY_OFFER_BUY_NOT_AUTHORIZED:
/// case MANAGE_BUY_OFFER_LINE_FULL:
/// case MANAGE_BUY_OFFER_UNDERFUNDED:
/// case MANAGE_BUY_OFFER_CROSS_SELF:
/// case MANAGE_BUY_OFFER_SELL_NO_ISSUER:
/// case MANAGE_BUY_OFFER_BUY_NO_ISSUER:
/// case MANAGE_BUY_OFFER_NOT_FOUND:
/// case MANAGE_BUY_OFFER_LOW_RESERVE:
///     void;
/// };
/// ```
///
pub const ManageBuyOfferResult = union(enum) {
    Success: ManageOfferSuccessResult,
    Malformed,
    SellNoTrust,
    BuyNoTrust,
    SellNotAuthorized,
    BuyNotAuthorized,
    LineFull,
    Underfunded,
    CrossSelf,
    SellNoIssuer,
    BuyNoIssuer,
    NotFound,
    LowReserve,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ManageBuyOfferResult {
        const disc = try ManageBuyOfferResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .Success => ManageBuyOfferResult{ .Success = try xdrDecodeGeneric(ManageOfferSuccessResult, allocator, reader) },
            .Malformed => ManageBuyOfferResult{ .Malformed = {} },
            .SellNoTrust => ManageBuyOfferResult{ .SellNoTrust = {} },
            .BuyNoTrust => ManageBuyOfferResult{ .BuyNoTrust = {} },
            .SellNotAuthorized => ManageBuyOfferResult{ .SellNotAuthorized = {} },
            .BuyNotAuthorized => ManageBuyOfferResult{ .BuyNotAuthorized = {} },
            .LineFull => ManageBuyOfferResult{ .LineFull = {} },
            .Underfunded => ManageBuyOfferResult{ .Underfunded = {} },
            .CrossSelf => ManageBuyOfferResult{ .CrossSelf = {} },
            .SellNoIssuer => ManageBuyOfferResult{ .SellNoIssuer = {} },
            .BuyNoIssuer => ManageBuyOfferResult{ .BuyNoIssuer = {} },
            .NotFound => ManageBuyOfferResult{ .NotFound = {} },
            .LowReserve => ManageBuyOfferResult{ .LowReserve = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ManageBuyOfferResult, writer: anytype) !void {
        const disc: ManageBuyOfferResultCode = switch (self) {
            .Success => .Success,
            .Malformed => .Malformed,
            .SellNoTrust => .SellNoTrust,
            .BuyNoTrust => .BuyNoTrust,
            .SellNotAuthorized => .SellNotAuthorized,
            .BuyNotAuthorized => .BuyNotAuthorized,
            .LineFull => .LineFull,
            .Underfunded => .Underfunded,
            .CrossSelf => .CrossSelf,
            .SellNoIssuer => .SellNoIssuer,
            .BuyNoIssuer => .BuyNoIssuer,
            .NotFound => .NotFound,
            .LowReserve => .LowReserve,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Success => |v| try xdrEncodeGeneric(ManageOfferSuccessResult, writer, v),
            .Malformed => {},
            .SellNoTrust => {},
            .BuyNoTrust => {},
            .SellNotAuthorized => {},
            .BuyNotAuthorized => {},
            .LineFull => {},
            .Underfunded => {},
            .CrossSelf => {},
            .SellNoIssuer => {},
            .BuyNoIssuer => {},
            .NotFound => {},
            .LowReserve => {},
        }
    }
};

/// SetOptionsResultCode is an XDR Enum defined as:
///
/// ```text
/// enum SetOptionsResultCode
/// {
///     // codes considered as "success" for the operation
///     SET_OPTIONS_SUCCESS = 0,
///     // codes considered as "failure" for the operation
///     SET_OPTIONS_LOW_RESERVE = -1,      // not enough funds to add a signer
///     SET_OPTIONS_TOO_MANY_SIGNERS = -2, // max number of signers already reached
///     SET_OPTIONS_BAD_FLAGS = -3,        // invalid combination of clear/set flags
///     SET_OPTIONS_INVALID_INFLATION = -4,      // inflation account does not exist
///     SET_OPTIONS_CANT_CHANGE = -5,            // can no longer change this option
///     SET_OPTIONS_UNKNOWN_FLAG = -6,           // can't set an unknown flag
///     SET_OPTIONS_THRESHOLD_OUT_OF_RANGE = -7, // bad value for weight/threshold
///     SET_OPTIONS_BAD_SIGNER = -8,             // signer cannot be masterkey
///     SET_OPTIONS_INVALID_HOME_DOMAIN = -9,    // malformed home domain
///     SET_OPTIONS_AUTH_REVOCABLE_REQUIRED =
///         -10 // auth revocable is required for clawback
/// };
/// ```
///
pub const SetOptionsResultCode = enum(i32) {
    Success = 0,
    LowReserve = -1,
    TooManySigners = -2,
    BadFlags = -3,
    InvalidInflation = -4,
    CantChange = -5,
    UnknownFlag = -6,
    ThresholdOutOfRange = -7,
    BadSigner = -8,
    InvalidHomeDomain = -9,
    AuthRevocableRequired = -10,
    _,

    pub const variants = [_]SetOptionsResultCode{
        .Success,
        .LowReserve,
        .TooManySigners,
        .BadFlags,
        .InvalidInflation,
        .CantChange,
        .UnknownFlag,
        .ThresholdOutOfRange,
        .BadSigner,
        .InvalidHomeDomain,
        .AuthRevocableRequired,
    };

    pub fn name(self: SetOptionsResultCode) []const u8 {
        return switch (self) {
            .Success => "Success",
            .LowReserve => "LowReserve",
            .TooManySigners => "TooManySigners",
            .BadFlags => "BadFlags",
            .InvalidInflation => "InvalidInflation",
            .CantChange => "CantChange",
            .UnknownFlag => "UnknownFlag",
            .ThresholdOutOfRange => "ThresholdOutOfRange",
            .BadSigner => "BadSigner",
            .InvalidHomeDomain => "InvalidHomeDomain",
            .AuthRevocableRequired => "AuthRevocableRequired",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SetOptionsResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: SetOptionsResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// SetOptionsResult is an XDR Union defined as:
///
/// ```text
/// union SetOptionsResult switch (SetOptionsResultCode code)
/// {
/// case SET_OPTIONS_SUCCESS:
///     void;
/// case SET_OPTIONS_LOW_RESERVE:
/// case SET_OPTIONS_TOO_MANY_SIGNERS:
/// case SET_OPTIONS_BAD_FLAGS:
/// case SET_OPTIONS_INVALID_INFLATION:
/// case SET_OPTIONS_CANT_CHANGE:
/// case SET_OPTIONS_UNKNOWN_FLAG:
/// case SET_OPTIONS_THRESHOLD_OUT_OF_RANGE:
/// case SET_OPTIONS_BAD_SIGNER:
/// case SET_OPTIONS_INVALID_HOME_DOMAIN:
/// case SET_OPTIONS_AUTH_REVOCABLE_REQUIRED:
///     void;
/// };
/// ```
///
pub const SetOptionsResult = union(enum) {
    Success,
    LowReserve,
    TooManySigners,
    BadFlags,
    InvalidInflation,
    CantChange,
    UnknownFlag,
    ThresholdOutOfRange,
    BadSigner,
    InvalidHomeDomain,
    AuthRevocableRequired,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SetOptionsResult {
        const disc = try SetOptionsResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .Success => SetOptionsResult{ .Success = {} },
            .LowReserve => SetOptionsResult{ .LowReserve = {} },
            .TooManySigners => SetOptionsResult{ .TooManySigners = {} },
            .BadFlags => SetOptionsResult{ .BadFlags = {} },
            .InvalidInflation => SetOptionsResult{ .InvalidInflation = {} },
            .CantChange => SetOptionsResult{ .CantChange = {} },
            .UnknownFlag => SetOptionsResult{ .UnknownFlag = {} },
            .ThresholdOutOfRange => SetOptionsResult{ .ThresholdOutOfRange = {} },
            .BadSigner => SetOptionsResult{ .BadSigner = {} },
            .InvalidHomeDomain => SetOptionsResult{ .InvalidHomeDomain = {} },
            .AuthRevocableRequired => SetOptionsResult{ .AuthRevocableRequired = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: SetOptionsResult, writer: anytype) !void {
        const disc: SetOptionsResultCode = switch (self) {
            .Success => .Success,
            .LowReserve => .LowReserve,
            .TooManySigners => .TooManySigners,
            .BadFlags => .BadFlags,
            .InvalidInflation => .InvalidInflation,
            .CantChange => .CantChange,
            .UnknownFlag => .UnknownFlag,
            .ThresholdOutOfRange => .ThresholdOutOfRange,
            .BadSigner => .BadSigner,
            .InvalidHomeDomain => .InvalidHomeDomain,
            .AuthRevocableRequired => .AuthRevocableRequired,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Success => {},
            .LowReserve => {},
            .TooManySigners => {},
            .BadFlags => {},
            .InvalidInflation => {},
            .CantChange => {},
            .UnknownFlag => {},
            .ThresholdOutOfRange => {},
            .BadSigner => {},
            .InvalidHomeDomain => {},
            .AuthRevocableRequired => {},
        }
    }
};

/// ChangeTrustResultCode is an XDR Enum defined as:
///
/// ```text
/// enum ChangeTrustResultCode
/// {
///     // codes considered as "success" for the operation
///     CHANGE_TRUST_SUCCESS = 0,
///     // codes considered as "failure" for the operation
///     CHANGE_TRUST_MALFORMED = -1,     // bad input
///     CHANGE_TRUST_NO_ISSUER = -2,     // could not find issuer
///     CHANGE_TRUST_INVALID_LIMIT = -3, // cannot drop limit below balance
///                                      // cannot create with a limit of 0
///     CHANGE_TRUST_LOW_RESERVE =
///         -4, // not enough funds to create a new trust line,
///     CHANGE_TRUST_SELF_NOT_ALLOWED = -5,   // trusting self is not allowed
///     CHANGE_TRUST_TRUST_LINE_MISSING = -6, // Asset trustline is missing for pool
///     CHANGE_TRUST_CANNOT_DELETE =
///         -7, // Asset trustline is still referenced in a pool
///     CHANGE_TRUST_NOT_AUTH_MAINTAIN_LIABILITIES =
///         -8 // Asset trustline is deauthorized
/// };
/// ```
///
pub const ChangeTrustResultCode = enum(i32) {
    Success = 0,
    Malformed = -1,
    NoIssuer = -2,
    InvalidLimit = -3,
    LowReserve = -4,
    SelfNotAllowed = -5,
    TrustLineMissing = -6,
    CannotDelete = -7,
    NotAuthMaintainLiabilities = -8,
    _,

    pub const variants = [_]ChangeTrustResultCode{
        .Success,
        .Malformed,
        .NoIssuer,
        .InvalidLimit,
        .LowReserve,
        .SelfNotAllowed,
        .TrustLineMissing,
        .CannotDelete,
        .NotAuthMaintainLiabilities,
    };

    pub fn name(self: ChangeTrustResultCode) []const u8 {
        return switch (self) {
            .Success => "Success",
            .Malformed => "Malformed",
            .NoIssuer => "NoIssuer",
            .InvalidLimit => "InvalidLimit",
            .LowReserve => "LowReserve",
            .SelfNotAllowed => "SelfNotAllowed",
            .TrustLineMissing => "TrustLineMissing",
            .CannotDelete => "CannotDelete",
            .NotAuthMaintainLiabilities => "NotAuthMaintainLiabilities",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ChangeTrustResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ChangeTrustResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ChangeTrustResult is an XDR Union defined as:
///
/// ```text
/// union ChangeTrustResult switch (ChangeTrustResultCode code)
/// {
/// case CHANGE_TRUST_SUCCESS:
///     void;
/// case CHANGE_TRUST_MALFORMED:
/// case CHANGE_TRUST_NO_ISSUER:
/// case CHANGE_TRUST_INVALID_LIMIT:
/// case CHANGE_TRUST_LOW_RESERVE:
/// case CHANGE_TRUST_SELF_NOT_ALLOWED:
/// case CHANGE_TRUST_TRUST_LINE_MISSING:
/// case CHANGE_TRUST_CANNOT_DELETE:
/// case CHANGE_TRUST_NOT_AUTH_MAINTAIN_LIABILITIES:
///     void;
/// };
/// ```
///
pub const ChangeTrustResult = union(enum) {
    Success,
    Malformed,
    NoIssuer,
    InvalidLimit,
    LowReserve,
    SelfNotAllowed,
    TrustLineMissing,
    CannotDelete,
    NotAuthMaintainLiabilities,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ChangeTrustResult {
        const disc = try ChangeTrustResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .Success => ChangeTrustResult{ .Success = {} },
            .Malformed => ChangeTrustResult{ .Malformed = {} },
            .NoIssuer => ChangeTrustResult{ .NoIssuer = {} },
            .InvalidLimit => ChangeTrustResult{ .InvalidLimit = {} },
            .LowReserve => ChangeTrustResult{ .LowReserve = {} },
            .SelfNotAllowed => ChangeTrustResult{ .SelfNotAllowed = {} },
            .TrustLineMissing => ChangeTrustResult{ .TrustLineMissing = {} },
            .CannotDelete => ChangeTrustResult{ .CannotDelete = {} },
            .NotAuthMaintainLiabilities => ChangeTrustResult{ .NotAuthMaintainLiabilities = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ChangeTrustResult, writer: anytype) !void {
        const disc: ChangeTrustResultCode = switch (self) {
            .Success => .Success,
            .Malformed => .Malformed,
            .NoIssuer => .NoIssuer,
            .InvalidLimit => .InvalidLimit,
            .LowReserve => .LowReserve,
            .SelfNotAllowed => .SelfNotAllowed,
            .TrustLineMissing => .TrustLineMissing,
            .CannotDelete => .CannotDelete,
            .NotAuthMaintainLiabilities => .NotAuthMaintainLiabilities,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Success => {},
            .Malformed => {},
            .NoIssuer => {},
            .InvalidLimit => {},
            .LowReserve => {},
            .SelfNotAllowed => {},
            .TrustLineMissing => {},
            .CannotDelete => {},
            .NotAuthMaintainLiabilities => {},
        }
    }
};

/// AllowTrustResultCode is an XDR Enum defined as:
///
/// ```text
/// enum AllowTrustResultCode
/// {
///     // codes considered as "success" for the operation
///     ALLOW_TRUST_SUCCESS = 0,
///     // codes considered as "failure" for the operation
///     ALLOW_TRUST_MALFORMED = -1,     // asset is not ASSET_TYPE_ALPHANUM
///     ALLOW_TRUST_NO_TRUST_LINE = -2, // trustor does not have a trustline
///                                     // source account does not require trust
///     ALLOW_TRUST_TRUST_NOT_REQUIRED = -3,
///     ALLOW_TRUST_CANT_REVOKE = -4,      // source account can't revoke trust,
///     ALLOW_TRUST_SELF_NOT_ALLOWED = -5, // trusting self is not allowed
///     ALLOW_TRUST_LOW_RESERVE = -6       // claimable balances can't be created
///                                        // on revoke due to low reserves
/// };
/// ```
///
pub const AllowTrustResultCode = enum(i32) {
    Success = 0,
    Malformed = -1,
    NoTrustLine = -2,
    TrustNotRequired = -3,
    CantRevoke = -4,
    SelfNotAllowed = -5,
    LowReserve = -6,
    _,

    pub const variants = [_]AllowTrustResultCode{
        .Success,
        .Malformed,
        .NoTrustLine,
        .TrustNotRequired,
        .CantRevoke,
        .SelfNotAllowed,
        .LowReserve,
    };

    pub fn name(self: AllowTrustResultCode) []const u8 {
        return switch (self) {
            .Success => "Success",
            .Malformed => "Malformed",
            .NoTrustLine => "NoTrustLine",
            .TrustNotRequired => "TrustNotRequired",
            .CantRevoke => "CantRevoke",
            .SelfNotAllowed => "SelfNotAllowed",
            .LowReserve => "LowReserve",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !AllowTrustResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: AllowTrustResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// AllowTrustResult is an XDR Union defined as:
///
/// ```text
/// union AllowTrustResult switch (AllowTrustResultCode code)
/// {
/// case ALLOW_TRUST_SUCCESS:
///     void;
/// case ALLOW_TRUST_MALFORMED:
/// case ALLOW_TRUST_NO_TRUST_LINE:
/// case ALLOW_TRUST_TRUST_NOT_REQUIRED:
/// case ALLOW_TRUST_CANT_REVOKE:
/// case ALLOW_TRUST_SELF_NOT_ALLOWED:
/// case ALLOW_TRUST_LOW_RESERVE:
///     void;
/// };
/// ```
///
pub const AllowTrustResult = union(enum) {
    Success,
    Malformed,
    NoTrustLine,
    TrustNotRequired,
    CantRevoke,
    SelfNotAllowed,
    LowReserve,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !AllowTrustResult {
        const disc = try AllowTrustResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .Success => AllowTrustResult{ .Success = {} },
            .Malformed => AllowTrustResult{ .Malformed = {} },
            .NoTrustLine => AllowTrustResult{ .NoTrustLine = {} },
            .TrustNotRequired => AllowTrustResult{ .TrustNotRequired = {} },
            .CantRevoke => AllowTrustResult{ .CantRevoke = {} },
            .SelfNotAllowed => AllowTrustResult{ .SelfNotAllowed = {} },
            .LowReserve => AllowTrustResult{ .LowReserve = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: AllowTrustResult, writer: anytype) !void {
        const disc: AllowTrustResultCode = switch (self) {
            .Success => .Success,
            .Malformed => .Malformed,
            .NoTrustLine => .NoTrustLine,
            .TrustNotRequired => .TrustNotRequired,
            .CantRevoke => .CantRevoke,
            .SelfNotAllowed => .SelfNotAllowed,
            .LowReserve => .LowReserve,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Success => {},
            .Malformed => {},
            .NoTrustLine => {},
            .TrustNotRequired => {},
            .CantRevoke => {},
            .SelfNotAllowed => {},
            .LowReserve => {},
        }
    }
};

/// AccountMergeResultCode is an XDR Enum defined as:
///
/// ```text
/// enum AccountMergeResultCode
/// {
///     // codes considered as "success" for the operation
///     ACCOUNT_MERGE_SUCCESS = 0,
///     // codes considered as "failure" for the operation
///     ACCOUNT_MERGE_MALFORMED = -1,       // can't merge onto itself
///     ACCOUNT_MERGE_NO_ACCOUNT = -2,      // destination does not exist
///     ACCOUNT_MERGE_IMMUTABLE_SET = -3,   // source account has AUTH_IMMUTABLE set
///     ACCOUNT_MERGE_HAS_SUB_ENTRIES = -4, // account has trust lines/offers
///     ACCOUNT_MERGE_SEQNUM_TOO_FAR = -5,  // sequence number is over max allowed
///     ACCOUNT_MERGE_DEST_FULL = -6,       // can't add source balance to
///                                         // destination balance
///     ACCOUNT_MERGE_IS_SPONSOR = -7       // can't merge account that is a sponsor
/// };
/// ```
///
pub const AccountMergeResultCode = enum(i32) {
    Success = 0,
    Malformed = -1,
    NoAccount = -2,
    ImmutableSet = -3,
    HasSubEntries = -4,
    SeqnumTooFar = -5,
    DestFull = -6,
    IsSponsor = -7,
    _,

    pub const variants = [_]AccountMergeResultCode{
        .Success,
        .Malformed,
        .NoAccount,
        .ImmutableSet,
        .HasSubEntries,
        .SeqnumTooFar,
        .DestFull,
        .IsSponsor,
    };

    pub fn name(self: AccountMergeResultCode) []const u8 {
        return switch (self) {
            .Success => "Success",
            .Malformed => "Malformed",
            .NoAccount => "NoAccount",
            .ImmutableSet => "ImmutableSet",
            .HasSubEntries => "HasSubEntries",
            .SeqnumTooFar => "SeqnumTooFar",
            .DestFull => "DestFull",
            .IsSponsor => "IsSponsor",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !AccountMergeResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: AccountMergeResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// AccountMergeResult is an XDR Union defined as:
///
/// ```text
/// union AccountMergeResult switch (AccountMergeResultCode code)
/// {
/// case ACCOUNT_MERGE_SUCCESS:
///     int64 sourceAccountBalance; // how much got transferred from source account
/// case ACCOUNT_MERGE_MALFORMED:
/// case ACCOUNT_MERGE_NO_ACCOUNT:
/// case ACCOUNT_MERGE_IMMUTABLE_SET:
/// case ACCOUNT_MERGE_HAS_SUB_ENTRIES:
/// case ACCOUNT_MERGE_SEQNUM_TOO_FAR:
/// case ACCOUNT_MERGE_DEST_FULL:
/// case ACCOUNT_MERGE_IS_SPONSOR:
///     void;
/// };
/// ```
///
pub const AccountMergeResult = union(enum) {
    Success: i64,
    Malformed,
    NoAccount,
    ImmutableSet,
    HasSubEntries,
    SeqnumTooFar,
    DestFull,
    IsSponsor,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !AccountMergeResult {
        const disc = try AccountMergeResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .Success => AccountMergeResult{ .Success = try xdrDecodeGeneric(i64, allocator, reader) },
            .Malformed => AccountMergeResult{ .Malformed = {} },
            .NoAccount => AccountMergeResult{ .NoAccount = {} },
            .ImmutableSet => AccountMergeResult{ .ImmutableSet = {} },
            .HasSubEntries => AccountMergeResult{ .HasSubEntries = {} },
            .SeqnumTooFar => AccountMergeResult{ .SeqnumTooFar = {} },
            .DestFull => AccountMergeResult{ .DestFull = {} },
            .IsSponsor => AccountMergeResult{ .IsSponsor = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: AccountMergeResult, writer: anytype) !void {
        const disc: AccountMergeResultCode = switch (self) {
            .Success => .Success,
            .Malformed => .Malformed,
            .NoAccount => .NoAccount,
            .ImmutableSet => .ImmutableSet,
            .HasSubEntries => .HasSubEntries,
            .SeqnumTooFar => .SeqnumTooFar,
            .DestFull => .DestFull,
            .IsSponsor => .IsSponsor,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Success => |v| try xdrEncodeGeneric(i64, writer, v),
            .Malformed => {},
            .NoAccount => {},
            .ImmutableSet => {},
            .HasSubEntries => {},
            .SeqnumTooFar => {},
            .DestFull => {},
            .IsSponsor => {},
        }
    }
};

/// InflationResultCode is an XDR Enum defined as:
///
/// ```text
/// enum InflationResultCode
/// {
///     // codes considered as "success" for the operation
///     INFLATION_SUCCESS = 0,
///     // codes considered as "failure" for the operation
///     INFLATION_NOT_TIME = -1
/// };
/// ```
///
pub const InflationResultCode = enum(i32) {
    Success = 0,
    NotTime = -1,
    _,

    pub const variants = [_]InflationResultCode{
        .Success,
        .NotTime,
    };

    pub fn name(self: InflationResultCode) []const u8 {
        return switch (self) {
            .Success => "Success",
            .NotTime => "NotTime",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !InflationResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: InflationResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// InflationPayout is an XDR Struct defined as:
///
/// ```text
/// struct InflationPayout // or use PaymentResultAtom to limit types?
/// {
///     AccountID destination;
///     int64 amount;
/// };
/// ```
///
pub const InflationPayout = struct {
    destination: AccountId,
    amount: i64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !InflationPayout {
        return InflationPayout{
            .destination = try xdrDecodeGeneric(AccountId, allocator, reader),
            .amount = try xdrDecodeGeneric(i64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: InflationPayout, writer: anytype) !void {
        try xdrEncodeGeneric(AccountId, writer, self.destination);
        try xdrEncodeGeneric(i64, writer, self.amount);
    }
};

/// InflationResult is an XDR Union defined as:
///
/// ```text
/// union InflationResult switch (InflationResultCode code)
/// {
/// case INFLATION_SUCCESS:
///     InflationPayout payouts<>;
/// case INFLATION_NOT_TIME:
///     void;
/// };
/// ```
///
pub const InflationResult = union(enum) {
    Success: []InflationPayout,
    NotTime,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !InflationResult {
        const disc = try InflationResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .Success => InflationResult{ .Success = try xdrDecodeGeneric([]InflationPayout, allocator, reader) },
            .NotTime => InflationResult{ .NotTime = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: InflationResult, writer: anytype) !void {
        const disc: InflationResultCode = switch (self) {
            .Success => .Success,
            .NotTime => .NotTime,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Success => |v| try xdrEncodeGeneric([]InflationPayout, writer, v),
            .NotTime => {},
        }
    }
};

/// ManageDataResultCode is an XDR Enum defined as:
///
/// ```text
/// enum ManageDataResultCode
/// {
///     // codes considered as "success" for the operation
///     MANAGE_DATA_SUCCESS = 0,
///     // codes considered as "failure" for the operation
///     MANAGE_DATA_NOT_SUPPORTED_YET =
///         -1, // The network hasn't moved to this protocol change yet
///     MANAGE_DATA_NAME_NOT_FOUND =
///         -2, // Trying to remove a Data Entry that isn't there
///     MANAGE_DATA_LOW_RESERVE = -3, // not enough funds to create a new Data Entry
///     MANAGE_DATA_INVALID_NAME = -4 // Name not a valid string
/// };
/// ```
///
pub const ManageDataResultCode = enum(i32) {
    Success = 0,
    NotSupportedYet = -1,
    NameNotFound = -2,
    LowReserve = -3,
    InvalidName = -4,
    _,

    pub const variants = [_]ManageDataResultCode{
        .Success,
        .NotSupportedYet,
        .NameNotFound,
        .LowReserve,
        .InvalidName,
    };

    pub fn name(self: ManageDataResultCode) []const u8 {
        return switch (self) {
            .Success => "Success",
            .NotSupportedYet => "NotSupportedYet",
            .NameNotFound => "NameNotFound",
            .LowReserve => "LowReserve",
            .InvalidName => "InvalidName",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ManageDataResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ManageDataResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ManageDataResult is an XDR Union defined as:
///
/// ```text
/// union ManageDataResult switch (ManageDataResultCode code)
/// {
/// case MANAGE_DATA_SUCCESS:
///     void;
/// case MANAGE_DATA_NOT_SUPPORTED_YET:
/// case MANAGE_DATA_NAME_NOT_FOUND:
/// case MANAGE_DATA_LOW_RESERVE:
/// case MANAGE_DATA_INVALID_NAME:
///     void;
/// };
/// ```
///
pub const ManageDataResult = union(enum) {
    Success,
    NotSupportedYet,
    NameNotFound,
    LowReserve,
    InvalidName,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ManageDataResult {
        const disc = try ManageDataResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .Success => ManageDataResult{ .Success = {} },
            .NotSupportedYet => ManageDataResult{ .NotSupportedYet = {} },
            .NameNotFound => ManageDataResult{ .NameNotFound = {} },
            .LowReserve => ManageDataResult{ .LowReserve = {} },
            .InvalidName => ManageDataResult{ .InvalidName = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ManageDataResult, writer: anytype) !void {
        const disc: ManageDataResultCode = switch (self) {
            .Success => .Success,
            .NotSupportedYet => .NotSupportedYet,
            .NameNotFound => .NameNotFound,
            .LowReserve => .LowReserve,
            .InvalidName => .InvalidName,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Success => {},
            .NotSupportedYet => {},
            .NameNotFound => {},
            .LowReserve => {},
            .InvalidName => {},
        }
    }
};

/// BumpSequenceResultCode is an XDR Enum defined as:
///
/// ```text
/// enum BumpSequenceResultCode
/// {
///     // codes considered as "success" for the operation
///     BUMP_SEQUENCE_SUCCESS = 0,
///     // codes considered as "failure" for the operation
///     BUMP_SEQUENCE_BAD_SEQ = -1 // `bumpTo` is not within bounds
/// };
/// ```
///
pub const BumpSequenceResultCode = enum(i32) {
    Success = 0,
    BadSeq = -1,
    _,

    pub const variants = [_]BumpSequenceResultCode{
        .Success,
        .BadSeq,
    };

    pub fn name(self: BumpSequenceResultCode) []const u8 {
        return switch (self) {
            .Success => "Success",
            .BadSeq => "BadSeq",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !BumpSequenceResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: BumpSequenceResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// BumpSequenceResult is an XDR Union defined as:
///
/// ```text
/// union BumpSequenceResult switch (BumpSequenceResultCode code)
/// {
/// case BUMP_SEQUENCE_SUCCESS:
///     void;
/// case BUMP_SEQUENCE_BAD_SEQ:
///     void;
/// };
/// ```
///
pub const BumpSequenceResult = union(enum) {
    Success,
    BadSeq,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !BumpSequenceResult {
        const disc = try BumpSequenceResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .Success => BumpSequenceResult{ .Success = {} },
            .BadSeq => BumpSequenceResult{ .BadSeq = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: BumpSequenceResult, writer: anytype) !void {
        const disc: BumpSequenceResultCode = switch (self) {
            .Success => .Success,
            .BadSeq => .BadSeq,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Success => {},
            .BadSeq => {},
        }
    }
};

/// CreateClaimableBalanceResultCode is an XDR Enum defined as:
///
/// ```text
/// enum CreateClaimableBalanceResultCode
/// {
///     CREATE_CLAIMABLE_BALANCE_SUCCESS = 0,
///     CREATE_CLAIMABLE_BALANCE_MALFORMED = -1,
///     CREATE_CLAIMABLE_BALANCE_LOW_RESERVE = -2,
///     CREATE_CLAIMABLE_BALANCE_NO_TRUST = -3,
///     CREATE_CLAIMABLE_BALANCE_NOT_AUTHORIZED = -4,
///     CREATE_CLAIMABLE_BALANCE_UNDERFUNDED = -5
/// };
/// ```
///
pub const CreateClaimableBalanceResultCode = enum(i32) {
    Success = 0,
    Malformed = -1,
    LowReserve = -2,
    NoTrust = -3,
    NotAuthorized = -4,
    Underfunded = -5,
    _,

    pub const variants = [_]CreateClaimableBalanceResultCode{
        .Success,
        .Malformed,
        .LowReserve,
        .NoTrust,
        .NotAuthorized,
        .Underfunded,
    };

    pub fn name(self: CreateClaimableBalanceResultCode) []const u8 {
        return switch (self) {
            .Success => "Success",
            .Malformed => "Malformed",
            .LowReserve => "LowReserve",
            .NoTrust => "NoTrust",
            .NotAuthorized => "NotAuthorized",
            .Underfunded => "Underfunded",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !CreateClaimableBalanceResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: CreateClaimableBalanceResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// CreateClaimableBalanceResult is an XDR Union defined as:
///
/// ```text
/// union CreateClaimableBalanceResult switch (
///     CreateClaimableBalanceResultCode code)
/// {
/// case CREATE_CLAIMABLE_BALANCE_SUCCESS:
///     ClaimableBalanceID balanceID;
/// case CREATE_CLAIMABLE_BALANCE_MALFORMED:
/// case CREATE_CLAIMABLE_BALANCE_LOW_RESERVE:
/// case CREATE_CLAIMABLE_BALANCE_NO_TRUST:
/// case CREATE_CLAIMABLE_BALANCE_NOT_AUTHORIZED:
/// case CREATE_CLAIMABLE_BALANCE_UNDERFUNDED:
///     void;
/// };
/// ```
///
pub const CreateClaimableBalanceResult = union(enum) {
    Success: ClaimableBalanceId,
    Malformed,
    LowReserve,
    NoTrust,
    NotAuthorized,
    Underfunded,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !CreateClaimableBalanceResult {
        const disc = try CreateClaimableBalanceResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .Success => CreateClaimableBalanceResult{ .Success = try xdrDecodeGeneric(ClaimableBalanceId, allocator, reader) },
            .Malformed => CreateClaimableBalanceResult{ .Malformed = {} },
            .LowReserve => CreateClaimableBalanceResult{ .LowReserve = {} },
            .NoTrust => CreateClaimableBalanceResult{ .NoTrust = {} },
            .NotAuthorized => CreateClaimableBalanceResult{ .NotAuthorized = {} },
            .Underfunded => CreateClaimableBalanceResult{ .Underfunded = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: CreateClaimableBalanceResult, writer: anytype) !void {
        const disc: CreateClaimableBalanceResultCode = switch (self) {
            .Success => .Success,
            .Malformed => .Malformed,
            .LowReserve => .LowReserve,
            .NoTrust => .NoTrust,
            .NotAuthorized => .NotAuthorized,
            .Underfunded => .Underfunded,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Success => |v| try xdrEncodeGeneric(ClaimableBalanceId, writer, v),
            .Malformed => {},
            .LowReserve => {},
            .NoTrust => {},
            .NotAuthorized => {},
            .Underfunded => {},
        }
    }
};

/// ClaimClaimableBalanceResultCode is an XDR Enum defined as:
///
/// ```text
/// enum ClaimClaimableBalanceResultCode
/// {
///     CLAIM_CLAIMABLE_BALANCE_SUCCESS = 0,
///     CLAIM_CLAIMABLE_BALANCE_DOES_NOT_EXIST = -1,
///     CLAIM_CLAIMABLE_BALANCE_CANNOT_CLAIM = -2,
///     CLAIM_CLAIMABLE_BALANCE_LINE_FULL = -3,
///     CLAIM_CLAIMABLE_BALANCE_NO_TRUST = -4,
///     CLAIM_CLAIMABLE_BALANCE_NOT_AUTHORIZED = -5
/// };
/// ```
///
pub const ClaimClaimableBalanceResultCode = enum(i32) {
    Success = 0,
    DoesNotExist = -1,
    CannotClaim = -2,
    LineFull = -3,
    NoTrust = -4,
    NotAuthorized = -5,
    _,

    pub const variants = [_]ClaimClaimableBalanceResultCode{
        .Success,
        .DoesNotExist,
        .CannotClaim,
        .LineFull,
        .NoTrust,
        .NotAuthorized,
    };

    pub fn name(self: ClaimClaimableBalanceResultCode) []const u8 {
        return switch (self) {
            .Success => "Success",
            .DoesNotExist => "DoesNotExist",
            .CannotClaim => "CannotClaim",
            .LineFull => "LineFull",
            .NoTrust => "NoTrust",
            .NotAuthorized => "NotAuthorized",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ClaimClaimableBalanceResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ClaimClaimableBalanceResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ClaimClaimableBalanceResult is an XDR Union defined as:
///
/// ```text
/// union ClaimClaimableBalanceResult switch (ClaimClaimableBalanceResultCode code)
/// {
/// case CLAIM_CLAIMABLE_BALANCE_SUCCESS:
///     void;
/// case CLAIM_CLAIMABLE_BALANCE_DOES_NOT_EXIST:
/// case CLAIM_CLAIMABLE_BALANCE_CANNOT_CLAIM:
/// case CLAIM_CLAIMABLE_BALANCE_LINE_FULL:
/// case CLAIM_CLAIMABLE_BALANCE_NO_TRUST:
/// case CLAIM_CLAIMABLE_BALANCE_NOT_AUTHORIZED:
///     void;
/// };
/// ```
///
pub const ClaimClaimableBalanceResult = union(enum) {
    Success,
    DoesNotExist,
    CannotClaim,
    LineFull,
    NoTrust,
    NotAuthorized,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ClaimClaimableBalanceResult {
        const disc = try ClaimClaimableBalanceResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .Success => ClaimClaimableBalanceResult{ .Success = {} },
            .DoesNotExist => ClaimClaimableBalanceResult{ .DoesNotExist = {} },
            .CannotClaim => ClaimClaimableBalanceResult{ .CannotClaim = {} },
            .LineFull => ClaimClaimableBalanceResult{ .LineFull = {} },
            .NoTrust => ClaimClaimableBalanceResult{ .NoTrust = {} },
            .NotAuthorized => ClaimClaimableBalanceResult{ .NotAuthorized = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ClaimClaimableBalanceResult, writer: anytype) !void {
        const disc: ClaimClaimableBalanceResultCode = switch (self) {
            .Success => .Success,
            .DoesNotExist => .DoesNotExist,
            .CannotClaim => .CannotClaim,
            .LineFull => .LineFull,
            .NoTrust => .NoTrust,
            .NotAuthorized => .NotAuthorized,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Success => {},
            .DoesNotExist => {},
            .CannotClaim => {},
            .LineFull => {},
            .NoTrust => {},
            .NotAuthorized => {},
        }
    }
};

/// BeginSponsoringFutureReservesResultCode is an XDR Enum defined as:
///
/// ```text
/// enum BeginSponsoringFutureReservesResultCode
/// {
///     // codes considered as "success" for the operation
///     BEGIN_SPONSORING_FUTURE_RESERVES_SUCCESS = 0,
///
///     // codes considered as "failure" for the operation
///     BEGIN_SPONSORING_FUTURE_RESERVES_MALFORMED = -1,
///     BEGIN_SPONSORING_FUTURE_RESERVES_ALREADY_SPONSORED = -2,
///     BEGIN_SPONSORING_FUTURE_RESERVES_RECURSIVE = -3
/// };
/// ```
///
pub const BeginSponsoringFutureReservesResultCode = enum(i32) {
    Success = 0,
    Malformed = -1,
    AlreadySponsored = -2,
    Recursive = -3,
    _,

    pub const variants = [_]BeginSponsoringFutureReservesResultCode{
        .Success,
        .Malformed,
        .AlreadySponsored,
        .Recursive,
    };

    pub fn name(self: BeginSponsoringFutureReservesResultCode) []const u8 {
        return switch (self) {
            .Success => "Success",
            .Malformed => "Malformed",
            .AlreadySponsored => "AlreadySponsored",
            .Recursive => "Recursive",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !BeginSponsoringFutureReservesResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: BeginSponsoringFutureReservesResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// BeginSponsoringFutureReservesResult is an XDR Union defined as:
///
/// ```text
/// union BeginSponsoringFutureReservesResult switch (
///     BeginSponsoringFutureReservesResultCode code)
/// {
/// case BEGIN_SPONSORING_FUTURE_RESERVES_SUCCESS:
///     void;
/// case BEGIN_SPONSORING_FUTURE_RESERVES_MALFORMED:
/// case BEGIN_SPONSORING_FUTURE_RESERVES_ALREADY_SPONSORED:
/// case BEGIN_SPONSORING_FUTURE_RESERVES_RECURSIVE:
///     void;
/// };
/// ```
///
pub const BeginSponsoringFutureReservesResult = union(enum) {
    Success,
    Malformed,
    AlreadySponsored,
    Recursive,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !BeginSponsoringFutureReservesResult {
        const disc = try BeginSponsoringFutureReservesResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .Success => BeginSponsoringFutureReservesResult{ .Success = {} },
            .Malformed => BeginSponsoringFutureReservesResult{ .Malformed = {} },
            .AlreadySponsored => BeginSponsoringFutureReservesResult{ .AlreadySponsored = {} },
            .Recursive => BeginSponsoringFutureReservesResult{ .Recursive = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: BeginSponsoringFutureReservesResult, writer: anytype) !void {
        const disc: BeginSponsoringFutureReservesResultCode = switch (self) {
            .Success => .Success,
            .Malformed => .Malformed,
            .AlreadySponsored => .AlreadySponsored,
            .Recursive => .Recursive,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Success => {},
            .Malformed => {},
            .AlreadySponsored => {},
            .Recursive => {},
        }
    }
};

/// EndSponsoringFutureReservesResultCode is an XDR Enum defined as:
///
/// ```text
/// enum EndSponsoringFutureReservesResultCode
/// {
///     // codes considered as "success" for the operation
///     END_SPONSORING_FUTURE_RESERVES_SUCCESS = 0,
///
///     // codes considered as "failure" for the operation
///     END_SPONSORING_FUTURE_RESERVES_NOT_SPONSORED = -1
/// };
/// ```
///
pub const EndSponsoringFutureReservesResultCode = enum(i32) {
    Success = 0,
    NotSponsored = -1,
    _,

    pub const variants = [_]EndSponsoringFutureReservesResultCode{
        .Success,
        .NotSponsored,
    };

    pub fn name(self: EndSponsoringFutureReservesResultCode) []const u8 {
        return switch (self) {
            .Success => "Success",
            .NotSponsored => "NotSponsored",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !EndSponsoringFutureReservesResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: EndSponsoringFutureReservesResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// EndSponsoringFutureReservesResult is an XDR Union defined as:
///
/// ```text
/// union EndSponsoringFutureReservesResult switch (
///     EndSponsoringFutureReservesResultCode code)
/// {
/// case END_SPONSORING_FUTURE_RESERVES_SUCCESS:
///     void;
/// case END_SPONSORING_FUTURE_RESERVES_NOT_SPONSORED:
///     void;
/// };
/// ```
///
pub const EndSponsoringFutureReservesResult = union(enum) {
    Success,
    NotSponsored,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !EndSponsoringFutureReservesResult {
        const disc = try EndSponsoringFutureReservesResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .Success => EndSponsoringFutureReservesResult{ .Success = {} },
            .NotSponsored => EndSponsoringFutureReservesResult{ .NotSponsored = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: EndSponsoringFutureReservesResult, writer: anytype) !void {
        const disc: EndSponsoringFutureReservesResultCode = switch (self) {
            .Success => .Success,
            .NotSponsored => .NotSponsored,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Success => {},
            .NotSponsored => {},
        }
    }
};

/// RevokeSponsorshipResultCode is an XDR Enum defined as:
///
/// ```text
/// enum RevokeSponsorshipResultCode
/// {
///     // codes considered as "success" for the operation
///     REVOKE_SPONSORSHIP_SUCCESS = 0,
///
///     // codes considered as "failure" for the operation
///     REVOKE_SPONSORSHIP_DOES_NOT_EXIST = -1,
///     REVOKE_SPONSORSHIP_NOT_SPONSOR = -2,
///     REVOKE_SPONSORSHIP_LOW_RESERVE = -3,
///     REVOKE_SPONSORSHIP_ONLY_TRANSFERABLE = -4,
///     REVOKE_SPONSORSHIP_MALFORMED = -5
/// };
/// ```
///
pub const RevokeSponsorshipResultCode = enum(i32) {
    Success = 0,
    DoesNotExist = -1,
    NotSponsor = -2,
    LowReserve = -3,
    OnlyTransferable = -4,
    Malformed = -5,
    _,

    pub const variants = [_]RevokeSponsorshipResultCode{
        .Success,
        .DoesNotExist,
        .NotSponsor,
        .LowReserve,
        .OnlyTransferable,
        .Malformed,
    };

    pub fn name(self: RevokeSponsorshipResultCode) []const u8 {
        return switch (self) {
            .Success => "Success",
            .DoesNotExist => "DoesNotExist",
            .NotSponsor => "NotSponsor",
            .LowReserve => "LowReserve",
            .OnlyTransferable => "OnlyTransferable",
            .Malformed => "Malformed",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !RevokeSponsorshipResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: RevokeSponsorshipResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// RevokeSponsorshipResult is an XDR Union defined as:
///
/// ```text
/// union RevokeSponsorshipResult switch (RevokeSponsorshipResultCode code)
/// {
/// case REVOKE_SPONSORSHIP_SUCCESS:
///     void;
/// case REVOKE_SPONSORSHIP_DOES_NOT_EXIST:
/// case REVOKE_SPONSORSHIP_NOT_SPONSOR:
/// case REVOKE_SPONSORSHIP_LOW_RESERVE:
/// case REVOKE_SPONSORSHIP_ONLY_TRANSFERABLE:
/// case REVOKE_SPONSORSHIP_MALFORMED:
///     void;
/// };
/// ```
///
pub const RevokeSponsorshipResult = union(enum) {
    Success,
    DoesNotExist,
    NotSponsor,
    LowReserve,
    OnlyTransferable,
    Malformed,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !RevokeSponsorshipResult {
        const disc = try RevokeSponsorshipResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .Success => RevokeSponsorshipResult{ .Success = {} },
            .DoesNotExist => RevokeSponsorshipResult{ .DoesNotExist = {} },
            .NotSponsor => RevokeSponsorshipResult{ .NotSponsor = {} },
            .LowReserve => RevokeSponsorshipResult{ .LowReserve = {} },
            .OnlyTransferable => RevokeSponsorshipResult{ .OnlyTransferable = {} },
            .Malformed => RevokeSponsorshipResult{ .Malformed = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: RevokeSponsorshipResult, writer: anytype) !void {
        const disc: RevokeSponsorshipResultCode = switch (self) {
            .Success => .Success,
            .DoesNotExist => .DoesNotExist,
            .NotSponsor => .NotSponsor,
            .LowReserve => .LowReserve,
            .OnlyTransferable => .OnlyTransferable,
            .Malformed => .Malformed,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Success => {},
            .DoesNotExist => {},
            .NotSponsor => {},
            .LowReserve => {},
            .OnlyTransferable => {},
            .Malformed => {},
        }
    }
};

/// ClawbackResultCode is an XDR Enum defined as:
///
/// ```text
/// enum ClawbackResultCode
/// {
///     // codes considered as "success" for the operation
///     CLAWBACK_SUCCESS = 0,
///
///     // codes considered as "failure" for the operation
///     CLAWBACK_MALFORMED = -1,
///     CLAWBACK_NOT_CLAWBACK_ENABLED = -2,
///     CLAWBACK_NO_TRUST = -3,
///     CLAWBACK_UNDERFUNDED = -4
/// };
/// ```
///
pub const ClawbackResultCode = enum(i32) {
    Success = 0,
    Malformed = -1,
    NotClawbackEnabled = -2,
    NoTrust = -3,
    Underfunded = -4,
    _,

    pub const variants = [_]ClawbackResultCode{
        .Success,
        .Malformed,
        .NotClawbackEnabled,
        .NoTrust,
        .Underfunded,
    };

    pub fn name(self: ClawbackResultCode) []const u8 {
        return switch (self) {
            .Success => "Success",
            .Malformed => "Malformed",
            .NotClawbackEnabled => "NotClawbackEnabled",
            .NoTrust => "NoTrust",
            .Underfunded => "Underfunded",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ClawbackResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ClawbackResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ClawbackResult is an XDR Union defined as:
///
/// ```text
/// union ClawbackResult switch (ClawbackResultCode code)
/// {
/// case CLAWBACK_SUCCESS:
///     void;
/// case CLAWBACK_MALFORMED:
/// case CLAWBACK_NOT_CLAWBACK_ENABLED:
/// case CLAWBACK_NO_TRUST:
/// case CLAWBACK_UNDERFUNDED:
///     void;
/// };
/// ```
///
pub const ClawbackResult = union(enum) {
    Success,
    Malformed,
    NotClawbackEnabled,
    NoTrust,
    Underfunded,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ClawbackResult {
        const disc = try ClawbackResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .Success => ClawbackResult{ .Success = {} },
            .Malformed => ClawbackResult{ .Malformed = {} },
            .NotClawbackEnabled => ClawbackResult{ .NotClawbackEnabled = {} },
            .NoTrust => ClawbackResult{ .NoTrust = {} },
            .Underfunded => ClawbackResult{ .Underfunded = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ClawbackResult, writer: anytype) !void {
        const disc: ClawbackResultCode = switch (self) {
            .Success => .Success,
            .Malformed => .Malformed,
            .NotClawbackEnabled => .NotClawbackEnabled,
            .NoTrust => .NoTrust,
            .Underfunded => .Underfunded,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Success => {},
            .Malformed => {},
            .NotClawbackEnabled => {},
            .NoTrust => {},
            .Underfunded => {},
        }
    }
};

/// ClawbackClaimableBalanceResultCode is an XDR Enum defined as:
///
/// ```text
/// enum ClawbackClaimableBalanceResultCode
/// {
///     // codes considered as "success" for the operation
///     CLAWBACK_CLAIMABLE_BALANCE_SUCCESS = 0,
///
///     // codes considered as "failure" for the operation
///     CLAWBACK_CLAIMABLE_BALANCE_DOES_NOT_EXIST = -1,
///     CLAWBACK_CLAIMABLE_BALANCE_NOT_ISSUER = -2,
///     CLAWBACK_CLAIMABLE_BALANCE_NOT_CLAWBACK_ENABLED = -3
/// };
/// ```
///
pub const ClawbackClaimableBalanceResultCode = enum(i32) {
    Success = 0,
    DoesNotExist = -1,
    NotIssuer = -2,
    NotClawbackEnabled = -3,
    _,

    pub const variants = [_]ClawbackClaimableBalanceResultCode{
        .Success,
        .DoesNotExist,
        .NotIssuer,
        .NotClawbackEnabled,
    };

    pub fn name(self: ClawbackClaimableBalanceResultCode) []const u8 {
        return switch (self) {
            .Success => "Success",
            .DoesNotExist => "DoesNotExist",
            .NotIssuer => "NotIssuer",
            .NotClawbackEnabled => "NotClawbackEnabled",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ClawbackClaimableBalanceResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ClawbackClaimableBalanceResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ClawbackClaimableBalanceResult is an XDR Union defined as:
///
/// ```text
/// union ClawbackClaimableBalanceResult switch (
///     ClawbackClaimableBalanceResultCode code)
/// {
/// case CLAWBACK_CLAIMABLE_BALANCE_SUCCESS:
///     void;
/// case CLAWBACK_CLAIMABLE_BALANCE_DOES_NOT_EXIST:
/// case CLAWBACK_CLAIMABLE_BALANCE_NOT_ISSUER:
/// case CLAWBACK_CLAIMABLE_BALANCE_NOT_CLAWBACK_ENABLED:
///     void;
/// };
/// ```
///
pub const ClawbackClaimableBalanceResult = union(enum) {
    Success,
    DoesNotExist,
    NotIssuer,
    NotClawbackEnabled,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ClawbackClaimableBalanceResult {
        const disc = try ClawbackClaimableBalanceResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .Success => ClawbackClaimableBalanceResult{ .Success = {} },
            .DoesNotExist => ClawbackClaimableBalanceResult{ .DoesNotExist = {} },
            .NotIssuer => ClawbackClaimableBalanceResult{ .NotIssuer = {} },
            .NotClawbackEnabled => ClawbackClaimableBalanceResult{ .NotClawbackEnabled = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ClawbackClaimableBalanceResult, writer: anytype) !void {
        const disc: ClawbackClaimableBalanceResultCode = switch (self) {
            .Success => .Success,
            .DoesNotExist => .DoesNotExist,
            .NotIssuer => .NotIssuer,
            .NotClawbackEnabled => .NotClawbackEnabled,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Success => {},
            .DoesNotExist => {},
            .NotIssuer => {},
            .NotClawbackEnabled => {},
        }
    }
};

/// SetTrustLineFlagsResultCode is an XDR Enum defined as:
///
/// ```text
/// enum SetTrustLineFlagsResultCode
/// {
///     // codes considered as "success" for the operation
///     SET_TRUST_LINE_FLAGS_SUCCESS = 0,
///
///     // codes considered as "failure" for the operation
///     SET_TRUST_LINE_FLAGS_MALFORMED = -1,
///     SET_TRUST_LINE_FLAGS_NO_TRUST_LINE = -2,
///     SET_TRUST_LINE_FLAGS_CANT_REVOKE = -3,
///     SET_TRUST_LINE_FLAGS_INVALID_STATE = -4,
///     SET_TRUST_LINE_FLAGS_LOW_RESERVE = -5 // claimable balances can't be created
///                                           // on revoke due to low reserves
/// };
/// ```
///
pub const SetTrustLineFlagsResultCode = enum(i32) {
    Success = 0,
    Malformed = -1,
    NoTrustLine = -2,
    CantRevoke = -3,
    InvalidState = -4,
    LowReserve = -5,
    _,

    pub const variants = [_]SetTrustLineFlagsResultCode{
        .Success,
        .Malformed,
        .NoTrustLine,
        .CantRevoke,
        .InvalidState,
        .LowReserve,
    };

    pub fn name(self: SetTrustLineFlagsResultCode) []const u8 {
        return switch (self) {
            .Success => "Success",
            .Malformed => "Malformed",
            .NoTrustLine => "NoTrustLine",
            .CantRevoke => "CantRevoke",
            .InvalidState => "InvalidState",
            .LowReserve => "LowReserve",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SetTrustLineFlagsResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: SetTrustLineFlagsResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// SetTrustLineFlagsResult is an XDR Union defined as:
///
/// ```text
/// union SetTrustLineFlagsResult switch (SetTrustLineFlagsResultCode code)
/// {
/// case SET_TRUST_LINE_FLAGS_SUCCESS:
///     void;
/// case SET_TRUST_LINE_FLAGS_MALFORMED:
/// case SET_TRUST_LINE_FLAGS_NO_TRUST_LINE:
/// case SET_TRUST_LINE_FLAGS_CANT_REVOKE:
/// case SET_TRUST_LINE_FLAGS_INVALID_STATE:
/// case SET_TRUST_LINE_FLAGS_LOW_RESERVE:
///     void;
/// };
/// ```
///
pub const SetTrustLineFlagsResult = union(enum) {
    Success,
    Malformed,
    NoTrustLine,
    CantRevoke,
    InvalidState,
    LowReserve,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SetTrustLineFlagsResult {
        const disc = try SetTrustLineFlagsResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .Success => SetTrustLineFlagsResult{ .Success = {} },
            .Malformed => SetTrustLineFlagsResult{ .Malformed = {} },
            .NoTrustLine => SetTrustLineFlagsResult{ .NoTrustLine = {} },
            .CantRevoke => SetTrustLineFlagsResult{ .CantRevoke = {} },
            .InvalidState => SetTrustLineFlagsResult{ .InvalidState = {} },
            .LowReserve => SetTrustLineFlagsResult{ .LowReserve = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: SetTrustLineFlagsResult, writer: anytype) !void {
        const disc: SetTrustLineFlagsResultCode = switch (self) {
            .Success => .Success,
            .Malformed => .Malformed,
            .NoTrustLine => .NoTrustLine,
            .CantRevoke => .CantRevoke,
            .InvalidState => .InvalidState,
            .LowReserve => .LowReserve,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Success => {},
            .Malformed => {},
            .NoTrustLine => {},
            .CantRevoke => {},
            .InvalidState => {},
            .LowReserve => {},
        }
    }
};

/// LiquidityPoolDepositResultCode is an XDR Enum defined as:
///
/// ```text
/// enum LiquidityPoolDepositResultCode
/// {
///     // codes considered as "success" for the operation
///     LIQUIDITY_POOL_DEPOSIT_SUCCESS = 0,
///
///     // codes considered as "failure" for the operation
///     LIQUIDITY_POOL_DEPOSIT_MALFORMED = -1,      // bad input
///     LIQUIDITY_POOL_DEPOSIT_NO_TRUST = -2,       // no trust line for one of the
///                                                 // assets
///     LIQUIDITY_POOL_DEPOSIT_NOT_AUTHORIZED = -3, // not authorized for one of the
///                                                 // assets
///     LIQUIDITY_POOL_DEPOSIT_UNDERFUNDED = -4,    // not enough balance for one of
///                                                 // the assets
///     LIQUIDITY_POOL_DEPOSIT_LINE_FULL = -5,      // pool share trust line doesn't
///                                                 // have sufficient limit
///     LIQUIDITY_POOL_DEPOSIT_BAD_PRICE = -6,      // deposit price outside bounds
///     LIQUIDITY_POOL_DEPOSIT_POOL_FULL = -7       // pool reserves are full
/// };
/// ```
///
pub const LiquidityPoolDepositResultCode = enum(i32) {
    Success = 0,
    Malformed = -1,
    NoTrust = -2,
    NotAuthorized = -3,
    Underfunded = -4,
    LineFull = -5,
    BadPrice = -6,
    PoolFull = -7,
    _,

    pub const variants = [_]LiquidityPoolDepositResultCode{
        .Success,
        .Malformed,
        .NoTrust,
        .NotAuthorized,
        .Underfunded,
        .LineFull,
        .BadPrice,
        .PoolFull,
    };

    pub fn name(self: LiquidityPoolDepositResultCode) []const u8 {
        return switch (self) {
            .Success => "Success",
            .Malformed => "Malformed",
            .NoTrust => "NoTrust",
            .NotAuthorized => "NotAuthorized",
            .Underfunded => "Underfunded",
            .LineFull => "LineFull",
            .BadPrice => "BadPrice",
            .PoolFull => "PoolFull",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LiquidityPoolDepositResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: LiquidityPoolDepositResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// LiquidityPoolDepositResult is an XDR Union defined as:
///
/// ```text
/// union LiquidityPoolDepositResult switch (LiquidityPoolDepositResultCode code)
/// {
/// case LIQUIDITY_POOL_DEPOSIT_SUCCESS:
///     void;
/// case LIQUIDITY_POOL_DEPOSIT_MALFORMED:
/// case LIQUIDITY_POOL_DEPOSIT_NO_TRUST:
/// case LIQUIDITY_POOL_DEPOSIT_NOT_AUTHORIZED:
/// case LIQUIDITY_POOL_DEPOSIT_UNDERFUNDED:
/// case LIQUIDITY_POOL_DEPOSIT_LINE_FULL:
/// case LIQUIDITY_POOL_DEPOSIT_BAD_PRICE:
/// case LIQUIDITY_POOL_DEPOSIT_POOL_FULL:
///     void;
/// };
/// ```
///
pub const LiquidityPoolDepositResult = union(enum) {
    Success,
    Malformed,
    NoTrust,
    NotAuthorized,
    Underfunded,
    LineFull,
    BadPrice,
    PoolFull,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LiquidityPoolDepositResult {
        const disc = try LiquidityPoolDepositResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .Success => LiquidityPoolDepositResult{ .Success = {} },
            .Malformed => LiquidityPoolDepositResult{ .Malformed = {} },
            .NoTrust => LiquidityPoolDepositResult{ .NoTrust = {} },
            .NotAuthorized => LiquidityPoolDepositResult{ .NotAuthorized = {} },
            .Underfunded => LiquidityPoolDepositResult{ .Underfunded = {} },
            .LineFull => LiquidityPoolDepositResult{ .LineFull = {} },
            .BadPrice => LiquidityPoolDepositResult{ .BadPrice = {} },
            .PoolFull => LiquidityPoolDepositResult{ .PoolFull = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: LiquidityPoolDepositResult, writer: anytype) !void {
        const disc: LiquidityPoolDepositResultCode = switch (self) {
            .Success => .Success,
            .Malformed => .Malformed,
            .NoTrust => .NoTrust,
            .NotAuthorized => .NotAuthorized,
            .Underfunded => .Underfunded,
            .LineFull => .LineFull,
            .BadPrice => .BadPrice,
            .PoolFull => .PoolFull,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Success => {},
            .Malformed => {},
            .NoTrust => {},
            .NotAuthorized => {},
            .Underfunded => {},
            .LineFull => {},
            .BadPrice => {},
            .PoolFull => {},
        }
    }
};

/// LiquidityPoolWithdrawResultCode is an XDR Enum defined as:
///
/// ```text
/// enum LiquidityPoolWithdrawResultCode
/// {
///     // codes considered as "success" for the operation
///     LIQUIDITY_POOL_WITHDRAW_SUCCESS = 0,
///
///     // codes considered as "failure" for the operation
///     LIQUIDITY_POOL_WITHDRAW_MALFORMED = -1,    // bad input
///     LIQUIDITY_POOL_WITHDRAW_NO_TRUST = -2,     // no trust line for one of the
///                                                // assets
///     LIQUIDITY_POOL_WITHDRAW_UNDERFUNDED = -3,  // not enough balance of the
///                                                // pool share
///     LIQUIDITY_POOL_WITHDRAW_LINE_FULL = -4,    // would go above limit for one
///                                                // of the assets
///     LIQUIDITY_POOL_WITHDRAW_UNDER_MINIMUM = -5 // didn't withdraw enough
/// };
/// ```
///
pub const LiquidityPoolWithdrawResultCode = enum(i32) {
    Success = 0,
    Malformed = -1,
    NoTrust = -2,
    Underfunded = -3,
    LineFull = -4,
    UnderMinimum = -5,
    _,

    pub const variants = [_]LiquidityPoolWithdrawResultCode{
        .Success,
        .Malformed,
        .NoTrust,
        .Underfunded,
        .LineFull,
        .UnderMinimum,
    };

    pub fn name(self: LiquidityPoolWithdrawResultCode) []const u8 {
        return switch (self) {
            .Success => "Success",
            .Malformed => "Malformed",
            .NoTrust => "NoTrust",
            .Underfunded => "Underfunded",
            .LineFull => "LineFull",
            .UnderMinimum => "UnderMinimum",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LiquidityPoolWithdrawResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: LiquidityPoolWithdrawResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// LiquidityPoolWithdrawResult is an XDR Union defined as:
///
/// ```text
/// union LiquidityPoolWithdrawResult switch (LiquidityPoolWithdrawResultCode code)
/// {
/// case LIQUIDITY_POOL_WITHDRAW_SUCCESS:
///     void;
/// case LIQUIDITY_POOL_WITHDRAW_MALFORMED:
/// case LIQUIDITY_POOL_WITHDRAW_NO_TRUST:
/// case LIQUIDITY_POOL_WITHDRAW_UNDERFUNDED:
/// case LIQUIDITY_POOL_WITHDRAW_LINE_FULL:
/// case LIQUIDITY_POOL_WITHDRAW_UNDER_MINIMUM:
///     void;
/// };
/// ```
///
pub const LiquidityPoolWithdrawResult = union(enum) {
    Success,
    Malformed,
    NoTrust,
    Underfunded,
    LineFull,
    UnderMinimum,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !LiquidityPoolWithdrawResult {
        const disc = try LiquidityPoolWithdrawResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .Success => LiquidityPoolWithdrawResult{ .Success = {} },
            .Malformed => LiquidityPoolWithdrawResult{ .Malformed = {} },
            .NoTrust => LiquidityPoolWithdrawResult{ .NoTrust = {} },
            .Underfunded => LiquidityPoolWithdrawResult{ .Underfunded = {} },
            .LineFull => LiquidityPoolWithdrawResult{ .LineFull = {} },
            .UnderMinimum => LiquidityPoolWithdrawResult{ .UnderMinimum = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: LiquidityPoolWithdrawResult, writer: anytype) !void {
        const disc: LiquidityPoolWithdrawResultCode = switch (self) {
            .Success => .Success,
            .Malformed => .Malformed,
            .NoTrust => .NoTrust,
            .Underfunded => .Underfunded,
            .LineFull => .LineFull,
            .UnderMinimum => .UnderMinimum,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Success => {},
            .Malformed => {},
            .NoTrust => {},
            .Underfunded => {},
            .LineFull => {},
            .UnderMinimum => {},
        }
    }
};

/// InvokeHostFunctionResultCode is an XDR Enum defined as:
///
/// ```text
/// enum InvokeHostFunctionResultCode
/// {
///     // codes considered as "success" for the operation
///     INVOKE_HOST_FUNCTION_SUCCESS = 0,
///
///     // codes considered as "failure" for the operation
///     INVOKE_HOST_FUNCTION_MALFORMED = -1,
///     INVOKE_HOST_FUNCTION_TRAPPED = -2,
///     INVOKE_HOST_FUNCTION_RESOURCE_LIMIT_EXCEEDED = -3,
///     INVOKE_HOST_FUNCTION_ENTRY_ARCHIVED = -4,
///     INVOKE_HOST_FUNCTION_INSUFFICIENT_REFUNDABLE_FEE = -5
/// };
/// ```
///
pub const InvokeHostFunctionResultCode = enum(i32) {
    Success = 0,
    Malformed = -1,
    Trapped = -2,
    ResourceLimitExceeded = -3,
    EntryArchived = -4,
    InsufficientRefundableFee = -5,
    _,

    pub const variants = [_]InvokeHostFunctionResultCode{
        .Success,
        .Malformed,
        .Trapped,
        .ResourceLimitExceeded,
        .EntryArchived,
        .InsufficientRefundableFee,
    };

    pub fn name(self: InvokeHostFunctionResultCode) []const u8 {
        return switch (self) {
            .Success => "Success",
            .Malformed => "Malformed",
            .Trapped => "Trapped",
            .ResourceLimitExceeded => "ResourceLimitExceeded",
            .EntryArchived => "EntryArchived",
            .InsufficientRefundableFee => "InsufficientRefundableFee",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !InvokeHostFunctionResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: InvokeHostFunctionResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// InvokeHostFunctionResult is an XDR Union defined as:
///
/// ```text
/// union InvokeHostFunctionResult switch (InvokeHostFunctionResultCode code)
/// {
/// case INVOKE_HOST_FUNCTION_SUCCESS:
///     Hash success; // sha256(InvokeHostFunctionSuccessPreImage)
/// case INVOKE_HOST_FUNCTION_MALFORMED:
/// case INVOKE_HOST_FUNCTION_TRAPPED:
/// case INVOKE_HOST_FUNCTION_RESOURCE_LIMIT_EXCEEDED:
/// case INVOKE_HOST_FUNCTION_ENTRY_ARCHIVED:
/// case INVOKE_HOST_FUNCTION_INSUFFICIENT_REFUNDABLE_FEE:
///     void;
/// };
/// ```
///
pub const InvokeHostFunctionResult = union(enum) {
    Success: Hash,
    Malformed,
    Trapped,
    ResourceLimitExceeded,
    EntryArchived,
    InsufficientRefundableFee,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !InvokeHostFunctionResult {
        const disc = try InvokeHostFunctionResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .Success => InvokeHostFunctionResult{ .Success = try xdrDecodeGeneric(Hash, allocator, reader) },
            .Malformed => InvokeHostFunctionResult{ .Malformed = {} },
            .Trapped => InvokeHostFunctionResult{ .Trapped = {} },
            .ResourceLimitExceeded => InvokeHostFunctionResult{ .ResourceLimitExceeded = {} },
            .EntryArchived => InvokeHostFunctionResult{ .EntryArchived = {} },
            .InsufficientRefundableFee => InvokeHostFunctionResult{ .InsufficientRefundableFee = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: InvokeHostFunctionResult, writer: anytype) !void {
        const disc: InvokeHostFunctionResultCode = switch (self) {
            .Success => .Success,
            .Malformed => .Malformed,
            .Trapped => .Trapped,
            .ResourceLimitExceeded => .ResourceLimitExceeded,
            .EntryArchived => .EntryArchived,
            .InsufficientRefundableFee => .InsufficientRefundableFee,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Success => |v| try xdrEncodeGeneric(Hash, writer, v),
            .Malformed => {},
            .Trapped => {},
            .ResourceLimitExceeded => {},
            .EntryArchived => {},
            .InsufficientRefundableFee => {},
        }
    }
};

/// ExtendFootprintTtlResultCode is an XDR Enum defined as:
///
/// ```text
/// enum ExtendFootprintTTLResultCode
/// {
///     // codes considered as "success" for the operation
///     EXTEND_FOOTPRINT_TTL_SUCCESS = 0,
///
///     // codes considered as "failure" for the operation
///     EXTEND_FOOTPRINT_TTL_MALFORMED = -1,
///     EXTEND_FOOTPRINT_TTL_RESOURCE_LIMIT_EXCEEDED = -2,
///     EXTEND_FOOTPRINT_TTL_INSUFFICIENT_REFUNDABLE_FEE = -3
/// };
/// ```
///
pub const ExtendFootprintTtlResultCode = enum(i32) {
    Success = 0,
    Malformed = -1,
    ResourceLimitExceeded = -2,
    InsufficientRefundableFee = -3,
    _,

    pub const variants = [_]ExtendFootprintTtlResultCode{
        .Success,
        .Malformed,
        .ResourceLimitExceeded,
        .InsufficientRefundableFee,
    };

    pub fn name(self: ExtendFootprintTtlResultCode) []const u8 {
        return switch (self) {
            .Success => "Success",
            .Malformed => "Malformed",
            .ResourceLimitExceeded => "ResourceLimitExceeded",
            .InsufficientRefundableFee => "InsufficientRefundableFee",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ExtendFootprintTtlResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ExtendFootprintTtlResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ExtendFootprintTtlResult is an XDR Union defined as:
///
/// ```text
/// union ExtendFootprintTTLResult switch (ExtendFootprintTTLResultCode code)
/// {
/// case EXTEND_FOOTPRINT_TTL_SUCCESS:
///     void;
/// case EXTEND_FOOTPRINT_TTL_MALFORMED:
/// case EXTEND_FOOTPRINT_TTL_RESOURCE_LIMIT_EXCEEDED:
/// case EXTEND_FOOTPRINT_TTL_INSUFFICIENT_REFUNDABLE_FEE:
///     void;
/// };
/// ```
///
pub const ExtendFootprintTtlResult = union(enum) {
    Success,
    Malformed,
    ResourceLimitExceeded,
    InsufficientRefundableFee,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ExtendFootprintTtlResult {
        const disc = try ExtendFootprintTtlResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .Success => ExtendFootprintTtlResult{ .Success = {} },
            .Malformed => ExtendFootprintTtlResult{ .Malformed = {} },
            .ResourceLimitExceeded => ExtendFootprintTtlResult{ .ResourceLimitExceeded = {} },
            .InsufficientRefundableFee => ExtendFootprintTtlResult{ .InsufficientRefundableFee = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ExtendFootprintTtlResult, writer: anytype) !void {
        const disc: ExtendFootprintTtlResultCode = switch (self) {
            .Success => .Success,
            .Malformed => .Malformed,
            .ResourceLimitExceeded => .ResourceLimitExceeded,
            .InsufficientRefundableFee => .InsufficientRefundableFee,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Success => {},
            .Malformed => {},
            .ResourceLimitExceeded => {},
            .InsufficientRefundableFee => {},
        }
    }
};

/// RestoreFootprintResultCode is an XDR Enum defined as:
///
/// ```text
/// enum RestoreFootprintResultCode
/// {
///     // codes considered as "success" for the operation
///     RESTORE_FOOTPRINT_SUCCESS = 0,
///
///     // codes considered as "failure" for the operation
///     RESTORE_FOOTPRINT_MALFORMED = -1,
///     RESTORE_FOOTPRINT_RESOURCE_LIMIT_EXCEEDED = -2,
///     RESTORE_FOOTPRINT_INSUFFICIENT_REFUNDABLE_FEE = -3
/// };
/// ```
///
pub const RestoreFootprintResultCode = enum(i32) {
    Success = 0,
    Malformed = -1,
    ResourceLimitExceeded = -2,
    InsufficientRefundableFee = -3,
    _,

    pub const variants = [_]RestoreFootprintResultCode{
        .Success,
        .Malformed,
        .ResourceLimitExceeded,
        .InsufficientRefundableFee,
    };

    pub fn name(self: RestoreFootprintResultCode) []const u8 {
        return switch (self) {
            .Success => "Success",
            .Malformed => "Malformed",
            .ResourceLimitExceeded => "ResourceLimitExceeded",
            .InsufficientRefundableFee => "InsufficientRefundableFee",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !RestoreFootprintResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: RestoreFootprintResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// RestoreFootprintResult is an XDR Union defined as:
///
/// ```text
/// union RestoreFootprintResult switch (RestoreFootprintResultCode code)
/// {
/// case RESTORE_FOOTPRINT_SUCCESS:
///     void;
/// case RESTORE_FOOTPRINT_MALFORMED:
/// case RESTORE_FOOTPRINT_RESOURCE_LIMIT_EXCEEDED:
/// case RESTORE_FOOTPRINT_INSUFFICIENT_REFUNDABLE_FEE:
///     void;
/// };
/// ```
///
pub const RestoreFootprintResult = union(enum) {
    Success,
    Malformed,
    ResourceLimitExceeded,
    InsufficientRefundableFee,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !RestoreFootprintResult {
        const disc = try RestoreFootprintResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .Success => RestoreFootprintResult{ .Success = {} },
            .Malformed => RestoreFootprintResult{ .Malformed = {} },
            .ResourceLimitExceeded => RestoreFootprintResult{ .ResourceLimitExceeded = {} },
            .InsufficientRefundableFee => RestoreFootprintResult{ .InsufficientRefundableFee = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: RestoreFootprintResult, writer: anytype) !void {
        const disc: RestoreFootprintResultCode = switch (self) {
            .Success => .Success,
            .Malformed => .Malformed,
            .ResourceLimitExceeded => .ResourceLimitExceeded,
            .InsufficientRefundableFee => .InsufficientRefundableFee,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Success => {},
            .Malformed => {},
            .ResourceLimitExceeded => {},
            .InsufficientRefundableFee => {},
        }
    }
};

/// OperationResultCode is an XDR Enum defined as:
///
/// ```text
/// enum OperationResultCode
/// {
///     opINNER = 0, // inner object result is valid
///
///     opBAD_AUTH = -1,            // too few valid signatures / wrong network
///     opNO_ACCOUNT = -2,          // source account was not found
///     opNOT_SUPPORTED = -3,       // operation not supported at this time
///     opTOO_MANY_SUBENTRIES = -4, // max number of subentries already reached
///     opEXCEEDED_WORK_LIMIT = -5, // operation did too much work
///     opTOO_MANY_SPONSORING = -6  // account is sponsoring too many entries
/// };
/// ```
///
pub const OperationResultCode = enum(i32) {
    OpInner = 0,
    OpBadAuth = -1,
    OpNoAccount = -2,
    OpNotSupported = -3,
    OpTooManySubentries = -4,
    OpExceededWorkLimit = -5,
    OpTooManySponsoring = -6,
    _,

    pub const variants = [_]OperationResultCode{
        .OpInner,
        .OpBadAuth,
        .OpNoAccount,
        .OpNotSupported,
        .OpTooManySubentries,
        .OpExceededWorkLimit,
        .OpTooManySponsoring,
    };

    pub fn name(self: OperationResultCode) []const u8 {
        return switch (self) {
            .OpInner => "OpInner",
            .OpBadAuth => "OpBadAuth",
            .OpNoAccount => "OpNoAccount",
            .OpNotSupported => "OpNotSupported",
            .OpTooManySubentries => "OpTooManySubentries",
            .OpExceededWorkLimit => "OpExceededWorkLimit",
            .OpTooManySponsoring => "OpTooManySponsoring",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !OperationResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: OperationResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// OperationResultTr is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (OperationType type)
///     {
///     case CREATE_ACCOUNT:
///         CreateAccountResult createAccountResult;
///     case PAYMENT:
///         PaymentResult paymentResult;
///     case PATH_PAYMENT_STRICT_RECEIVE:
///         PathPaymentStrictReceiveResult pathPaymentStrictReceiveResult;
///     case MANAGE_SELL_OFFER:
///         ManageSellOfferResult manageSellOfferResult;
///     case CREATE_PASSIVE_SELL_OFFER:
///         ManageSellOfferResult createPassiveSellOfferResult;
///     case SET_OPTIONS:
///         SetOptionsResult setOptionsResult;
///     case CHANGE_TRUST:
///         ChangeTrustResult changeTrustResult;
///     case ALLOW_TRUST:
///         AllowTrustResult allowTrustResult;
///     case ACCOUNT_MERGE:
///         AccountMergeResult accountMergeResult;
///     case INFLATION:
///         InflationResult inflationResult;
///     case MANAGE_DATA:
///         ManageDataResult manageDataResult;
///     case BUMP_SEQUENCE:
///         BumpSequenceResult bumpSeqResult;
///     case MANAGE_BUY_OFFER:
///         ManageBuyOfferResult manageBuyOfferResult;
///     case PATH_PAYMENT_STRICT_SEND:
///         PathPaymentStrictSendResult pathPaymentStrictSendResult;
///     case CREATE_CLAIMABLE_BALANCE:
///         CreateClaimableBalanceResult createClaimableBalanceResult;
///     case CLAIM_CLAIMABLE_BALANCE:
///         ClaimClaimableBalanceResult claimClaimableBalanceResult;
///     case BEGIN_SPONSORING_FUTURE_RESERVES:
///         BeginSponsoringFutureReservesResult beginSponsoringFutureReservesResult;
///     case END_SPONSORING_FUTURE_RESERVES:
///         EndSponsoringFutureReservesResult endSponsoringFutureReservesResult;
///     case REVOKE_SPONSORSHIP:
///         RevokeSponsorshipResult revokeSponsorshipResult;
///     case CLAWBACK:
///         ClawbackResult clawbackResult;
///     case CLAWBACK_CLAIMABLE_BALANCE:
///         ClawbackClaimableBalanceResult clawbackClaimableBalanceResult;
///     case SET_TRUST_LINE_FLAGS:
///         SetTrustLineFlagsResult setTrustLineFlagsResult;
///     case LIQUIDITY_POOL_DEPOSIT:
///         LiquidityPoolDepositResult liquidityPoolDepositResult;
///     case LIQUIDITY_POOL_WITHDRAW:
///         LiquidityPoolWithdrawResult liquidityPoolWithdrawResult;
///     case INVOKE_HOST_FUNCTION:
///         InvokeHostFunctionResult invokeHostFunctionResult;
///     case EXTEND_FOOTPRINT_TTL:
///         ExtendFootprintTTLResult extendFootprintTTLResult;
///     case RESTORE_FOOTPRINT:
///         RestoreFootprintResult restoreFootprintResult;
///     }
/// ```
///
pub const OperationResultTr = union(enum) {
    CreateAccount: CreateAccountResult,
    Payment: PaymentResult,
    PathPaymentStrictReceive: PathPaymentStrictReceiveResult,
    ManageSellOffer: ManageSellOfferResult,
    CreatePassiveSellOffer: ManageSellOfferResult,
    SetOptions: SetOptionsResult,
    ChangeTrust: ChangeTrustResult,
    AllowTrust: AllowTrustResult,
    AccountMerge: AccountMergeResult,
    Inflation: InflationResult,
    ManageData: ManageDataResult,
    BumpSequence: BumpSequenceResult,
    ManageBuyOffer: ManageBuyOfferResult,
    PathPaymentStrictSend: PathPaymentStrictSendResult,
    CreateClaimableBalance: CreateClaimableBalanceResult,
    ClaimClaimableBalance: ClaimClaimableBalanceResult,
    BeginSponsoringFutureReserves: BeginSponsoringFutureReservesResult,
    EndSponsoringFutureReserves: EndSponsoringFutureReservesResult,
    RevokeSponsorship: RevokeSponsorshipResult,
    Clawback: ClawbackResult,
    ClawbackClaimableBalance: ClawbackClaimableBalanceResult,
    SetTrustLineFlags: SetTrustLineFlagsResult,
    LiquidityPoolDeposit: LiquidityPoolDepositResult,
    LiquidityPoolWithdraw: LiquidityPoolWithdrawResult,
    InvokeHostFunction: InvokeHostFunctionResult,
    ExtendFootprintTtl: ExtendFootprintTtlResult,
    RestoreFootprint: RestoreFootprintResult,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !OperationResultTr {
        const disc = try OperationType.xdrDecode(allocator, reader);
        return switch (disc) {
            .CreateAccount => OperationResultTr{ .CreateAccount = try xdrDecodeGeneric(CreateAccountResult, allocator, reader) },
            .Payment => OperationResultTr{ .Payment = try xdrDecodeGeneric(PaymentResult, allocator, reader) },
            .PathPaymentStrictReceive => OperationResultTr{ .PathPaymentStrictReceive = try xdrDecodeGeneric(PathPaymentStrictReceiveResult, allocator, reader) },
            .ManageSellOffer => OperationResultTr{ .ManageSellOffer = try xdrDecodeGeneric(ManageSellOfferResult, allocator, reader) },
            .CreatePassiveSellOffer => OperationResultTr{ .CreatePassiveSellOffer = try xdrDecodeGeneric(ManageSellOfferResult, allocator, reader) },
            .SetOptions => OperationResultTr{ .SetOptions = try xdrDecodeGeneric(SetOptionsResult, allocator, reader) },
            .ChangeTrust => OperationResultTr{ .ChangeTrust = try xdrDecodeGeneric(ChangeTrustResult, allocator, reader) },
            .AllowTrust => OperationResultTr{ .AllowTrust = try xdrDecodeGeneric(AllowTrustResult, allocator, reader) },
            .AccountMerge => OperationResultTr{ .AccountMerge = try xdrDecodeGeneric(AccountMergeResult, allocator, reader) },
            .Inflation => OperationResultTr{ .Inflation = try xdrDecodeGeneric(InflationResult, allocator, reader) },
            .ManageData => OperationResultTr{ .ManageData = try xdrDecodeGeneric(ManageDataResult, allocator, reader) },
            .BumpSequence => OperationResultTr{ .BumpSequence = try xdrDecodeGeneric(BumpSequenceResult, allocator, reader) },
            .ManageBuyOffer => OperationResultTr{ .ManageBuyOffer = try xdrDecodeGeneric(ManageBuyOfferResult, allocator, reader) },
            .PathPaymentStrictSend => OperationResultTr{ .PathPaymentStrictSend = try xdrDecodeGeneric(PathPaymentStrictSendResult, allocator, reader) },
            .CreateClaimableBalance => OperationResultTr{ .CreateClaimableBalance = try xdrDecodeGeneric(CreateClaimableBalanceResult, allocator, reader) },
            .ClaimClaimableBalance => OperationResultTr{ .ClaimClaimableBalance = try xdrDecodeGeneric(ClaimClaimableBalanceResult, allocator, reader) },
            .BeginSponsoringFutureReserves => OperationResultTr{ .BeginSponsoringFutureReserves = try xdrDecodeGeneric(BeginSponsoringFutureReservesResult, allocator, reader) },
            .EndSponsoringFutureReserves => OperationResultTr{ .EndSponsoringFutureReserves = try xdrDecodeGeneric(EndSponsoringFutureReservesResult, allocator, reader) },
            .RevokeSponsorship => OperationResultTr{ .RevokeSponsorship = try xdrDecodeGeneric(RevokeSponsorshipResult, allocator, reader) },
            .Clawback => OperationResultTr{ .Clawback = try xdrDecodeGeneric(ClawbackResult, allocator, reader) },
            .ClawbackClaimableBalance => OperationResultTr{ .ClawbackClaimableBalance = try xdrDecodeGeneric(ClawbackClaimableBalanceResult, allocator, reader) },
            .SetTrustLineFlags => OperationResultTr{ .SetTrustLineFlags = try xdrDecodeGeneric(SetTrustLineFlagsResult, allocator, reader) },
            .LiquidityPoolDeposit => OperationResultTr{ .LiquidityPoolDeposit = try xdrDecodeGeneric(LiquidityPoolDepositResult, allocator, reader) },
            .LiquidityPoolWithdraw => OperationResultTr{ .LiquidityPoolWithdraw = try xdrDecodeGeneric(LiquidityPoolWithdrawResult, allocator, reader) },
            .InvokeHostFunction => OperationResultTr{ .InvokeHostFunction = try xdrDecodeGeneric(InvokeHostFunctionResult, allocator, reader) },
            .ExtendFootprintTtl => OperationResultTr{ .ExtendFootprintTtl = try xdrDecodeGeneric(ExtendFootprintTtlResult, allocator, reader) },
            .RestoreFootprint => OperationResultTr{ .RestoreFootprint = try xdrDecodeGeneric(RestoreFootprintResult, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: OperationResultTr, writer: anytype) !void {
        const disc: OperationType = switch (self) {
            .CreateAccount => .CreateAccount,
            .Payment => .Payment,
            .PathPaymentStrictReceive => .PathPaymentStrictReceive,
            .ManageSellOffer => .ManageSellOffer,
            .CreatePassiveSellOffer => .CreatePassiveSellOffer,
            .SetOptions => .SetOptions,
            .ChangeTrust => .ChangeTrust,
            .AllowTrust => .AllowTrust,
            .AccountMerge => .AccountMerge,
            .Inflation => .Inflation,
            .ManageData => .ManageData,
            .BumpSequence => .BumpSequence,
            .ManageBuyOffer => .ManageBuyOffer,
            .PathPaymentStrictSend => .PathPaymentStrictSend,
            .CreateClaimableBalance => .CreateClaimableBalance,
            .ClaimClaimableBalance => .ClaimClaimableBalance,
            .BeginSponsoringFutureReserves => .BeginSponsoringFutureReserves,
            .EndSponsoringFutureReserves => .EndSponsoringFutureReserves,
            .RevokeSponsorship => .RevokeSponsorship,
            .Clawback => .Clawback,
            .ClawbackClaimableBalance => .ClawbackClaimableBalance,
            .SetTrustLineFlags => .SetTrustLineFlags,
            .LiquidityPoolDeposit => .LiquidityPoolDeposit,
            .LiquidityPoolWithdraw => .LiquidityPoolWithdraw,
            .InvokeHostFunction => .InvokeHostFunction,
            .ExtendFootprintTtl => .ExtendFootprintTtl,
            .RestoreFootprint => .RestoreFootprint,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .CreateAccount => |v| try xdrEncodeGeneric(CreateAccountResult, writer, v),
            .Payment => |v| try xdrEncodeGeneric(PaymentResult, writer, v),
            .PathPaymentStrictReceive => |v| try xdrEncodeGeneric(PathPaymentStrictReceiveResult, writer, v),
            .ManageSellOffer => |v| try xdrEncodeGeneric(ManageSellOfferResult, writer, v),
            .CreatePassiveSellOffer => |v| try xdrEncodeGeneric(ManageSellOfferResult, writer, v),
            .SetOptions => |v| try xdrEncodeGeneric(SetOptionsResult, writer, v),
            .ChangeTrust => |v| try xdrEncodeGeneric(ChangeTrustResult, writer, v),
            .AllowTrust => |v| try xdrEncodeGeneric(AllowTrustResult, writer, v),
            .AccountMerge => |v| try xdrEncodeGeneric(AccountMergeResult, writer, v),
            .Inflation => |v| try xdrEncodeGeneric(InflationResult, writer, v),
            .ManageData => |v| try xdrEncodeGeneric(ManageDataResult, writer, v),
            .BumpSequence => |v| try xdrEncodeGeneric(BumpSequenceResult, writer, v),
            .ManageBuyOffer => |v| try xdrEncodeGeneric(ManageBuyOfferResult, writer, v),
            .PathPaymentStrictSend => |v| try xdrEncodeGeneric(PathPaymentStrictSendResult, writer, v),
            .CreateClaimableBalance => |v| try xdrEncodeGeneric(CreateClaimableBalanceResult, writer, v),
            .ClaimClaimableBalance => |v| try xdrEncodeGeneric(ClaimClaimableBalanceResult, writer, v),
            .BeginSponsoringFutureReserves => |v| try xdrEncodeGeneric(BeginSponsoringFutureReservesResult, writer, v),
            .EndSponsoringFutureReserves => |v| try xdrEncodeGeneric(EndSponsoringFutureReservesResult, writer, v),
            .RevokeSponsorship => |v| try xdrEncodeGeneric(RevokeSponsorshipResult, writer, v),
            .Clawback => |v| try xdrEncodeGeneric(ClawbackResult, writer, v),
            .ClawbackClaimableBalance => |v| try xdrEncodeGeneric(ClawbackClaimableBalanceResult, writer, v),
            .SetTrustLineFlags => |v| try xdrEncodeGeneric(SetTrustLineFlagsResult, writer, v),
            .LiquidityPoolDeposit => |v| try xdrEncodeGeneric(LiquidityPoolDepositResult, writer, v),
            .LiquidityPoolWithdraw => |v| try xdrEncodeGeneric(LiquidityPoolWithdrawResult, writer, v),
            .InvokeHostFunction => |v| try xdrEncodeGeneric(InvokeHostFunctionResult, writer, v),
            .ExtendFootprintTtl => |v| try xdrEncodeGeneric(ExtendFootprintTtlResult, writer, v),
            .RestoreFootprint => |v| try xdrEncodeGeneric(RestoreFootprintResult, writer, v),
        }
    }
};

/// OperationResult is an XDR Union defined as:
///
/// ```text
/// union OperationResult switch (OperationResultCode code)
/// {
/// case opINNER:
///     union switch (OperationType type)
///     {
///     case CREATE_ACCOUNT:
///         CreateAccountResult createAccountResult;
///     case PAYMENT:
///         PaymentResult paymentResult;
///     case PATH_PAYMENT_STRICT_RECEIVE:
///         PathPaymentStrictReceiveResult pathPaymentStrictReceiveResult;
///     case MANAGE_SELL_OFFER:
///         ManageSellOfferResult manageSellOfferResult;
///     case CREATE_PASSIVE_SELL_OFFER:
///         ManageSellOfferResult createPassiveSellOfferResult;
///     case SET_OPTIONS:
///         SetOptionsResult setOptionsResult;
///     case CHANGE_TRUST:
///         ChangeTrustResult changeTrustResult;
///     case ALLOW_TRUST:
///         AllowTrustResult allowTrustResult;
///     case ACCOUNT_MERGE:
///         AccountMergeResult accountMergeResult;
///     case INFLATION:
///         InflationResult inflationResult;
///     case MANAGE_DATA:
///         ManageDataResult manageDataResult;
///     case BUMP_SEQUENCE:
///         BumpSequenceResult bumpSeqResult;
///     case MANAGE_BUY_OFFER:
///         ManageBuyOfferResult manageBuyOfferResult;
///     case PATH_PAYMENT_STRICT_SEND:
///         PathPaymentStrictSendResult pathPaymentStrictSendResult;
///     case CREATE_CLAIMABLE_BALANCE:
///         CreateClaimableBalanceResult createClaimableBalanceResult;
///     case CLAIM_CLAIMABLE_BALANCE:
///         ClaimClaimableBalanceResult claimClaimableBalanceResult;
///     case BEGIN_SPONSORING_FUTURE_RESERVES:
///         BeginSponsoringFutureReservesResult beginSponsoringFutureReservesResult;
///     case END_SPONSORING_FUTURE_RESERVES:
///         EndSponsoringFutureReservesResult endSponsoringFutureReservesResult;
///     case REVOKE_SPONSORSHIP:
///         RevokeSponsorshipResult revokeSponsorshipResult;
///     case CLAWBACK:
///         ClawbackResult clawbackResult;
///     case CLAWBACK_CLAIMABLE_BALANCE:
///         ClawbackClaimableBalanceResult clawbackClaimableBalanceResult;
///     case SET_TRUST_LINE_FLAGS:
///         SetTrustLineFlagsResult setTrustLineFlagsResult;
///     case LIQUIDITY_POOL_DEPOSIT:
///         LiquidityPoolDepositResult liquidityPoolDepositResult;
///     case LIQUIDITY_POOL_WITHDRAW:
///         LiquidityPoolWithdrawResult liquidityPoolWithdrawResult;
///     case INVOKE_HOST_FUNCTION:
///         InvokeHostFunctionResult invokeHostFunctionResult;
///     case EXTEND_FOOTPRINT_TTL:
///         ExtendFootprintTTLResult extendFootprintTTLResult;
///     case RESTORE_FOOTPRINT:
///         RestoreFootprintResult restoreFootprintResult;
///     }
///     tr;
/// case opBAD_AUTH:
/// case opNO_ACCOUNT:
/// case opNOT_SUPPORTED:
/// case opTOO_MANY_SUBENTRIES:
/// case opEXCEEDED_WORK_LIMIT:
/// case opTOO_MANY_SPONSORING:
///     void;
/// };
/// ```
///
pub const OperationResult = union(enum) {
    OpInner: OperationResultTr,
    OpBadAuth,
    OpNoAccount,
    OpNotSupported,
    OpTooManySubentries,
    OpExceededWorkLimit,
    OpTooManySponsoring,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !OperationResult {
        const disc = try OperationResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .OpInner => OperationResult{ .OpInner = try xdrDecodeGeneric(OperationResultTr, allocator, reader) },
            .OpBadAuth => OperationResult{ .OpBadAuth = {} },
            .OpNoAccount => OperationResult{ .OpNoAccount = {} },
            .OpNotSupported => OperationResult{ .OpNotSupported = {} },
            .OpTooManySubentries => OperationResult{ .OpTooManySubentries = {} },
            .OpExceededWorkLimit => OperationResult{ .OpExceededWorkLimit = {} },
            .OpTooManySponsoring => OperationResult{ .OpTooManySponsoring = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: OperationResult, writer: anytype) !void {
        const disc: OperationResultCode = switch (self) {
            .OpInner => .OpInner,
            .OpBadAuth => .OpBadAuth,
            .OpNoAccount => .OpNoAccount,
            .OpNotSupported => .OpNotSupported,
            .OpTooManySubentries => .OpTooManySubentries,
            .OpExceededWorkLimit => .OpExceededWorkLimit,
            .OpTooManySponsoring => .OpTooManySponsoring,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .OpInner => |v| try xdrEncodeGeneric(OperationResultTr, writer, v),
            .OpBadAuth => {},
            .OpNoAccount => {},
            .OpNotSupported => {},
            .OpTooManySubentries => {},
            .OpExceededWorkLimit => {},
            .OpTooManySponsoring => {},
        }
    }
};

/// TransactionResultCode is an XDR Enum defined as:
///
/// ```text
/// enum TransactionResultCode
/// {
///     txFEE_BUMP_INNER_SUCCESS = 1, // fee bump inner transaction succeeded
///     txSUCCESS = 0,                // all operations succeeded
///
///     txFAILED = -1, // one of the operations failed (none were applied)
///
///     txTOO_EARLY = -2,         // ledger closeTime before minTime
///     txTOO_LATE = -3,          // ledger closeTime after maxTime
///     txMISSING_OPERATION = -4, // no operation was specified
///     txBAD_SEQ = -5,           // sequence number does not match source account
///
///     txBAD_AUTH = -6,             // too few valid signatures / wrong network
///     txINSUFFICIENT_BALANCE = -7, // fee would bring account below reserve
///     txNO_ACCOUNT = -8,           // source account not found
///     txINSUFFICIENT_FEE = -9,     // fee is too small
///     txBAD_AUTH_EXTRA = -10,      // unused signatures attached to transaction
///     txINTERNAL_ERROR = -11,      // an unknown error occurred
///
///     txNOT_SUPPORTED = -12,          // transaction type not supported
///     txFEE_BUMP_INNER_FAILED = -13,  // fee bump inner transaction failed
///     txBAD_SPONSORSHIP = -14,        // sponsorship not confirmed
///     txBAD_MIN_SEQ_AGE_OR_GAP = -15, // minSeqAge or minSeqLedgerGap conditions not met
///     txMALFORMED = -16,              // precondition is invalid
///     txSOROBAN_INVALID = -17         // soroban-specific preconditions were not met
/// };
/// ```
///
pub const TransactionResultCode = enum(i32) {
    TxFeeBumpInnerSuccess = 1,
    TxSuccess = 0,
    TxFailed = -1,
    TxTooEarly = -2,
    TxTooLate = -3,
    TxMissingOperation = -4,
    TxBadSeq = -5,
    TxBadAuth = -6,
    TxInsufficientBalance = -7,
    TxNoAccount = -8,
    TxInsufficientFee = -9,
    TxBadAuthExtra = -10,
    TxInternalError = -11,
    TxNotSupported = -12,
    TxFeeBumpInnerFailed = -13,
    TxBadSponsorship = -14,
    TxBadMinSeqAgeOrGap = -15,
    TxMalformed = -16,
    TxSorobanInvalid = -17,
    _,

    pub const variants = [_]TransactionResultCode{
        .TxFeeBumpInnerSuccess,
        .TxSuccess,
        .TxFailed,
        .TxTooEarly,
        .TxTooLate,
        .TxMissingOperation,
        .TxBadSeq,
        .TxBadAuth,
        .TxInsufficientBalance,
        .TxNoAccount,
        .TxInsufficientFee,
        .TxBadAuthExtra,
        .TxInternalError,
        .TxNotSupported,
        .TxFeeBumpInnerFailed,
        .TxBadSponsorship,
        .TxBadMinSeqAgeOrGap,
        .TxMalformed,
        .TxSorobanInvalid,
    };

    pub fn name(self: TransactionResultCode) []const u8 {
        return switch (self) {
            .TxFeeBumpInnerSuccess => "TxFeeBumpInnerSuccess",
            .TxSuccess => "TxSuccess",
            .TxFailed => "TxFailed",
            .TxTooEarly => "TxTooEarly",
            .TxTooLate => "TxTooLate",
            .TxMissingOperation => "TxMissingOperation",
            .TxBadSeq => "TxBadSeq",
            .TxBadAuth => "TxBadAuth",
            .TxInsufficientBalance => "TxInsufficientBalance",
            .TxNoAccount => "TxNoAccount",
            .TxInsufficientFee => "TxInsufficientFee",
            .TxBadAuthExtra => "TxBadAuthExtra",
            .TxInternalError => "TxInternalError",
            .TxNotSupported => "TxNotSupported",
            .TxFeeBumpInnerFailed => "TxFeeBumpInnerFailed",
            .TxBadSponsorship => "TxBadSponsorship",
            .TxBadMinSeqAgeOrGap => "TxBadMinSeqAgeOrGap",
            .TxMalformed => "TxMalformed",
            .TxSorobanInvalid => "TxSorobanInvalid",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionResultCode {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: TransactionResultCode, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// InnerTransactionResultResult is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (TransactionResultCode code)
///     {
///     // txFEE_BUMP_INNER_SUCCESS is not included
///     case txSUCCESS:
///     case txFAILED:
///         OperationResult results<>;
///     case txTOO_EARLY:
///     case txTOO_LATE:
///     case txMISSING_OPERATION:
///     case txBAD_SEQ:
///     case txBAD_AUTH:
///     case txINSUFFICIENT_BALANCE:
///     case txNO_ACCOUNT:
///     case txINSUFFICIENT_FEE:
///     case txBAD_AUTH_EXTRA:
///     case txINTERNAL_ERROR:
///     case txNOT_SUPPORTED:
///     // txFEE_BUMP_INNER_FAILED is not included
///     case txBAD_SPONSORSHIP:
///     case txBAD_MIN_SEQ_AGE_OR_GAP:
///     case txMALFORMED:
///     case txSOROBAN_INVALID:
///         void;
///     }
/// ```
///
pub const InnerTransactionResultResult = union(enum) {
    TxSuccess: []OperationResult,
    TxFailed: []OperationResult,
    TxTooEarly,
    TxTooLate,
    TxMissingOperation,
    TxBadSeq,
    TxBadAuth,
    TxInsufficientBalance,
    TxNoAccount,
    TxInsufficientFee,
    TxBadAuthExtra,
    TxInternalError,
    TxNotSupported,
    TxBadSponsorship,
    TxBadMinSeqAgeOrGap,
    TxMalformed,
    TxSorobanInvalid,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !InnerTransactionResultResult {
        const disc = try TransactionResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .TxSuccess => InnerTransactionResultResult{ .TxSuccess = try xdrDecodeGeneric([]OperationResult, allocator, reader) },
            .TxFailed => InnerTransactionResultResult{ .TxFailed = try xdrDecodeGeneric([]OperationResult, allocator, reader) },
            .TxTooEarly => InnerTransactionResultResult{ .TxTooEarly = {} },
            .TxTooLate => InnerTransactionResultResult{ .TxTooLate = {} },
            .TxMissingOperation => InnerTransactionResultResult{ .TxMissingOperation = {} },
            .TxBadSeq => InnerTransactionResultResult{ .TxBadSeq = {} },
            .TxBadAuth => InnerTransactionResultResult{ .TxBadAuth = {} },
            .TxInsufficientBalance => InnerTransactionResultResult{ .TxInsufficientBalance = {} },
            .TxNoAccount => InnerTransactionResultResult{ .TxNoAccount = {} },
            .TxInsufficientFee => InnerTransactionResultResult{ .TxInsufficientFee = {} },
            .TxBadAuthExtra => InnerTransactionResultResult{ .TxBadAuthExtra = {} },
            .TxInternalError => InnerTransactionResultResult{ .TxInternalError = {} },
            .TxNotSupported => InnerTransactionResultResult{ .TxNotSupported = {} },
            .TxBadSponsorship => InnerTransactionResultResult{ .TxBadSponsorship = {} },
            .TxBadMinSeqAgeOrGap => InnerTransactionResultResult{ .TxBadMinSeqAgeOrGap = {} },
            .TxMalformed => InnerTransactionResultResult{ .TxMalformed = {} },
            .TxSorobanInvalid => InnerTransactionResultResult{ .TxSorobanInvalid = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: InnerTransactionResultResult, writer: anytype) !void {
        const disc: TransactionResultCode = switch (self) {
            .TxSuccess => .TxSuccess,
            .TxFailed => .TxFailed,
            .TxTooEarly => .TxTooEarly,
            .TxTooLate => .TxTooLate,
            .TxMissingOperation => .TxMissingOperation,
            .TxBadSeq => .TxBadSeq,
            .TxBadAuth => .TxBadAuth,
            .TxInsufficientBalance => .TxInsufficientBalance,
            .TxNoAccount => .TxNoAccount,
            .TxInsufficientFee => .TxInsufficientFee,
            .TxBadAuthExtra => .TxBadAuthExtra,
            .TxInternalError => .TxInternalError,
            .TxNotSupported => .TxNotSupported,
            .TxBadSponsorship => .TxBadSponsorship,
            .TxBadMinSeqAgeOrGap => .TxBadMinSeqAgeOrGap,
            .TxMalformed => .TxMalformed,
            .TxSorobanInvalid => .TxSorobanInvalid,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .TxSuccess => |v| try xdrEncodeGeneric([]OperationResult, writer, v),
            .TxFailed => |v| try xdrEncodeGeneric([]OperationResult, writer, v),
            .TxTooEarly => {},
            .TxTooLate => {},
            .TxMissingOperation => {},
            .TxBadSeq => {},
            .TxBadAuth => {},
            .TxInsufficientBalance => {},
            .TxNoAccount => {},
            .TxInsufficientFee => {},
            .TxBadAuthExtra => {},
            .TxInternalError => {},
            .TxNotSupported => {},
            .TxBadSponsorship => {},
            .TxBadMinSeqAgeOrGap => {},
            .TxMalformed => {},
            .TxSorobanInvalid => {},
        }
    }
};

/// InnerTransactionResultExt is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (int v)
///     {
///     case 0:
///         void;
///     }
/// ```
///
pub const InnerTransactionResultExt = union(enum) {
    V0,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !InnerTransactionResultExt {
        _ = allocator;
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => InnerTransactionResultExt{ .V0 = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: InnerTransactionResultExt, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
        }
    }
};

/// InnerTransactionResult is an XDR Struct defined as:
///
/// ```text
/// struct InnerTransactionResult
/// {
///     // Always 0. Here for binary compatibility.
///     int64 feeCharged;
///
///     union switch (TransactionResultCode code)
///     {
///     // txFEE_BUMP_INNER_SUCCESS is not included
///     case txSUCCESS:
///     case txFAILED:
///         OperationResult results<>;
///     case txTOO_EARLY:
///     case txTOO_LATE:
///     case txMISSING_OPERATION:
///     case txBAD_SEQ:
///     case txBAD_AUTH:
///     case txINSUFFICIENT_BALANCE:
///     case txNO_ACCOUNT:
///     case txINSUFFICIENT_FEE:
///     case txBAD_AUTH_EXTRA:
///     case txINTERNAL_ERROR:
///     case txNOT_SUPPORTED:
///     // txFEE_BUMP_INNER_FAILED is not included
///     case txBAD_SPONSORSHIP:
///     case txBAD_MIN_SEQ_AGE_OR_GAP:
///     case txMALFORMED:
///     case txSOROBAN_INVALID:
///         void;
///     }
///     result;
///
///     // reserved for future use
///     union switch (int v)
///     {
///     case 0:
///         void;
///     }
///     ext;
/// };
/// ```
///
pub const InnerTransactionResult = struct {
    fee_charged: i64,
    result: InnerTransactionResultResult,
    ext: InnerTransactionResultExt,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !InnerTransactionResult {
        return InnerTransactionResult{
            .fee_charged = try xdrDecodeGeneric(i64, allocator, reader),
            .result = try xdrDecodeGeneric(InnerTransactionResultResult, allocator, reader),
            .ext = try xdrDecodeGeneric(InnerTransactionResultExt, allocator, reader),
        };
    }

    pub fn xdrEncode(self: InnerTransactionResult, writer: anytype) !void {
        try xdrEncodeGeneric(i64, writer, self.fee_charged);
        try xdrEncodeGeneric(InnerTransactionResultResult, writer, self.result);
        try xdrEncodeGeneric(InnerTransactionResultExt, writer, self.ext);
    }
};

/// InnerTransactionResultPair is an XDR Struct defined as:
///
/// ```text
/// struct InnerTransactionResultPair
/// {
///     Hash transactionHash;          // hash of the inner transaction
///     InnerTransactionResult result; // result for the inner transaction
/// };
/// ```
///
pub const InnerTransactionResultPair = struct {
    transaction_hash: Hash,
    result: InnerTransactionResult,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !InnerTransactionResultPair {
        return InnerTransactionResultPair{
            .transaction_hash = try xdrDecodeGeneric(Hash, allocator, reader),
            .result = try xdrDecodeGeneric(InnerTransactionResult, allocator, reader),
        };
    }

    pub fn xdrEncode(self: InnerTransactionResultPair, writer: anytype) !void {
        try xdrEncodeGeneric(Hash, writer, self.transaction_hash);
        try xdrEncodeGeneric(InnerTransactionResult, writer, self.result);
    }
};

/// TransactionResultResult is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (TransactionResultCode code)
///     {
///     case txFEE_BUMP_INNER_SUCCESS:
///     case txFEE_BUMP_INNER_FAILED:
///         InnerTransactionResultPair innerResultPair;
///     case txSUCCESS:
///     case txFAILED:
///         OperationResult results<>;
///     case txTOO_EARLY:
///     case txTOO_LATE:
///     case txMISSING_OPERATION:
///     case txBAD_SEQ:
///     case txBAD_AUTH:
///     case txINSUFFICIENT_BALANCE:
///     case txNO_ACCOUNT:
///     case txINSUFFICIENT_FEE:
///     case txBAD_AUTH_EXTRA:
///     case txINTERNAL_ERROR:
///     case txNOT_SUPPORTED:
///     // case txFEE_BUMP_INNER_FAILED: handled above
///     case txBAD_SPONSORSHIP:
///     case txBAD_MIN_SEQ_AGE_OR_GAP:
///     case txMALFORMED:
///     case txSOROBAN_INVALID:
///         void;
///     }
/// ```
///
pub const TransactionResultResult = union(enum) {
    TxFeeBumpInnerSuccess: InnerTransactionResultPair,
    TxFeeBumpInnerFailed: InnerTransactionResultPair,
    TxSuccess: []OperationResult,
    TxFailed: []OperationResult,
    TxTooEarly,
    TxTooLate,
    TxMissingOperation,
    TxBadSeq,
    TxBadAuth,
    TxInsufficientBalance,
    TxNoAccount,
    TxInsufficientFee,
    TxBadAuthExtra,
    TxInternalError,
    TxNotSupported,
    TxBadSponsorship,
    TxBadMinSeqAgeOrGap,
    TxMalformed,
    TxSorobanInvalid,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionResultResult {
        const disc = try TransactionResultCode.xdrDecode(allocator, reader);
        return switch (disc) {
            .TxFeeBumpInnerSuccess => TransactionResultResult{ .TxFeeBumpInnerSuccess = try xdrDecodeGeneric(InnerTransactionResultPair, allocator, reader) },
            .TxFeeBumpInnerFailed => TransactionResultResult{ .TxFeeBumpInnerFailed = try xdrDecodeGeneric(InnerTransactionResultPair, allocator, reader) },
            .TxSuccess => TransactionResultResult{ .TxSuccess = try xdrDecodeGeneric([]OperationResult, allocator, reader) },
            .TxFailed => TransactionResultResult{ .TxFailed = try xdrDecodeGeneric([]OperationResult, allocator, reader) },
            .TxTooEarly => TransactionResultResult{ .TxTooEarly = {} },
            .TxTooLate => TransactionResultResult{ .TxTooLate = {} },
            .TxMissingOperation => TransactionResultResult{ .TxMissingOperation = {} },
            .TxBadSeq => TransactionResultResult{ .TxBadSeq = {} },
            .TxBadAuth => TransactionResultResult{ .TxBadAuth = {} },
            .TxInsufficientBalance => TransactionResultResult{ .TxInsufficientBalance = {} },
            .TxNoAccount => TransactionResultResult{ .TxNoAccount = {} },
            .TxInsufficientFee => TransactionResultResult{ .TxInsufficientFee = {} },
            .TxBadAuthExtra => TransactionResultResult{ .TxBadAuthExtra = {} },
            .TxInternalError => TransactionResultResult{ .TxInternalError = {} },
            .TxNotSupported => TransactionResultResult{ .TxNotSupported = {} },
            .TxBadSponsorship => TransactionResultResult{ .TxBadSponsorship = {} },
            .TxBadMinSeqAgeOrGap => TransactionResultResult{ .TxBadMinSeqAgeOrGap = {} },
            .TxMalformed => TransactionResultResult{ .TxMalformed = {} },
            .TxSorobanInvalid => TransactionResultResult{ .TxSorobanInvalid = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: TransactionResultResult, writer: anytype) !void {
        const disc: TransactionResultCode = switch (self) {
            .TxFeeBumpInnerSuccess => .TxFeeBumpInnerSuccess,
            .TxFeeBumpInnerFailed => .TxFeeBumpInnerFailed,
            .TxSuccess => .TxSuccess,
            .TxFailed => .TxFailed,
            .TxTooEarly => .TxTooEarly,
            .TxTooLate => .TxTooLate,
            .TxMissingOperation => .TxMissingOperation,
            .TxBadSeq => .TxBadSeq,
            .TxBadAuth => .TxBadAuth,
            .TxInsufficientBalance => .TxInsufficientBalance,
            .TxNoAccount => .TxNoAccount,
            .TxInsufficientFee => .TxInsufficientFee,
            .TxBadAuthExtra => .TxBadAuthExtra,
            .TxInternalError => .TxInternalError,
            .TxNotSupported => .TxNotSupported,
            .TxBadSponsorship => .TxBadSponsorship,
            .TxBadMinSeqAgeOrGap => .TxBadMinSeqAgeOrGap,
            .TxMalformed => .TxMalformed,
            .TxSorobanInvalid => .TxSorobanInvalid,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .TxFeeBumpInnerSuccess => |v| try xdrEncodeGeneric(InnerTransactionResultPair, writer, v),
            .TxFeeBumpInnerFailed => |v| try xdrEncodeGeneric(InnerTransactionResultPair, writer, v),
            .TxSuccess => |v| try xdrEncodeGeneric([]OperationResult, writer, v),
            .TxFailed => |v| try xdrEncodeGeneric([]OperationResult, writer, v),
            .TxTooEarly => {},
            .TxTooLate => {},
            .TxMissingOperation => {},
            .TxBadSeq => {},
            .TxBadAuth => {},
            .TxInsufficientBalance => {},
            .TxNoAccount => {},
            .TxInsufficientFee => {},
            .TxBadAuthExtra => {},
            .TxInternalError => {},
            .TxNotSupported => {},
            .TxBadSponsorship => {},
            .TxBadMinSeqAgeOrGap => {},
            .TxMalformed => {},
            .TxSorobanInvalid => {},
        }
    }
};

/// TransactionResultExt is an XDR NestedUnion defined as:
///
/// ```text
/// union switch (int v)
///     {
///     case 0:
///         void;
///     }
/// ```
///
pub const TransactionResultExt = union(enum) {
    V0,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionResultExt {
        _ = allocator;
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => TransactionResultExt{ .V0 = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: TransactionResultExt, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
        }
    }
};

/// TransactionResult is an XDR Struct defined as:
///
/// ```text
/// struct TransactionResult
/// {
///     int64 feeCharged; // actual fee charged for the transaction
///
///     union switch (TransactionResultCode code)
///     {
///     case txFEE_BUMP_INNER_SUCCESS:
///     case txFEE_BUMP_INNER_FAILED:
///         InnerTransactionResultPair innerResultPair;
///     case txSUCCESS:
///     case txFAILED:
///         OperationResult results<>;
///     case txTOO_EARLY:
///     case txTOO_LATE:
///     case txMISSING_OPERATION:
///     case txBAD_SEQ:
///     case txBAD_AUTH:
///     case txINSUFFICIENT_BALANCE:
///     case txNO_ACCOUNT:
///     case txINSUFFICIENT_FEE:
///     case txBAD_AUTH_EXTRA:
///     case txINTERNAL_ERROR:
///     case txNOT_SUPPORTED:
///     // case txFEE_BUMP_INNER_FAILED: handled above
///     case txBAD_SPONSORSHIP:
///     case txBAD_MIN_SEQ_AGE_OR_GAP:
///     case txMALFORMED:
///     case txSOROBAN_INVALID:
///         void;
///     }
///     result;
///
///     // reserved for future use
///     union switch (int v)
///     {
///     case 0:
///         void;
///     }
///     ext;
/// };
/// ```
///
pub const TransactionResult = struct {
    fee_charged: i64,
    result: TransactionResultResult,
    ext: TransactionResultExt,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TransactionResult {
        return TransactionResult{
            .fee_charged = try xdrDecodeGeneric(i64, allocator, reader),
            .result = try xdrDecodeGeneric(TransactionResultResult, allocator, reader),
            .ext = try xdrDecodeGeneric(TransactionResultExt, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TransactionResult, writer: anytype) !void {
        try xdrEncodeGeneric(i64, writer, self.fee_charged);
        try xdrEncodeGeneric(TransactionResultResult, writer, self.result);
        try xdrEncodeGeneric(TransactionResultExt, writer, self.ext);
    }
};

/// Hash is an XDR Typedef defined as:
///
/// ```text
/// typedef opaque Hash[32];
/// ```
///
pub const Hash = struct {
    value: [32]u8,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !Hash {
        return Hash{
            .value = try xdrDecodeGeneric([32]u8, allocator, reader),
        };
    }

    pub fn xdrEncode(self: Hash, writer: anytype) !void {
        try xdrEncodeGeneric([32]u8, writer, self.value);
    }

    pub fn asSlice(self: *const Hash) []const u8 {
        return &self.value;
    }
};

/// Uint256 is an XDR Typedef defined as:
///
/// ```text
/// typedef opaque uint256[32];
/// ```
///
pub const Uint256 = struct {
    value: [32]u8,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !Uint256 {
        return Uint256{
            .value = try xdrDecodeGeneric([32]u8, allocator, reader),
        };
    }

    pub fn xdrEncode(self: Uint256, writer: anytype) !void {
        try xdrEncodeGeneric([32]u8, writer, self.value);
    }

    pub fn asSlice(self: *const Uint256) []const u8 {
        return &self.value;
    }
};

/// Uint32 is an XDR Typedef defined as:
///
/// ```text
/// typedef unsigned int uint32;
/// ```
///
pub const Uint32 = u32;

/// Int32 is an XDR Typedef defined as:
///
/// ```text
/// typedef int int32;
/// ```
///
pub const Int32 = i32;

/// Uint64 is an XDR Typedef defined as:
///
/// ```text
/// typedef unsigned hyper uint64;
/// ```
///
pub const Uint64 = u64;

/// Int64 is an XDR Typedef defined as:
///
/// ```text
/// typedef hyper int64;
/// ```
///
pub const Int64 = i64;

/// TimePoint is an XDR Typedef defined as:
///
/// ```text
/// typedef uint64 TimePoint;
/// ```
///
pub const TimePoint = struct {
    value: u64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !TimePoint {
        return TimePoint{
            .value = try xdrDecodeGeneric(u64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: TimePoint, writer: anytype) !void {
        try xdrEncodeGeneric(u64, writer, self.value);
    }
};

/// Duration is an XDR Typedef defined as:
///
/// ```text
/// typedef uint64 Duration;
/// ```
///
pub const Duration = struct {
    value: u64,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !Duration {
        return Duration{
            .value = try xdrDecodeGeneric(u64, allocator, reader),
        };
    }

    pub fn xdrEncode(self: Duration, writer: anytype) !void {
        try xdrEncodeGeneric(u64, writer, self.value);
    }
};

/// ExtensionPoint is an XDR Union defined as:
///
/// ```text
/// union ExtensionPoint switch (int v)
/// {
/// case 0:
///     void;
/// };
/// ```
///
pub const ExtensionPoint = union(enum) {
    V0,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ExtensionPoint {
        _ = allocator;
        const disc_value = try reader.readInt(i32, .big);
        return switch (disc_value) {
            0 => ExtensionPoint{ .V0 = {} },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ExtensionPoint, writer: anytype) !void {
        switch (self) {
            .V0 => try writer.writeInt(i32, 0, .big),
        }
    }
};

/// CryptoKeyType is an XDR Enum defined as:
///
/// ```text
/// enum CryptoKeyType
/// {
///     KEY_TYPE_ED25519 = 0,
///     KEY_TYPE_PRE_AUTH_TX = 1,
///     KEY_TYPE_HASH_X = 2,
///     KEY_TYPE_ED25519_SIGNED_PAYLOAD = 3,
///     // MUXED enum values for supported type are derived from the enum values
///     // above by ORing them with 0x100
///     KEY_TYPE_MUXED_ED25519 = 0x100
/// };
/// ```
///
pub const CryptoKeyType = enum(i32) {
    Ed25519 = 0,
    PreAuthTx = 1,
    HashX = 2,
    Ed25519SignedPayload = 3,
    MuxedEd25519 = 256,
    _,

    pub const variants = [_]CryptoKeyType{
        .Ed25519,
        .PreAuthTx,
        .HashX,
        .Ed25519SignedPayload,
        .MuxedEd25519,
    };

    pub fn name(self: CryptoKeyType) []const u8 {
        return switch (self) {
            .Ed25519 => "Ed25519",
            .PreAuthTx => "PreAuthTx",
            .HashX => "HashX",
            .Ed25519SignedPayload => "Ed25519SignedPayload",
            .MuxedEd25519 => "MuxedEd25519",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !CryptoKeyType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: CryptoKeyType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// PublicKeyType is an XDR Enum defined as:
///
/// ```text
/// enum PublicKeyType
/// {
///     PUBLIC_KEY_TYPE_ED25519 = KEY_TYPE_ED25519
/// };
/// ```
///
pub const PublicKeyType = enum(i32) {
    PublicKeyTypeEd25519 = 0,
    _,

    pub const variants = [_]PublicKeyType{
        .PublicKeyTypeEd25519,
    };

    pub fn name(self: PublicKeyType) []const u8 {
        return switch (self) {
            .PublicKeyTypeEd25519 => "PublicKeyTypeEd25519",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !PublicKeyType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: PublicKeyType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// SignerKeyType is an XDR Enum defined as:
///
/// ```text
/// enum SignerKeyType
/// {
///     SIGNER_KEY_TYPE_ED25519 = KEY_TYPE_ED25519,
///     SIGNER_KEY_TYPE_PRE_AUTH_TX = KEY_TYPE_PRE_AUTH_TX,
///     SIGNER_KEY_TYPE_HASH_X = KEY_TYPE_HASH_X,
///     SIGNER_KEY_TYPE_ED25519_SIGNED_PAYLOAD = KEY_TYPE_ED25519_SIGNED_PAYLOAD
/// };
/// ```
///
pub const SignerKeyType = enum(i32) {
    Ed25519 = 0,
    PreAuthTx = 1,
    HashX = 2,
    Ed25519SignedPayload = 3,
    _,

    pub const variants = [_]SignerKeyType{
        .Ed25519,
        .PreAuthTx,
        .HashX,
        .Ed25519SignedPayload,
    };

    pub fn name(self: SignerKeyType) []const u8 {
        return switch (self) {
            .Ed25519 => "Ed25519",
            .PreAuthTx => "PreAuthTx",
            .HashX => "HashX",
            .Ed25519SignedPayload => "Ed25519SignedPayload",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SignerKeyType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: SignerKeyType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// PublicKey is an XDR Union defined as:
///
/// ```text
/// union PublicKey switch (PublicKeyType type)
/// {
/// case PUBLIC_KEY_TYPE_ED25519:
///     uint256 ed25519;
/// };
/// ```
///
pub const PublicKey = union(enum) {
    PublicKeyTypeEd25519: Uint256,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !PublicKey {
        const disc = try PublicKeyType.xdrDecode(allocator, reader);
        return switch (disc) {
            .PublicKeyTypeEd25519 => PublicKey{ .PublicKeyTypeEd25519 = try xdrDecodeGeneric(Uint256, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: PublicKey, writer: anytype) !void {
        const disc: PublicKeyType = switch (self) {
            .PublicKeyTypeEd25519 => .PublicKeyTypeEd25519,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .PublicKeyTypeEd25519 => |v| try xdrEncodeGeneric(Uint256, writer, v),
        }
    }
};

/// SignerKeyEd25519SignedPayload is an XDR NestedStruct defined as:
///
/// ```text
/// struct
///     {
///         /* Public key that must sign the payload. */
///         uint256 ed25519;
///         /* Payload to be raw signed by ed25519. */
///         opaque payload<64>;
///     }
/// ```
///
pub const SignerKeyEd25519SignedPayload = struct {
    ed25519: Uint256,
    payload: BoundedArray(u8, 64),

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SignerKeyEd25519SignedPayload {
        return SignerKeyEd25519SignedPayload{
            .ed25519 = try xdrDecodeGeneric(Uint256, allocator, reader),
            .payload = try xdrDecodeGeneric(BoundedArray(u8, 64), allocator, reader),
        };
    }

    pub fn xdrEncode(self: SignerKeyEd25519SignedPayload, writer: anytype) !void {
        try xdrEncodeGeneric(Uint256, writer, self.ed25519);
        try xdrEncodeGeneric(BoundedArray(u8, 64), writer, self.payload);
    }
};

/// SignerKey is an XDR Union defined as:
///
/// ```text
/// union SignerKey switch (SignerKeyType type)
/// {
/// case SIGNER_KEY_TYPE_ED25519:
///     uint256 ed25519;
/// case SIGNER_KEY_TYPE_PRE_AUTH_TX:
///     /* SHA-256 Hash of TransactionSignaturePayload structure */
///     uint256 preAuthTx;
/// case SIGNER_KEY_TYPE_HASH_X:
///     /* Hash of random 256 bit preimage X */
///     uint256 hashX;
/// case SIGNER_KEY_TYPE_ED25519_SIGNED_PAYLOAD:
///     struct
///     {
///         /* Public key that must sign the payload. */
///         uint256 ed25519;
///         /* Payload to be raw signed by ed25519. */
///         opaque payload<64>;
///     } ed25519SignedPayload;
/// };
/// ```
///
pub const SignerKey = union(enum) {
    Ed25519: Uint256,
    PreAuthTx: Uint256,
    HashX: Uint256,
    Ed25519SignedPayload: SignerKeyEd25519SignedPayload,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SignerKey {
        const disc = try SignerKeyType.xdrDecode(allocator, reader);
        return switch (disc) {
            .Ed25519 => SignerKey{ .Ed25519 = try xdrDecodeGeneric(Uint256, allocator, reader) },
            .PreAuthTx => SignerKey{ .PreAuthTx = try xdrDecodeGeneric(Uint256, allocator, reader) },
            .HashX => SignerKey{ .HashX = try xdrDecodeGeneric(Uint256, allocator, reader) },
            .Ed25519SignedPayload => SignerKey{ .Ed25519SignedPayload = try xdrDecodeGeneric(SignerKeyEd25519SignedPayload, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: SignerKey, writer: anytype) !void {
        const disc: SignerKeyType = switch (self) {
            .Ed25519 => .Ed25519,
            .PreAuthTx => .PreAuthTx,
            .HashX => .HashX,
            .Ed25519SignedPayload => .Ed25519SignedPayload,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .Ed25519 => |v| try xdrEncodeGeneric(Uint256, writer, v),
            .PreAuthTx => |v| try xdrEncodeGeneric(Uint256, writer, v),
            .HashX => |v| try xdrEncodeGeneric(Uint256, writer, v),
            .Ed25519SignedPayload => |v| try xdrEncodeGeneric(SignerKeyEd25519SignedPayload, writer, v),
        }
    }
};

/// Signature is an XDR Typedef defined as:
///
/// ```text
/// typedef opaque Signature<64>;
/// ```
///
pub const Signature = struct {
    value: BoundedArray(u8, 64),

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !Signature {
        return Signature{
            .value = try xdrDecodeGeneric(BoundedArray(u8, 64), allocator, reader),
        };
    }

    pub fn xdrEncode(self: Signature, writer: anytype) !void {
        try xdrEncodeGeneric(BoundedArray(u8, 64), writer, self.value);
    }

    pub fn asSlice(self: Signature) []const u8 {
        return self.value.data;
    }
};

/// SignatureHint is an XDR Typedef defined as:
///
/// ```text
/// typedef opaque SignatureHint[4];
/// ```
///
pub const SignatureHint = struct {
    value: [4]u8,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SignatureHint {
        return SignatureHint{
            .value = try xdrDecodeGeneric([4]u8, allocator, reader),
        };
    }

    pub fn xdrEncode(self: SignatureHint, writer: anytype) !void {
        try xdrEncodeGeneric([4]u8, writer, self.value);
    }

    pub fn asSlice(self: *const SignatureHint) []const u8 {
        return &self.value;
    }
};

/// NodeId is an XDR Typedef defined as:
///
/// ```text
/// typedef PublicKey NodeID;
/// ```
///
pub const NodeId = struct {
    value: PublicKey,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !NodeId {
        return NodeId{
            .value = try xdrDecodeGeneric(PublicKey, allocator, reader),
        };
    }

    pub fn xdrEncode(self: NodeId, writer: anytype) !void {
        try xdrEncodeGeneric(PublicKey, writer, self.value);
    }
};

/// AccountId is an XDR Typedef defined as:
///
/// ```text
/// typedef PublicKey AccountID;
/// ```
///
pub const AccountId = struct {
    value: PublicKey,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !AccountId {
        return AccountId{
            .value = try xdrDecodeGeneric(PublicKey, allocator, reader),
        };
    }

    pub fn xdrEncode(self: AccountId, writer: anytype) !void {
        try xdrEncodeGeneric(PublicKey, writer, self.value);
    }
};

/// ContractId is an XDR Typedef defined as:
///
/// ```text
/// typedef Hash ContractID;
/// ```
///
pub const ContractId = struct {
    value: Hash,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ContractId {
        return ContractId{
            .value = try xdrDecodeGeneric(Hash, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ContractId, writer: anytype) !void {
        try xdrEncodeGeneric(Hash, writer, self.value);
    }
};

/// Curve25519Secret is an XDR Struct defined as:
///
/// ```text
/// struct Curve25519Secret
/// {
///     opaque key[32];
/// };
/// ```
///
pub const Curve25519Secret = struct {
    key: [32]u8,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !Curve25519Secret {
        return Curve25519Secret{
            .key = try xdrDecodeGeneric([32]u8, allocator, reader),
        };
    }

    pub fn xdrEncode(self: Curve25519Secret, writer: anytype) !void {
        try xdrEncodeGeneric([32]u8, writer, self.key);
    }
};

/// Curve25519Public is an XDR Struct defined as:
///
/// ```text
/// struct Curve25519Public
/// {
///     opaque key[32];
/// };
/// ```
///
pub const Curve25519Public = struct {
    key: [32]u8,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !Curve25519Public {
        return Curve25519Public{
            .key = try xdrDecodeGeneric([32]u8, allocator, reader),
        };
    }

    pub fn xdrEncode(self: Curve25519Public, writer: anytype) !void {
        try xdrEncodeGeneric([32]u8, writer, self.key);
    }
};

/// HmacSha256Key is an XDR Struct defined as:
///
/// ```text
/// struct HmacSha256Key
/// {
///     opaque key[32];
/// };
/// ```
///
pub const HmacSha256Key = struct {
    key: [32]u8,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !HmacSha256Key {
        return HmacSha256Key{
            .key = try xdrDecodeGeneric([32]u8, allocator, reader),
        };
    }

    pub fn xdrEncode(self: HmacSha256Key, writer: anytype) !void {
        try xdrEncodeGeneric([32]u8, writer, self.key);
    }
};

/// HmacSha256Mac is an XDR Struct defined as:
///
/// ```text
/// struct HmacSha256Mac
/// {
///     opaque mac[32];
/// };
/// ```
///
pub const HmacSha256Mac = struct {
    mac: [32]u8,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !HmacSha256Mac {
        return HmacSha256Mac{
            .mac = try xdrDecodeGeneric([32]u8, allocator, reader),
        };
    }

    pub fn xdrEncode(self: HmacSha256Mac, writer: anytype) !void {
        try xdrEncodeGeneric([32]u8, writer, self.mac);
    }
};

/// ShortHashSeed is an XDR Struct defined as:
///
/// ```text
/// struct ShortHashSeed
/// {
///     opaque seed[16];
/// };
/// ```
///
pub const ShortHashSeed = struct {
    seed: [16]u8,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ShortHashSeed {
        return ShortHashSeed{
            .seed = try xdrDecodeGeneric([16]u8, allocator, reader),
        };
    }

    pub fn xdrEncode(self: ShortHashSeed, writer: anytype) !void {
        try xdrEncodeGeneric([16]u8, writer, self.seed);
    }
};

/// BinaryFuseFilterType is an XDR Enum defined as:
///
/// ```text
/// enum BinaryFuseFilterType
/// {
///     BINARY_FUSE_FILTER_8_BIT = 0,
///     BINARY_FUSE_FILTER_16_BIT = 1,
///     BINARY_FUSE_FILTER_32_BIT = 2
/// };
/// ```
///
pub const BinaryFuseFilterType = enum(i32) {
    B8Bit = 0,
    B16Bit = 1,
    B32Bit = 2,
    _,

    pub const variants = [_]BinaryFuseFilterType{
        .B8Bit,
        .B16Bit,
        .B32Bit,
    };

    pub fn name(self: BinaryFuseFilterType) []const u8 {
        return switch (self) {
            .B8Bit => "B8Bit",
            .B16Bit => "B16Bit",
            .B32Bit => "B32Bit",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !BinaryFuseFilterType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: BinaryFuseFilterType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// SerializedBinaryFuseFilter is an XDR Struct defined as:
///
/// ```text
/// struct SerializedBinaryFuseFilter
/// {
///     BinaryFuseFilterType type;
///
///     // Seed used to hash input to filter
///     ShortHashSeed inputHashSeed;
///
///     // Seed used for internal filter hash operations
///     ShortHashSeed filterSeed;
///     uint32 segmentLength;
///     uint32 segementLengthMask;
///     uint32 segmentCount;
///     uint32 segmentCountLength;
///     uint32 fingerprintLength; // Length in terms of element count, not bytes
///
///     // Array of uint8_t, uint16_t, or uint32_t depending on filter type
///     opaque fingerprints<>;
/// };
/// ```
///
pub const SerializedBinaryFuseFilter = struct {
    type: BinaryFuseFilterType,
    input_hash_seed: ShortHashSeed,
    filter_seed: ShortHashSeed,
    segment_length: u32,
    segement_length_mask: u32,
    segment_count: u32,
    segment_count_length: u32,
    fingerprint_length: u32,
    fingerprints: []u8,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !SerializedBinaryFuseFilter {
        return SerializedBinaryFuseFilter{
            .type = try xdrDecodeGeneric(BinaryFuseFilterType, allocator, reader),
            .input_hash_seed = try xdrDecodeGeneric(ShortHashSeed, allocator, reader),
            .filter_seed = try xdrDecodeGeneric(ShortHashSeed, allocator, reader),
            .segment_length = try xdrDecodeGeneric(u32, allocator, reader),
            .segement_length_mask = try xdrDecodeGeneric(u32, allocator, reader),
            .segment_count = try xdrDecodeGeneric(u32, allocator, reader),
            .segment_count_length = try xdrDecodeGeneric(u32, allocator, reader),
            .fingerprint_length = try xdrDecodeGeneric(u32, allocator, reader),
            .fingerprints = try xdrDecodeGeneric([]u8, allocator, reader),
        };
    }

    pub fn xdrEncode(self: SerializedBinaryFuseFilter, writer: anytype) !void {
        try xdrEncodeGeneric(BinaryFuseFilterType, writer, self.type);
        try xdrEncodeGeneric(ShortHashSeed, writer, self.input_hash_seed);
        try xdrEncodeGeneric(ShortHashSeed, writer, self.filter_seed);
        try xdrEncodeGeneric(u32, writer, self.segment_length);
        try xdrEncodeGeneric(u32, writer, self.segement_length_mask);
        try xdrEncodeGeneric(u32, writer, self.segment_count);
        try xdrEncodeGeneric(u32, writer, self.segment_count_length);
        try xdrEncodeGeneric(u32, writer, self.fingerprint_length);
        try xdrEncodeGeneric([]u8, writer, self.fingerprints);
    }
};

/// PoolId is an XDR Typedef defined as:
///
/// ```text
/// typedef Hash PoolID;
/// ```
///
pub const PoolId = struct {
    value: Hash,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !PoolId {
        return PoolId{
            .value = try xdrDecodeGeneric(Hash, allocator, reader),
        };
    }

    pub fn xdrEncode(self: PoolId, writer: anytype) !void {
        try xdrEncodeGeneric(Hash, writer, self.value);
    }
};

/// ClaimableBalanceIdType is an XDR Enum defined as:
///
/// ```text
/// enum ClaimableBalanceIDType
/// {
///     CLAIMABLE_BALANCE_ID_TYPE_V0 = 0
/// };
/// ```
///
pub const ClaimableBalanceIdType = enum(i32) {
    ClaimableBalanceIdTypeV0 = 0,
    _,

    pub const variants = [_]ClaimableBalanceIdType{
        .ClaimableBalanceIdTypeV0,
    };

    pub fn name(self: ClaimableBalanceIdType) []const u8 {
        return switch (self) {
            .ClaimableBalanceIdTypeV0 => "ClaimableBalanceIdTypeV0",
            _ => "unknown",
        };
    }

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ClaimableBalanceIdType {
        _ = allocator;
        const value = try reader.readInt(i32, .big);
        return @enumFromInt(value);
    }

    pub fn xdrEncode(self: ClaimableBalanceIdType, writer: anytype) !void {
        try writer.writeInt(i32, @intFromEnum(self), .big);
    }
};

/// ClaimableBalanceId is an XDR Union defined as:
///
/// ```text
/// union ClaimableBalanceID switch (ClaimableBalanceIDType type)
/// {
/// case CLAIMABLE_BALANCE_ID_TYPE_V0:
///     Hash v0;
/// };
/// ```
///
pub const ClaimableBalanceId = union(enum) {
    ClaimableBalanceIdTypeV0: Hash,

    pub fn xdrDecode(allocator: Allocator, reader: anytype) !ClaimableBalanceId {
        const disc = try ClaimableBalanceIdType.xdrDecode(allocator, reader);
        return switch (disc) {
            .ClaimableBalanceIdTypeV0 => ClaimableBalanceId{ .ClaimableBalanceIdTypeV0 = try xdrDecodeGeneric(Hash, allocator, reader) },
            else => return error.InvalidUnionDiscriminant,
        };
    }

    pub fn xdrEncode(self: ClaimableBalanceId, writer: anytype) !void {
        const disc: ClaimableBalanceIdType = switch (self) {
            .ClaimableBalanceIdTypeV0 => .ClaimableBalanceIdTypeV0,
        };
        try disc.xdrEncode(writer);
        switch (self) {
            .ClaimableBalanceIdTypeV0 => |v| try xdrEncodeGeneric(Hash, writer, v),
        }
    }
};

pub const TypeVariant = enum {
    Value,
    ScpBallot,
    ScpStatementType,
    ScpNomination,
    ScpStatement,
    ScpStatementPledges,
    ScpStatementPrepare,
    ScpStatementConfirm,
    ScpStatementExternalize,
    ScpEnvelope,
    ScpQuorumSet,
    ConfigSettingContractExecutionLanesV0,
    ConfigSettingContractComputeV0,
    ConfigSettingContractParallelComputeV0,
    ConfigSettingContractLedgerCostV0,
    ConfigSettingContractLedgerCostExtV0,
    ConfigSettingContractHistoricalDataV0,
    ConfigSettingContractEventsV0,
    ConfigSettingContractBandwidthV0,
    ContractCostType,
    ContractCostParamEntry,
    StateArchivalSettings,
    EvictionIterator,
    ConfigSettingScpTiming,
    ContractCostParams,
    ConfigSettingId,
    ConfigSettingEntry,
    ScEnvMetaKind,
    ScEnvMetaEntry,
    ScEnvMetaEntryInterfaceVersion,
    ScMetaV0,
    ScMetaKind,
    ScMetaEntry,
    ScSpecType,
    ScSpecTypeOption,
    ScSpecTypeResult,
    ScSpecTypeVec,
    ScSpecTypeMap,
    ScSpecTypeTuple,
    ScSpecTypeBytesN,
    ScSpecTypeUdt,
    ScSpecTypeDef,
    ScSpecUdtStructFieldV0,
    ScSpecUdtStructV0,
    ScSpecUdtUnionCaseVoidV0,
    ScSpecUdtUnionCaseTupleV0,
    ScSpecUdtUnionCaseV0Kind,
    ScSpecUdtUnionCaseV0,
    ScSpecUdtUnionV0,
    ScSpecUdtEnumCaseV0,
    ScSpecUdtEnumV0,
    ScSpecUdtErrorEnumCaseV0,
    ScSpecUdtErrorEnumV0,
    ScSpecFunctionInputV0,
    ScSpecFunctionV0,
    ScSpecEventParamLocationV0,
    ScSpecEventParamV0,
    ScSpecEventDataFormat,
    ScSpecEventV0,
    ScSpecEntryKind,
    ScSpecEntry,
    ScValType,
    ScErrorType,
    ScErrorCode,
    ScError,
    UInt128Parts,
    Int128Parts,
    UInt256Parts,
    Int256Parts,
    ContractExecutableType,
    ContractExecutable,
    ScAddressType,
    MuxedEd25519Account,
    ScAddress,
    ScVec,
    ScMap,
    ScBytes,
    ScString,
    ScSymbol,
    ScNonceKey,
    ScContractInstance,
    ScVal,
    ScMapEntry,
    LedgerCloseMetaBatch,
    StoredTransactionSet,
    StoredDebugTransactionSet,
    PersistedScpStateV0,
    PersistedScpStateV1,
    PersistedScpState,
    Thresholds,
    String32,
    String64,
    SequenceNumber,
    DataValue,
    AssetCode4,
    AssetCode12,
    AssetType,
    AssetCode,
    AlphaNum4,
    AlphaNum12,
    Asset,
    Price,
    Liabilities,
    ThresholdIndexes,
    LedgerEntryType,
    Signer,
    AccountFlags,
    SponsorshipDescriptor,
    AccountEntryExtensionV3,
    AccountEntryExtensionV2,
    AccountEntryExtensionV2Ext,
    AccountEntryExtensionV1,
    AccountEntryExtensionV1Ext,
    AccountEntry,
    AccountEntryExt,
    TrustLineFlags,
    LiquidityPoolType,
    TrustLineAsset,
    TrustLineEntryExtensionV2,
    TrustLineEntryExtensionV2Ext,
    TrustLineEntry,
    TrustLineEntryExt,
    TrustLineEntryV1,
    TrustLineEntryV1Ext,
    OfferEntryFlags,
    OfferEntry,
    OfferEntryExt,
    DataEntry,
    DataEntryExt,
    ClaimPredicateType,
    ClaimPredicate,
    ClaimantType,
    Claimant,
    ClaimantV0,
    ClaimableBalanceFlags,
    ClaimableBalanceEntryExtensionV1,
    ClaimableBalanceEntryExtensionV1Ext,
    ClaimableBalanceEntry,
    ClaimableBalanceEntryExt,
    LiquidityPoolConstantProductParameters,
    LiquidityPoolEntry,
    LiquidityPoolEntryBody,
    LiquidityPoolEntryConstantProduct,
    ContractDataDurability,
    ContractDataEntry,
    ContractCodeCostInputs,
    ContractCodeEntry,
    ContractCodeEntryExt,
    ContractCodeEntryV1,
    TtlEntry,
    LedgerEntryExtensionV1,
    LedgerEntryExtensionV1Ext,
    LedgerEntry,
    LedgerEntryData,
    LedgerEntryExt,
    LedgerKey,
    LedgerKeyAccount,
    LedgerKeyTrustLine,
    LedgerKeyOffer,
    LedgerKeyData,
    LedgerKeyClaimableBalance,
    LedgerKeyLiquidityPool,
    LedgerKeyContractData,
    LedgerKeyContractCode,
    LedgerKeyConfigSetting,
    LedgerKeyTtl,
    EnvelopeType,
    BucketListType,
    BucketEntryType,
    HotArchiveBucketEntryType,
    BucketMetadata,
    BucketMetadataExt,
    BucketEntry,
    HotArchiveBucketEntry,
    UpgradeType,
    StellarValueType,
    LedgerCloseValueSignature,
    StellarValue,
    StellarValueExt,
    LedgerHeaderFlags,
    LedgerHeaderExtensionV1,
    LedgerHeaderExtensionV1Ext,
    LedgerHeader,
    LedgerHeaderExt,
    LedgerUpgradeType,
    ConfigUpgradeSetKey,
    LedgerUpgrade,
    ConfigUpgradeSet,
    TxSetComponentType,
    DependentTxCluster,
    ParallelTxExecutionStage,
    ParallelTxsComponent,
    TxSetComponent,
    TxSetComponentTxsMaybeDiscountedFee,
    TransactionPhase,
    TransactionSet,
    TransactionSetV1,
    GeneralizedTransactionSet,
    TransactionResultPair,
    TransactionResultSet,
    TransactionHistoryEntry,
    TransactionHistoryEntryExt,
    TransactionHistoryResultEntry,
    TransactionHistoryResultEntryExt,
    LedgerHeaderHistoryEntry,
    LedgerHeaderHistoryEntryExt,
    LedgerScpMessages,
    ScpHistoryEntryV0,
    ScpHistoryEntry,
    LedgerEntryChangeType,
    LedgerEntryChange,
    LedgerEntryChanges,
    OperationMeta,
    TransactionMetaV1,
    TransactionMetaV2,
    ContractEventType,
    ContractEvent,
    ContractEventBody,
    ContractEventV0,
    DiagnosticEvent,
    SorobanTransactionMetaExtV1,
    SorobanTransactionMetaExt,
    SorobanTransactionMeta,
    TransactionMetaV3,
    OperationMetaV2,
    SorobanTransactionMetaV2,
    TransactionEventStage,
    TransactionEvent,
    TransactionMetaV4,
    InvokeHostFunctionSuccessPreImage,
    TransactionMeta,
    TransactionResultMeta,
    TransactionResultMetaV1,
    UpgradeEntryMeta,
    LedgerCloseMetaV0,
    LedgerCloseMetaExtV1,
    LedgerCloseMetaExt,
    LedgerCloseMetaV1,
    LedgerCloseMetaV2,
    LedgerCloseMeta,
    ErrorCode,
    SError,
    SendMore,
    SendMoreExtended,
    AuthCert,
    Hello,
    Auth,
    IpAddrType,
    PeerAddress,
    PeerAddressIp,
    MessageType,
    DontHave,
    SurveyMessageCommandType,
    SurveyMessageResponseType,
    TimeSlicedSurveyStartCollectingMessage,
    SignedTimeSlicedSurveyStartCollectingMessage,
    TimeSlicedSurveyStopCollectingMessage,
    SignedTimeSlicedSurveyStopCollectingMessage,
    SurveyRequestMessage,
    TimeSlicedSurveyRequestMessage,
    SignedTimeSlicedSurveyRequestMessage,
    EncryptedBody,
    SurveyResponseMessage,
    TimeSlicedSurveyResponseMessage,
    SignedTimeSlicedSurveyResponseMessage,
    PeerStats,
    TimeSlicedNodeData,
    TimeSlicedPeerData,
    TimeSlicedPeerDataList,
    TopologyResponseBodyV2,
    SurveyResponseBody,
    TxAdvertVector,
    FloodAdvert,
    TxDemandVector,
    FloodDemand,
    StellarMessage,
    AuthenticatedMessage,
    AuthenticatedMessageV0,
    LiquidityPoolParameters,
    MuxedAccount,
    MuxedAccountMed25519,
    DecoratedSignature,
    OperationType,
    CreateAccountOp,
    PaymentOp,
    PathPaymentStrictReceiveOp,
    PathPaymentStrictSendOp,
    ManageSellOfferOp,
    ManageBuyOfferOp,
    CreatePassiveSellOfferOp,
    SetOptionsOp,
    ChangeTrustAsset,
    ChangeTrustOp,
    AllowTrustOp,
    ManageDataOp,
    BumpSequenceOp,
    CreateClaimableBalanceOp,
    ClaimClaimableBalanceOp,
    BeginSponsoringFutureReservesOp,
    RevokeSponsorshipType,
    RevokeSponsorshipOp,
    RevokeSponsorshipOpSigner,
    ClawbackOp,
    ClawbackClaimableBalanceOp,
    SetTrustLineFlagsOp,
    LiquidityPoolDepositOp,
    LiquidityPoolWithdrawOp,
    HostFunctionType,
    ContractIdPreimageType,
    ContractIdPreimage,
    ContractIdPreimageFromAddress,
    CreateContractArgs,
    CreateContractArgsV2,
    InvokeContractArgs,
    HostFunction,
    SorobanAuthorizedFunctionType,
    SorobanAuthorizedFunction,
    SorobanAuthorizedInvocation,
    SorobanAddressCredentials,
    SorobanCredentialsType,
    SorobanCredentials,
    SorobanAuthorizationEntry,
    SorobanAuthorizationEntries,
    InvokeHostFunctionOp,
    ExtendFootprintTtlOp,
    RestoreFootprintOp,
    Operation,
    OperationBody,
    HashIdPreimage,
    HashIdPreimageOperationId,
    HashIdPreimageRevokeId,
    HashIdPreimageContractId,
    HashIdPreimageSorobanAuthorization,
    MemoType,
    Memo,
    TimeBounds,
    LedgerBounds,
    PreconditionsV2,
    PreconditionType,
    Preconditions,
    LedgerFootprint,
    SorobanResources,
    SorobanResourcesExtV0,
    SorobanTransactionData,
    SorobanTransactionDataExt,
    TransactionV0,
    TransactionV0Ext,
    TransactionV0Envelope,
    Transaction,
    TransactionExt,
    TransactionV1Envelope,
    FeeBumpTransaction,
    FeeBumpTransactionInnerTx,
    FeeBumpTransactionExt,
    FeeBumpTransactionEnvelope,
    TransactionEnvelope,
    TransactionSignaturePayload,
    TransactionSignaturePayloadTaggedTransaction,
    ClaimAtomType,
    ClaimOfferAtomV0,
    ClaimOfferAtom,
    ClaimLiquidityAtom,
    ClaimAtom,
    CreateAccountResultCode,
    CreateAccountResult,
    PaymentResultCode,
    PaymentResult,
    PathPaymentStrictReceiveResultCode,
    SimplePaymentResult,
    PathPaymentStrictReceiveResult,
    PathPaymentStrictReceiveResultSuccess,
    PathPaymentStrictSendResultCode,
    PathPaymentStrictSendResult,
    PathPaymentStrictSendResultSuccess,
    ManageSellOfferResultCode,
    ManageOfferEffect,
    ManageOfferSuccessResult,
    ManageOfferSuccessResultOffer,
    ManageSellOfferResult,
    ManageBuyOfferResultCode,
    ManageBuyOfferResult,
    SetOptionsResultCode,
    SetOptionsResult,
    ChangeTrustResultCode,
    ChangeTrustResult,
    AllowTrustResultCode,
    AllowTrustResult,
    AccountMergeResultCode,
    AccountMergeResult,
    InflationResultCode,
    InflationPayout,
    InflationResult,
    ManageDataResultCode,
    ManageDataResult,
    BumpSequenceResultCode,
    BumpSequenceResult,
    CreateClaimableBalanceResultCode,
    CreateClaimableBalanceResult,
    ClaimClaimableBalanceResultCode,
    ClaimClaimableBalanceResult,
    BeginSponsoringFutureReservesResultCode,
    BeginSponsoringFutureReservesResult,
    EndSponsoringFutureReservesResultCode,
    EndSponsoringFutureReservesResult,
    RevokeSponsorshipResultCode,
    RevokeSponsorshipResult,
    ClawbackResultCode,
    ClawbackResult,
    ClawbackClaimableBalanceResultCode,
    ClawbackClaimableBalanceResult,
    SetTrustLineFlagsResultCode,
    SetTrustLineFlagsResult,
    LiquidityPoolDepositResultCode,
    LiquidityPoolDepositResult,
    LiquidityPoolWithdrawResultCode,
    LiquidityPoolWithdrawResult,
    InvokeHostFunctionResultCode,
    InvokeHostFunctionResult,
    ExtendFootprintTtlResultCode,
    ExtendFootprintTtlResult,
    RestoreFootprintResultCode,
    RestoreFootprintResult,
    OperationResultCode,
    OperationResult,
    OperationResultTr,
    TransactionResultCode,
    InnerTransactionResult,
    InnerTransactionResultResult,
    InnerTransactionResultExt,
    InnerTransactionResultPair,
    TransactionResult,
    TransactionResultResult,
    TransactionResultExt,
    Hash,
    Uint256,
    Uint32,
    Int32,
    Uint64,
    Int64,
    TimePoint,
    Duration,
    ExtensionPoint,
    CryptoKeyType,
    PublicKeyType,
    SignerKeyType,
    PublicKey,
    SignerKey,
    SignerKeyEd25519SignedPayload,
    Signature,
    SignatureHint,
    NodeId,
    AccountId,
    ContractId,
    Curve25519Secret,
    Curve25519Public,
    HmacSha256Key,
    HmacSha256Mac,
    ShortHashSeed,
    BinaryFuseFilterType,
    SerializedBinaryFuseFilter,
    PoolId,
    ClaimableBalanceIdType,
    ClaimableBalanceId,

    pub const variants = [_]TypeVariant{
        .Value,
        .ScpBallot,
        .ScpStatementType,
        .ScpNomination,
        .ScpStatement,
        .ScpStatementPledges,
        .ScpStatementPrepare,
        .ScpStatementConfirm,
        .ScpStatementExternalize,
        .ScpEnvelope,
        .ScpQuorumSet,
        .ConfigSettingContractExecutionLanesV0,
        .ConfigSettingContractComputeV0,
        .ConfigSettingContractParallelComputeV0,
        .ConfigSettingContractLedgerCostV0,
        .ConfigSettingContractLedgerCostExtV0,
        .ConfigSettingContractHistoricalDataV0,
        .ConfigSettingContractEventsV0,
        .ConfigSettingContractBandwidthV0,
        .ContractCostType,
        .ContractCostParamEntry,
        .StateArchivalSettings,
        .EvictionIterator,
        .ConfigSettingScpTiming,
        .ContractCostParams,
        .ConfigSettingId,
        .ConfigSettingEntry,
        .ScEnvMetaKind,
        .ScEnvMetaEntry,
        .ScEnvMetaEntryInterfaceVersion,
        .ScMetaV0,
        .ScMetaKind,
        .ScMetaEntry,
        .ScSpecType,
        .ScSpecTypeOption,
        .ScSpecTypeResult,
        .ScSpecTypeVec,
        .ScSpecTypeMap,
        .ScSpecTypeTuple,
        .ScSpecTypeBytesN,
        .ScSpecTypeUdt,
        .ScSpecTypeDef,
        .ScSpecUdtStructFieldV0,
        .ScSpecUdtStructV0,
        .ScSpecUdtUnionCaseVoidV0,
        .ScSpecUdtUnionCaseTupleV0,
        .ScSpecUdtUnionCaseV0Kind,
        .ScSpecUdtUnionCaseV0,
        .ScSpecUdtUnionV0,
        .ScSpecUdtEnumCaseV0,
        .ScSpecUdtEnumV0,
        .ScSpecUdtErrorEnumCaseV0,
        .ScSpecUdtErrorEnumV0,
        .ScSpecFunctionInputV0,
        .ScSpecFunctionV0,
        .ScSpecEventParamLocationV0,
        .ScSpecEventParamV0,
        .ScSpecEventDataFormat,
        .ScSpecEventV0,
        .ScSpecEntryKind,
        .ScSpecEntry,
        .ScValType,
        .ScErrorType,
        .ScErrorCode,
        .ScError,
        .UInt128Parts,
        .Int128Parts,
        .UInt256Parts,
        .Int256Parts,
        .ContractExecutableType,
        .ContractExecutable,
        .ScAddressType,
        .MuxedEd25519Account,
        .ScAddress,
        .ScVec,
        .ScMap,
        .ScBytes,
        .ScString,
        .ScSymbol,
        .ScNonceKey,
        .ScContractInstance,
        .ScVal,
        .ScMapEntry,
        .LedgerCloseMetaBatch,
        .StoredTransactionSet,
        .StoredDebugTransactionSet,
        .PersistedScpStateV0,
        .PersistedScpStateV1,
        .PersistedScpState,
        .Thresholds,
        .String32,
        .String64,
        .SequenceNumber,
        .DataValue,
        .AssetCode4,
        .AssetCode12,
        .AssetType,
        .AssetCode,
        .AlphaNum4,
        .AlphaNum12,
        .Asset,
        .Price,
        .Liabilities,
        .ThresholdIndexes,
        .LedgerEntryType,
        .Signer,
        .AccountFlags,
        .SponsorshipDescriptor,
        .AccountEntryExtensionV3,
        .AccountEntryExtensionV2,
        .AccountEntryExtensionV2Ext,
        .AccountEntryExtensionV1,
        .AccountEntryExtensionV1Ext,
        .AccountEntry,
        .AccountEntryExt,
        .TrustLineFlags,
        .LiquidityPoolType,
        .TrustLineAsset,
        .TrustLineEntryExtensionV2,
        .TrustLineEntryExtensionV2Ext,
        .TrustLineEntry,
        .TrustLineEntryExt,
        .TrustLineEntryV1,
        .TrustLineEntryV1Ext,
        .OfferEntryFlags,
        .OfferEntry,
        .OfferEntryExt,
        .DataEntry,
        .DataEntryExt,
        .ClaimPredicateType,
        .ClaimPredicate,
        .ClaimantType,
        .Claimant,
        .ClaimantV0,
        .ClaimableBalanceFlags,
        .ClaimableBalanceEntryExtensionV1,
        .ClaimableBalanceEntryExtensionV1Ext,
        .ClaimableBalanceEntry,
        .ClaimableBalanceEntryExt,
        .LiquidityPoolConstantProductParameters,
        .LiquidityPoolEntry,
        .LiquidityPoolEntryBody,
        .LiquidityPoolEntryConstantProduct,
        .ContractDataDurability,
        .ContractDataEntry,
        .ContractCodeCostInputs,
        .ContractCodeEntry,
        .ContractCodeEntryExt,
        .ContractCodeEntryV1,
        .TtlEntry,
        .LedgerEntryExtensionV1,
        .LedgerEntryExtensionV1Ext,
        .LedgerEntry,
        .LedgerEntryData,
        .LedgerEntryExt,
        .LedgerKey,
        .LedgerKeyAccount,
        .LedgerKeyTrustLine,
        .LedgerKeyOffer,
        .LedgerKeyData,
        .LedgerKeyClaimableBalance,
        .LedgerKeyLiquidityPool,
        .LedgerKeyContractData,
        .LedgerKeyContractCode,
        .LedgerKeyConfigSetting,
        .LedgerKeyTtl,
        .EnvelopeType,
        .BucketListType,
        .BucketEntryType,
        .HotArchiveBucketEntryType,
        .BucketMetadata,
        .BucketMetadataExt,
        .BucketEntry,
        .HotArchiveBucketEntry,
        .UpgradeType,
        .StellarValueType,
        .LedgerCloseValueSignature,
        .StellarValue,
        .StellarValueExt,
        .LedgerHeaderFlags,
        .LedgerHeaderExtensionV1,
        .LedgerHeaderExtensionV1Ext,
        .LedgerHeader,
        .LedgerHeaderExt,
        .LedgerUpgradeType,
        .ConfigUpgradeSetKey,
        .LedgerUpgrade,
        .ConfigUpgradeSet,
        .TxSetComponentType,
        .DependentTxCluster,
        .ParallelTxExecutionStage,
        .ParallelTxsComponent,
        .TxSetComponent,
        .TxSetComponentTxsMaybeDiscountedFee,
        .TransactionPhase,
        .TransactionSet,
        .TransactionSetV1,
        .GeneralizedTransactionSet,
        .TransactionResultPair,
        .TransactionResultSet,
        .TransactionHistoryEntry,
        .TransactionHistoryEntryExt,
        .TransactionHistoryResultEntry,
        .TransactionHistoryResultEntryExt,
        .LedgerHeaderHistoryEntry,
        .LedgerHeaderHistoryEntryExt,
        .LedgerScpMessages,
        .ScpHistoryEntryV0,
        .ScpHistoryEntry,
        .LedgerEntryChangeType,
        .LedgerEntryChange,
        .LedgerEntryChanges,
        .OperationMeta,
        .TransactionMetaV1,
        .TransactionMetaV2,
        .ContractEventType,
        .ContractEvent,
        .ContractEventBody,
        .ContractEventV0,
        .DiagnosticEvent,
        .SorobanTransactionMetaExtV1,
        .SorobanTransactionMetaExt,
        .SorobanTransactionMeta,
        .TransactionMetaV3,
        .OperationMetaV2,
        .SorobanTransactionMetaV2,
        .TransactionEventStage,
        .TransactionEvent,
        .TransactionMetaV4,
        .InvokeHostFunctionSuccessPreImage,
        .TransactionMeta,
        .TransactionResultMeta,
        .TransactionResultMetaV1,
        .UpgradeEntryMeta,
        .LedgerCloseMetaV0,
        .LedgerCloseMetaExtV1,
        .LedgerCloseMetaExt,
        .LedgerCloseMetaV1,
        .LedgerCloseMetaV2,
        .LedgerCloseMeta,
        .ErrorCode,
        .SError,
        .SendMore,
        .SendMoreExtended,
        .AuthCert,
        .Hello,
        .Auth,
        .IpAddrType,
        .PeerAddress,
        .PeerAddressIp,
        .MessageType,
        .DontHave,
        .SurveyMessageCommandType,
        .SurveyMessageResponseType,
        .TimeSlicedSurveyStartCollectingMessage,
        .SignedTimeSlicedSurveyStartCollectingMessage,
        .TimeSlicedSurveyStopCollectingMessage,
        .SignedTimeSlicedSurveyStopCollectingMessage,
        .SurveyRequestMessage,
        .TimeSlicedSurveyRequestMessage,
        .SignedTimeSlicedSurveyRequestMessage,
        .EncryptedBody,
        .SurveyResponseMessage,
        .TimeSlicedSurveyResponseMessage,
        .SignedTimeSlicedSurveyResponseMessage,
        .PeerStats,
        .TimeSlicedNodeData,
        .TimeSlicedPeerData,
        .TimeSlicedPeerDataList,
        .TopologyResponseBodyV2,
        .SurveyResponseBody,
        .TxAdvertVector,
        .FloodAdvert,
        .TxDemandVector,
        .FloodDemand,
        .StellarMessage,
        .AuthenticatedMessage,
        .AuthenticatedMessageV0,
        .LiquidityPoolParameters,
        .MuxedAccount,
        .MuxedAccountMed25519,
        .DecoratedSignature,
        .OperationType,
        .CreateAccountOp,
        .PaymentOp,
        .PathPaymentStrictReceiveOp,
        .PathPaymentStrictSendOp,
        .ManageSellOfferOp,
        .ManageBuyOfferOp,
        .CreatePassiveSellOfferOp,
        .SetOptionsOp,
        .ChangeTrustAsset,
        .ChangeTrustOp,
        .AllowTrustOp,
        .ManageDataOp,
        .BumpSequenceOp,
        .CreateClaimableBalanceOp,
        .ClaimClaimableBalanceOp,
        .BeginSponsoringFutureReservesOp,
        .RevokeSponsorshipType,
        .RevokeSponsorshipOp,
        .RevokeSponsorshipOpSigner,
        .ClawbackOp,
        .ClawbackClaimableBalanceOp,
        .SetTrustLineFlagsOp,
        .LiquidityPoolDepositOp,
        .LiquidityPoolWithdrawOp,
        .HostFunctionType,
        .ContractIdPreimageType,
        .ContractIdPreimage,
        .ContractIdPreimageFromAddress,
        .CreateContractArgs,
        .CreateContractArgsV2,
        .InvokeContractArgs,
        .HostFunction,
        .SorobanAuthorizedFunctionType,
        .SorobanAuthorizedFunction,
        .SorobanAuthorizedInvocation,
        .SorobanAddressCredentials,
        .SorobanCredentialsType,
        .SorobanCredentials,
        .SorobanAuthorizationEntry,
        .SorobanAuthorizationEntries,
        .InvokeHostFunctionOp,
        .ExtendFootprintTtlOp,
        .RestoreFootprintOp,
        .Operation,
        .OperationBody,
        .HashIdPreimage,
        .HashIdPreimageOperationId,
        .HashIdPreimageRevokeId,
        .HashIdPreimageContractId,
        .HashIdPreimageSorobanAuthorization,
        .MemoType,
        .Memo,
        .TimeBounds,
        .LedgerBounds,
        .PreconditionsV2,
        .PreconditionType,
        .Preconditions,
        .LedgerFootprint,
        .SorobanResources,
        .SorobanResourcesExtV0,
        .SorobanTransactionData,
        .SorobanTransactionDataExt,
        .TransactionV0,
        .TransactionV0Ext,
        .TransactionV0Envelope,
        .Transaction,
        .TransactionExt,
        .TransactionV1Envelope,
        .FeeBumpTransaction,
        .FeeBumpTransactionInnerTx,
        .FeeBumpTransactionExt,
        .FeeBumpTransactionEnvelope,
        .TransactionEnvelope,
        .TransactionSignaturePayload,
        .TransactionSignaturePayloadTaggedTransaction,
        .ClaimAtomType,
        .ClaimOfferAtomV0,
        .ClaimOfferAtom,
        .ClaimLiquidityAtom,
        .ClaimAtom,
        .CreateAccountResultCode,
        .CreateAccountResult,
        .PaymentResultCode,
        .PaymentResult,
        .PathPaymentStrictReceiveResultCode,
        .SimplePaymentResult,
        .PathPaymentStrictReceiveResult,
        .PathPaymentStrictReceiveResultSuccess,
        .PathPaymentStrictSendResultCode,
        .PathPaymentStrictSendResult,
        .PathPaymentStrictSendResultSuccess,
        .ManageSellOfferResultCode,
        .ManageOfferEffect,
        .ManageOfferSuccessResult,
        .ManageOfferSuccessResultOffer,
        .ManageSellOfferResult,
        .ManageBuyOfferResultCode,
        .ManageBuyOfferResult,
        .SetOptionsResultCode,
        .SetOptionsResult,
        .ChangeTrustResultCode,
        .ChangeTrustResult,
        .AllowTrustResultCode,
        .AllowTrustResult,
        .AccountMergeResultCode,
        .AccountMergeResult,
        .InflationResultCode,
        .InflationPayout,
        .InflationResult,
        .ManageDataResultCode,
        .ManageDataResult,
        .BumpSequenceResultCode,
        .BumpSequenceResult,
        .CreateClaimableBalanceResultCode,
        .CreateClaimableBalanceResult,
        .ClaimClaimableBalanceResultCode,
        .ClaimClaimableBalanceResult,
        .BeginSponsoringFutureReservesResultCode,
        .BeginSponsoringFutureReservesResult,
        .EndSponsoringFutureReservesResultCode,
        .EndSponsoringFutureReservesResult,
        .RevokeSponsorshipResultCode,
        .RevokeSponsorshipResult,
        .ClawbackResultCode,
        .ClawbackResult,
        .ClawbackClaimableBalanceResultCode,
        .ClawbackClaimableBalanceResult,
        .SetTrustLineFlagsResultCode,
        .SetTrustLineFlagsResult,
        .LiquidityPoolDepositResultCode,
        .LiquidityPoolDepositResult,
        .LiquidityPoolWithdrawResultCode,
        .LiquidityPoolWithdrawResult,
        .InvokeHostFunctionResultCode,
        .InvokeHostFunctionResult,
        .ExtendFootprintTtlResultCode,
        .ExtendFootprintTtlResult,
        .RestoreFootprintResultCode,
        .RestoreFootprintResult,
        .OperationResultCode,
        .OperationResult,
        .OperationResultTr,
        .TransactionResultCode,
        .InnerTransactionResult,
        .InnerTransactionResultResult,
        .InnerTransactionResultExt,
        .InnerTransactionResultPair,
        .TransactionResult,
        .TransactionResultResult,
        .TransactionResultExt,
        .Hash,
        .Uint256,
        .Uint32,
        .Int32,
        .Uint64,
        .Int64,
        .TimePoint,
        .Duration,
        .ExtensionPoint,
        .CryptoKeyType,
        .PublicKeyType,
        .SignerKeyType,
        .PublicKey,
        .SignerKey,
        .SignerKeyEd25519SignedPayload,
        .Signature,
        .SignatureHint,
        .NodeId,
        .AccountId,
        .ContractId,
        .Curve25519Secret,
        .Curve25519Public,
        .HmacSha256Key,
        .HmacSha256Mac,
        .ShortHashSeed,
        .BinaryFuseFilterType,
        .SerializedBinaryFuseFilter,
        .PoolId,
        .ClaimableBalanceIdType,
        .ClaimableBalanceId,
    };

    pub fn name(self: TypeVariant) []const u8 {
        return switch (self) {
            .Value => "Value",
            .ScpBallot => "ScpBallot",
            .ScpStatementType => "ScpStatementType",
            .ScpNomination => "ScpNomination",
            .ScpStatement => "ScpStatement",
            .ScpStatementPledges => "ScpStatementPledges",
            .ScpStatementPrepare => "ScpStatementPrepare",
            .ScpStatementConfirm => "ScpStatementConfirm",
            .ScpStatementExternalize => "ScpStatementExternalize",
            .ScpEnvelope => "ScpEnvelope",
            .ScpQuorumSet => "ScpQuorumSet",
            .ConfigSettingContractExecutionLanesV0 => "ConfigSettingContractExecutionLanesV0",
            .ConfigSettingContractComputeV0 => "ConfigSettingContractComputeV0",
            .ConfigSettingContractParallelComputeV0 => "ConfigSettingContractParallelComputeV0",
            .ConfigSettingContractLedgerCostV0 => "ConfigSettingContractLedgerCostV0",
            .ConfigSettingContractLedgerCostExtV0 => "ConfigSettingContractLedgerCostExtV0",
            .ConfigSettingContractHistoricalDataV0 => "ConfigSettingContractHistoricalDataV0",
            .ConfigSettingContractEventsV0 => "ConfigSettingContractEventsV0",
            .ConfigSettingContractBandwidthV0 => "ConfigSettingContractBandwidthV0",
            .ContractCostType => "ContractCostType",
            .ContractCostParamEntry => "ContractCostParamEntry",
            .StateArchivalSettings => "StateArchivalSettings",
            .EvictionIterator => "EvictionIterator",
            .ConfigSettingScpTiming => "ConfigSettingScpTiming",
            .ContractCostParams => "ContractCostParams",
            .ConfigSettingId => "ConfigSettingId",
            .ConfigSettingEntry => "ConfigSettingEntry",
            .ScEnvMetaKind => "ScEnvMetaKind",
            .ScEnvMetaEntry => "ScEnvMetaEntry",
            .ScEnvMetaEntryInterfaceVersion => "ScEnvMetaEntryInterfaceVersion",
            .ScMetaV0 => "ScMetaV0",
            .ScMetaKind => "ScMetaKind",
            .ScMetaEntry => "ScMetaEntry",
            .ScSpecType => "ScSpecType",
            .ScSpecTypeOption => "ScSpecTypeOption",
            .ScSpecTypeResult => "ScSpecTypeResult",
            .ScSpecTypeVec => "ScSpecTypeVec",
            .ScSpecTypeMap => "ScSpecTypeMap",
            .ScSpecTypeTuple => "ScSpecTypeTuple",
            .ScSpecTypeBytesN => "ScSpecTypeBytesN",
            .ScSpecTypeUdt => "ScSpecTypeUdt",
            .ScSpecTypeDef => "ScSpecTypeDef",
            .ScSpecUdtStructFieldV0 => "ScSpecUdtStructFieldV0",
            .ScSpecUdtStructV0 => "ScSpecUdtStructV0",
            .ScSpecUdtUnionCaseVoidV0 => "ScSpecUdtUnionCaseVoidV0",
            .ScSpecUdtUnionCaseTupleV0 => "ScSpecUdtUnionCaseTupleV0",
            .ScSpecUdtUnionCaseV0Kind => "ScSpecUdtUnionCaseV0Kind",
            .ScSpecUdtUnionCaseV0 => "ScSpecUdtUnionCaseV0",
            .ScSpecUdtUnionV0 => "ScSpecUdtUnionV0",
            .ScSpecUdtEnumCaseV0 => "ScSpecUdtEnumCaseV0",
            .ScSpecUdtEnumV0 => "ScSpecUdtEnumV0",
            .ScSpecUdtErrorEnumCaseV0 => "ScSpecUdtErrorEnumCaseV0",
            .ScSpecUdtErrorEnumV0 => "ScSpecUdtErrorEnumV0",
            .ScSpecFunctionInputV0 => "ScSpecFunctionInputV0",
            .ScSpecFunctionV0 => "ScSpecFunctionV0",
            .ScSpecEventParamLocationV0 => "ScSpecEventParamLocationV0",
            .ScSpecEventParamV0 => "ScSpecEventParamV0",
            .ScSpecEventDataFormat => "ScSpecEventDataFormat",
            .ScSpecEventV0 => "ScSpecEventV0",
            .ScSpecEntryKind => "ScSpecEntryKind",
            .ScSpecEntry => "ScSpecEntry",
            .ScValType => "ScValType",
            .ScErrorType => "ScErrorType",
            .ScErrorCode => "ScErrorCode",
            .ScError => "ScError",
            .UInt128Parts => "UInt128Parts",
            .Int128Parts => "Int128Parts",
            .UInt256Parts => "UInt256Parts",
            .Int256Parts => "Int256Parts",
            .ContractExecutableType => "ContractExecutableType",
            .ContractExecutable => "ContractExecutable",
            .ScAddressType => "ScAddressType",
            .MuxedEd25519Account => "MuxedEd25519Account",
            .ScAddress => "ScAddress",
            .ScVec => "ScVec",
            .ScMap => "ScMap",
            .ScBytes => "ScBytes",
            .ScString => "ScString",
            .ScSymbol => "ScSymbol",
            .ScNonceKey => "ScNonceKey",
            .ScContractInstance => "ScContractInstance",
            .ScVal => "ScVal",
            .ScMapEntry => "ScMapEntry",
            .LedgerCloseMetaBatch => "LedgerCloseMetaBatch",
            .StoredTransactionSet => "StoredTransactionSet",
            .StoredDebugTransactionSet => "StoredDebugTransactionSet",
            .PersistedScpStateV0 => "PersistedScpStateV0",
            .PersistedScpStateV1 => "PersistedScpStateV1",
            .PersistedScpState => "PersistedScpState",
            .Thresholds => "Thresholds",
            .String32 => "String32",
            .String64 => "String64",
            .SequenceNumber => "SequenceNumber",
            .DataValue => "DataValue",
            .AssetCode4 => "AssetCode4",
            .AssetCode12 => "AssetCode12",
            .AssetType => "AssetType",
            .AssetCode => "AssetCode",
            .AlphaNum4 => "AlphaNum4",
            .AlphaNum12 => "AlphaNum12",
            .Asset => "Asset",
            .Price => "Price",
            .Liabilities => "Liabilities",
            .ThresholdIndexes => "ThresholdIndexes",
            .LedgerEntryType => "LedgerEntryType",
            .Signer => "Signer",
            .AccountFlags => "AccountFlags",
            .SponsorshipDescriptor => "SponsorshipDescriptor",
            .AccountEntryExtensionV3 => "AccountEntryExtensionV3",
            .AccountEntryExtensionV2 => "AccountEntryExtensionV2",
            .AccountEntryExtensionV2Ext => "AccountEntryExtensionV2Ext",
            .AccountEntryExtensionV1 => "AccountEntryExtensionV1",
            .AccountEntryExtensionV1Ext => "AccountEntryExtensionV1Ext",
            .AccountEntry => "AccountEntry",
            .AccountEntryExt => "AccountEntryExt",
            .TrustLineFlags => "TrustLineFlags",
            .LiquidityPoolType => "LiquidityPoolType",
            .TrustLineAsset => "TrustLineAsset",
            .TrustLineEntryExtensionV2 => "TrustLineEntryExtensionV2",
            .TrustLineEntryExtensionV2Ext => "TrustLineEntryExtensionV2Ext",
            .TrustLineEntry => "TrustLineEntry",
            .TrustLineEntryExt => "TrustLineEntryExt",
            .TrustLineEntryV1 => "TrustLineEntryV1",
            .TrustLineEntryV1Ext => "TrustLineEntryV1Ext",
            .OfferEntryFlags => "OfferEntryFlags",
            .OfferEntry => "OfferEntry",
            .OfferEntryExt => "OfferEntryExt",
            .DataEntry => "DataEntry",
            .DataEntryExt => "DataEntryExt",
            .ClaimPredicateType => "ClaimPredicateType",
            .ClaimPredicate => "ClaimPredicate",
            .ClaimantType => "ClaimantType",
            .Claimant => "Claimant",
            .ClaimantV0 => "ClaimantV0",
            .ClaimableBalanceFlags => "ClaimableBalanceFlags",
            .ClaimableBalanceEntryExtensionV1 => "ClaimableBalanceEntryExtensionV1",
            .ClaimableBalanceEntryExtensionV1Ext => "ClaimableBalanceEntryExtensionV1Ext",
            .ClaimableBalanceEntry => "ClaimableBalanceEntry",
            .ClaimableBalanceEntryExt => "ClaimableBalanceEntryExt",
            .LiquidityPoolConstantProductParameters => "LiquidityPoolConstantProductParameters",
            .LiquidityPoolEntry => "LiquidityPoolEntry",
            .LiquidityPoolEntryBody => "LiquidityPoolEntryBody",
            .LiquidityPoolEntryConstantProduct => "LiquidityPoolEntryConstantProduct",
            .ContractDataDurability => "ContractDataDurability",
            .ContractDataEntry => "ContractDataEntry",
            .ContractCodeCostInputs => "ContractCodeCostInputs",
            .ContractCodeEntry => "ContractCodeEntry",
            .ContractCodeEntryExt => "ContractCodeEntryExt",
            .ContractCodeEntryV1 => "ContractCodeEntryV1",
            .TtlEntry => "TtlEntry",
            .LedgerEntryExtensionV1 => "LedgerEntryExtensionV1",
            .LedgerEntryExtensionV1Ext => "LedgerEntryExtensionV1Ext",
            .LedgerEntry => "LedgerEntry",
            .LedgerEntryData => "LedgerEntryData",
            .LedgerEntryExt => "LedgerEntryExt",
            .LedgerKey => "LedgerKey",
            .LedgerKeyAccount => "LedgerKeyAccount",
            .LedgerKeyTrustLine => "LedgerKeyTrustLine",
            .LedgerKeyOffer => "LedgerKeyOffer",
            .LedgerKeyData => "LedgerKeyData",
            .LedgerKeyClaimableBalance => "LedgerKeyClaimableBalance",
            .LedgerKeyLiquidityPool => "LedgerKeyLiquidityPool",
            .LedgerKeyContractData => "LedgerKeyContractData",
            .LedgerKeyContractCode => "LedgerKeyContractCode",
            .LedgerKeyConfigSetting => "LedgerKeyConfigSetting",
            .LedgerKeyTtl => "LedgerKeyTtl",
            .EnvelopeType => "EnvelopeType",
            .BucketListType => "BucketListType",
            .BucketEntryType => "BucketEntryType",
            .HotArchiveBucketEntryType => "HotArchiveBucketEntryType",
            .BucketMetadata => "BucketMetadata",
            .BucketMetadataExt => "BucketMetadataExt",
            .BucketEntry => "BucketEntry",
            .HotArchiveBucketEntry => "HotArchiveBucketEntry",
            .UpgradeType => "UpgradeType",
            .StellarValueType => "StellarValueType",
            .LedgerCloseValueSignature => "LedgerCloseValueSignature",
            .StellarValue => "StellarValue",
            .StellarValueExt => "StellarValueExt",
            .LedgerHeaderFlags => "LedgerHeaderFlags",
            .LedgerHeaderExtensionV1 => "LedgerHeaderExtensionV1",
            .LedgerHeaderExtensionV1Ext => "LedgerHeaderExtensionV1Ext",
            .LedgerHeader => "LedgerHeader",
            .LedgerHeaderExt => "LedgerHeaderExt",
            .LedgerUpgradeType => "LedgerUpgradeType",
            .ConfigUpgradeSetKey => "ConfigUpgradeSetKey",
            .LedgerUpgrade => "LedgerUpgrade",
            .ConfigUpgradeSet => "ConfigUpgradeSet",
            .TxSetComponentType => "TxSetComponentType",
            .DependentTxCluster => "DependentTxCluster",
            .ParallelTxExecutionStage => "ParallelTxExecutionStage",
            .ParallelTxsComponent => "ParallelTxsComponent",
            .TxSetComponent => "TxSetComponent",
            .TxSetComponentTxsMaybeDiscountedFee => "TxSetComponentTxsMaybeDiscountedFee",
            .TransactionPhase => "TransactionPhase",
            .TransactionSet => "TransactionSet",
            .TransactionSetV1 => "TransactionSetV1",
            .GeneralizedTransactionSet => "GeneralizedTransactionSet",
            .TransactionResultPair => "TransactionResultPair",
            .TransactionResultSet => "TransactionResultSet",
            .TransactionHistoryEntry => "TransactionHistoryEntry",
            .TransactionHistoryEntryExt => "TransactionHistoryEntryExt",
            .TransactionHistoryResultEntry => "TransactionHistoryResultEntry",
            .TransactionHistoryResultEntryExt => "TransactionHistoryResultEntryExt",
            .LedgerHeaderHistoryEntry => "LedgerHeaderHistoryEntry",
            .LedgerHeaderHistoryEntryExt => "LedgerHeaderHistoryEntryExt",
            .LedgerScpMessages => "LedgerScpMessages",
            .ScpHistoryEntryV0 => "ScpHistoryEntryV0",
            .ScpHistoryEntry => "ScpHistoryEntry",
            .LedgerEntryChangeType => "LedgerEntryChangeType",
            .LedgerEntryChange => "LedgerEntryChange",
            .LedgerEntryChanges => "LedgerEntryChanges",
            .OperationMeta => "OperationMeta",
            .TransactionMetaV1 => "TransactionMetaV1",
            .TransactionMetaV2 => "TransactionMetaV2",
            .ContractEventType => "ContractEventType",
            .ContractEvent => "ContractEvent",
            .ContractEventBody => "ContractEventBody",
            .ContractEventV0 => "ContractEventV0",
            .DiagnosticEvent => "DiagnosticEvent",
            .SorobanTransactionMetaExtV1 => "SorobanTransactionMetaExtV1",
            .SorobanTransactionMetaExt => "SorobanTransactionMetaExt",
            .SorobanTransactionMeta => "SorobanTransactionMeta",
            .TransactionMetaV3 => "TransactionMetaV3",
            .OperationMetaV2 => "OperationMetaV2",
            .SorobanTransactionMetaV2 => "SorobanTransactionMetaV2",
            .TransactionEventStage => "TransactionEventStage",
            .TransactionEvent => "TransactionEvent",
            .TransactionMetaV4 => "TransactionMetaV4",
            .InvokeHostFunctionSuccessPreImage => "InvokeHostFunctionSuccessPreImage",
            .TransactionMeta => "TransactionMeta",
            .TransactionResultMeta => "TransactionResultMeta",
            .TransactionResultMetaV1 => "TransactionResultMetaV1",
            .UpgradeEntryMeta => "UpgradeEntryMeta",
            .LedgerCloseMetaV0 => "LedgerCloseMetaV0",
            .LedgerCloseMetaExtV1 => "LedgerCloseMetaExtV1",
            .LedgerCloseMetaExt => "LedgerCloseMetaExt",
            .LedgerCloseMetaV1 => "LedgerCloseMetaV1",
            .LedgerCloseMetaV2 => "LedgerCloseMetaV2",
            .LedgerCloseMeta => "LedgerCloseMeta",
            .ErrorCode => "ErrorCode",
            .SError => "SError",
            .SendMore => "SendMore",
            .SendMoreExtended => "SendMoreExtended",
            .AuthCert => "AuthCert",
            .Hello => "Hello",
            .Auth => "Auth",
            .IpAddrType => "IpAddrType",
            .PeerAddress => "PeerAddress",
            .PeerAddressIp => "PeerAddressIp",
            .MessageType => "MessageType",
            .DontHave => "DontHave",
            .SurveyMessageCommandType => "SurveyMessageCommandType",
            .SurveyMessageResponseType => "SurveyMessageResponseType",
            .TimeSlicedSurveyStartCollectingMessage => "TimeSlicedSurveyStartCollectingMessage",
            .SignedTimeSlicedSurveyStartCollectingMessage => "SignedTimeSlicedSurveyStartCollectingMessage",
            .TimeSlicedSurveyStopCollectingMessage => "TimeSlicedSurveyStopCollectingMessage",
            .SignedTimeSlicedSurveyStopCollectingMessage => "SignedTimeSlicedSurveyStopCollectingMessage",
            .SurveyRequestMessage => "SurveyRequestMessage",
            .TimeSlicedSurveyRequestMessage => "TimeSlicedSurveyRequestMessage",
            .SignedTimeSlicedSurveyRequestMessage => "SignedTimeSlicedSurveyRequestMessage",
            .EncryptedBody => "EncryptedBody",
            .SurveyResponseMessage => "SurveyResponseMessage",
            .TimeSlicedSurveyResponseMessage => "TimeSlicedSurveyResponseMessage",
            .SignedTimeSlicedSurveyResponseMessage => "SignedTimeSlicedSurveyResponseMessage",
            .PeerStats => "PeerStats",
            .TimeSlicedNodeData => "TimeSlicedNodeData",
            .TimeSlicedPeerData => "TimeSlicedPeerData",
            .TimeSlicedPeerDataList => "TimeSlicedPeerDataList",
            .TopologyResponseBodyV2 => "TopologyResponseBodyV2",
            .SurveyResponseBody => "SurveyResponseBody",
            .TxAdvertVector => "TxAdvertVector",
            .FloodAdvert => "FloodAdvert",
            .TxDemandVector => "TxDemandVector",
            .FloodDemand => "FloodDemand",
            .StellarMessage => "StellarMessage",
            .AuthenticatedMessage => "AuthenticatedMessage",
            .AuthenticatedMessageV0 => "AuthenticatedMessageV0",
            .LiquidityPoolParameters => "LiquidityPoolParameters",
            .MuxedAccount => "MuxedAccount",
            .MuxedAccountMed25519 => "MuxedAccountMed25519",
            .DecoratedSignature => "DecoratedSignature",
            .OperationType => "OperationType",
            .CreateAccountOp => "CreateAccountOp",
            .PaymentOp => "PaymentOp",
            .PathPaymentStrictReceiveOp => "PathPaymentStrictReceiveOp",
            .PathPaymentStrictSendOp => "PathPaymentStrictSendOp",
            .ManageSellOfferOp => "ManageSellOfferOp",
            .ManageBuyOfferOp => "ManageBuyOfferOp",
            .CreatePassiveSellOfferOp => "CreatePassiveSellOfferOp",
            .SetOptionsOp => "SetOptionsOp",
            .ChangeTrustAsset => "ChangeTrustAsset",
            .ChangeTrustOp => "ChangeTrustOp",
            .AllowTrustOp => "AllowTrustOp",
            .ManageDataOp => "ManageDataOp",
            .BumpSequenceOp => "BumpSequenceOp",
            .CreateClaimableBalanceOp => "CreateClaimableBalanceOp",
            .ClaimClaimableBalanceOp => "ClaimClaimableBalanceOp",
            .BeginSponsoringFutureReservesOp => "BeginSponsoringFutureReservesOp",
            .RevokeSponsorshipType => "RevokeSponsorshipType",
            .RevokeSponsorshipOp => "RevokeSponsorshipOp",
            .RevokeSponsorshipOpSigner => "RevokeSponsorshipOpSigner",
            .ClawbackOp => "ClawbackOp",
            .ClawbackClaimableBalanceOp => "ClawbackClaimableBalanceOp",
            .SetTrustLineFlagsOp => "SetTrustLineFlagsOp",
            .LiquidityPoolDepositOp => "LiquidityPoolDepositOp",
            .LiquidityPoolWithdrawOp => "LiquidityPoolWithdrawOp",
            .HostFunctionType => "HostFunctionType",
            .ContractIdPreimageType => "ContractIdPreimageType",
            .ContractIdPreimage => "ContractIdPreimage",
            .ContractIdPreimageFromAddress => "ContractIdPreimageFromAddress",
            .CreateContractArgs => "CreateContractArgs",
            .CreateContractArgsV2 => "CreateContractArgsV2",
            .InvokeContractArgs => "InvokeContractArgs",
            .HostFunction => "HostFunction",
            .SorobanAuthorizedFunctionType => "SorobanAuthorizedFunctionType",
            .SorobanAuthorizedFunction => "SorobanAuthorizedFunction",
            .SorobanAuthorizedInvocation => "SorobanAuthorizedInvocation",
            .SorobanAddressCredentials => "SorobanAddressCredentials",
            .SorobanCredentialsType => "SorobanCredentialsType",
            .SorobanCredentials => "SorobanCredentials",
            .SorobanAuthorizationEntry => "SorobanAuthorizationEntry",
            .SorobanAuthorizationEntries => "SorobanAuthorizationEntries",
            .InvokeHostFunctionOp => "InvokeHostFunctionOp",
            .ExtendFootprintTtlOp => "ExtendFootprintTtlOp",
            .RestoreFootprintOp => "RestoreFootprintOp",
            .Operation => "Operation",
            .OperationBody => "OperationBody",
            .HashIdPreimage => "HashIdPreimage",
            .HashIdPreimageOperationId => "HashIdPreimageOperationId",
            .HashIdPreimageRevokeId => "HashIdPreimageRevokeId",
            .HashIdPreimageContractId => "HashIdPreimageContractId",
            .HashIdPreimageSorobanAuthorization => "HashIdPreimageSorobanAuthorization",
            .MemoType => "MemoType",
            .Memo => "Memo",
            .TimeBounds => "TimeBounds",
            .LedgerBounds => "LedgerBounds",
            .PreconditionsV2 => "PreconditionsV2",
            .PreconditionType => "PreconditionType",
            .Preconditions => "Preconditions",
            .LedgerFootprint => "LedgerFootprint",
            .SorobanResources => "SorobanResources",
            .SorobanResourcesExtV0 => "SorobanResourcesExtV0",
            .SorobanTransactionData => "SorobanTransactionData",
            .SorobanTransactionDataExt => "SorobanTransactionDataExt",
            .TransactionV0 => "TransactionV0",
            .TransactionV0Ext => "TransactionV0Ext",
            .TransactionV0Envelope => "TransactionV0Envelope",
            .Transaction => "Transaction",
            .TransactionExt => "TransactionExt",
            .TransactionV1Envelope => "TransactionV1Envelope",
            .FeeBumpTransaction => "FeeBumpTransaction",
            .FeeBumpTransactionInnerTx => "FeeBumpTransactionInnerTx",
            .FeeBumpTransactionExt => "FeeBumpTransactionExt",
            .FeeBumpTransactionEnvelope => "FeeBumpTransactionEnvelope",
            .TransactionEnvelope => "TransactionEnvelope",
            .TransactionSignaturePayload => "TransactionSignaturePayload",
            .TransactionSignaturePayloadTaggedTransaction => "TransactionSignaturePayloadTaggedTransaction",
            .ClaimAtomType => "ClaimAtomType",
            .ClaimOfferAtomV0 => "ClaimOfferAtomV0",
            .ClaimOfferAtom => "ClaimOfferAtom",
            .ClaimLiquidityAtom => "ClaimLiquidityAtom",
            .ClaimAtom => "ClaimAtom",
            .CreateAccountResultCode => "CreateAccountResultCode",
            .CreateAccountResult => "CreateAccountResult",
            .PaymentResultCode => "PaymentResultCode",
            .PaymentResult => "PaymentResult",
            .PathPaymentStrictReceiveResultCode => "PathPaymentStrictReceiveResultCode",
            .SimplePaymentResult => "SimplePaymentResult",
            .PathPaymentStrictReceiveResult => "PathPaymentStrictReceiveResult",
            .PathPaymentStrictReceiveResultSuccess => "PathPaymentStrictReceiveResultSuccess",
            .PathPaymentStrictSendResultCode => "PathPaymentStrictSendResultCode",
            .PathPaymentStrictSendResult => "PathPaymentStrictSendResult",
            .PathPaymentStrictSendResultSuccess => "PathPaymentStrictSendResultSuccess",
            .ManageSellOfferResultCode => "ManageSellOfferResultCode",
            .ManageOfferEffect => "ManageOfferEffect",
            .ManageOfferSuccessResult => "ManageOfferSuccessResult",
            .ManageOfferSuccessResultOffer => "ManageOfferSuccessResultOffer",
            .ManageSellOfferResult => "ManageSellOfferResult",
            .ManageBuyOfferResultCode => "ManageBuyOfferResultCode",
            .ManageBuyOfferResult => "ManageBuyOfferResult",
            .SetOptionsResultCode => "SetOptionsResultCode",
            .SetOptionsResult => "SetOptionsResult",
            .ChangeTrustResultCode => "ChangeTrustResultCode",
            .ChangeTrustResult => "ChangeTrustResult",
            .AllowTrustResultCode => "AllowTrustResultCode",
            .AllowTrustResult => "AllowTrustResult",
            .AccountMergeResultCode => "AccountMergeResultCode",
            .AccountMergeResult => "AccountMergeResult",
            .InflationResultCode => "InflationResultCode",
            .InflationPayout => "InflationPayout",
            .InflationResult => "InflationResult",
            .ManageDataResultCode => "ManageDataResultCode",
            .ManageDataResult => "ManageDataResult",
            .BumpSequenceResultCode => "BumpSequenceResultCode",
            .BumpSequenceResult => "BumpSequenceResult",
            .CreateClaimableBalanceResultCode => "CreateClaimableBalanceResultCode",
            .CreateClaimableBalanceResult => "CreateClaimableBalanceResult",
            .ClaimClaimableBalanceResultCode => "ClaimClaimableBalanceResultCode",
            .ClaimClaimableBalanceResult => "ClaimClaimableBalanceResult",
            .BeginSponsoringFutureReservesResultCode => "BeginSponsoringFutureReservesResultCode",
            .BeginSponsoringFutureReservesResult => "BeginSponsoringFutureReservesResult",
            .EndSponsoringFutureReservesResultCode => "EndSponsoringFutureReservesResultCode",
            .EndSponsoringFutureReservesResult => "EndSponsoringFutureReservesResult",
            .RevokeSponsorshipResultCode => "RevokeSponsorshipResultCode",
            .RevokeSponsorshipResult => "RevokeSponsorshipResult",
            .ClawbackResultCode => "ClawbackResultCode",
            .ClawbackResult => "ClawbackResult",
            .ClawbackClaimableBalanceResultCode => "ClawbackClaimableBalanceResultCode",
            .ClawbackClaimableBalanceResult => "ClawbackClaimableBalanceResult",
            .SetTrustLineFlagsResultCode => "SetTrustLineFlagsResultCode",
            .SetTrustLineFlagsResult => "SetTrustLineFlagsResult",
            .LiquidityPoolDepositResultCode => "LiquidityPoolDepositResultCode",
            .LiquidityPoolDepositResult => "LiquidityPoolDepositResult",
            .LiquidityPoolWithdrawResultCode => "LiquidityPoolWithdrawResultCode",
            .LiquidityPoolWithdrawResult => "LiquidityPoolWithdrawResult",
            .InvokeHostFunctionResultCode => "InvokeHostFunctionResultCode",
            .InvokeHostFunctionResult => "InvokeHostFunctionResult",
            .ExtendFootprintTtlResultCode => "ExtendFootprintTtlResultCode",
            .ExtendFootprintTtlResult => "ExtendFootprintTtlResult",
            .RestoreFootprintResultCode => "RestoreFootprintResultCode",
            .RestoreFootprintResult => "RestoreFootprintResult",
            .OperationResultCode => "OperationResultCode",
            .OperationResult => "OperationResult",
            .OperationResultTr => "OperationResultTr",
            .TransactionResultCode => "TransactionResultCode",
            .InnerTransactionResult => "InnerTransactionResult",
            .InnerTransactionResultResult => "InnerTransactionResultResult",
            .InnerTransactionResultExt => "InnerTransactionResultExt",
            .InnerTransactionResultPair => "InnerTransactionResultPair",
            .TransactionResult => "TransactionResult",
            .TransactionResultResult => "TransactionResultResult",
            .TransactionResultExt => "TransactionResultExt",
            .Hash => "Hash",
            .Uint256 => "Uint256",
            .Uint32 => "Uint32",
            .Int32 => "Int32",
            .Uint64 => "Uint64",
            .Int64 => "Int64",
            .TimePoint => "TimePoint",
            .Duration => "Duration",
            .ExtensionPoint => "ExtensionPoint",
            .CryptoKeyType => "CryptoKeyType",
            .PublicKeyType => "PublicKeyType",
            .SignerKeyType => "SignerKeyType",
            .PublicKey => "PublicKey",
            .SignerKey => "SignerKey",
            .SignerKeyEd25519SignedPayload => "SignerKeyEd25519SignedPayload",
            .Signature => "Signature",
            .SignatureHint => "SignatureHint",
            .NodeId => "NodeId",
            .AccountId => "AccountId",
            .ContractId => "ContractId",
            .Curve25519Secret => "Curve25519Secret",
            .Curve25519Public => "Curve25519Public",
            .HmacSha256Key => "HmacSha256Key",
            .HmacSha256Mac => "HmacSha256Mac",
            .ShortHashSeed => "ShortHashSeed",
            .BinaryFuseFilterType => "BinaryFuseFilterType",
            .SerializedBinaryFuseFilter => "SerializedBinaryFuseFilter",
            .PoolId => "PoolId",
            .ClaimableBalanceIdType => "ClaimableBalanceIdType",
            .ClaimableBalanceId => "ClaimableBalanceId",
        };
    }
};
