const std = @import("std");
const Allocator = std.mem.Allocator;

const input = @embedFile("day09_input.txt");

const Point = struct {
    x: i64,
    y: i64,
};

const Context = struct {
    allocator: Allocator,
    tile: []Point,
};

fn parse(allocator: Allocator, inputStr: []const u8) !Context {
    var tileAL = try std.ArrayList(Point).initCapacity(allocator, 10000);
    defer tileAL.deinit(allocator);

    var it = std.mem.tokenizeScalar(u8, inputStr, '\n');
    while (it.next()) |line| {
        if (line.len == 0) continue;
        var p = std.mem.tokenizeScalar(u8, line, ',');

        const x = try std.fmt.parseInt(i64, p.next().?, 10);
        const y = try std.fmt.parseInt(i64, p.next().?, 10);
        try tileAL.append(allocator, .{ .x = x, .y = y });
    }
    const tile = try tileAL.toOwnedSlice(allocator);

    return Context{
        .allocator = allocator,
        .tile = tile,
    };
}

pub fn part1(ctx: Context) !i64 {
    const tile = ctx.tile;
    var result: i64 = 0;

    for (0..tile.len) |i| {
        for (0..i) |j| {
            const dx: i64 = @intCast(@abs(tile[i].x - tile[j].x) + 1);
            const dy: i64 = @intCast(@abs(tile[i].y - tile[j].y) + 1);
            result = @max(result, dx * dy);
        }
    }

    return result;
}

const Edge = struct {
    a: Point,
    b: Point,
    is_horizontal: bool,
};

pub fn part2(ctx: Context) !i64 {
    const tile = ctx.tile;

    var edgeAL = try std.ArrayList(Edge).initCapacity(ctx.allocator, tile.len);
    defer edgeAL.deinit(ctx.allocator);
    for (0..tile.len) |i| {
        const j = @mod(i + 1, tile.len);
        const is_horizontal = tile[i].y == tile[j].y;
        try edgeAL.append(ctx.allocator, .{
            .a = Point{ .x = @min(tile[i].x, tile[j].x), .y = @min(tile[i].y, tile[j].y) },
            .b = Point{ .x = @max(tile[i].x, tile[j].x), .y = @max(tile[i].y, tile[j].y) },
            .is_horizontal = is_horizontal,
        });
    }
    const edge = try edgeAL.toOwnedSlice(ctx.allocator);

    var result: i64 = 0;

    for (0..tile.len) |i| {
        for (0..i) |j| {
            const max_x: i64 = @max(tile[i].x, tile[j].x);
            const max_y: i64 = @max(tile[i].y, tile[j].y);
            const min_x: i64 = @min(tile[i].x, tile[j].x);
            const min_y: i64 = @min(tile[i].y, tile[j].y);
            const dx: i64 = max_x - min_x + 1;
            const dy: i64 = max_y - min_y + 1;
            const area: i64 = dx * dy;
            if (area <= result) continue;

            // corners
            const left_top = Point{ .x = min_x, .y = min_y };
            const left_bottom = Point{ .x = min_x, .y = max_y };
            const right_top = Point{ .x = max_x, .y = min_y };
            const right_bottom = Point{ .x = max_x, .y = max_y };

            const corners = [_]Point{ left_top, left_bottom, right_top, right_bottom };
            const rect_edge = [_]Edge{
                .{ .a = left_top, .b = right_top, .is_horizontal = true },
                .{ .a = left_bottom, .b = right_bottom, .is_horizontal = true },
                .{ .a = left_top, .b = left_bottom, .is_horizontal = false },
                .{ .a = right_top, .b = right_bottom, .is_horizontal = false },
            };

            var found_all: bool = true;
            for (corners) |p| {
                // check if any one of corners is outside of red/green tiles
                var found_corner: bool = false;
                var appeard_left: i64 = 0;
                for (edge) |e| {
                    if (e.is_horizontal) {
                        // on the edge
                        if (p.y == e.a.y and e.a.x <= p.x and p.x <= e.b.x) {
                            found_corner = true;
                        }
                    } else {
                        // on the edge
                        if (p.x == e.a.x and e.a.y <= p.y and p.y <= e.b.y) {
                            found_corner = true;
                        }

                        // count number of time p appeared to the left of an edge
                        if (p.x < e.a.x and e.a.y < p.y and p.y <= e.b.y) {
                            appeard_left += 1;
                        }
                    }
                }
                if (@mod(appeard_left, 2) != 0) {
                    found_corner = true;
                }
                if (!found_corner) {
                    found_all = false;
                    break;
                }
            }
            if (!found_all) continue;

            var is_illegal: bool = false;
            // check for intersection
            for (edge) |e| {
                for (rect_edge) |re| {
                    if (e.is_horizontal != re.is_horizontal) {
                        const h_edge = if (e.is_horizontal) e else re;
                        const v_edge = if (e.is_horizontal) re else e;

                        const hx1 = h_edge.a.x;
                        const hx2 = h_edge.b.x;
                        const hy = h_edge.a.y;

                        const vx = v_edge.a.x;
                        const vy1 = v_edge.a.y;
                        const vy2 = v_edge.b.y;

                        if (hx1 < vx and vx < hx2 and vy1 < hy and hy < vy2) {
                            is_illegal = true;
                        }
                    }
                }
            }
            if (is_illegal) continue;
            result = area;
        }
    }

    return result;
}

const example =
    \\7,1
    \\11,1
    \\11,7
    \\9,7
    \\9,5
    \\2,5
    \\2,3
    \\7,3
;

test "part1 example" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, example);

    const result = try part1(ctx);
    std.debug.print("Day 09 Part 1 Example Result: {}\n", .{result});
    try std.testing.expectEqual(50, result);
}

test "part1" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, input);

    const result = try part1(ctx);
    std.debug.print("Day 09 Part 1 Result: {}\n", .{result});
    try std.testing.expectEqual(4777967538, result);
}

test "part2 example" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, example);

    const result = try part2(ctx);
    std.debug.print("Day 09 Part 2 Example Result: {}\n", .{result});
    try std.testing.expectEqual(24, result);
}

test "part2" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, input);

    const result = try part2(ctx);
    std.debug.print("Day 09 Part 2 Result: {}\n", .{result});
    try std.testing.expectEqual(6844224, result);
}
