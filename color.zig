const std = @import("std");

pub const Color = struct {
    red: u8, blue: u8, green: u8,
    pub fn RGB(red: u8, green: u8, blue: u8) Color {
        return Color{.red = red, .green = green, .blue = blue};
    }
};

pub fn SetFore(red: u8, green: u8, blue: u8, writer: anytype) !void {
    try writer.print("\x1b[38;2;{};{};{}m", .{red, green, blue});
}

pub fn SetBack(red: u8, green: u8, blue: u8, writer: anytype) !void {
    try writer.print("\x1b[48;2;{};{};{}m", .{red, green, blue});
}

pub fn SetForeColor(color: Color, writer: anytype) !void {
    try SetFore(color.red, color.green, color.blue, writer);
}

pub fn SetBackColor(color: Color, writer: anytype) !void {
    try SetBack(color.red, color.green, color.blue, writer);
}

pub fn Goto(x: u16, y: u16, writer: anytype) !void {
    try writer.print("\x1b[{};{}H", .{y, x});
}

test "Test" {
    SetFore(255, 0, 0);
    std.debug.print("Hello World!\n", .{});
}