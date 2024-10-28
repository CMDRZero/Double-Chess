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
    //.{.player = {}},
    .{.cpu = bot.Compute},
    .{.player = {}},
    //.{.cpu = bot.Compute},
};

const botdelayms = 650;

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
    var madeMode: bool = false;
    
    main: while (true) : (it += 1) {
        bmap.DrawCells(tiles, orient);
        bmap.DrawCastleRights(game, orient);
        game.DrawBoard(&bmap, orient);

        const curragent = agents[@intFromEnum(game.currentPlayer)];
        switch (curragent) {
            .player => {
                const qmove = player.Handle(&game, moves, orient, &tiles) catch break: main;
                if (qmove) |move|{
                    game = gamecopy;
                    engine.ApplyMove(&game, move.first);
                    if (move.second) |smove| engine.ApplyMove(&game, smove);
                    madeMode = true;
                }
                //Ask the player handler for input, quit if they throw an error
            },
            .cpu  => |Compute| {
                const move = Compute(game);
                std.time.sleep(botdelayms * std.time.ns_per_ms);
                player.ResetTiles(&tiles);
                engine.ApplyMove(&game, move.first);
                tiles[move.first.from] = .highlight;
                tiles[move.first.to] = .highlight;
                bmap.DrawCells(tiles, orient);
                bmap.DrawCastleRights(game, orient);
                game.DrawBoard(&bmap, orient);
                try bmap.RenderBoard(&stdout);
                std.time.sleep(botdelayms * std.time.ns_per_ms);
                if (move.second) |smove| {
                    engine.ApplyMove(&game, smove);
                    tiles[smove.from] = .highlight;
                    tiles[smove.to] = .highlight;
                }
                bmap.DrawCells(tiles, orient);
                bmap.DrawCastleRights(game, orient);
                game.DrawBoard(&bmap, orient);
                try bmap.RenderBoard(&stdout);
                madeMode = true;
            },
        }
        if (madeMode){
            madeMode = false;
            game.NextMove();
            moves = try engine.LegalMoves(&game);
            if (moves.items.len == 0){
                try bmap.RenderBoard(&stdout);
                if (game.inCheck) {
                    game.NextMove();
                    std.debug.print("{s} wins by checkmate.\n", .{@tagName(game.currentPlayer)});
                } else {
                    std.debug.print("Stalemate.\n", .{});
                }
                break: main;
            }
            player.ack = false;
            gamecopy = game;
        }

        try bmap.RenderBoard(&stdout);
        std.debug.print("Iter: {}\n", .{it});
        std.debug.print("Players turn is {}\n", .{game.currentPlayer});
        std.time.sleep(5 * std.time.ns_per_ms);
    }
    std.debug.print("Program exited\n", .{});
}