const std = @import("std");
const Allocator = std.mem.Allocator;

const input = @embedFile("day03_input.txt");

const bank = []const u8;

const Context = struct {
    allocator: Allocator,
    banks: []bank,
};

fn parse(allocator: Allocator) !Context {
    var banks = try std.ArrayList(bank).initCapacity(allocator, 10000);
    errdefer banks.deinit(allocator);

    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |line| {
        if (line.len == 0) continue;

        try banks.append(allocator, line);
    }

    const banks_slice = try banks.toOwnedSlice(allocator);

    return Context{
        .allocator = allocator,
        .banks = banks_slice,
    };
}

pub fn part1(ctx: Context) !i64 {
    var result: i64 = 0;

    for (ctx.banks) |b| {
        var largestTensIndex: usize = 0;
        for (0..(b.len - 1)) |i| {
            if (b[i] > b[largestTensIndex]) {
                largestTensIndex = i;
            }
        }
        var largestOnesIndex: usize = largestTensIndex + 1;
        for ((largestTensIndex + 1)..b.len) |i| {
            if (b[i] > b[largestOnesIndex]) {
                largestOnesIndex = i;
            }
        }
        const largest = (b[largestTensIndex] - '0') * 10 + (b[largestOnesIndex] - '0');
        result += largest;
    }
    return result;
}

pub fn part2(ctx: Context) !i64 {
    var result: i64 = 0;

    for (ctx.banks) |b| {
        const rows = b.len + 1;
        const cols = 12 + 1;
        // 2d array init
        var dpArrayList = try std.ArrayList([cols]i64).initCapacity(ctx.allocator, rows);
        for (0..rows) |_| {
            try dpArrayList.append(ctx.allocator, .{0} ** cols);
        }
        const dp = try dpArrayList.toOwnedSlice(ctx.allocator);
        defer {
            ctx.allocator.free(dp);
        }
        for (1..rows) |i| {
            for (1..cols) |j| {
                // DP[i][j] = maximum value taking i-th number in bank as (12-j)-th digit
                //
                // DP[i][j] = max(
                //   DP[i-1][j],
                //   DP[i-1][j-1] + bank[i] * 10 ** (12-j),
                // )
                const digit = b[i - 1] - '0';
                const toAdd = digit * std.math.pow(i64, 10, @as(i64, @intCast(12 - j)));
                dp[i][j] = @max(dp[i - 1][j], dp[i - 1][j - 1] + toAdd);
            }
        }

        var largest: i64 = 0;
        for (0..rows) |i| {
            largest = @max(largest, dp[i][cols - 1]);
        }
        result += largest;
    }

    return result;
}

const exampleBanks = [_]bank{
    "987654321111111",
    "811111111111119",
    "234234234234278",
    "818181911112111",
};

test "part1 example" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const ctx = Context{
        .allocator = allocator,
        .banks = @constCast(exampleBanks[0..]),
    };

    const result = try part1(ctx);
    std.debug.print("Day 03 Part 1 Example Result: {}\n", .{result});
    try std.testing.expectEqual(357, result);
}

test "part1" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const ctx = try parse(allocator);
    defer {
        allocator.free(ctx.banks);
    }

    const result = try part1(ctx);
    std.debug.print("Day 03 Part 1 Result: {}\n", .{result});
    try std.testing.expectEqual(17432, result);
}

test "part2 example" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const ctx = Context{
        .allocator = allocator,
        .banks = @constCast(exampleBanks[0..]),
    };

    const result = try part2(ctx);
    std.debug.print("Day 03 Part 2 Example Result: {}\n", .{result});
    try std.testing.expectEqual(3121910778619, result);
}

test "part2" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const ctx = try parse(allocator);
    defer {
        allocator.free(ctx.banks);
    }

    const result = try part2(ctx);
    std.debug.print("Day 03 Part 2 Result: {}\n", .{result});
    try std.testing.expectEqual(173065202451341, result);
}
