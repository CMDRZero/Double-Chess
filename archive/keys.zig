const std = @import("std");
const win32 = @import("win32.zig");
const console = win32.system.console;
const KEY_EVENT = console.KEY_EVENT;
const MOUSE_EVENT = console.MOUSE_EVENT;
pub const UNICODE = true;

pub fn main() !void {
    @import("term.zig").EnableMouseAsInput();
    std.debug.print("Current mouse mode is: {}\n", .{@import("term.zig").GetMouseInputMode()});

    _ = std.os.windows.kernel32.SetConsoleOutputCP(65001);
    const stdin = console.GetStdHandle(console.STD_INPUT_HANDLE);
    
    var input_records: [1]console.INPUT_RECORD = undefined;

    while (true) {
        var num_events_read: u32 = 0;
        const result = console.ReadConsoleInput(
            stdin,                          // Handle to the console input buffer
            &input_records,                 // Pointer to the buffer to receive the input records
            @intCast(input_records.len),    // Number of input records to read
            &num_events_read,               // Pointer to the variable that receives the number of input records read
        );
        if (result != std.os.windows.TRUE) {
            const err = std.os.windows.kernel32.GetLastError();
            std.debug.print("Failed to read console input: {}\n", .{err});
            break;
        }

        for (input_records[0..num_events_read]) |record| {
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
                std.debug.print("Got event: {}\n", .{ record.EventType });
            } else {
                std.debug.print("Got event: {}\n", .{ record.EventType });
            }
        }
    }
}