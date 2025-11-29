const std = @import("std");
const Allocator = std.mem.Allocator;

const input = @embedFile("dayDD_input.txt");

const Context = struct {
    allocator: Allocator,
    grid: [][]const u8,
};

fn parse(allocator: Allocator) !Context {
    // var grid = try std.ArrayList([]const u8).initCapacity(allocator, 10000);
    // defer grid.deinit(allocator);
    //
    // var it = std.mem.tokenizeScalar(u8, input, '\n');
    // while (it.next()) |line| {
    //     if (line.len == 0) continue;
    //
    //     try grid.append(allocator, line);
    // }
    //
    // const grid_finalized = try grid.toOwnedSlice(allocator);
    //
    // return Context{
    //     .allocator = allocator,
    //     .grid = grid_finalized,
    // };
}

pub fn part1(ctx: Context) !i64 {
    return 0;
}

pub fn part2(ctx: Context) !i64 {
    return 0;
}

const example = [_][]const u8{};

test "part1 example" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = Context{
        .allocator = allocator,
        .grid = @constCast(example[0..]),
    };

    const result = try part1(ctx);
    std.debug.print("Day DD Part 1 Example Result: {}\n", .{result});
    try std.testing.expectEqual(13, result);
}

test "part1" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator);

    const result = try part1(ctx);
    std.debug.print("Day DD Part 1 Result: {}\n", .{result});
    try std.testing.expectEqual(1533, result);
}

test "part2 example" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = Context{
        .allocator = allocator,
        .grid = @constCast(example[0..]),
    };

    const result = try part2(ctx);
    std.debug.print("Day DD Part 2 Example Result: {}\n", .{result});
    try std.testing.expectEqual(43, result);
}

test "part2" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator);

    const result = try part2(ctx);
    std.debug.print("Day DD Part 2 Result: {}\n", .{result});
    try std.testing.expectEqual(9206, result);
}
