const std = @import("std");
const Allocator = std.mem.Allocator;

const input = @embedFile("day11_input.txt");

const Context = struct {
    allocator: Allocator,
    adj: std.AutoHashMap(u64, std.ArrayList(u64)),
};

fn deviceNameAsU64(name: []const u8) u64 {
    var hash: u64 = 0;
    for (name) |c| {
        hash *= 100;
        hash += c - 'a';
    }
    return hash;
}

fn parse(allocator: Allocator, inputStr: []const u8) !Context {
    var adj = std.AutoHashMap(u64, std.ArrayList(u64)).init(allocator);

    var it = std.mem.tokenizeScalar(u8, inputStr, '\n');
    while (it.next()) |line| {
        if (line.len == 0) continue;
        var p = std.mem.tokenizeSequence(u8, line, ": ");

        const from = deviceNameAsU64(p.next() orelse unreachable);

        var toAL = try std.ArrayList(u64).initCapacity(allocator, 10);
        defer toAL.deinit(allocator);
        var toIt = std.mem.tokenizeScalar(u8, p.next() orelse unreachable, ' ');
        while (toIt.next()) |name| {
            const to = deviceNameAsU64(name);
            try toAL.append(allocator, to);
        }

        try adj.put(from, toAL);
    }

    return Context{
        .allocator = allocator,
        .adj = adj,
    };
}

const State = struct {
    device: u64,
    node: std.DoublyLinkedList.Node = .{},
};

pub fn part1(ctx: Context) !u64 {
    var adj = ctx.adj;
    defer adj.deinit();

    var dp = std.AutoHashMap(u64, u64).init(ctx.allocator);
    defer dp.deinit();

    var q: std.DoublyLinkedList = .{};
    var initial_state: State = .{
        .device = deviceNameAsU64("you"),
    };
    q.append(&initial_state.node);
    try dp.put(initial_state.device, 1);

    var it = q.first;
    while (it) |node| : (it = node.next) {
        const state: *State = @fieldParentPtr("node", node);
        const device = state.*.device;
        std.debug.print("Visiting device: {}\n", .{device});

        const to = adj.get(device).?;
        for (to.items) |next_device| {
            const current_score = dp.get(next_device) orelse 0;
            const to_add = dp.get(device) orelse 0;
            try dp.put(next_device, current_score + to_add);

            var new_state: State = .{
                .device = next_device,
            };
            q.append(&new_state.node);
        }
    }

    return dp.get(deviceNameAsU64("out")).?;
}

// pub fn part2(ctx: Context) u64 {
// }

const example =
    \\aaa: you hhh
    \\you: bbb ccc
    \\bbb: ddd eee
    \\ccc: ddd eee fff
    \\ddd: ggg
    \\eee: out
    \\fff: out
    \\ggg: out
    \\hhh: ccc fff iii
    \\iii: out
;

test "part1 example" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, example);

    const result = try part1(ctx);
    std.debug.print("Day 11 Part 1 Example Result: {}\n", .{result});
    try std.testing.expectEqual(50, result);
}

// test "part1" {
//     var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
//     defer arena.deinit();
//     const allocator = arena.allocator();
//
//     const ctx = try parse(allocator, input);
//
//     const result = try part1(ctx);
//     std.debug.print("Day 11 Part 1 Result: {}\n", .{result});
//     try std.testing.expectEqual(4777967538, result);
// }
//
// test "part2 example" {
//     var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
//     defer arena.deinit();
//     const allocator = arena.allocator();
//
//     const ctx = try parse(allocator, example);
//
//     const result = try part2(ctx);
//     std.debug.print("Day 11 Part 2 Example Result: {}\n", .{result});
//     try std.testing.expectEqual(24, result);
// }
//
// test "part2" {
//     var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
//     defer arena.deinit();
//     const allocator = arena.allocator();
//
//     const ctx = try parse(allocator, input);
//
//     const result = try part2(ctx);
//     std.debug.print("Day 11 Part 2 Result: {}\n", .{result});
//     try std.testing.expectEqual(6844224, result);
// }
