const std = @import("std");
const Allocator = std.mem.Allocator;

const input = @embedFile("day07_input.txt");

const Context = struct {
    allocator: Allocator,
    manifold: [][]u8,
};

fn parse(allocator: Allocator, inputStr: []const u8) !Context {
    var manifoldAL = try std.ArrayList([]u8).initCapacity(allocator, 10000);
    defer manifoldAL.deinit(allocator);

    var it = std.mem.tokenizeScalar(u8, inputStr, '\n');
    while (it.next()) |line| {
        if (line.len == 0) continue;
        var al = try std.ArrayList(u8).initCapacity(allocator, line.len);
        try al.appendSlice(allocator, line);
        const mutableLine = try al.toOwnedSlice(allocator);
        try manifoldAL.append(allocator, mutableLine);
    }
    const manifold = try manifoldAL.toOwnedSlice(allocator);

    return Context{
        .allocator = allocator,
        .manifold = manifold,
    };
}

pub fn part1(ctx: Context) !i64 {
    var result: i64 = 0;

    const manifold = ctx.manifold;
    var stack = try std.ArrayList(struct {
        i: usize,
        j: usize,
    }).initCapacity(ctx.allocator, 10000);

    for (0..manifold[0].len) |j| {
        const char = manifold[0][j];
        if (char == 'S') {
            try stack.append(ctx.allocator, .{ .i = 0, .j = j });
        }
    }

    while (stack.pop()) |pos| {
        const i = pos.i + 1;
        const j = pos.j;
        if (i >= manifold.len) continue;
        const char = manifold[i][j];

        if (char == '^') {
            result += 1;
            manifold[i][j] = '.'; // mark as visited
            if (0 <= j - 1 and manifold[i][j - 1] == '.') {
                manifold[i][j - 1] = '|';
                try stack.append(ctx.allocator, .{ .i = i, .j = j - 1 });
            }
            if (j + 1 < manifold[i].len and manifold[i][j + 1] == '.') {
                manifold[i][j + 1] = '|';
                try stack.append(ctx.allocator, .{ .i = i, .j = j + 1 });
            }
        } else if (manifold[i][j] == '.') {
            manifold[i][j] = '|';
            try stack.append(ctx.allocator, .{ .i = i, .j = j });
        }
    }

    return result;
}

pub fn part2(ctx: Context) !i64 {
    const manifold = ctx.manifold;

    const max_width = 10000; // being lazy here
    var sum = [_]i64{0} ** max_width;
    for (0..manifold[0].len) |j| {
        const char = manifold[0][j];
        if (char == 'S') {
            sum[j] = 1;
            manifold[0][j] = '|';
        }
    }

    for (0..(manifold.len - 1)) |i| {
        // DP with minimal space
        var new_sum = [_]i64{0} ** max_width;

        for (0..manifold[i].len) |j| {
            const char = manifold[i][j];
            if (char != '|') {
                continue;
            }
            const next_i = i + 1;
            const next_char = manifold[next_i][j];
            if (next_char == '^') {
                if (0 <= j - 1) {
                    manifold[next_i][j - 1] = '|';
                    new_sum[j - 1] += sum[j];
                }
                if (j + 1 < manifold[next_i].len) {
                    manifold[next_i][j + 1] = '|';
                    new_sum[j + 1] += sum[j];
                }
            } else {
                manifold[next_i][j] = '|';
                new_sum[j] += sum[j];
            }
        }
        sum = new_sum;
    }

    var result: i64 = 0;
    for (0..sum.len) |j| {
        result += sum[j];
    }

    return result;
}

const example =
    \\.......S.......
    \\...............
    \\.......^.......
    \\...............
    \\......^.^......
    \\...............
    \\.....^.^.^.....
    \\...............
    \\....^.^...^....
    \\...............
    \\...^.^...^.^...
    \\...............
    \\..^...^.....^..
    \\...............
    \\.^.^.^.^.^...^.
    \\...............
;

test "part1 example" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, example);

    const result = try part1(ctx);
    std.debug.print("Day 07 Part 1 Example Result: {}\n", .{result});
    try std.testing.expectEqual(21, result);
}

test "part1" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, input);

    const result = try part1(ctx);
    std.debug.print("Day 07 Part 1 Result: {}\n", .{result});
    try std.testing.expectEqual(1658, result);
}

test "part2 example" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, example);

    const result = try part2(ctx);
    std.debug.print("Day 07 Part 2 Example Result: {}\n", .{result});
    try std.testing.expectEqual(40, result);
}

test "part2" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, input);

    const result = try part2(ctx);
    std.debug.print("Day 07 Part 2 Result: {}\n", .{result});
    try std.testing.expectEqual(53916299384254, result);
}
