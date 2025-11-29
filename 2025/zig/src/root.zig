//! By convention, root.zig is the root source file when making a library.
pub const regex = @import("regex");

const std = @import("std");
pub const posix_regex = @cImport(@cInclude("regez.h"));
const REGEX_T_SIZEOF = posix_regex.sizeof_regex_t;
const REGEX_T_ALIGNOF = posix_regex.alignof_regex_t;

// TODO: PCRE2: https://sheran.sg/blog/building-and-using-pcre2-in-zig/

pub const RegexOptions = packed struct {
    extended: bool = true, // REG_EXTENDED: 0x001
    ignore_case: bool = false, // REG_ICASE: 0x002
    newline: bool = false, // REG_NEWLINE: 0x004
    nosub: bool = false, // REG_NOSUB: 0x008
};

const RegexFlags = packed union {
    value: u4,
    flags: RegexOptions,
};

pub const Regex = struct {
    const Self = @This();
    reg: [*]posix_regex.regex_t, // TODO: opaque size unknown
    pub fn compile(allocator: std.mem.Allocator, pattern: [:0]const u8, opts: RegexOptions) error{NotCompiled}!Regex {
        const slice = try allocator.alignedAlloc(u8, REGEX_T_ALIGNOF, REGEX_T_SIZEOF);
        defer allocator.free(slice);

        const reg: [*]posix_regex.regex_t = @ptrCast(slice.ptr);
        const flags = RegexFlags{ .flags = opts };
        if (posix_regex.regcomp(reg, pattern, @as(c_int, flags.value)) != 0) {
            return error.NotCompiled;
        }
        return .{ .reg = reg };
    }
    pub fn deinit(self: *Self) void {
        posix_regex.regfree(self.reg);
    }
    pub fn match(self: *Self, text: [:0]const u8) bool {
        return posix_regex.regexec(self.reg, text, 0, null, 0) == 0;
    }
};
