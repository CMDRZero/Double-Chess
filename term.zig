const std = @import("std");
const win32 = @import("win32.zig");

pub fn RGBEnable() void {
    const hOutput = win32.system.console.GetStdHandle(win32.system.console.STD_OUTPUT_HANDLE);
    var dwMode: win32.system.console.CONSOLE_MODE = undefined;
    _ = win32.system.console.GetConsoleMode(hOutput, &dwMode);
    dwMode = @bitCast(@as(u32, @bitCast(dwMode)) 
        | @as(u32, @bitCast(win32.system.console.ENABLE_LINE_INPUT)) 
        | @as(u32, @bitCast(win32.system.console.ENABLE_VIRTUAL_TERMINAL_PROCESSING)) 
        | @as(u32, @bitCast(win32.system.console.ENABLE_PROCESSED_OUTPUT)));
    _ = win32.system.console.SetConsoleMode(hOutput, dwMode);
}

pub fn EnableRawInput() void {
    const hInput = win32.system.console.GetStdHandle(win32.system.console.STD_INPUT_HANDLE);
    var dwMode: win32.system.console.CONSOLE_MODE = undefined;
    _ = win32.system.console.GetConsoleMode(hInput, &dwMode);
    dwMode = @bitCast(@as(u32, @bitCast(dwMode)) 
        & ~@as(u32, @bitCast(win32.system.console.ENABLE_LINE_INPUT)));
    _ = win32.system.console.SetConsoleMode(hInput, dwMode);
}

pub fn EnableMouseAsInput() void {
    const hInput = win32.system.console.GetStdHandle(win32.system.console.STD_INPUT_HANDLE);
    var dwMode: win32.system.console.CONSOLE_MODE = undefined;
    _ = win32.system.console.GetConsoleMode(hInput, &dwMode);
    dwMode = @bitCast(@as(u32, @bitCast(dwMode)) 
        | @as(u32, @bitCast(win32.system.console.ENABLE_WINDOW_INPUT))
        | @as(u32, @bitCast(win32.system.console.ENABLE_EXTENDED_FLAGS))
        | @as(u32, @bitCast(win32.system.console.ENABLE_MOUSE_INPUT))
        & ~@as(u32, @bitCast(win32.system.console.ENABLE_QUICK_EDIT_MODE))); 
    _ = win32.system.console.SetConsoleMode(hInput, dwMode);
}

pub fn GetInputMode() bool {
    const hInput = win32.system.console.GetStdHandle(win32.system.console.STD_INPUT_HANDLE);
    var dwMode: win32.system.console.CONSOLE_MODE = undefined;
    _ = win32.system.console.GetConsoleMode(hInput, &dwMode);
    return 0 != (@as(u32, @bitCast(dwMode)) & @as(u32, @bitCast(win32.system.console.ENABLE_LINE_INPUT)));
}

pub fn GetMouseInputMode() bool {
    const hInput = win32.system.console.GetStdHandle(win32.system.console.STD_INPUT_HANDLE);
    var dwMode: win32.system.console.CONSOLE_MODE = undefined;
    _ = win32.system.console.GetConsoleMode(hInput, &dwMode);
    return 0 != (@as(u32, @bitCast(dwMode)) & @as(u32, @bitCast(win32.system.console.ENABLE_MOUSE_INPUT)));
}

pub fn GotoTrueCursorOrigin() void {
    const hOutput = win32.system.console.GetStdHandle(win32.system.console.STD_OUTPUT_HANDLE);
    const COORD = win32.system.console.COORD;
    const code = win32.system.console.SetConsoleCursorPosition(hOutput, COORD{.X = 0, .Y = 0});
    if (code != std.os.windows.TRUE) {
        var buf: [512] u8 = undefined; 
        const err: win32.foundation.WIN32_ERROR = win32.foundation.GetLastError();
        const ecode = @tagName(err);
        
        @panic(std.fmt.bufPrint(&buf, "Cursor set failed, got code: {s}\n", .{ecode}) catch unreachable);
    }
}