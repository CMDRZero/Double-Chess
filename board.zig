const map = @import("map.zig");

const Piecetype = map.Piecetype;

pub const BitBoard = u64;
const CompactBoard = [4]BitBoard; //Basically a [64] u4, but we store each bit in its own board for simplicity sake, only every used for compression anyways

pub const Orientation = enum {
    aswhite,
    asblack,
};

pub const Color = enum(u1) {
    white,
    black,
    pub inline fn Int(self: Color) u1 {return @intFromEnum(self);}
};

pub const Piece = packed struct(u4) {
    color: Color,
    piece: Piecetype,

    pub inline fn Int(self: @This()) u4 {
        return @bitCast(self);
    }
    pub inline fn Piece(val: u4) @This() {
        return @bitCast(val);
    }
};

pub const TileState = enum(u4) {
    normal = 1,
    highlight = 3,
    move = 4,
    capture = 5,
    double = 6,
    illegal = 7,
    pub fn Int(self: @This()) u4 {
        return @intFromEnum(self);
    }
};
pub const Tileboard = [64]TileState;

pub const Move = struct {
    first: SingleMove,
    second: ?SingleMove,    //Second move might not exist like on turn 1 and if you place in check
};

pub const SingleMove = struct {
    flags: MoveFlag,
    piece: Piece,
    from: u6,
    to: u6,
};

pub const CompactMove = packed struct (u16) {
    flags: MoveFlag,
    from: u6,
    to: u6,
};

pub const MoveFlag = enum (u4) {
    quiet = 0,
    doublejump = 1,
    kingcastle = 2,
    queencastle = 3,
    capture = 4,
    en_capture = 5,
    prom_rook = 8,
    prom_knight = 9,
    prom_bishop = 10,
    prom_queen = 11,
    cap_prom_rook = 12,
    cap_prom_knight = 13,
    cap_prom_bishop = 14,
    cap_prom_queen = 15,

    pub inline fn Int(self: @This()) u4 {return @intFromEnum(self);}

    pub fn GetPromotion(self: @This(), color: Color) ?Piece {
        if (self.Int() & 0b1000 != 0){
            return Piece{.piece = @enumFromInt((self.Int() & 7) + 1), .color = color};
        } else {
            return null;
        }
    }

    pub fn AddPromotion(self: *@This(), piece: Piecetype) void {
        self.* = @enumFromInt(self.Int() | 0b1000 | (@intFromEnum(piece) - 1));
    }
};

pub const SparseBoard = struct {
    boards: [12]BitBoard = .{
        0b11111111_00000000, //whitepawn
        @bitReverse(@as(BitBoard, 0b11111111_00000000)), //blackpawn
        0b00000000_10000001, //whiterook
        @bitReverse(@as(BitBoard, 0b00000000_10000001)), //blackrook
        0b00000000_01000010, //whiteknight
        @bitReverse(@as(BitBoard, 0b00000000_01000010)), //blackknight
        0b00000000_00100100, //whitebishop
        @bitReverse(@as(BitBoard, 0b00000000_00100100)), //blackbishop
        0b00000000_00010000, //whitequeen
        @bitReverse(@as(BitBoard, 0b00000000_00001000)), //blackqueen
        0b00000000_00001000, //whiteking
        @bitReverse(@as(BitBoard, 0b00000000_00010000)), //blackking
    },

    enpassant: BitBoard = 0,
    attackers: BitBoard = 0x00_00_FF_FF_00_00_00_00,
    kingcastle: [2] bool = .{true, true},
    queencastle: [2] bool = .{true, true},
    currentPlayer: Color = .white,
    inCheck: bool = false,
    firstmove: bool = true,

    const Self = @This();

    pub fn DrawBoard(self: Self, bmap: *map.Map, orient: Orientation) void {
        for (0..6) |idx| {
            DrawBitBoard(bmap, 5, self.boards[@intCast(2 * idx)], @enumFromInt(idx), orient); //Whitepieces
            DrawBitBoard(bmap, 4, self.boards[@intCast(2 * idx + 1)], @enumFromInt(idx), orient); //Blackpieces
        }
    }

    pub fn PieceFromPos(self: Self, pos: u6) ?Piece {
        const sel: u64 = @as(u64, 1) << pos;
        for (0..12) |idx| {
            if (self.boards[idx] & sel != 0) return Piece.Piece(@intCast(idx));
        }
        return null;
    }

    pub fn NextMove(self: *Self) void {
        self.firstmove = false;
        self.currentPlayer = @enumFromInt(~@intFromEnum(self.currentPlayer));
    }
};

pub fn CoordToGridCell(x: i32, y: i32, orient: Orientation) !u6 {
    const relx = x - 7; //x relative to the top left of the board
    const rely = 2 * y - 7;

    if (relx < 0 or relx >= 8 * 13) return error.Out_of_Bounds;
    if (rely < 0 or rely >= 8 * 13) return error.Out_of_Bounds;

    const gridx: u3 = @intCast(@divFloor(relx, 13)); //0 is left side
    const gridy: u3 = @intCast(@divFloor(rely, 13)); //0 is top

    var pos = @as(u6, gridy) << 3 | @as(u6, gridx); //00 is top left, which is only true for black, thus
    if (orient == .aswhite) {
        pos = @as(u6, 7 - gridy) << 3 | @as(u6, 7 - gridx); //Now 00 is bottom right
    }
    return pos;
}

fn DrawBitBoard(bmap: *map.Map, colorID: u4, bitboard: BitBoard, piece: map.Piecetype, orient: Orientation) void {
    var copy = bitboard;
    for (0..8) |y| {
        for (0..8) |x| {
            if (copy & 1 == 1) {
                if (orient == .aswhite) {
                    bmap.DrawPiece(piece, colorID, @intCast(7 - x), @intCast(7 - y));
                } else {
                    bmap.DrawPiece(piece, colorID, @intCast(x), @intCast(y));
                }
            }
            copy >>= 1;
        }
    }
}
