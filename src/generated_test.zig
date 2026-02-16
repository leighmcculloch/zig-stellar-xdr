const std = @import("std");
const base64 = std.base64;
const xdr = @import("generated.zig");

fn roundtrip(comptime T: type, input: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Decode base64 to XDR bytes.
    const decoded_len = try base64.standard.Decoder.calcSizeForSlice(input);
    const decoded = try allocator.alloc(u8, decoded_len);
    try base64.standard.Decoder.decode(decoded, input);

    // Decode XDR bytes to value.
    var read_stream = std.io.fixedBufferStream(decoded);
    const val = try xdr.xdrDecode(T, allocator, read_stream.reader());

    // Encode value back to XDR bytes.
    var buf: std.ArrayList(u8) = .{};
    defer buf.deinit(allocator);
    try xdr.xdrEncode(T, buf.writer(allocator), val);

    // Encode XDR bytes to base64.
    const encoded = try allocator.alloc(u8, base64.standard.Encoder.calcSize(buf.items.len));
    _ = base64.standard.Encoder.encode(encoded, buf.items);

    // Compare.
    try std.testing.expectEqualStrings(input, encoded);
}

test "roundtrip ScVal" {
    try roundtrip(xdr.ScVal, "AAAABrlxYNcR1m9w");
}

test "roundtrip TransactionEnvelope" {
    try roundtrip(xdr.TransactionEnvelope, "AAAAAgAAAQCqwcvuQdSO/E2Mf/gUTbYryEc6gs/nEXl+OoDjLTtmJMhpVLoohnLxxbOXYS9czEti9zftAAAAAZTxCFrVVZB3ReQf0MhplZQAAAACsS1EGbMjRswAAAAAAAAAAAAAAAG+jADyAAAAARgAAAA=");
}

test "roundtrip LedgerCloseMeta" {
    try roundtrip(xdr.LedgerCloseMeta, "AAAAAQAAAAEAAAAA4T8aikBOmqf7Kqoi6LEs638UZgVkXbkRWDIGywQwf94vPUphgto6GvA2aW16xtKupWu5OmeJxHkhhPdgosY0sDFARfhUhgoRQdIVWiVpt0iGwp7oHgOm5bU7Z3M5zfXwC3eR+6yCPFGKF/ax1nAgSdpsm/0AAAABAAAAAxYGigAAAAABAAAAAJUX+Ne2D1TCtu1WEFmFtve8cQ01BPeGiyh93Gmv86A3AAAAAEVXTIhAwsdYHmk9plMr97wT0T236tMGjUnfpBosFEmRcRNSIPyMywInbCdAin4b/MPLDFlkoPl1gNe9sN+DYxcgo3Xfg8iWlUVfWjL/iURAsiYlul6afpr9cOw5BXLdCOsAeTg5m7zgLutxoc7CKIWNvgOb3TDkg/tBTBhcGgyzphNJZ1rFxSv7+2vwJFkdsQLbom5vfFw1viKuSNGKlnp8kYNva8DQAplSUNTT19hyalR/zDOxNLMPuIToEctIwF5vAesfaTzpQcFaZrLROdZKHvEhnLn29VlDXDDaB9oKzLEDeRSrq9/QdDonAAAAAAAAAAAAAAAB+I9ddm8oHe63FhgJIzHOQ1pqdPUch7AisqqtKl4IiWwAAAAAAAAAAAAAAAIAAAAHWIF8/wAAAAMAAAAD8x44OgAAAAcAAAAApntontT7GMF9u6qcZmBLkFiAhkBf+tt/qWW/l6iI+FEAAAAAAAAAAQAAAAAAAAAAAAAABLv/SOsAAAAFzHQqMcevWgE2ZPcvjus7xV6RXjDPdSM2oYzapVoRnuwAAAAAAAAAAitp0O7dJBAJ+f2woQAAAAB/sAxIghR/N6M9kLF3aN23L79JPXJ0VJJZHdmtvUVdyAAAAALBuhWRbADZPjn7EFEAAAAALdnKkAFdJlc43rmRs/jxwMKB6MWb4+o6n1vCQdyx4wUTw7w/reFaQQEofG+cB7uIbSrukeUqRT1KOqBebYNHgTjxq8MAAAAAAAAAAMDXxCoAAAAGAAAAAAAAAASYMIpi+YnK37tcb0dQdNO2IbClRMyNAsq6xOi1O6RPlwAAAAiQXOcjLIxcggAAAAAAAAAD3oCAswAAAAAAAAAEJLupqwAAAAIAAAABSIPV2QAAAAcAAAABAAAAAAAAAACq1+C+zwMf0EqbZjoCFYV6+JplWv+DwjiJmm3CL+Dyr6LJVv3Nk0iq16vI0tCbW8LBJYEbgnzZ9e6cn8hMaJU4+ujUOhUTrj0AAAABdAAAAAAAAAEAAAAAAAAAAAAAAAIAAAACAAAAAC43w6v8R44OhYeNl/03Y8RS6JsjpEsJOSAho6ZPcKcqere2kHrdN40AAAAAdWh1S77GgMgAAAAAAAAAAA==");
}

