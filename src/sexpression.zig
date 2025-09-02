const mecha = @import("mecha");
const std = @import("std");

const testing = std.testing;

fn token(comptime parser: anytype) mecha.Parser(void) {
    return mecha.combine(.{ parser.discard(), whitespace });
}

const value = mecha.oneOf(.{
    word,
    sexpr,
});

fn valueRef() mecha.Parser(void) {
    return value;
}

const word = mecha.oneOf(.{
    token(mecha.string("hoge")),
    token(mecha.string("fuga")),
});

const whitespace = mecha.oneOf(.{
    mecha.ascii.char(0x20), // SPC
    mecha.ascii.char(0x0A), // LF
    mecha.ascii.char(0x0D), // CR
    mecha.ascii.char(0x09), // BS
}).many(.{ .collect = false }).discard();

const element = mecha.ref(valueRef);
const left_parenthesis = token(mecha.ascii.char('('));
const right_parenthesis = token(mecha.ascii.char(')'));
const sexpr = mecha.combine(.{
    whitespace,
    left_parenthesis,

    mecha.combine(.{ whitespace, element })
        .many(.{ .collect = false })
        .discard(),

    right_parenthesis,
});

const expression = mecha.combine(.{ sexpr });

test "expression" {
    const allocator = testing.allocator;

    const default_value = try expression.parse(allocator, "( hoge )");
    std.debug.print("{any}\n", .{default_value});

    const two_token_value = try expression.parse(allocator, "( hoge fuga )");
    std.debug.print("{any}\n", .{two_token_value});

    const recursed_value = try expression.parse(allocator, "( hoge ( fuga ) )");
    std.debug.print("{any}\n", .{recursed_value});

    const more_recursed_value = try expression.parse(allocator, "( hoge ( ( hoge hoge ) fuga ) )");
    std.debug.print("{any}\n", .{more_recursed_value});
}
