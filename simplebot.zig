const engine = @import("engine.zig");
const board = @import("board.zig");


pub fn Compute(game: board.SparseBoard) board.Move {
    const moves = engine.ReadLegalMoves(game) catch unreachable;
    var value: i32 = -100_000;
    var cmove = moves.items[0];
    for (moves.items) |move| {
        var temp = game;
        engine.ApplyTurn(&temp, move);
        const nval = Valuate(temp);
        if (nval > value){
            value = nval;
            cmove = move;
        }
    }
    return cmove;
}

fn Valuate(game: board.SparseBoard) i32 {
    const playID: u1 = @intFromEnum(game.currentPlayer);
    const convID: u1 = 1-playID;
    const values = [5]i32 {1_000, 5_000, 4_000, 3_000, 9_000};
    var val: i32 = 0;
    for (0..5) |idx| {
        val += values[idx] * @popCount(game.boards[2 * idx + playID]);
        val -= values[idx] * @popCount(game.boards[2 * idx + convID]);
    }
    return val;
}