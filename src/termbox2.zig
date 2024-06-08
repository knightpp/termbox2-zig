const opts = @import("build_options");
pub const c = @cImport({
    @cDefine("TB_IMPL", {});
    if (opts.attr_w != .default) {
        @cDefine("TB_OPT_ATTR_W", std.fmt.comptimePrint("{}", .{@intFromEnum(opts.attr_w)}));
    }
    if (opts.egc) {
        @cDefine("TB_OPT_EGC", {});
    }
    if (opts.printf_buf != 0) {
        @cDefine("TB_OPT_PRINTF_BUF", std.fmt.comptimePrint("{}", .{opts.printf_buf}));
    }
    if (opts.read_buf != 0) {
        @cDefine("TB_OPT_READ_BUF", std.fmt.comptimePrint("{}", .{opts.read_buf}));
    }
    @cInclude("termbox2.h");
});
const std = @import("std");

pub const Error = error{
    UNRECOGNIZED,
    ERR,
    NEED_MORE,
    INIT_ALREADY,
    INIT_OPEN,
    MEM,
    NO_EVENT,
    NO_TERM,
    NOT_INIT,
    OUT_OF_BOUNDS,
    READ,
    RESIZE_IOCTL,
    RESIZE_PIPE,
    RESIZE_SIGACTION,
    POLL,
    TCGETATTR,
    TCSETATTR,
    UNSUPPORTED_TERM,
    RESIZE_WRITE,
    RESIZE_POLL,
    RESIZE_READ,
    RESIZE_SSCANF,
    CAP_COLLISION,
};

fn mapErr(int: c_int) Error {
    std.debug.assert(int < 0);

    return switch (int) {
        c.TB_ERR => Error.ERR,
        c.TB_ERR_NEED_MORE => Error.NEED_MORE,
        c.TB_ERR_INIT_ALREADY => Error.INIT_ALREADY,
        c.TB_ERR_INIT_OPEN => Error.INIT_OPEN,
        c.TB_ERR_MEM => Error.MEM,
        c.TB_ERR_NO_EVENT => Error.NO_EVENT,
        c.TB_ERR_NO_TERM => Error.NO_TERM,
        c.TB_ERR_NOT_INIT => Error.NOT_INIT,
        c.TB_ERR_OUT_OF_BOUNDS => Error.OUT_OF_BOUNDS,
        c.TB_ERR_READ => Error.READ,
        c.TB_ERR_RESIZE_IOCTL => Error.RESIZE_IOCTL,
        c.TB_ERR_RESIZE_PIPE => Error.RESIZE_PIPE,
        c.TB_ERR_RESIZE_SIGACTION => Error.RESIZE_SIGACTION,
        c.TB_ERR_POLL => Error.POLL,
        c.TB_ERR_TCGETATTR => Error.TCGETATTR,
        c.TB_ERR_TCSETATTR => Error.TCSETATTR,
        c.TB_ERR_UNSUPPORTED_TERM => Error.UNSUPPORTED_TERM,
        c.TB_ERR_RESIZE_WRITE => Error.RESIZE_WRITE,
        c.TB_ERR_RESIZE_POLL => Error.RESIZE_POLL,
        c.TB_ERR_RESIZE_READ => Error.RESIZE_READ,
        c.TB_ERR_RESIZE_SSCANF => Error.RESIZE_SSCANF,
        c.TB_ERR_CAP_COLLISION => Error.CAP_COLLISION,
        else => Error.UNRECOGNIZED,
    };
}

fn parseErr(int: c_int) Error!void {
    if (int >= 0) {
        return;
    }

    return mapErr(int);
}

