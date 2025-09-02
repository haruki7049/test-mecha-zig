const mecha = @import("mecha");
const std = @import("std");

const testing = std.testing;

const Chunk = struct {
    id: [4]u8,
    size: [4]u8,
    four_cc: [4]u8,
    data: []const u8,
};

const char = mecha.ascii.ascii;
const four_chars = char.manyN(4, .{});

const number = mecha.ascii.range('0', '9');
const four_numbers = number.manyN(4, .{});

const id = four_chars;
const size = four_numbers;
const four_cc = four_chars;
const data = char.many(.{});

const chunk = mecha.combine(.{
    id,
    size,
    four_cc,
    data,
}).map(mecha.toStruct(Chunk));

test "sexpr" {
    const allocator = testing.allocator;

    const default_value = try chunk.parse(allocator, &[_]u8{ 'R', 'I', 'F', 'F', 'W', 'A', 'V', 'E', 0x00, 0x00, 0x00, 0x00 });
    std.debug.print("{any}\n", .{default_value});
}