fn decodeFromBase64(comptime T: type, allocator: std.mem.Allocator, encoded: []const u8) !T {
    const decoded_len = try base64.standard.Decoder.calcSizeForSlice(encoded);
    const decoded = try allocator.alloc(u8, decoded_len);
    try base64.standard.Decoder.decode(decoded, encoded);
    var stream = std.io.fixedBufferStream(decoded);
    return try xdr.xdrDecode(T, allocator, stream.reader());
}

fn encodeToBase64(comptime T: type, allocator: std.mem.Allocator, val: T) ![]const u8 {
    var buf: std.ArrayList(u8) = .{};
    defer buf.deinit(allocator);
    try xdr.xdrEncode(T, buf.writer(allocator), val);
    const encoded = try allocator.alloc(u8, base64.standard.Encoder.calcSize(buf.items.len));
    _ = base64.standard.Encoder.encode(encoded, buf.items);
    return encoded;
}

// --- Decode and access field values ---

test "decode ScVal and access fields" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const val = try decodeFromBase64(xdr.ScVal, arena.allocator(), "AAAABrlxYNcR1m9w");
    try std.testing.expectEqual(xdr.ScVal.I64, @as(std.meta.Tag(xdr.ScVal), val));
    try std.testing.expectEqual(@as(i64, -5084176027491078288), val.I64);
}

test "decode TransactionEnvelope and access fields" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const val = try decodeFromBase64(xdr.TransactionEnvelope, arena.allocator(), "AAAAAgAAAQCqwcvuQdSO/E2Mf/gUTbYryEc6gs/nEXl+OoDjLTtmJMhpVLoohnLxxbOXYS9czEti9zftAAAAAZTxCFrVVZB3ReQf0MhplZQAAAACsS1EGbMjRswAAAAAAAAAAAAAAAG+jADyAAAAARgAAAA=");
    try std.testing.expectEqual(xdr.TransactionEnvelope.Tx, @as(std.meta.Tag(xdr.TransactionEnvelope), val));

    const tx_env = val.Tx;
    const tx = tx_env.tx;

    // Source account is a muxed ed25519 key.
    try std.testing.expectEqual(xdr.MuxedAccount.MuxedEd25519, @as(std.meta.Tag(xdr.MuxedAccount), tx.source_account));
    const muxed = tx.source_account.MuxedEd25519;
    try std.testing.expectEqual(@as(u64, 12304339881120009980), muxed.id);
    const expected_ed25519 = [32]u8{
        0x4D, 0x8C, 0x7F, 0xF8, 0x14, 0x4D, 0xB6, 0x2B, 0xC8, 0x47, 0x3A, 0x82, 0xCF, 0xE7, 0x11, 0x79,
        0x7E, 0x3A, 0x80, 0xE3, 0x2D, 0x3B, 0x66, 0x24, 0xC8, 0x69, 0x54, 0xBA, 0x28, 0x86, 0x72, 0xF1,
    };
    try std.testing.expectEqual(expected_ed25519, muxed.ed25519.value);

    // Fee, sequence number.
    try std.testing.expectEqual(@as(u32, 3316881249), tx.fee);
    try std.testing.expectEqual(@as(i64, 3412827241794975725), tx.seq_num.value);

    // Preconditions (TimeBounds).
    try std.testing.expectEqual(xdr.Preconditions.Time, @as(std.meta.Tag(xdr.Preconditions), tx.cond));
    try std.testing.expectEqual(@as(u64, 10732368573219836023), tx.cond.Time.min_time.value);
    try std.testing.expectEqual(@as(u64, 5036185264883078548), tx.cond.Time.max_time.value);

    // Memo (Id).
    try std.testing.expectEqual(xdr.Memo.Id, @as(std.meta.Tag(xdr.Memo), tx.memo));
    try std.testing.expectEqual(@as(u64, 12766935395835528908), tx.memo.Id);

    // Operations (empty).
    try std.testing.expectEqual(@as(usize, 0), tx.operations.data.len);

    // Extension (V0).
    try std.testing.expectEqual(xdr.TransactionExt.V0, @as(std.meta.Tag(xdr.TransactionExt), tx.ext));

    // Signatures.
    try std.testing.expectEqual(@as(usize, 1), tx_env.signatures.data.len);
}

