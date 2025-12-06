const std = @import("std");
const Allocator = std.mem.Allocator;

const input = @embedFile("day02_input.txt");

const range = struct {
    from: u64,
    to: u64,
};

const Context = struct {
    allocator: Allocator,
    ranges: []range,
};

fn parse(allocator: Allocator, inputStr: []const u8) !Context {
    var ranges = try std.ArrayList(range).initCapacity(allocator, 10000);
    errdefer ranges.deinit(allocator);

    var it = std.mem.tokenizeScalar(u8, inputStr, ',');
    while (it.next()) |line| {
        if (line.len == 0) continue;

        var nums = std.mem.tokenizeScalar(u8, line, '-');
        const fromStr = nums.next() orelse unreachable;
        const toStr = nums.next() orelse unreachable;
        const trimmedToStr = std.mem.trim(u8, toStr, " \n\r\t");
        const from = try std.fmt.parseInt(u64, fromStr, 10);
        const to = try std.fmt.parseInt(u64, trimmedToStr, 10);
        try ranges.append(allocator, range{ .from = from, .to = to });
    }

    const ranges_slice = try ranges.toOwnedSlice(allocator);

    return Context{
        .allocator = allocator,
        .ranges = ranges_slice,
    };
}

pub fn part1(ctx: Context) !u64 {
    var result: u64 = 0;

    const maximum_pat: u64 = std.math.pow(u64, 10, 9);
    for (ctx.ranges) |r| {
        const from: usize = @intCast(r.from);
        const to: usize = @intCast(r.to);
        for (from..(to + 1)) |v| {
            const value: u64 = @intCast(v);
            var pot: u64 = 10;
            while (pot <= maximum_pat) : (pot *= 10) {
                const pattern = @mod(value, pot);

                const leading_zero = @divFloor(pattern, @divFloor(pot, 10)) == 0;
                if (leading_zero) continue;

                const shifted = @divFloor(value, pot);

                if (pattern == shifted) {
                    result += value;
                    break;
                }
            }
        }
    }
    return result;
}

pub fn part2(ctx: Context) !u64 {
    var result: u64 = 0;

    const maximum_pat: u64 = std.math.pow(u64, 10, 9);
    for (ctx.ranges) |r| {
        const from: usize = @intCast(r.from);
        const to: usize = @intCast(r.to);
        for (from..(to + 1)) |v| {
            var pot: u64 = 10;
            while (pot <= maximum_pat) : (pot *= 10) {
                var value: u64 = @intCast(v);
                const pattern = @mod(value, pot);

                const leading_zero = @divFloor(pattern, @divFloor(pot, 10)) == 0;
                if (leading_zero) continue;

                value = @divFloor(value, pot);
                if (value == 0) continue; // any value would repeat once

                while (@mod(value, pot) == pattern) {
                    value = @divFloor(value, pot);
                }

                if (value == 0) {
                    result += @intCast(v);
                    break;
                }
            }
        }
    }
    return result;
}

const example =
    \\11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124
;

test "part1 example" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, example);

    const result = try part1(ctx);
    std.debug.print("Day 02 Part 1 Example Result: {}\n", .{result});
    try std.testing.expectEqual(1227775554, result);
}

test "part1" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, input);

    const result = try part1(ctx);
    std.debug.print("Day 02 Part 1 Result: {}\n", .{result});
    try std.testing.expectEqual(37314786486, result);
}

test "part2 example" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, example);

    const result = try part2(ctx);
    std.debug.print("Day 02 Part 2 Example Result: {}\n", .{result});
    try std.testing.expectEqual(4174379265, result);
}

test "part2" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, input);

    const result = try part2(ctx);
    std.debug.print("Day 02 Part 2 Result: {}\n", .{result});
    try std.testing.expectEqual(47477053982, result);
}
