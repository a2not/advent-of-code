const std = @import("std");
const Allocator = std.mem.Allocator;

const input = @embedFile("day08_input.txt");

const position = struct {
    x: i64,
    y: i64,
    z: i64,
};

const Context = struct {
    allocator: Allocator,
    box: []position,
};

fn parse(allocator: Allocator, inputStr: []const u8) !Context {
    var boxAL = try std.ArrayList(position).initCapacity(allocator, 10000);
    defer boxAL.deinit(allocator);

    var it = std.mem.tokenizeScalar(u8, inputStr, '\n');
    while (it.next()) |line| {
        if (line.len == 0) continue;
        var p = std.mem.tokenizeScalar(u8, line, ',');

        const x = try std.fmt.parseInt(i64, p.next().?, 10);
        const y = try std.fmt.parseInt(i64, p.next().?, 10);
        const z = try std.fmt.parseInt(i64, p.next().?, 10);
        try boxAL.append(allocator, .{ .x = x, .y = y, .z = z });
    }
    const box = try boxAL.toOwnedSlice(allocator);

    return Context{
        .allocator = allocator,
        .box = box,
    };
}

const Edge = struct {
    score: i64,
    i: usize,
    j: usize,
};

fn compareEdges(_: void, a: Edge, b: Edge) std.math.Order {
    return std.math.order(a.score, b.score);
}
fn compareSizes(_: void, a: u64, b: u64) std.math.Order {
    return std.math.order(b, a); // desc
}

const UnionFind = @import("advent_of_code").UnionFind;

pub fn part1(ctx: Context, circuitsToConnect: usize) !u64 {
    const box = ctx.box;

    var pq = std.PriorityQueue(Edge, void, compareEdges).init(ctx.allocator, {});
    defer pq.deinit();

    for (0..box.len) |i| {
        for ((i + 1)..box.len) |j| {
            const posA = box[i];
            const posB = box[j];
            const dist = std.math.pow(i64, posA.x - posB.x, 2) + std.math.pow(i64, posA.y - posB.y, 2) + std.math.pow(i64, posA.z - posB.z, 2);
            try pq.add(.{ .score = dist, .i = i, .j = j });
        }
    }

    var uf = try UnionFind.init(ctx.allocator, box.len);
    defer uf.deinit(ctx.allocator);

    for (0..circuitsToConnect) |_| {
        const e = pq.remove();
        const i = e.i;
        const j = e.j;

        uf.unite(i, j);
    }

    var visitedAL = try std.ArrayList(bool).initCapacity(ctx.allocator, box.len);
    for (0..box.len) |_| {
        try visitedAL.append(ctx.allocator, false);
    }
    const visited = try visitedAL.toOwnedSlice(ctx.allocator);

    var sizes = std.PriorityQueue(u64, void, compareSizes).init(ctx.allocator, {});
    defer sizes.deinit();

    for (0..box.len) |i| {
        const root_i = uf.find(i);
        if (visited[root_i]) continue;
        visited[root_i] = true;

        const size = uf.get_size(i);
        try sizes.add(size);
    }
    return sizes.remove() * sizes.remove() * sizes.remove();
}

pub fn part2(ctx: Context) !i64 {
    const box = ctx.box;

    var pq = std.PriorityQueue(Edge, void, compareEdges).init(ctx.allocator, {});
    defer pq.deinit();

    for (0..box.len) |i| {
        for ((i + 1)..box.len) |j| {
            const posA = box[i];
            const posB = box[j];
            const dist = std.math.pow(i64, posA.x - posB.x, 2) + std.math.pow(i64, posA.y - posB.y, 2) + std.math.pow(i64, posA.z - posB.z, 2);
            try pq.add(.{ .score = dist, .i = i, .j = j });
        }
    }

    var uf = try UnionFind.init(ctx.allocator, box.len);
    defer uf.deinit(ctx.allocator);

    var result: i64 = 0;
    while (pq.removeOrNull()) |e| {
        const i = e.i;
        const j = e.j;

        const sameSet = uf.same_set(i, j);
        if (!sameSet) {
            result = box[i].x * box[j].x;
        }
        uf.unite(i, j);
    }

    return result;
}

const example =
    \\162,817,812
    \\57,618,57
    \\906,360,560
    \\592,479,940
    \\352,342,300
    \\466,668,158
    \\542,29,236
    \\431,825,988
    \\739,650,466
    \\52,470,668
    \\216,146,977
    \\819,987,18
    \\117,168,530
    \\805,96,715
    \\346,949,466
    \\970,615,88
    \\941,993,340
    \\862,61,35
    \\984,92,344
    \\425,690,689
;

test "part1 example" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, example);

    const result = try part1(ctx, 10);
    std.debug.print("Day 08 Part 1 Example Result: {}\n", .{result});
    try std.testing.expectEqual(40, result);
}

test "part1" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, input);

    const result = try part1(ctx, 1000);
    std.debug.print("Day 08 Part 1 Result: {}\n", .{result});
    try std.testing.expectEqual(131580, result);
}

test "part2 example" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, example);

    const result = try part2(ctx);
    std.debug.print("Day 08 Part 2 Example Result: {}\n", .{result});
    try std.testing.expectEqual(25272, result);
}

test "part2" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, input);

    const result = try part2(ctx);
    std.debug.print("Day 08 Part 2 Result: {}\n", .{result});
    try std.testing.expectEqual(6844224, result);
}