test "decode LedgerCloseMeta and access fields" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const val = try decodeFromBase64(xdr.LedgerCloseMeta, arena.allocator(), "AAAAAQAAAAEAAAAA4T8aikBOmqf7Kqoi6LEs638UZgVkXbkRWDIGywQwf94vPUphgto6GvA2aW16xtKupWu5OmeJxHkhhPdgosY0sDFARfhUhgoRQdIVWiVpt0iGwp7oHgOm5bU7Z3M5zfXwC3eR+6yCPFGKF/ax1nAgSdpsm/0AAAABAAAAAxYGigAAAAABAAAAAJUX+Ne2D1TCtu1WEFmFtve8cQ01BPeGiyh93Gmv86A3AAAAAEVXTIhAwsdYHmk9plMr97wT0T236tMGjUnfpBosFEmRcRNSIPyMywInbCdAin4b/MPLDFlkoPl1gNe9sN+DYxcgo3Xfg8iWlUVfWjL/iURAsiYlul6afpr9cOw5BXLdCOsAeTg5m7zgLutxoc7CKIWNvgOb3TDkg/tBTBhcGgyzphNJZ1rFxSv7+2vwJFkdsQLbom5vfFw1viKuSNGKlnp8kYNva8DQAplSUNTT19hyalR/zDOxNLMPuIToEctIwF5vAesfaTzpQcFaZrLROdZKHvEhnLn29VlDXDDaB9oKzLEDeRSrq9/QdDonAAAAAAAAAAAAAAAB+I9ddm8oHe63FhgJIzHOQ1pqdPUch7AisqqtKl4IiWwAAAAAAAAAAAAAAAIAAAAHWIF8/wAAAAMAAAAD8x44OgAAAAcAAAAApntontT7GMF9u6qcZmBLkFiAhkBf+tt/qWW/l6iI+FEAAAAAAAAAAQAAAAAAAAAAAAAABLv/SOsAAAAFzHQqMcevWgE2ZPcvjus7xV6RXjDPdSM2oYzapVoRnuwAAAAAAAAAAitp0O7dJBAJ+f2woQAAAAB/sAxIghR/N6M9kLF3aN23L79JPXJ0VJJZHdmtvUVdyAAAAALBuhWRbADZPjn7EFEAAAAALdnKkAFdJlc43rmRs/jxwMKB6MWb4+o6n1vCQdyx4wUTw7w/reFaQQEofG+cB7uIbSrukeUqRT1KOqBebYNHgTjxq8MAAAAAAAAAAMDXxCoAAAAGAAAAAAAAAASYMIpi+YnK37tcb0dQdNO2IbClRMyNAsq6xOi1O6RPlwAAAAiQXOcjLIxcggAAAAAAAAAD3oCAswAAAAAAAAAEJLupqwAAAAIAAAABSIPV2QAAAAcAAAABAAAAAAAAAACq1+C+zwMf0EqbZjoCFYV6+JplWv+DwjiJmm3CL+Dyr6LJVv3Nk0iq16vI0tCbW8LBJYEbgnzZ9e6cn8hMaJU4+ujUOhUTrj0AAAABdAAAAAAAAAEAAAAAAAAAAAAAAAIAAAACAAAAAC43w6v8R44OhYeNl/03Y8RS6JsjpEsJOSAho6ZPcKcqere2kHrdN40AAAAAdWh1S77GgMgAAAAAAAAAAA==");
    try std.testing.expectEqual(xdr.LedgerCloseMeta.V1, @as(std.meta.Tag(xdr.LedgerCloseMeta), val));

    const v1 = val.V1;
    const header = v1.ledger_header.header;

    // Ledger header fields.
    try std.testing.expectEqual(@as(u32, 4030097773), header.ledger_version);
    try std.testing.expectEqual(@as(u32, 547583455), header.ledger_seq);
    try std.testing.expectEqual(@as(i64, -8950738691540690382), header.total_coins);
    try std.testing.expectEqual(@as(i64, -33420477571127878), header.fee_pool);
    try std.testing.expectEqual(@as(u32, 3942676792), header.base_fee);
    try std.testing.expectEqual(@as(u32, 966507744), header.base_reserve);
    try std.testing.expectEqual(@as(u32, 787181985), header.max_tx_set_size);

    // Transaction set.
    try std.testing.expectEqual(xdr.GeneralizedTransactionSet.V1, @as(std.meta.Tag(xdr.GeneralizedTransactionSet), v1.tx_set));

    // Counts.
    try std.testing.expectEqual(@as(usize, 0), v1.tx_processing.len);
    try std.testing.expectEqual(@as(usize, 2), v1.upgrades_processing.len);
    try std.testing.expectEqual(@as(usize, 0), v1.scp_info.len);
}

