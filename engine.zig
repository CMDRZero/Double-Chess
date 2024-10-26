const std = @import("std");
const board = @import("board.zig");
const bits = @import("bits.zig");

const Move = board.Move;
const SingleMove = board.SingleMove;
const Board = board.SparseBoard;
const Piece = board.Piece;
const Vec = std.ArrayList;
const Bitboard = board.BitBoard;
const one: u64 = 1;

pub var alloc: std.mem.Allocator = undefined;

pub inline fn RawSingleMoves(game: Board) !Vec(SingleMove) {
    return CompMoves(.rawmoves, game);
}

pub inline fn ComputeCheckTiles(game: *Board) void {
    CompMoves(.setattackers, game);
}

pub fn CompMoves(comptime mode: enum {rawmoves, setattackers}, game: if (mode == .rawmoves) Board else *Board) if (mode == .rawmoves) anyerror!Vec(SingleMove) else void {
    var playID: u4 = undefined;
    var convID: u4 = undefined;
    if (mode == .rawmoves) {
        playID = @intFromEnum(game.currentPlayer);
        convID = 1-playID;
    } else {
        convID = @intFromEnum(game.currentPlayer);
        playID = 1-convID;
    }
    var moves = Vec(SingleMove).init(alloc);

    const allies: Bitboard = game.boards[0 + playID] | game.boards[2 + playID] | game.boards[4 + playID] | game.boards[6 + playID] | game.boards[8 + playID] | game.boards[10 + playID];
    const enemies: Bitboard = game.boards[0 + convID] | game.boards[2 + convID] | game.boards[4 + convID] | game.boards[6 + convID] | game.boards[8 + convID] | game.boards[10 + convID];
    const blocks: Bitboard = allies | enemies;

    if (mode == .setattackers) game.attackers = 0;

    var bb: Bitboard = undefined; 
    var pieceID: u4 = undefined;
    { //Pawn Handling
        pieceID = 0 + playID;
        const piece = Piece.Piece(pieceID);
        bb = game.boards[pieceID];           
        
        var ohpos: u64 = undefined;
        while (bb != 0) : (bb ^= ohpos) {               //Iterate over all pawns from the pawn bitboard buffer
            const pos = bits.LogHSB(bb);
            ohpos = one << pos;
            var temp: u64 = undefined;
            
            if (mode == .rawmoves) {
                temp = Forwards(ohpos, playID);    //Start with just a normal move forwards
                if (temp & blocks == 0) {
                    try moves.append( SingleMove{.from = pos, .to = bits.LogHSB(temp), .piece = piece});
                    try HandlePromotions(&moves);
                    if (GetY(pos) == @as(u3, if (playID == 0) 1 else 6)) {   //White can double jump on itial rank (1) and black on initial rank (6)
                        temp = Forwards(temp, playID);                      //Try double jump
                        if (temp & blocks == 0) {
                            try moves.append( SingleMove{.from = pos, .to = bits.LogHSB(temp), .piece = piece});
                            //You never promote from a double move
                        }
                    }
                }
            }
            
            const pawncap = enemies | game.enpassant;   //Pawns can also capture enpassant tiles so we add them here
            if (GetX(pos) < 7) {
                temp = Forwards(ohpos, playID) << 1;     //Forwards and towards A rank
                if (mode == .setattackers) game.attackers |= temp;
                if (temp & pawncap != 0) {
                    if (mode == .rawmoves) try moves.append( SingleMove{.from = pos, .to = bits.LogHSB(temp), .piece = piece});
                    if (mode == .rawmoves) try HandlePromotions(&moves);
                }
            }

            if (GetX(pos) > 0) {
                temp = Forwards(ohpos, playID) >> 1;     //Forwards and towards H rank
                if (mode == .setattackers) game.attackers |= temp;
                if (temp & pawncap != 0) {
                    if (mode == .rawmoves) try moves.append( SingleMove{.from = pos, .to = bits.LogHSB(temp), .piece = piece});
                    if (mode == .rawmoves) try HandlePromotions(&moves);
                }
            }
        }
    }
    {   //Rook Handling
        pieceID = 2 + playID;
        const piece = Piece.Piece(pieceID);
        bb = game.boards[pieceID];           
        
        var ohpos: u64 = undefined;
        while (bb != 0) : (bb ^= ohpos) { 
            //std.debug.print("From piece: {}\n", .{pieceID});
            const pos = bits.LogHSB(bb);
            ohpos = one << pos;
            var rms = GenerateRookMoves(pos, blocks);
            if (mode == .rawmoves) rms &= ~allies;
            var rdest: u6 = undefined;
            while (rms != 0) : (rms ^= one << rdest) {
                if (mode == .setattackers) game.attackers |= rms;
                rdest = bits.LogHSB(rms);
                if (mode == .rawmoves) try moves.append( SingleMove{.from = pos, .to = rdest, .piece = piece});
            } 
        }
    }
    {   //Bishop Handling
        pieceID = 6 + playID;
        const piece = Piece.Piece(pieceID);
        bb = game.boards[pieceID];           
        
        var ohpos: u64 = undefined;
        while (bb != 0) : (bb ^= ohpos) { 
            const pos = bits.LogHSB(bb);
            ohpos = one << pos;
            var rms = GenerateBishopMoves(pos, blocks);
            if (mode == .rawmoves) rms &= ~allies;
            var rdest: u6 = undefined;
            while (rms != 0) : (rms ^= one << rdest) {
                if (mode == .setattackers) game.attackers |= rms;
                rdest = bits.LogHSB(rms);
                if (mode == .rawmoves) try moves.append( SingleMove{.from = pos, .to = rdest, .piece = piece});
            } 
        }
    }
    {   //Queen Handling
        pieceID = 8 + playID;
        const piece = Piece.Piece(pieceID);
        bb = game.boards[pieceID];           
        
        var ohpos: u64 = undefined;
        while (bb != 0) : (bb ^= ohpos) { 
            const pos = bits.LogHSB(bb);
            ohpos = one << pos;
            var rms = GenerateBishopMoves(pos, blocks);
            rms |= GenerateRookMoves(pos, blocks);
            if (mode == .rawmoves) rms &= ~allies;
            var rdest: u6 = undefined;
            while (rms != 0) : (rms ^= one << rdest) {
                if (mode == .setattackers) game.attackers |= rms;
                rdest = bits.LogHSB(rms);
                if (mode == .rawmoves) try moves.append( SingleMove{.from = pos, .to = rdest, .piece = piece});
            } 
        }
    }
    {   //Knight Handling
        pieceID = 4 + playID;
        const piece = Piece.Piece(pieceID);
        bb = game.boards[pieceID];           
        
        var ohpos: u64 = undefined;
        while (bb != 0) : (bb ^= ohpos) { 
            const pos = bits.LogHSB(bb);
            ohpos = one << pos;
            var rms = GenerateKnightMoves(pos);
            if (mode == .rawmoves) rms &= ~allies;
            var rdest: u6 = undefined;
            while (rms != 0) : (rms ^= one << rdest) {
                if (mode == .setattackers) game.attackers |= rms;
                rdest = bits.LogHSB(rms);
                if (mode == .rawmoves) try moves.append( SingleMove{.from = pos, .to = rdest, .piece = piece});
            } 
        }
    }
    {   //King Handling  //Add Castling
        pieceID = 10 + playID;
        const piece = Piece.Piece(pieceID);
        bb = game.boards[pieceID];           
        
        var ohpos: u64 = undefined;
        while (bb != 0) : (bb ^= ohpos) { 
            const pos = bits.LogHSB(bb);
            ohpos = one << pos;
            var rms = GenerateKingMoves(pos);
            if (mode == .rawmoves) rms &= ~allies;
            var mov: u64 = undefined;
            while (rms != 0) : (rms ^= mov) {
                const rdest = bits.LogHSB(rms);
                mov = one << rdest;
                if (mode == .setattackers) game.attackers |= rms;
                if (mode == .rawmoves and mov & game.attackers == 0) {
                    try moves.append( SingleMove{.from = pos, .to = rdest, .piece = piece});
                }
            } 
        }
    }
    
    if (mode == .rawmoves) return moves;
}

