const std = @import("std");
const Allocator = std.mem.Allocator;

const input = @embedFile("day04_input.txt");

const Context = struct {
    allocator: Allocator,
    grid: [][]const u8,
};

fn parse(allocator: Allocator) !Context {
    var grid = try std.ArrayList([]const u8).initCapacity(allocator, 10000);
    defer grid.deinit(allocator);

    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |line| {
        if (line.len == 0) continue;

        try grid.append(allocator, line);
    }

    const grid_finalized = try grid.toOwnedSlice(allocator);

    return Context{
        .allocator = allocator,
        .grid = grid_finalized,
    };
}

pub fn part1(ctx: Context) !i64 {
    var result: i64 = 0;

    const grid = ctx.grid;
    const dir = [_]i32{ -1, 0, 1 };
    for (0..grid.len) |i| {
        for (0..grid[i].len) |j| {
            if (grid[i][j] != '@') continue;

            var count: i32 = 0;
            for (dir) |di| {
                for (dir) |dj| {
                    if (di == 0 and dj == 0) continue;

                    const ai: i32 = @as(i32, @intCast(i)) + di;
                    const aj: i32 = @as(i32, @intCast(j)) + dj;
                    if (ai < 0 or grid.len <= ai) continue;
                    if (aj < 0 or grid[@intCast(ai)].len <= aj) continue;
                    if (grid[@intCast(ai)][@intCast(aj)] == '@') {
                        count += 1;
                    }
                }
            }
            if (count < 4) {
                result += 1;
            }
        }
    }

    return result;
}
pub fn part2(ctx: Context) !i64 {
    var result: i64 = 0;

    // Create a mutable copy of the grid
    // wierd but okay
    var grid = try ctx.allocator.alloc([]u8, ctx.grid.len);
    defer {
        for (grid) |row| ctx.allocator.free(row);
        ctx.allocator.free(grid);
    }
    for (ctx.grid, 0..) |row, i| {
        grid[i] = try ctx.allocator.dupe(u8, row);
    }

    // DFS
    const index = struct {
        i: usize,
        j: usize,
    };
    var stack = try std.ArrayList(index).initCapacity(ctx.allocator, 10000);

    for (0..grid.len) |i| {
        for (0..grid[i].len) |j| {
            if (grid[i][j] != '@') continue;
            try stack.append(ctx.allocator, index{ .i = i, .j = j });
        }
    }

    const dir = [_]i32{ -1, 0, 1 };
    while (stack.items.len > 0) {
        const current = stack.pop() orelse break;
        if (grid[current.i][current.j] != '@') continue;

        var count: i32 = 0;
        var candidates = try std.ArrayList(index).initCapacity(ctx.allocator, 10);
        for (dir) |di| {
            for (dir) |dj| {
                if (di == 0 and dj == 0) continue;

                const ai: i32 = @as(i32, @intCast(current.i)) + di;
                const aj: i32 = @as(i32, @intCast(current.j)) + dj;
                if (ai < 0 or grid.len <= ai) continue;
                if (aj < 0 or grid[@intCast(ai)].len <= aj) continue;
                if (grid[@intCast(ai)][@intCast(aj)] == '@') {
                    count += 1;
                    try candidates.append(ctx.allocator, index{ .i = @intCast(ai), .j = @intCast(aj) });
                }
            }
        }
        if (count < 4) {
            result += 1;
            grid[current.i][current.j] = '.';
            try stack.appendSlice(ctx.allocator, try candidates.toOwnedSlice(ctx.allocator));
        }
    }

    return result;
}

const exampleGrid = [_][]const u8{
    "..@@.@@@@.",
    "@@@.@.@.@@",
    "@@@@@.@.@@",
    "@.@@@@..@.",
    "@@.@@@@.@@",
    ".@@@@@@@.@",
    ".@.@.@.@@@",
    "@.@@@.@@@@",
    ".@@@@@@@@.",
    "@.@.@@@.@.",
};

test "part1 example" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = Context{
        .allocator = allocator,
        .grid = @constCast(exampleGrid[0..]),
    };

    const result = try part1(ctx);
    std.debug.print("Day 04 Part 1 Example Result: {}\n", .{result});
    try std.testing.expectEqual(13, result);
}

test "part1" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator);
    defer {
        allocator.free(ctx.grid);
    }

    const result = try part1(ctx);
    std.debug.print("Day 04 Part 1 Result: {}\n", .{result});
    try std.testing.expectEqual(1533, result);
}

test "part2 example" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = Context{
        .allocator = allocator,
        .grid = @constCast(exampleGrid[0..]),
    };

    const result = try part2(ctx);
    std.debug.print("Day 04 Part 2 Example Result: {}\n", .{result});
    try std.testing.expectEqual(43, result);
}

test "part2" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator);
    defer {
        allocator.free(ctx.grid);
    }

    const result = try part2(ctx);
    std.debug.print("Day 04 Part 2 Result: {}\n", .{result});
    try std.testing.expectEqual(9206, result);
}