// --- Hand-craft values and encode ---

test "hand-craft ScVal and encode" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const val = xdr.ScVal{ .I64 = -5084176027491078288 };
    const encoded = try encodeToBase64(xdr.ScVal, arena.allocator(), val);
    try std.testing.expectEqualStrings("AAAABrlxYNcR1m9w", encoded);
}

test "hand-craft TransactionEnvelope and encode" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Decode the expected value so we can copy the signature bytes exactly.
    const expected_b64 = "AAAAAgAAAQCqwcvuQdSO/E2Mf/gUTbYryEc6gs/nEXl+OoDjLTtmJMhpVLoohnLxxbOXYS9czEti9zftAAAAAZTxCFrVVZB3ReQf0MhplZQAAAACsS1EGbMjRswAAAAAAAAAAAAAAAG+jADyAAAAARgAAAA=";
    const ref = try decodeFromBase64(xdr.TransactionEnvelope, allocator, expected_b64);
    const ref_sig = ref.Tx.signatures.data[0];

    // Construct the operations BoundedArray (empty).
    const empty_ops = try allocator.alloc(xdr.Operation, 0);

    // Construct the signatures BoundedArray (1 entry, copied from decoded).
    const sigs = try allocator.alloc(xdr.DecoratedSignature, 1);
    sigs[0] = ref_sig;

    const val = xdr.TransactionEnvelope{
        .Tx = .{
            .tx = .{
                .source_account = .{
                    .MuxedEd25519 = .{
                        .id = 12304339881120009980,
                        .ed25519 = .{ .value = .{
                            0x4D, 0x8C, 0x7F, 0xF8, 0x14, 0x4D, 0xB6, 0x2B, 0xC8, 0x47, 0x3A, 0x82, 0xCF, 0xE7, 0x11, 0x79,
                            0x7E, 0x3A, 0x80, 0xE3, 0x2D, 0x3B, 0x66, 0x24, 0xC8, 0x69, 0x54, 0xBA, 0x28, 0x86, 0x72, 0xF1,
                        } },
                    },
                },
                .fee = 3316881249,
                .seq_num = .{ .value = 3412827241794975725 },
                .cond = .{
                    .Time = .{
                        .min_time = .{ .value = 10732368573219836023 },
                        .max_time = .{ .value = 5036185264883078548 },
                    },
                },
                .memo = .{ .Id = 12766935395835528908 },
                .operations = try xdr.BoundedArray(xdr.Operation, 100).init(empty_ops),
                .ext = .{ .V0 = {} },
            },
            .signatures = try xdr.BoundedArray(xdr.DecoratedSignature, 20).init(sigs),
        },
    };

    const encoded = try encodeToBase64(xdr.TransactionEnvelope, allocator, val);
    try std.testing.expectEqualStrings(expected_b64, encoded);
}
