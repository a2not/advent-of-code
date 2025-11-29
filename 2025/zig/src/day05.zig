const std = @import("std");
const Allocator = std.mem.Allocator;

const input = @embedFile("day05_input.txt");

const range = struct {
    from: i64,
    to: i64,
};

const Context = struct {
    allocator: Allocator,
    ranges: []range,
    ingredients: []i64,
};

fn parse(allocator: Allocator) !Context {
    var ranges = try std.ArrayList(range).initCapacity(allocator, 10000);
    defer ranges.deinit(allocator);
    var sections = std.mem.tokenizeSequence(u8, input, "\n\n");
    if (sections.next()) |section| {
        var it = std.mem.tokenizeScalar(u8, section, '\n');
        while (it.next()) |line| {
            if (line.len == 0) continue;

            var nums = std.mem.tokenizeScalar(u8, line, '-');
            const from_str = nums.next() orelse return error.InvalidInput;
            const to_str = nums.next() orelse return error.InvalidInput;

            const from = try std.fmt.parseInt(i64, from_str, 10);
            const to = try std.fmt.parseInt(i64, to_str, 10);

            try ranges.append(allocator, range{
                .from = from,
                .to = to,
            });
        }
    }
    const ranges_finalized = try ranges.toOwnedSlice(allocator);

    var ingredients = try std.ArrayList(i64).initCapacity(allocator, 10000);
    defer ingredients.deinit(allocator);
    if (sections.next()) |section| {
        var it = std.mem.tokenizeScalar(u8, section, '\n');
        while (it.next()) |line| {
            if (line.len == 0) continue;

            const value = try std.fmt.parseInt(i64, line, 10);

            try ingredients.append(allocator, value);
        }
    }
    const ingredients_finalized = try ingredients.toOwnedSlice(allocator);

    return Context{
        .allocator = allocator,
        .ranges = ranges_finalized,
        .ingredients = ingredients_finalized,
    };
}

pub fn part1(ctx: Context) !i64 {
    var result: i64 = 0;
    for (ctx.ingredients) |v| {
        for (ctx.ranges) |r| {
            if (r.from <= v and v <= r.to) {
                result += 1;
                break;
            }
        }
    }
    return result;
}

fn lLessThan(_: void, a: range, b: range) bool {
    return a.from < b.from;
}
pub fn part2(ctx: Context) !i64 {
    var result: i64 = 0;
    var cur_from: ?i64 = null;
    var cur_to: ?i64 = null;

    const ranges = try ctx.allocator.alloc(range, ctx.ranges.len);
    @memcpy(ranges, ctx.ranges);
    std.mem.sort(range, ranges, {}, lLessThan);

    for (ranges) |r| {
        if (cur_from == null and cur_to == null) {
            cur_from = r.from;
            cur_to = r.to;
            continue;
        }

        if (cur_to.? < r.from) {
            result += cur_to.? - cur_from.? + 1;
            cur_from = r.from;
            cur_to = r.to;
        } else {
            cur_to = @max(cur_to.?, r.to);
        }
    }
    result += cur_to.? - cur_from.? + 1;
    return result;
}

const exampleRanges = [_]range{
    .{ .from = 3, .to = 5 },
    .{ .from = 10, .to = 14 },
    .{ .from = 16, .to = 20 },
    .{ .from = 12, .to = 18 },
    // 3-5
    // 10-14
    // 16-20
    // 12-18
};

const exampleIngredients = [_]i64{ 1, 5, 8, 11, 17, 32 };

test "part1 example" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = Context{
        .allocator = allocator,
        .ranges = @constCast(exampleRanges[0..]),
        .ingredients = @constCast(exampleIngredients[0..]),
    };

    const result = try part1(ctx);
    std.debug.print("Day 05 Part 1 Example Result: {}\n", .{result});
    try std.testing.expectEqual(3, result);
}

test "part1" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator);

    const result = try part1(ctx);
    std.debug.print("Day 05 Part 1 Result: {}\n", .{result});
    try std.testing.expectEqual(623, result);
}

test "part2 example" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = Context{
        .allocator = allocator,
        .ranges = @constCast(exampleRanges[0..]),
        .ingredients = @constCast(exampleIngredients[0..]),
    };

    const result = try part2(ctx);
    std.debug.print("Day 05 Part 2 Example Result: {}\n", .{result});
    try std.testing.expectEqual(14, result);
}

test "part2" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator);

    const result = try part2(ctx);
    std.debug.print("Day 05 Part 2 Result: {}\n", .{result});
    try std.testing.expectEqual(353507173555373, result);
}
