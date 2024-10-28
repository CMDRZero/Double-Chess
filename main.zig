const std = @import("std");
const map = @import("map.zig");
const color = @import("color.zig");
const prefs = @import("prefs.zig");
const term = @import("term.zig");
const input = @import("input.zig");
const board = @import("board.zig");
const player = @import("player.zig");
const engine = @import("engine.zig");
pub const UNICODE = true;

const bot = @import("simplebot.zig");

const state = enum {
    animating,
    processing,
};

const agent = union (enum) {
    player: void,
    cpu: MoveGenerator,
};

const agents: [2] agent = .{
    .{.player = {}},
    //.{.cpu = bot.Compute},
    //.{.player = {}},
    .{.cpu = bot.Compute},
};

const MoveGenerator = * const fn (board.SparseBoard) board.Move;

pub fn main() !void {
    term.RGBEnable();
    term.EnableRawInput();
    term.EnableMouseAsInput();
    if (std.os.windows.kernel32.SetConsoleOutputCP(65001) != 1) @panic("Failed to set console mode!\n");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    engine.alloc = gpa.allocator();

    const rawstdout = std.io.getStdOut().writer();
    var stdout = std.io.bufferedWriter(rawstdout);
    player.winstdin = input.console.GetStdHandle(input.console.STD_INPUT_HANDLE);

    var bmap = map.Map {.colors = prefs.colors};
    bmap.DrawStatics();

    var game = board.SparseBoard {};
    var gamecopy = game;
    var tiles: board.Tileboard = .{.normal} ** 64;
    
    const orient: board.Orientation = .aswhite;
    var it: u64 = 0;
    var moves: std.ArrayList(board.Move) = try engine.LegalMoves(&game);
    
    main: while (true) : (it += 1) {
        //const moves = try engine.LegalMoves(game);
        //const moves = try engine.RawSingleMoves(game);
        
        bmap.DrawCells(tiles, orient);
        game.DrawBoard(&bmap, orient);

        const curragent = agents[@intFromEnum(game.currentPlayer)];
        var qmove: ?board.Move = null;
        switch (curragent) {
            .player => {
                qmove = player.Handle(&game, moves, orient, &tiles) catch break: main;
                //Ask the player handler for input, quit if they throw an error
            },
            .cpu  => |Compute| {
                qmove = Compute(game);
                std.time.sleep(900 * std.time.ns_per_ms);
            },
        }
        if (qmove) |move|{
            game = gamecopy;
            engine.ApplyMove(&game, move.first);
            if (move.second) |smove| engine.ApplyMove(&game, smove);
            game.NextMove();
            gamecopy = game;
            moves = try engine.LegalMoves(&game);
            player.ack = false;
        }

        try bmap.RenderBoard(&stdout);
        std.debug.print("Iter: {}\n", .{it});
        std.debug.print("Players turn is {}\n", .{game.currentPlayer});
        std.time.sleep(5 * std.time.ns_per_ms);
    }
    std.debug.print("Program exited\n", .{});
}