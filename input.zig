const std = @import("std");
const win32 = @import("win32.zig");
pub const console = win32.system.console;
pub const KEY_EVENT = console.KEY_EVENT;
pub const MOUSE_EVENT = console.MOUSE_EVENT;
pub const UNICODE = true;

pub var input_records: [1]console.INPUT_RECORD = undefined;

pub fn ReadInput(stdin: *anyopaque) !u32 {
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
        return error.console_read_failure;
    }
    return num_events_read;
}