pub fn LegalMoves(game: *Board) !Vec(Move) {
    ComputeCheckTiles(game);
    return RawDoubles(game.*);
    // var moves = Vec(Move).init(alloc);
    // for ((try RawSingleMoves(game)).items) |singlemove| {
    //     try moves.append(Move{.first = singlemove, .second = null});
    // }
    // return moves;
}

fn RawDoubles(game: Board) !Vec(Move) {
    var moves = Vec(Move).init(alloc);
    const first = try RawSingleMoves(game);
    const kingID = 10 + @as(u4, @intFromEnum(game.currentPlayer));
    for (first.items) |firstmov| {
        const currlength = moves.items.len;
        var newgame = game;
        ApplyMove(&newgame, firstmov);
        ComputeCheckTiles(&newgame);
        const secs = try RawSingleMoves(newgame);
        for (secs.items) |secmove| {
            if (newgame.PieceFromPos(secmove.to)) |cap| if(cap.piece == .king) { //If this move is a king capture
                moves.shrinkRetainingCapacity(currlength); //Abort all current moves because that was check
                try moves.append(Move{.first = firstmov, .second = null}); //Add this as a legal single move
                break;  //Stop checking new moves on this branch
            };
            var temp = newgame;
            ApplyMove(&temp, secmove);
            ComputeCheckTiles(&temp);
            if (temp.attackers & temp.boards[kingID] != 0) { //Cannot end in check
                continue;
            }
            try moves.append(Move{.first = firstmov, .second = secmove});
        }
    }
    return moves;
}

