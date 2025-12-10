const std = @import("std");
const Allocator = std.mem.Allocator;

const input = @embedFile("day10_input.txt");

const Light = struct {
    bits: u64,
    max_bit: u64,
};

const Joltage = struct {
    values: []u64,
    score: u64,
};

const Line = struct {
    light: Light,
    buttons: [][]u6, // u6 is required to bit shift operation because u6 is enough to represent u64
    joltage: Joltage,
};

const Context = struct {
    allocator: Allocator,
    lines: []Line,
};

fn parseLight(inputStr: []const u8) Light {
    var light: u64 = 1;
    var max_bit: u64 = 1;
    // mind the surrounding []
    for (1..(inputStr.len - 1)) |i| {
        const c = inputStr[i];
        light <<= 1;
        if (c == '#') {
            light |= 1;
        }

        max_bit <<= 1;
    }
    return Light{
        .bits = light,
        .max_bit = max_bit,
    };
}

fn parseButton(allocator: Allocator, inputStr: []const u8) ![]u6 {
    var buttonAL = try std.ArrayList(u6).initCapacity(allocator, 100);
    defer buttonAL.deinit(allocator);

    // mind the surrounding ()
    var it = std.mem.tokenizeScalar(u8, inputStr[1..(inputStr.len - 1)], ',');
    while (it.next()) |idx| {
        const id = try std.fmt.parseInt(u6, idx, 10);
        try buttonAL.append(allocator, id);
    }
    return try buttonAL.toOwnedSlice(allocator);
}

fn parseJoltage(allocator: Allocator, inputStr: []const u8) !Joltage {
    var valuesAL = try std.ArrayList(u64).initCapacity(allocator, 100);
    defer valuesAL.deinit(allocator);

    // mind the surrounding {}
    var it = std.mem.tokenizeScalar(u8, inputStr[1..(inputStr.len - 1)], ',');
    while (it.next()) |v| {
        const value = try std.fmt.parseInt(u64, v, 10);
        try valuesAL.append(allocator, value);
    }
    return Joltage{
        .values = try valuesAL.toOwnedSlice(allocator),
        .score = 0,
    };
}

fn parse(allocator: Allocator, inputStr: []const u8) !Context {
    var linesAL = try std.ArrayList(Line).initCapacity(allocator, 10000);
    defer linesAL.deinit(allocator);

    var it = std.mem.tokenizeScalar(u8, inputStr, '\n');
    while (it.next()) |line| {
        if (line.len == 0) continue;

        var inputAL = try std.ArrayList([]const u8).initCapacity(allocator, 10000);
        defer inputAL.deinit(allocator);

        var p = std.mem.tokenizeScalar(u8, line, ' ');
        while (p.next()) |token| {
            try inputAL.append(allocator, token);
        }
        const inputs = try inputAL.toOwnedSlice(allocator);

        // at least one light, one button, and one joltage requirement
        std.debug.assert(inputs.len >= 3);

        const light = parseLight(inputs[0]);

        var buttonsAL = try std.ArrayList([]u6).initCapacity(allocator, 10000);
        defer buttonsAL.deinit(allocator);
        for (1..(inputs.len - 1)) |i| {
            const button = try parseButton(allocator, inputs[i]);
            try buttonsAL.append(allocator, button);
        }

        const joltage = try parseJoltage(allocator, inputs[inputs.len - 1]);

        try linesAL.append(allocator, .{
            .light = light,
            .buttons = try buttonsAL.toOwnedSlice(allocator),
            .joltage = joltage,
        });
    }

    return Context{
        .allocator = allocator,
        .lines = try linesAL.toOwnedSlice(allocator),
    };
}

