const std = @import("std");
const Allocator = std.mem.Allocator;

const input = @embedFile("day01_input.txt");

const operation = struct {
    toLeft: bool,
    value: i32,
};

const Context = struct {
    allocator: Allocator,
    N: usize,
    operations: []operation,
};

fn parse(allocator: Allocator) !Context {
    var N: usize = 0;
    var operations = try std.ArrayList(operation).initCapacity(allocator, 1000);
    defer operations.deinit(allocator);

    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |line| {
        if (line.len == 0) continue;

        const direction = line[0];
        const value = try std.fmt.parseInt(i32, line[1..], 10);
        try operations.append(allocator, operation{
            .toLeft = direction == 'L',
            .value = value,
        });

        N += 1;
    }

    const operations_items = try allocator.dupe(operation, operations.items);

    return Context{
        .allocator = allocator,
        .N = N,
        .operations = operations_items,
    };
}

pub fn part1(ctx: Context) !i32 {
    var position: i32 = 50;
    var numPointsAtZero: i32 = 0;
    for (ctx.operations) |v| {
        const toAdd = if (v.toLeft) -v.value else v.value;
        position = @mod(position + toAdd, 100);
        if (position == 0) {
            numPointsAtZero += 1;
        }
    }

    return numPointsAtZero;
}

pub fn part2(ctx: Context) !i32 {
    var position: i32 = 50;
    var numPassedZero: i32 = 0;
    for (ctx.operations) |v| {
        const toAdd = if (v.toLeft) -v.value else v.value;
        const newPosition = position + toAdd;
        if (newPosition < 0) {
            const count: i32 = @divTrunc(-newPosition, 100);
            numPassedZero += count + 1;
            if (position == 0) {
                numPassedZero -= 1;
            }
        } else if (newPosition >= 100) {
            const count: i32 = @divTrunc(newPosition, 100);
            numPassedZero += count;
        } else if (newPosition == 0) {
            numPassedZero += 1;
        }
        position = @mod(newPosition, 100);
    }

    return numPassedZero;
}

const exampleOperations = [_]operation{
    .{ .toLeft = true, .value = 68 },
    .{ .toLeft = true, .value = 30 },
    .{ .toLeft = false, .value = 48 },
    .{ .toLeft = true, .value = 5 },
    .{ .toLeft = false, .value = 60 },
    .{ .toLeft = true, .value = 55 },
    .{ .toLeft = true, .value = 1 },
    .{ .toLeft = true, .value = 99 },
    .{ .toLeft = false, .value = 14 },
    .{ .toLeft = true, .value = 82 },
    // L68
    // L30
    // R48
    // L5
    // R60
    // L55
    // L1
    // L99
    // R14
    // L82
};

test "part1 example" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const ctx = Context{
        .allocator = allocator,
        .N = 10,
        .operations = @constCast(exampleOperations[0..]),
    };

    const result = try part1(ctx);
    std.debug.print("Day 01 Part 1 Example Result: {}\n", .{result});
    try std.testing.expectEqual(3, result);
}

test "part1" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const ctx = try parse(allocator);
    defer {
        allocator.free(ctx.operations);
    }

    const result = try part1(ctx);
    std.debug.print("Day 01 Part 1 Result: {}\n", .{result});
    try std.testing.expectEqual(992, result);
}

test "part2 example" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const ctx = Context{
        .allocator = allocator,
        .N = 10,
        .operations = @constCast(exampleOperations[0..]),
    };

    const result = try part2(ctx);
    std.debug.print("Day 01 Part 2 Example Result: {}\n", .{result});
    try std.testing.expectEqual(6, result);
}

test "part2" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const ctx = try parse(allocator);
    defer {
        allocator.free(ctx.operations);
    }

    const result = try part2(ctx);
    std.debug.print("Day 01 Part 2 Result: {}\n", .{result});
    try std.testing.expectEqual(6133, result);
}
