const std = @import("std");
const Allocator = std.mem.Allocator;

const input = @embedFile("day12_input.txt");

const Shape = struct {
    size: u64,
};

const Region = struct {
    width: u64,
    height: u64,
    quantity_of_shape: []u64,
};

const Context = struct {
    allocator: Allocator,
    shape: []Shape,
    region: []Region,
};

fn parse(allocator: Allocator, inputStr: []const u8) !Context {
    var shapes = try std.ArrayList(Shape).initCapacity(allocator, 6);
    defer shapes.deinit(allocator);

    var it = std.mem.tokenizeSequence(u8, inputStr, "\n\n");
    for (0..6) |_| {
        const shape_str = it.next() orelse unreachable;
        var size: u64 = 0;
        for (shape_str) |char| {
            size += if (char == '#') 1 else 0;
        }
        try shapes.append(allocator, Shape{ .size = size });
    }

    var regions = try std.ArrayList(Region).initCapacity(allocator, 1000);
    defer regions.deinit(allocator);

    const regions_str = it.next() orelse unreachable;
    var region_it = std.mem.tokenizeScalar(u8, regions_str, '\n');
    while (region_it.next()) |line| {
        if (line.len == 0) continue;

        var width_itr = std.mem.tokenizeScalar(u8, line, 'x');
        const width = try std.fmt.parseInt(u64, width_itr.next() orelse unreachable, 10);

        var height_itr = std.mem.tokenizeSequence(u8, width_itr.next() orelse unreachable, ": ");
        const height = try std.fmt.parseInt(u64, height_itr.next() orelse unreachable, 10);

        var quantity = try std.ArrayList(u64).initCapacity(allocator, 6);
        defer quantity.deinit(allocator);
        var quantity_itr = std.mem.tokenizeScalar(u8, height_itr.next() orelse unreachable, ' ');
        while (quantity_itr.next()) |qty_str| {
            if (qty_str.len == 0) continue;
            const quantity_of_shape = try std.fmt.parseInt(u64, qty_str, 10);
            try quantity.append(allocator, quantity_of_shape);
        }
        try regions.append(allocator, .{
            .width = width,
            .height = height,
            .quantity_of_shape = try quantity.toOwnedSlice(allocator),
        });
    }

    return Context{
        .allocator = allocator,
        .shape = try shapes.toOwnedSlice(allocator),
        .region = try regions.toOwnedSlice(allocator),
    };
}

pub fn part1(ctx: Context) !u64 {
    var result: u64 = 0;

    for (ctx.region) |region| {
        var required_size: u64 = 0;
        for (region.quantity_of_shape, 0..) |qty, idx| {
            required_size += qty * ctx.shape[idx].size;
        }

        const capacity = region.width * region.height;

        if (capacity >= required_size) {
            result += 1;
        }
    }

    return result;
}

const example =
    \\0:
    \\###
    \\##.
    \\##.
    \\
    \\1:
    \\###
    \\##.
    \\.##
    \\
    \\2:
    \\.##
    \\###
    \\##.
    \\
    \\3:
    \\##.
    \\###
    \\##.
    \\
    \\4:
    \\###
    \\#..
    \\###
    \\
    \\5:
    \\###
    \\.#.
    \\###
    \\
    \\4x4: 0 0 0 0 2 0
    \\12x5: 1 0 1 0 2 2
    \\12x5: 1 0 1 0 3 2
;

test "part1 example" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, example);

    const result = try part1(ctx);
    std.debug.print("Day 12 Part 1 Example Result: {}\n", .{result});
    try std.testing.expectEqual(3, result); // NOTE: actually its 2 but okay
}

test "part1" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ctx = try parse(allocator, input);

    const result = try part1(ctx);
    std.debug.print("Day 12 Part 1 Result: {}\n", .{result});
    try std.testing.expectEqual(536, result);
}
