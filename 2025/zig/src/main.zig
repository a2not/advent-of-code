const std = @import("std");

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
}

const Regex = @import("advent_of_code").regex.Regex;

// test "simple test" {
//     const pattern = "^(.+)\\1+$";
//     var re = try Regex.compile(std.testing.allocator, pattern);
//     defer re.deinit();
//
//     std.debug.assert(try re.isMatch("123123123") == true);
// }

test {
    _ = @import("./day01.zig");
    // _ = @import("./day02.zig");
    _ = @import("./day03.zig");
    _ = @import("./day04.zig");
    _ = @import("./day05.zig");
}
