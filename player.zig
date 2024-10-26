const std = @import("std");
const input = @import("input.zig");
const board = @import("board.zig");
const win32 = @import("win32.zig");
const engine = @import("engine.zig");

const Piece = board.Piece;
const Vec = @import("std").ArrayList;

pub var winstdin: *anyopaque = undefined;

const State = enum {
    unselected,
    selected,
    dispatks,
};

var state: State = .unselected;
pub var ack = true;

var oldMouseState: u32 = 0;
var selected: u6 = undefined;
var psel: Piece = undefined;
var fmov: board.SingleMove = undefined;
var substep: u1 = 0;

pub fn Handle(sboard: *board.SparseBoard, rawmoves: Vec(board.Move), orientation: board.Orientation, tiles: *board.Tileboard) !?board.Move {
    const evtsRead: u32 = try input.ReadInput(winstdin);
    var moves = Vec(board.SingleMove).init(rawmoves.allocator);
    
    for (rawmoves.items) |rawmove|{
        if (substep == 0){
            try moves.append(rawmove.first);
        } else if (std.meta.eql(rawmove.first, fmov)) {
            try moves.append(rawmove.second orelse continue);
        }
    }

    if (moves.items.len == 0) {
        substep = 0;
        return board.Move {.first = fmov, .second = null};
    }

    for (input.input_records[0..evtsRead]) |record| {
        if (record.EventType == input.KEY_EVENT) {
            const keyEvent = record.Event.KeyEvent;
            if (keyEvent.bKeyDown == 0 and keyEvent.uChar.AsciiChar == 'q') { //Keyup Q
                return error.Quit;
            } else if (keyEvent.bKeyDown == 0 and keyEvent.uChar.AsciiChar == 'd') { //Keyup D
                var oldmove: ?board.SingleMove = null;
                for (moves.items) |move| {
                    if (oldmove) |oldmovenotnull| {
                        if (!std.meta.eql(move, oldmovenotnull)) std.debug.print("\x1b[130GMove: `{s}`"++" "**30++"\n", .{NameMove(move)});
                    } else {
                        std.debug.print("\x1b[5;130HMove: `{s}`"++" "**30++"\n", .{NameMove(move)});
                    }
                    oldmove = move;
                    //std.debug.print("Move: `{}`\n", .{move});
                }
                for (0..20) |_| std.debug.print("\x1b[130G"++" "**30++"\n", .{});
            } else if (keyEvent.bKeyDown == 1 and keyEvent.uChar.AsciiChar == 'c' and state == .unselected) { //Keydown C and neutral
                state = .dispatks;
                var copyatks = sboard.attackers;
                ResetTiles(tiles);
                for(0..64) |ind| {
                    if (copyatks & 1 == 1) tiles[@intCast(ind)] = .capture;
                    copyatks >>= 1;
                }
            } else if (keyEvent.bKeyDown == 1 and keyEvent.uChar.AsciiChar == 'c' and state == .dispatks) { //Keydown C and was showing
                state = .unselected;
                ResetTiles(tiles);
            } 
        } else if (record.EventType == input.MOUSE_EVENT) {
            const mouseEvent = record.Event.MouseEvent;
            const mouseState = mouseEvent.dwButtonState;
            defer oldMouseState = mouseEvent.dwButtonState;
            if (oldMouseState & 2 == 2 and mouseState & 2 == 0) { //Right click up
                state = .unselected;
                ResetTiles(tiles);
            }
            if (oldMouseState & 1 == 1 and mouseState & 1 == 0) { //Left click up
                const mx = mouseEvent.dwMousePosition.X;
                const my = mouseEvent.dwMousePosition.Y;

                const cell = board.CoordToGridCell(mx, my, orientation) catch continue;

                if (state == .unselected) {
                    if (!ack) ResetTiles(tiles);
                    ack = true;

                    for (moves.items) |move| {if (move.from == cell) break;} else continue; //Escape if not a valid piece to move;
                    state = .selected;
                    selected = cell;
                    psel = sboard.PieceFromPos(cell).?;
                    
                    tiles[cell] = .highlight;
                    if (substep == 0){
                        for (rawmoves.items) |rawmove| {
                            const first = rawmove.first;
                            const sec = rawmove.second orelse continue;
                            if (first.from == selected and sec.from == first.to){
                                tiles[sec.to] = .double;
                            }
                        }
                    }
                    for (moves.items) |move| {
                        if (move.from == selected) {
                            if (sboard.PieceFromPos(move.to) != null){
                                tiles[move.to] = .capture;
                            } else {
                                tiles[move.to] = .move;
                            }
                        }
                    }
                } else if (state == .selected) {
                    state = .unselected;
                    ResetTiles(tiles);
                    for (moves.items) |move| {if (move.from == selected and move.to == cell) break;} else continue; //Escape if not a valid piece to move;
                    tiles[cell] = .highlight;
                    tiles[selected] = .highlight;
                    if (substep == 0){
                        substep = 1;
                        fmov = board.SingleMove{ .from = selected, .to = cell, .piece = psel};
                        engine.ApplyMove(sboard, fmov);
                        engine.ComputeCheckTiles(sboard);
                        for (rawmoves.items) |rawmove| {if (std.meta.eql(rawmove.first, fmov) and rawmove.second != null) break;} 
                        else {
                            substep = 0;
                            return board.Move {.first = fmov, .second = null};
                        }

                        
                    } else {
                        substep = 0;
                        return board.Move {.first = fmov, .second = board.SingleMove{ .from = selected, .to = cell, .piece = psel}};
                    }
                }
            }
        }
    }

    return null;
}

fn ResetTiles(tiles: *board.Tileboard) void {
    for(0..64) |ind| {
        tiles[@intCast(ind)] = .normal;
    }
}

fn NameMove(move: board.SingleMove) [] u8 {
    var buf: [128]u8 = undefined;
    return std.fmt.bufPrint(&buf, "{s}.{s} {s} -> {s}", .{@tagName(move.piece.color), @tagName(move.piece.piece), LetterTile(move.from), LetterTile(move.to)}) catch unreachable;
}

fn LetterTile(pos: u6) [2]u8 {
    const x = engine.GetX(pos);
    const y = engine.GetY(pos);
    var buf: [2] u8 = undefined;
    buf[0] = ([8]u8 {'H', 'G', 'F', 'E', 'D', 'C', 'B', 'A', })[x];
    buf[1] = ([8]u8 {'1', '2', '3', '4', '5', '6', '7', '8', })[y];
    return buf;
}