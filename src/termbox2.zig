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

fn parseErr(int: c_int) Error!void {
    return switch (int) {
        c.TB_OK => {},
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
        else => {
            if (int > 0) {
                return;
            }

            return Error.UNRECOGNIZED;
        },
    };
}

pub fn init() Error!void {
    return parseErr(c.tb_init());
}
pub fn shutdown() Error!void {
    return parseErr(c.tb_shutdown());
}

pub fn width() Error!c_int {
    const w = c.tb_width();
    if (w > 0) {
        return w;
    }
    try parseErr(w);
    return w;
}
pub fn height() Error!c_int {
    const h = c.tb_height();
    if (h > 0) {
        return h;
    }
    try parseErr(h);
    return h;
}

pub fn clear() Error!void {
    return parseErr(c.tb_clear());
}
pub fn present() Error!void {
    return parseErr(c.tb_present());
}

pub fn set_cursor(cx: c_int, cy: c_int) Error!void {
    return parseErr(c.tb_set_cursor(cx, cy));
}
pub fn hide_cursor() Error!void {
    return parseErr(c.tb_hide_cursor());
}

pub fn set_cell(x: c_int, y: c_int, ch: u32, fg: c.uintattr_t, bg: c.uintattr_t) Error!void {
    return parseErr(c.tb_set_cell(x, y, ch, fg, bg));
}

pub fn peek_event(event: *c.tb_event, timeout_ms: c_int) Error!void {
    return parseErr(c.tb_peek_event(event, timeout_ms));
}
pub fn poll_event(event: *c.tb_event) Error!void {
    return parseErr(c.tb_poll_event(event));
}

pub fn print(x: c_int, y: c_int, fg: c.uintattr_t, bg: c.uintattr_t, str: [:0]const u8) Error!void {
    return parseErr(c.tb_print(x, y, fg, bg, str));
}
pub fn printf(alloc: std.mem.Allocator, x: c_int, y: c_int, fg: c.uintattr_t, bg: c.uintattr_t, comptime fmt: []const u8, args: anytype) !void {
    var buf = std.ArrayList(u8).init(alloc);
    defer buf.deinit();

    try std.fmt.format(buf.writer(), fmt, args);
    try buf.append(0);

    try print(x, y, fg, bg, @ptrCast(buf.items));
}
