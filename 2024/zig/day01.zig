const std = @import("std");
const Allocator = std.mem.Allocator;

const input = @embedFile("day01_input.txt");

const Context = struct {
    allocator: Allocator,
    N: usize,
    left: []i32,
    right: []i32,
};

fn init(allocator: Allocator) !Context {
    var N: usize = 0;
    var left = try std.ArrayList(i32).initCapacity(allocator, 1000);
    defer left.deinit(allocator);
    var right = try std.ArrayList(i32).initCapacity(allocator, 1000);
    defer right.deinit(allocator);

    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |line| {
        if (line.len == 0) continue;

        var parts = std.mem.tokenizeScalar(u8, line, ' ');
        const left_val = try std.fmt.parseInt(i32, parts.next().?, 10);
        const right_val = try std.fmt.parseInt(i32, parts.next().?, 10);

        try left.append(allocator, left_val);
        try right.append(allocator, right_val);
        N += 1;
    }

    const left_items = try allocator.dupe(i32, left.items);
    const right_items = try allocator.dupe(i32, right.items);

    return Context{
        .allocator = allocator,
        .N = N,
        .left = left_items,
        .right = right_items,
    };
}

pub fn part1(ctx: Context) !i32 {
    std.mem.sort(i32, ctx.left, {}, comptime std.sort.asc(i32));
    std.mem.sort(i32, ctx.right, {}, comptime std.sort.asc(i32));

    var sum: i32 = 0;
    for (0..ctx.N) |i| {
        const diff = @abs(ctx.left[i] - ctx.right[i]);
        sum += @intCast(diff);
    }

    return sum;
}

pub fn part2(ctx: Context) !i32 {
    var counter = std.AutoHashMap(i32, i32).init(ctx.allocator);
    defer counter.deinit();

    for (0..ctx.N) |i| {
        const newval = (counter.get(@intCast(ctx.right[i])) orelse 0) + 1;
        try counter.put(@intCast(ctx.right[i]), newval);
    }

    var sum: i32 = 0;
    for (0..ctx.N) |i| {
        const count = counter.get(@intCast(ctx.left[i])) orelse 0;
        sum += ctx.left[i] * count;
    }
    return sum;
}

test "part1" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const ctx = try init(allocator);
    defer {
        allocator.free(ctx.left);
        allocator.free(ctx.right);
    }

    const result = try part1(ctx);
    std.debug.print("Day 01 Part 1 Result: {}\n", .{result});
    try std.testing.expect(result == 2031679);
}

test "part2 example" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const left_array = [_]i32{ 3, 4, 2, 1, 3, 3 };
    const right_array = [_]i32{ 4, 3, 5, 3, 9, 3 };
    const ctx = Context{
        .allocator = allocator,
        .N = 6,
        .left = @constCast(left_array[0..]),
        .right = @constCast(right_array[0..]),
    };

    const result = try part2(ctx);
    std.debug.print("Day 01 Part 2 example Result: {}\n", .{result});
    try std.testing.expect(result == 31);
}

test "part2" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const ctx = try init(allocator);
    defer {
        allocator.free(ctx.left);
        allocator.free(ctx.right);
    }

    const result = try part2(ctx);
    std.debug.print("Day 01 Part 2 Result: {}\n", .{result});
    try std.testing.expect(result == 19678534);
}
