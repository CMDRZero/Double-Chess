const std = @import("std");
const win32 = @import("win32.zig");
const console = win32.system.console;
const KEY_EVENT = console.KEY_EVENT;
const MOUSE_EVENT = console.MOUSE_EVENT;
pub const UNICODE = true;

pub const input = @import("input.zig");

pub fn main() !void {
    @import("term.zig").EnableMouseAsInput();
    _ = std.os.windows.kernel32.SetConsoleOutputCP(65001);
    const stdin = console.GetStdHandle(console.STD_INPUT_HANDLE);
    

    while (true) {
        const num_events_read: u32 = try input.ReadInput(stdin);

        for (input.input_records[0..num_events_read]) |record| {
            if (record.EventType == KEY_EVENT) {
                const keyEvent = record.Event.KeyEvent;
                if (keyEvent.bKeyDown != 0) {
                    // std.debug.print("Key down: {} (code: {})\n", .{ keyEvent.UnicodeChar, keyEvent.wVirtualKeyCode });
                    std.debug.print("Key down: {c} (code: {})\n", .{ (keyEvent.uChar.AsciiChar), keyEvent.wVirtualKeyCode });
                } else {
                    // std.debug.print("Key up: {} (code: {})\n", .{ keyEvent.UnicodeChar, keyEvent.wVirtualKeyCode });
                    std.debug.print("Key up: {c} (code: {})\n", .{ keyEvent.uChar.AsciiChar, keyEvent.wVirtualKeyCode });
                }
            } else if (record.EventType == MOUSE_EVENT) {
                const mouseEvent = record.Event.MouseEvent;
                std.debug.print("Got position x: {}, y: {}\n", .{ mouseEvent.dwMousePosition.X, mouseEvent.dwMousePosition.Y });
                std.debug.print("Flags: {b}\n", .{ mouseEvent.dwEventFlags }); 
                std.debug.print("Buttons: {b}\n", .{ mouseEvent.dwButtonState }); 
            } else {
                std.debug.print("Got event: {}\n", .{ record.EventType });
            }
        }
    }
}