const std = @import("std");
const Allocator = std.mem.Allocator;

const input = @embedFile("day11_input.txt");

const Adj = std.AutoHashMap(u64, std.ArrayList(u64));
const Context = struct {
    allocator: Allocator,
    adj: Adj,
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
    var adj = Adj.init(allocator);

    var it = std.mem.tokenizeScalar(u8, inputStr, '\n');
    while (it.next()) |line| {
        if (line.len == 0) continue;
        var p = std.mem.tokenizeSequence(u8, line, ": ");

        const from = deviceNameAsU64(p.next() orelse unreachable);

        var toAL = try std.ArrayList(u64).initCapacity(allocator, 10);
        // defer toAL.deinit(allocator); // NOTE: let the arena allocator do the job. I know it's better to init arena allocator at the top of parse func but i'm lazy.
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
    order: u64,
};

fn compareState(_: void, a: State, b: State) std.math.Order {
    return std.math.order(a.order, b.order);
}

pub fn part1(ctx: Context) !u64 {
    var result: u64 = 0;

    // BFS
    var adj = ctx.adj;
    defer adj.deinit();

    // NOTE: PQ as deque since intrusive DoublyLinkedList was hard to juggle with
    // https://www.openmymind.net/Zigs-New-LinkedList-API/
    var q = std.PriorityQueue(State, void, compareState).init(ctx.allocator, {});
    defer q.deinit();

    var order_counter: u64 = 0;
    const initial_state: State = .{
        .device = deviceNameAsU64("you"),
        .order = order_counter,
    };
    try q.add(initial_state);
    order_counter += 1;

    var it = q.iterator();
    while (it.next()) |state| {
        const device = state.device;
        if (device == deviceNameAsU64("out")) {
            result += 1;
            continue;
        }

        const to = adj.get(device) orelse continue;
        for (to.items) |next_device| {
            const new_state: State = .{
                .device = next_device,
                .order = order_counter,
            };
            try q.add(new_state);
            order_counter += 1;
        }
    }

    return result;
}

const Cache = std.AutoHashMap(u64, u64);

fn cacheKey(device: u64, passedFFT: bool, passedDAC: bool) u64 {
    var ck = device;
    ck <<= 1;
    ck |= @intFromBool(passedFFT);
    ck <<= 1;
    ck |= @intFromBool(passedDAC);
    return ck;
}

pub fn solvePart2From(allocator: Allocator, adj: Adj, cache: *Cache, device: u64, passedFFT: bool, passedDAC: bool) !u64 {
    if (device == deviceNameAsU64("out")) {
        return if (passedFFT and passedDAC) 1 else 0;
    }

    const ck = cacheKey(device, passedFFT, passedDAC);

    if (cache.get(ck)) |res| return res;

    var res: usize = 0;

    const to = adj.get(device) orelse return 0;
    for (to.items) |next_device| {
        const dac = passedDAC or (next_device == deviceNameAsU64("dac"));
        const fft = passedFFT or (next_device == deviceNameAsU64("fft"));
        std.debug.print("At device: {}, next_device: {}, passedFFT: {}, passedDAC: {}\n", .{ device, next_device, passedFFT, passedDAC });

        res += try solvePart2From(allocator, adj, cache, next_device, fft, dac);
    }

    cache.putAssumeCapacityNoClobber(ck, res);

    std.debug.print("Device: {}, passedFFT: {}, passedDAC: {} => res: {}\n", .{ device, passedFFT, passedDAC, res });
    return res;
}

pub fn part2(ctx: Context) !u64 {
    // cached DFS
    var adj = ctx.adj;
    defer adj.deinit();

    var cache: Cache = .init(ctx.allocator);
    defer cache.deinit();
    try cache.ensureTotalCapacity(std.math.pow(u32, 2, 13));

    return solvePart2From(ctx.allocator, adj, &cache, deviceNameAsU64("svr"), false, false);
}

const example1 =
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

    const ctx = try parse(allocator, example1);

    const result = try part1(ctx);
    std.debug.print("Day 11 Part 1 Example Result: {}\n", .{result});
    try std.testing.expectEqual(5, result);
}

test "part1" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, input);

    const result = try part1(ctx);
    std.debug.print("Day 11 Part 1 Result: {}\n", .{result});
    try std.testing.expectEqual(758, result);
}

const example2 =
    \\svr: aaa bbb
    \\aaa: fft
    \\fft: ccc
    \\bbb: tty
    \\tty: ccc
    \\ccc: ddd eee
    \\ddd: hub
    \\hub: fff
    \\eee: dac
    \\dac: fff
    \\fff: ggg hhh
    \\ggg: out
    \\hhh: out
;

test "part2 example" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, example2);

    const result = try part2(ctx);
    std.debug.print("Day 11 Part 2 Example Result: {}\n", .{result});
    try std.testing.expectEqual(2, result);
}

test "part2" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, input);

    const result = try part2(ctx);
    std.debug.print("Day 11 Part 2 Result: {}\n", .{result});
    try std.testing.expectEqual(167507919734400, result);
}
