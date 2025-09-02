const mecha = @import("mecha");
const std = @import("std");

const testing = std.testing;

const Expression = struct {
    const SExpression = struct {
        values: []const Value,
    };
    const Word = enum {
        Hoge,
        Fuga,
    };
    const Value = union(enum) {
        sexpr: SExpression,
        word: Word,
    };
};

const value = mecha.oneOf(.{
    word.map((struct {
        fn f(w: Expression.Word) Expression.Value {
            return .{ .word = w };
        }
    }).f),
    sexpression.map((struct {
        fn f(w: Expression.SExpression) Expression.Value {
            return .{ .sexpr = w };
        }
    }).f),
});

fn valueRef() mecha.Parser(Expression.Value) {
    return value;
}

const word = mecha.oneOf(.{
    wordToken(mecha.string("hoge"), .Hoge),
    wordToken(mecha.string("fuga"), .Fuga),
});

fn wordToken(comptime parser: anytype, w: Expression.Word) mecha.Parser(Expression.Word) {
    return mecha.combine(.{ parser, whitespace }).map((struct {
        fn f(_: []const u8) Expression.Word {
            return w;
        }
    }).f);
}

const whitespace = mecha.oneOf(.{
    mecha.ascii.char(0x20), // SPC
    mecha.ascii.char(0x0A), // LF
    mecha.ascii.char(0x0D), // CR
    mecha.ascii.char(0x09), // BS
}).many(.{ .collect = false }).discard();

fn discardToken(comptime parser: anytype) mecha.Parser(void) {
    return mecha.combine(.{ parser.discard(), whitespace });
}

const element = mecha.ref(valueRef);
const left_parenthesis = discardToken(mecha.ascii.char('('));
const right_parenthesis = discardToken(mecha.ascii.char(')'));
const sexpression = mecha.combine(.{
    whitespace,
    left_parenthesis,

    mecha.combine(.{ whitespace, element })
        .many(.{ .collect = true }),

    right_parenthesis,
}).map(mecha.toStruct(Expression.SExpression));

test "sexpr" {
    const allocator = testing.allocator;

    const default_value = try sexpression.parse(allocator, "( hoge )");
    defer allocator.free(default_value.value.ok.values);
    std.debug.print("{any}\n", .{default_value});

    const two_token_value = try sexpression.parse(allocator, "( hoge fuga )");
    defer allocator.free(two_token_value.value.ok.values);
    std.debug.print("{any}\n", .{two_token_value});

    const recursed_value = try sexpression.parse(allocator, "( hoge ( fuga ) )");
    defer freeValue(allocator, .{ .sexpr = recursed_value.value.ok });
    std.debug.print("{any}\n", .{recursed_value});

    const more_recursed_value = try sexpression.parse(allocator, "( hoge ( ( hoge hoge ) fuga ) )");
    defer freeValue(allocator, .{ .sexpr = more_recursed_value.value.ok });
    std.debug.print("{any}\n", .{more_recursed_value});
}

fn freeValue(allocator: std.mem.Allocator, val: Expression.Value) void {
    switch (val) {
        .word => {},
        .sexpr => {
            const sexpr = val.sexpr;
            // ネストされた値も再帰的に解放
            for (sexpr.values) |v| {
                freeValue(allocator, v);
            }
            allocator.free(sexpr.values);
        },
    }
}