fn GenerateRookMoves(pos: u6, rawblockers: Bitboard) Bitboard {
    const blockers = rawblockers ^ one << pos;
    var atks: Bitboard = 0;
    var x: u3 = @intCast((pos & 7));
    var y: u3 = @intCast(pos >> 3);
    while (x > 0 and (blockers >> PackPos(x, y)) & 1 == 0) : (x -= 1){
        atks |= one << PackPos(x-1, y);
    }

    x = @intCast((pos & 7));
    y = @intCast(pos >> 3);
    while (x < 7 and (blockers >> PackPos(x, y)) & 1 == 0) : (x += 1){
        atks |= one << PackPos(x+1, y);
    }

    x = @intCast(pos & 7);
    y = @intCast((pos >> 3) );
    while (y > 0 and (blockers >> PackPos(x, y)) & 1 == 0) : (y -= 1){
        atks |= one << PackPos(x, y-1);
    }

    x = @intCast(pos & 7);
    y = @intCast((pos >> 3));
    while (y < 7 and (blockers >> PackPos(x, y)) & 1 == 0) : (y += 1){
        atks |= one << PackPos(x, y+1);
    }
    return atks;
}

fn GenerateKingMoves(pos: u6) Bitboard {
    var atks: Bitboard = 0;
    const x = @as(i5, GetX(pos));
    const y = @as(i5, GetY(pos));
    inline for (.{-1, 0, 1}) |dy| {
        inline for (.{-1, 0, 1}) |dx| {
            const tx = x + dx;
            const ty = y + dy;
            if (0 <= tx and tx <= 7 and 0 <= ty and ty <= 7) {
                atks |= one << PackPos(@intCast(tx), @intCast(ty));
            }
        }
    }
    return atks;
}

fn GenerateBishopMoves(pos: u6, rawblockers: Bitboard) Bitboard {
    const blockers = rawblockers ^ one << pos;
    var atks: Bitboard = 0;
    var x: u3 = GetX(pos);
    var y: u3 = GetY(pos);
    while (x > 0 and y > 0 and (blockers >> PackPos(x, y)) & 1 == 0) : ({x -= 1; y -= 1;}){
        atks |= one << PackPos(x-1, y-1);
    }

    x = GetX(pos); y = GetY(pos);
    while (x > 0 and y < 7 and (blockers >> PackPos(x, y)) & 1 == 0) : ({x -= 1; y += 1;}){
        atks |= one << PackPos(x-1, y+1);
    }

    x = GetX(pos); y = GetY(pos);
    while (x < 7 and y > 0 and (blockers >> PackPos(x, y)) & 1 == 0) : ({x += 1; y -= 1;}){
        atks |= one << PackPos(x+1, y-1);
    }

    x = GetX(pos); y = GetY(pos);
    while (x < 7 and y < 7 and (blockers >> PackPos(x, y)) & 1 == 0) : ({x += 1; y += 1;}){
        atks |= one << PackPos(x+1, y+1);
    }
    return atks;
}

fn GenerateKnightMoves(pos: u6) Bitboard {
    var atks: Bitboard = 0;
    const x = @as(i5, GetX(pos));
    const y = @as(i5, GetY(pos));
    var tx = x;
    var ty = y;
    inline for (.{-1, 1}) |signy| {
        inline for (.{-1, 1}) |signx| {
            tx = x + 2 * signx;
            ty = y + 1 * signy;
            if (0 <= tx and tx <= 7 and 0 <= ty and ty <= 7) {
                atks |= one << PackPos(@intCast(tx), @intCast(ty));
            }
            tx = x + 1 * signx;
            ty = y + 2 * signy;
            if (0 <= tx and tx <= 7 and 0 <= ty and ty <= 7) {
                atks |= one << PackPos(@intCast(tx), @intCast(ty));
            }
        }
    }
    return atks;
}

pub fn ApplyMove(game: *Board, move: SingleMove) void {
    const pid = move.piece.Int();
    const qdid = game.PieceFromPos(move.to);
    game.boards[pid] ^= one << move.from;
    game.boards[pid] ^= one << move.to;
    if (qdid) |did| {
        game.boards[did.Int()] ^= one << move.to;
    }
}

inline fn Forwards(val: u64, dir: u4) u64 {
    return std.math.rotl(u64, val, 8 -% 16 * @as(u64, dir));
}

inline fn PosForwards(val: u6, dir: u4) u6 {
    return val + 8 -% 16 * @as(u6, dir);
}

///Assumes the most recent move exists and is a pawn move
fn HandlePromotions(moves: *Vec(SingleMove)) !void {
    const recent = moves.items[moves.items.len - 1];
    if (recent.to >> 3 == 0 or recent.to & 0o10 == 7) { //If a pawn somehow ends up on the first or last rank, its promoted
        moves.items[moves.items.len - 1].promotion = Piece{.piece = .queen, .color = recent.piece.color};
        var tempmove = recent;
        tempmove.promotion = Piece{.piece = .rook, .color = recent.piece.color};
        try moves.append(tempmove);
        tempmove.promotion = Piece{.piece = .knight, .color = recent.piece.color};
        try moves.append(tempmove);
        tempmove.promotion = Piece{.piece = .bishop, .color = recent.piece.color};
        try moves.append(tempmove);
    }
}

pub inline fn PackPos(x: u3, y: u3) u6 {
    return @as(u6, y) << 3 | @as(u6, x);
}

pub inline fn GetX(pos: u6) u3 {
    return @intCast(pos & 7);
}
pub inline fn GetY(pos: u6) u3 {
    return @intCast(pos >> 3);
}