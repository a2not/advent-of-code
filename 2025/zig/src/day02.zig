const std = @import("std");
const Allocator = std.mem.Allocator;

const input = @embedFile("day02_input.txt");

const range = struct {
    from: i64,
    to: i64,
};

const Context = struct {
    allocator: Allocator,
    ranges: []range,
};

fn parse(allocator: Allocator) !Context {
    var ranges = try std.ArrayList(range).initCapacity(allocator, 10000);
    errdefer ranges.deinit(allocator);

    var it = std.mem.tokenizeScalar(u8, input, ',');
    while (it.next()) |line| {
        if (line.len == 0) continue;

        var nums = std.mem.tokenizeScalar(u8, line, '-');
        const fromStr = nums.next() orelse unreachable;
        const toStr = nums.next() orelse unreachable;
        const trimmedToStr = std.mem.trim(u8, toStr, " \n\r\t");
        const from = try std.fmt.parseInt(i64, fromStr, 10);
        const to = try std.fmt.parseInt(i64, trimmedToStr, 10);
        try ranges.append(allocator, range{ .from = from, .to = to });
    }

    const ranges_slice = try ranges.toOwnedSlice(allocator);

    return Context{
        .allocator = allocator,
        .ranges = ranges_slice,
    };
}

pub fn part1(ctx: Context) !i64 {
    var result: i64 = 0;

    for (ctx.ranges) |r| {
        const from: usize = @intCast(r.from);
        const to: usize = @intCast(r.to);
        for (from..(to + 1)) |v| {
            std.debug.print("Checking value: {d}", .{v});
            const valueStr: []u8 = try std.fmt.allocPrint(ctx.allocator, "{d}", .{v});
            defer ctx.allocator.free(valueStr);

            const len = valueStr.len;
            if (@mod(len, 2) != 0) {
                continue;
            }

            const left = valueStr[0..(len / 2)];
            const right = valueStr[(len / 2)..len];
            if (std.mem.eql(u8, left, right)) {
                result += @intCast(v);
            }
        }
    }
    return result;
}

const Regex = @import("advent_of_code").regex.Regex;

pub fn part2(ctx: Context) !i64 {
    var result: i64 = 0;

    const pattern = "^(.+)\\1+$";
    var re = try Regex.compile(ctx.allocator, pattern);
    defer re.deinit();

    for (ctx.ranges) |r| {
        const from: usize = @intCast(r.from);
        const to: usize = @intCast(r.to);
        for (from..(to + 1)) |v| {
            const valueStr: []u8 = try std.fmt.allocPrint(ctx.allocator, "{d}", .{v});
            defer ctx.allocator.free(valueStr);

            if (try re.isMatch(valueStr)) {
                result += @intCast(v);
            } else {
                std.debug.print("No match for value: {d}\n", .{v});
            }
        }
    }
    return result;
}

const exampleRanges = [_]range{
    .{ .from = 11, .to = 22 },
    .{ .from = 95, .to = 115 },
    .{ .from = 998, .to = 1012 },
    .{ .from = 1188511880, .to = 1188511890 },
    .{ .from = 222220, .to = 222224 },
    .{ .from = 1698522, .to = 1698528 },
    .{ .from = 446443, .to = 446449 },
    .{ .from = 38593856, .to = 38593862 },
    .{ .from = 565653, .to = 565659 },
    .{ .from = 824824821, .to = 824824827 },
    .{ .from = 2121212118, .to = 2121212124 },
    // 11-22,
    // 95-115,
    // 998-1012,
    // 1188511880-1188511890,
    // 222220-222224,
    // 1698522-1698528,
    // 446443-446449,
    // 38593856-38593862,
    // 565653-565659,
    // 824824821-824824827,
    // 2121212118-2121212124
};

test "part1 example" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const ctx = Context{
        .allocator = allocator,
        .ranges = @constCast(exampleRanges[0..]),
    };

    const result = try part1(ctx);
    std.debug.print("Day 02 Part 1 Example Result: {}\n", .{result});
    try std.testing.expectEqual(1227775554, result);
}

test "part1" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const ctx = try parse(allocator);
    defer {
        allocator.free(ctx.ranges);
    }

    const result = try part1(ctx);
    std.debug.print("Day 02 Part 1 Result: {}\n", .{result});
    try std.testing.expectEqual(37314786486, result);
}

// test "part2 example" {
//     var gpa = std.heap.GeneralPurposeAllocator(.{}){};
//     defer _ = gpa.deinit();
//     const allocator = gpa.allocator();
//
//     const ctx = Context{
//         .allocator = allocator,
//         .ranges = @constCast(exampleRanges[0..]),
//     };
//
//     const result = try part2(ctx);
//     std.debug.print("Day 02 Part 2 Example Result: {}\n", .{result});
//     try std.testing.expectEqual(4174379265, result);
// }
//
// test "part2" {
//     var gpa = std.heap.GeneralPurposeAllocator(.{}){};
//     defer _ = gpa.deinit();
//     const allocator = gpa.allocator();
//
//     const ctx = try parse(allocator);
//     defer {
//         allocator.free(ctx.ranges);
//     }
//
//     const result = try part2(ctx);
//     std.debug.print("Day 02 Part 2 Result: {}\n", .{result});
//     try std.testing.expectEqual(47477053982, result);
// }