pub const Attribute = switch (opts.attr_w) {
    .default, .@"16" => enum(c.uintattr_t) {
        default = c.TB_DEFAULT,
        black = c.TB_BLACK,
        red = c.TB_RED,
        green = c.TB_GREEN,
        yellow = c.TB_YELLOW,
        blue = c.TB_BLUE,
        magenta = c.TB_MAGENTA,
        cyan = c.TB_CYAN,
        white = c.TB_WHITE,
    },
    .@"32" => enum(c.uintattr_t) {
        default = c.TB_DEFAULT,
        black = c.TB_BLACK,
        red = c.TB_RED,
        green = c.TB_GREEN,
        yellow = c.TB_YELLOW,
        blue = c.TB_BLUE,
        magenta = c.TB_MAGENTA,
        cyan = c.TB_CYAN,
        white = c.TB_WHITE,

        bold = c.TB_BOLD,
        underline = c.TB_UNDERLINE,
        reverse = c.TB_REVERSE,
        italic = c.TB_ITALIC,
        blink = c.TB_BLINK,
        hi_black = c.TB_HI_BLACK,
        bright = c.TB_BRIGHT,
        dim = c.TB_DIM,
    },
    .@"64" => enum(c.uintattr_t) {
        default = c.TB_DEFAULT,
        black = c.TB_BLACK,
        red = c.TB_RED,
        green = c.TB_GREEN,
        yellow = c.TB_YELLOW,
        blue = c.TB_BLUE,
        magenta = c.TB_MAGENTA,
        cyan = c.TB_CYAN,
        white = c.TB_WHITE,

        bold = c.TB_BOLD,
        underline = c.TB_UNDERLINE,
        reverse = c.TB_REVERSE,
        italic = c.TB_ITALIC,
        blink = c.TB_BLINK,
        hi_black = c.TB_HI_BLACK,
        bright = c.TB_BRIGHT,
        dim = c.TB_DIM,

        strikeout = c.TB_STRIKEOUT,
        underline_2 = c.TB_UNDERLINE_2,
        overline = c.TB_OVERLINE,
        invisible = c.TB_INVISIBLE,
    },
};

pub fn init() Error!void {
    return parseErr(c.tb_init());
}
pub fn shutdown() Error!void {
    return parseErr(c.tb_shutdown());
}

pub fn width() Error!u32 {
    const w = c.tb_width();
    if (w < 0) {
        return mapErr(w);
    }
    return std.math.cast(u32, w) orelse unreachable;
}
pub fn height() Error!u32 {
    const h = c.tb_height();
    if (h < 0) {
        return mapErr(h);
    }
    return std.math.cast(u32, h) orelse unreachable;
}

pub fn clear() Error!void {
    return parseErr(c.tb_clear());
}
pub fn present() Error!void {
    return parseErr(c.tb_present());
}

pub fn set_cursor(cx: u32, cy: u32) Error!void {
    return parseErr(c.tb_set_cursor(@intCast(cx), @intCast(cy)));
}
pub fn hide_cursor() Error!void {
    return parseErr(c.tb_hide_cursor());
}

pub fn set_cell(x: u32, y: u32, char: u32, fg: Attribute, bg: Attribute) Error!void {
    return parseErr(c.tb_set_cell(@intCast(x), @intCast(y), char, @intFromEnum(fg), @intFromEnum(bg)));
}

pub fn peek_event(event: *c.tb_event, timeout_ms: c_int) Error!void {
    return parseErr(c.tb_peek_event(event, timeout_ms));
}
pub fn poll_event() !c.tb_event {
    var event: c.tb_event = std.mem.zeroes(c.tb_event);
    try parseErr(c.tb_poll_event(&event));
    return event;
}

pub fn print(x: u32, y: u32, fg: Attribute, bg: Attribute, str: [*:0]const u8) Error!void {
    return parseErr(c.tb_print(@intCast(x), @intCast(y), @intFromEnum(fg), @intFromEnum(bg), str));
}
pub fn printf(alloc: std.mem.Allocator, x: u32, y: u32, fg: Attribute, bg: Attribute, comptime fmt: []const u8, args: anytype) !void {
    var buf = std.ArrayList(u8).init(alloc);
    defer buf.deinit();

    try std.fmt.format(buf.writer(), fmt, args);
    try buf.append(0);

    try print(x, y, fg, bg, @ptrCast(buf.items));
}

const testing = std.testing;

test "width" {
    try init();

    const w = try width();
    try testing.expect(w > 0);

    try shutdown();
}

test "height" {
    try init();

    const h = try height();
    try testing.expect(h > 0);

    try shutdown();
}

test "clear" {
    try init();

    try clear();

    try shutdown();
}

test "present" {
    try init();

    try present();

    try shutdown();
}

test "set_cursor" {
    try init();

    try set_cursor(15, 15);

    try shutdown();
}

test "hide_cursor" {
    try init();

    try hide_cursor();

    try shutdown();
}

test "print" {
    try init();

    try print(0, 0, .default, .default, "test");

    try shutdown();
}

test "printf" {
    const alloc = testing.allocator;

    try init();

    try printf(alloc, 0, 0, .yellow, .default, "test {s}", .{"b"});

    try shutdown();
}

// test "poll_event" {
//     try init();

//     const event = try poll_event();
//     std.debug.print("{}", .{event});

//     try shutdown();

//     return error.Test;
// }
