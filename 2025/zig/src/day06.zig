const std = @import("std");
const Allocator = std.mem.Allocator;

const input = @embedFile("day06_input.txt");

const Context = struct {
    allocator: Allocator,
    numbers: [][]const u8,
    operators: []u8,
};

const whitespace_chars = &[_]u8{ ' ', '\t', '\n', '\r' };

fn parse(allocator: Allocator, inputStr: []const u8) !Context {
    var inputsAL = try std.ArrayList([]const u8).initCapacity(allocator, 10000);
    defer inputsAL.deinit(allocator);

    var it = std.mem.tokenizeScalar(u8, inputStr, '\n');
    while (it.next()) |line| {
        if (line.len == 0) continue;
        try inputsAL.append(allocator, line);
    }
    const inputs = try inputsAL.toOwnedSlice(allocator);

    var numbersAL = try std.ArrayList([]const u8).initCapacity(allocator, 10000);
    defer numbersAL.deinit(allocator);
    for (0..(inputs.len - 1)) |i| {
        const line = inputs[i];
        try numbersAL.append(allocator, line);
    }
    const numbers = try numbersAL.toOwnedSlice(allocator);

    var operatorsAL = try std.ArrayList(u8).initCapacity(allocator, 10000);
    var parts = std.mem.tokenizeScalar(u8, inputs[inputs.len - 1], ' ');
    while (parts.next()) |part| {
        const value = std.mem.trim(u8, part, whitespace_chars);
        try operatorsAL.append(allocator, value[0]);
    }
    const operators = try operatorsAL.toOwnedSlice(allocator);

    return Context{
        .allocator = allocator,
        .numbers = numbers,
        .operators = operators,
    };
}

pub fn part1(ctx: Context) !i64 {
    var result: i64 = 0;

    var numbersAL = try std.ArrayList([]i64).initCapacity(ctx.allocator, 10000);
    for (ctx.numbers) |row| {
        var rowAL = try std.ArrayList(i64).initCapacity(ctx.allocator, 10000);
        var parts = std.mem.tokenizeScalar(u8, row, ' ');
        while (parts.next()) |part| {
            const valueStr = std.mem.trim(u8, part, whitespace_chars);
            try rowAL.append(ctx.allocator, try std.fmt.parseInt(i64, valueStr, 10));
        }
        const rowSlice = try rowAL.toOwnedSlice(ctx.allocator);
        try numbersAL.append(ctx.allocator, rowSlice);
    }
    const numbers = try numbersAL.toOwnedSlice(ctx.allocator);

    const m = numbers[0].len;

    for (0..m) |j| {
        const operator = ctx.operators[j];
        var result_col: i64 = if (operator == '*') 1 else 0;
        for (numbers) |row| {
            const value = row[j];
            if (operator == '*') {
                result_col *= value;
            } else if (operator == '+') {
                result_col += value;
            } else {
                return error.InvalidOperator;
            }
        }
        result += result_col;
    }
    return result;
}

pub fn part2(ctx: Context) !i64 {
    var result: i64 = 0;

    var i: usize = 0;

    for (0..ctx.operators.len) |j| {
        const operator = ctx.operators[j];
        var result_col: i64 = if (operator == '*') 1 else 0;

        while (i <= ctx.numbers[0].len) {
            if (i == ctx.numbers[0].len) {
                result += result_col;
                break;
            }

            var num: i64 = 0;
            var all_whitespace = true;
            for (ctx.numbers) |number_str| {
                const ch = number_str[i];
                if (ch != ' ') {
                    all_whitespace = false;
                    const digit: i64 = ch - '0';
                    num = num * 10 + digit;
                }
            }
            i += 1;

            if (all_whitespace) {
                result += result_col;
                break;
            }
            if (operator == '*') {
                result_col *= num;
            } else if (operator == '+') {
                result_col += num;
            } else {
                return error.InvalidOperator;
            }
        }
    }
    return result;
}

const example =
    \\123 328  51 64 
    \\ 45 64  387 23 
    \\  6 98  215 314
    \\*   +   *   +
;

test "part1 example" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, example);

    const result = try part1(ctx);
    std.debug.print("Day 06 Part 1 Example Result: {}\n", .{result});
    try std.testing.expectEqual(4277556, result);
}

test "part1" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, input);

    const result = try part1(ctx);
    std.debug.print("Day 06 Part 1 Result: {}\n", .{result});
    try std.testing.expectEqual(5335495999141, result);
}

test "part2 example" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, example);

    const result = try part2(ctx);
    std.debug.print("Day 06 Part 2 Example Result: {}\n", .{result});
    try std.testing.expectEqual(3263827, result);
}

test "part2" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, input);

    const result = try part2(ctx);
    std.debug.print("Day 06 Part 2 Result: {}\n", .{result});
    try std.testing.expectEqual(9206, result);
}
