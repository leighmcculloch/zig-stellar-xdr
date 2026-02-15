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