pub fn part1(ctx: Context) !u64 {
    var result: u64 = 0;

    for (ctx.lines) |line| {
        const light = line.light;
        const n = light.max_bit << 1;

        var dpArrayList = try std.ArrayList(u64).initCapacity(ctx.allocator, n);
        defer dpArrayList.deinit(ctx.allocator);
        for (0..n) |_| {
            try dpArrayList.append(ctx.allocator, 1_000_000_000);
        }
        const dp = try dpArrayList.toOwnedSlice(ctx.allocator);
        defer ctx.allocator.free(dp);
        dp[light.max_bit] = 0;

        for (line.buttons) |button| {
            var next_dpArrayList = try std.ArrayList(u64).initCapacity(ctx.allocator, n);
            defer next_dpArrayList.deinit(ctx.allocator);
            for (0..n) |_| {
                try next_dpArrayList.append(ctx.allocator, 1_000_000_000);
            }
            const next_dp = try next_dpArrayList.toOwnedSlice(ctx.allocator);
            defer ctx.allocator.free(next_dp);
            next_dp[light.max_bit] = 0;

            for (0..n) |i| {
                // not press
                next_dp[i] = @min(next_dp[i], dp[i]);

                // press
                var next_light: u64 = i;
                for (button) |idx| {
                    next_light ^= light.max_bit >> (1 + idx);
                }
                next_dp[next_light] = @min(next_dp[next_light], dp[i] + 1);
            }

            // copy next_dp to dp
            for (0..n) |i| {
                dp[i] = next_dp[i];
            }
        }

        result += dp[light.bits];
    }

    return result;
}

fn valuesToString(allocator: Allocator, values: []u64) ![]u8 {
    var valueStrsAL = try std.ArrayList([]u8).initCapacity(allocator, values.len);
    defer valueStrsAL.deinit(allocator);

    for (values) |v| {
        const s = try std.fmt.allocPrint(allocator, "{}", .{v});
        try valueStrsAL.append(allocator, s);
    }

    return try std.mem.join(allocator, ",", valueStrsAL.items);
}

pub fn part2(ctx: Context) !u64 {
    var result: u64 = 0;

    for (0..ctx.lines.len) |i| {
        std.debug.print("Processing line {}/{}\n", .{ i + 1, ctx.lines.len });
        const line = ctx.lines[i];

        // cached BFS
        var cache = std.StringHashMap(u64).init(ctx.allocator);
        defer cache.deinit();

        const initKey = try valuesToString(ctx.allocator, line.joltage.values);
        try cache.put(initKey, 0);

        var q = try std.ArrayList(Joltage).initCapacity(ctx.allocator, 100);
        defer q.deinit(ctx.allocator);
        try q.append(ctx.allocator, line.joltage);

        var ptr: usize = 0;

        while (ptr < q.items.len) : (ptr += 1) {
            const state = q.items[ptr];

            var reached = true;
            for (state.values) |v| {
                if (v != 0) reached = false;
            }
            if (reached) {
                // found one of the shortest way
                result += state.score;
                break;
            }

            var reached_negative = false;
            for (line.buttons) |b| {
                var valuesAL = try std.ArrayList(u64).initCapacity(ctx.allocator, 1000);
                defer valuesAL.deinit(ctx.allocator);

                for (state.values) |v| {
                    try valuesAL.append(ctx.allocator, v);
                }

                var next_state = Joltage{
                    .values = try valuesAL.toOwnedSlice(ctx.allocator),
                    .score = state.score + 1,
                };

                for (b) |idx| {
                    const id = idx;
                    if (next_state.values[id] == 0) {
                        reached_negative = true;
                        break;
                    }
                    next_state.values[id] -= 1;
                }
                if (reached_negative) {
                    continue;
                }

                const key = try valuesToString(ctx.allocator, next_state.values);
                if (cache.get(key)) |existing_score| {
                    if (next_state.score >= existing_score) {
                        continue;
                    }
                    try cache.put(key, next_state.score);
                } else {
                    // new state
                    try cache.put(key, next_state.score);
                }

                try q.append(ctx.allocator, next_state);
                std.debug.print("queue len {}\n", .{q.items.len});
            }
        }
    }

    return result;
}

const example =
    \\[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
    \\[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
    \\[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}
;

test "part1 example" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, example);

    const result = try part1(ctx);
    std.debug.print("Day 10 Part 1 Example Result: {}\n", .{result});
    try std.testing.expectEqual(7, result);
}

test "part1" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, input);

    const result = try part1(ctx);
    std.debug.print("Day 10 Part 1 Result: {}\n", .{result});
    try std.testing.expectEqual(475, result);
}

test "part2 example" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, example);

    const result = try part2(ctx);
    std.debug.print("Day 10 Part 2 Example Result: {}\n", .{result});
    try std.testing.expectEqual(33, result);
}

test "part2" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, input);

    const result = try part2(ctx);
    std.debug.print("Day 10 Part 2 Result: {}\n", .{result});
    try std.testing.expectEqual(6844224, result);
}
