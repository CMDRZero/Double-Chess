pub const std = @import("std");
pub const math = std.math;
pub const color = @import("color.zig");
pub const term = @import("term.zig");
pub const board = @import("board.zig");

pub const bitshape = std.meta.Int(.unsigned, 13*13);
const bheight = 5 + 2 + 13 * 8 + 2;
const bwidth = bheight + 13 + 2 + 13 + 5 + 13 + 5 + 13;
pub const Board = [bheight][bwidth] u4;

const Color = color.Color;

pub const Piecetype = enum (u3) {
    pawn = 0,
    rook = 1,
    knight = 2,
    bishop = 3,
    queen = 4,
    king = 5,
    attack = 6,
    double = 7,
};

const letters = [_]u25 {
    _A_shape,
    _B_shape,
    _C_shape,
    _D_shape,
    _E_shape,
    _F_shape,
    _G_shape,
    _H_shape,
    _1_shape,
    _2_shape,
    _3_shape,
    _4_shape,
    _5_shape,
    _6_shape,
    _7_shape,
    _8_shape,
};

const Colorpair = struct {
    fore: u4, 
    back: u4,

    fn WritePair(self: *@This(), top: u4, bottom: u4, colors: [16] Color, writer: anytype) !void {
        if (top == self.fore and bottom == self.back) {
            try writer.print("{u}", .{'▀'});
        } else if (top == self.back and bottom == self.fore) {
            try writer.print("{u}", .{'▄'});
        } else if (top == self.fore and bottom == self.fore) {
            try writer.print("{u}", .{'█'});
        } else if (top == self.back and bottom == self.back) {
            try writer.print("{u}", .{' '});
        } else if (top == self.fore) {
            self.back = bottom;
            try color.SetBackColor(colors[bottom], writer);
            try writer.print("{u}", .{'▀'});
        } else if (top == self.back) {
            self.fore = bottom;
            try color.SetForeColor(colors[bottom], writer);
            try writer.print("{u}", .{'▄'});
        } else if (bottom == self.fore) {
            self.back = top;
            try color.SetBackColor(colors[top], writer);
            try writer.print("{u}", .{'▄'});
        } else if (bottom == self.back) {
            self.fore = top;
            try color.SetForeColor(colors[top], writer);
            try writer.print("{u}", .{'▀'});
        } else {
            self.fore = top;
            self.back = bottom;
            try color.SetForeColor(colors[top], writer);
            try color.SetBackColor(colors[bottom], writer);
            try writer.print("{u}", .{'▀'});
        }
    }
    fn SetWrite(self: *@This(), top: u4, bottom: u4, colors: [16] Color, writer: anytype) !void {
        self.fore = top;
        self.back = bottom;
        try color.SetForeColor(colors[top], writer);
        try color.SetBackColor(colors[bottom], writer);
        try writer.print("{u}", .{'▀'});
    }
    fn CreateWrite(top: u4, bottom: u4, colors: [16] Color, writer: anytype) !@This() {
        try color.SetForeColor(colors[top], writer);
        try color.SetBackColor(colors[bottom], writer);
        try writer.print("{u}", .{'▀'});
        return @This() {.fore = top, .back = bottom, };
    }
};

pub const Map = struct {
    const Self = @This();
    colors: [16] Color = undefined,
    backer: Board = .{.{0} ** bwidth} ** bheight,

    pub fn WriteSquare(self: *Self, comptime width: u8, mask: std.meta.Int(.unsigned, width * width), colorID: u4, x: u16, y: u16) void {
        var copymask = mask;
        for (0..width) |dy| {
            for (0..width) |dx| {
                if (copymask & 1 == 1){
                    self.backer[y + dy][x + dx] = colorID;
                }
                copymask >>= 1;
            }
        }
    }

    pub fn DrawPiece(self: *Self, piece: Piecetype, colorID: u4, xcell: u3, ycell: u3) void {
        const mask = switch (piece){
            .pawn => pawnshape,
            .rook => rookshape,
            .knight => knightshape,
            .bishop => bishopshape,
            .queen => queenshape,
            .king => kingshape,
            .attack => attackshape,
            .double => doubleshape
        };
        self.WriteSquare(13, mask, colorID, 7 + 13 * @as(u16, xcell), 7 + 13 * @as(u16, ycell));
    }

    pub fn DrawLetter(self: *Self, letter: u3, colorID: u4, xcell: u3) void {
        const mask = letters[letter];
        self.WriteSquare(5, mask, colorID, 7 + 4 + 13 * @as(u16, xcell), 0);
    }

    pub fn DrawNumber(self: *Self, letter: u3, colorID: u4, ycell: u3) void {
        const mask = letters[8+@as(u4, letter)];
        self.WriteSquare(5, mask, colorID, 0, 7 + 4 + 13 * @as(u16, ycell));
    }

    pub fn DrawCell(self: *Self, colorID: u4, xcell: u3, ycell: u3) void {
        const mask = ~@as(bitshape, 0);
        self.WriteSquare(13, mask, colorID, 7 + 13 * @as(u16, xcell), 7 + 13 * @as(u16, ycell));
    }

    pub fn DrawEdge(self: *Self, colorID: u4) void {
        for (0 .. 13 * 8 + 4) |dx| {
            self.backer[5][5 + dx] = colorID;
            self.backer[6][5 + dx] = colorID;

            self.backer[5 + 2 + 8 * 13][5 + dx] = colorID;
            self.backer[6 + 2 + 8 * 13][5 + dx] = colorID;
        }

        for (0 .. 13 * 8 + 4) |dx| {
            self.backer[5 + dx][5] = colorID;
            self.backer[5 + dx][6] = colorID;

            self.backer[5 + dx][5 + 2 + 8 * 13] = colorID;
            self.backer[5 + dx][6 + 2 + 8 * 13] = colorID;
        }
    }

    pub fn DrawCells(self: *Self, tiles: board.Tileboard, orient: board.Orientation) void {
        for (0..8) |row| {
            for (0..8) |col| {
                var tilestate: board.TileState = undefined;
                if (orient == .asblack){
                    tilestate = tiles[row * 8 + col];
                } else {
                    tilestate = tiles[63 - (row * 8 + col)];
                }
                
                if (tilestate == .move) {
                    const colordelta: u4 = @intCast(1 - (col & 1 ^ row & 1));
                    const tcolor: u4 = 2 * tilestate.Int() + colordelta;
                    self.DrawCell(2 * board.TileState.normal.Int() + colordelta, @intCast(col), @intCast(row));
                    self.DrawPiece(.attack, tcolor, @intCast(col), @intCast(row));
                } else if (tilestate == .double) {
                    const colordelta: u4 = @intCast(1 - (col & 1 ^ row & 1));
                    const tcolor: u4 = 2 * tilestate.Int() + colordelta;
                    self.DrawCell(2 * board.TileState.normal.Int() + colordelta, @intCast(col), @intCast(row));
                    self.DrawPiece(.double, tcolor, @intCast(col), @intCast(row));
                } else {
                    const colordelta: u4 = @intCast(1 - (col & 1 ^ row & 1));
                    const tcolor: u4 = 2 * tilestate.Int() + colordelta;
                    self.DrawCell(tcolor, @intCast(col), @intCast(row));
                }
            }
        }
    }

    pub fn DrawCastleRights(self: *Self, game: board.SparseBoard, orient: board.Orientation) void {
        const wYcol: u16 = if (orient == .aswhite) 7 + 13 * 7 else 7;
        const bYcol: u16 = if (orient == .asblack) 7 + 13 * 7 else 7;
        var rights: [2][2] bool = undefined;
        if (orient == .aswhite) {rights = .{game.queencastle, game.kingcastle};} //Queen on left, king on right
        else {rights = .{game.queencastle, game.kingcastle};}
        
        const lrookpos = 7 + 13 * 8 + 2 + 13; //Right edge plus 13 so we can fit in promotions
        for (lrookpos .. lrookpos + 13 * 3 + 5 * 2) |x|{
            for (0 .. 13) |y|{
                self.backer[wYcol + y][x] = 0;
                self.backer[bYcol + y][x] = 0;
            }
        }
        
        if (game.currentPlayer == .white and game.inCheck) self.WriteSquare(13, ~@as(bitshape, 0), 0xB, lrookpos + 13 + 5, wYcol);
        self.WriteSquare(13, kingshape, 5, lrookpos + 13 + 5, wYcol);
        if (rights[0][0] or rights[1][0]) {
            if (rights[0][0]) {
                self.WriteSquare(13, rookshape, 5, lrookpos, wYcol);
                self.WriteSquare(5, _l_arrow_shape, 5, lrookpos + 13, wYcol + 4);
            }
            if (rights[1][0]) {
                self.WriteSquare(5, _r_arrow_shape, 5, lrookpos + 13 + 5 + 13, wYcol + 4);
                self.WriteSquare(13, rookshape, 5, lrookpos + 13 + 5 + 13 + 5, wYcol);
            }
        }
        
        if (game.currentPlayer == .black and game.inCheck) self.WriteSquare(13, ~@as(bitshape, 0), 0xB, lrookpos + 13 + 5, bYcol);
        self.WriteSquare(13, kingshape, 4, lrookpos + 13 + 5, bYcol);
        if (rights[0][1] or rights[1][1]) {
            if (rights[0][1]) {
                self.WriteSquare(13, rookshape, 4, lrookpos, bYcol);
                self.WriteSquare(5, _l_arrow_shape, 4, lrookpos + 13, bYcol + 4);
            }
            if (rights[1][1]) {
                self.WriteSquare(5, _r_arrow_shape, 4, lrookpos + 13 + 5 + 13, bYcol + 4);
                self.WriteSquare(13, rookshape, 4, lrookpos + 13 + 5 + 13 + 5, bYcol);
            }
        }
    } 

    pub fn DrawStatics(self: *Self) void {
        self.DrawEdge(15);

        inline for(0..8) |let| {
            self.DrawLetter(let, 15, let);
        }

        inline for(0..8) |let| {
            self.DrawNumber(7 - let, 15, let);
    }
    }

    pub fn RenderBoard(self: Self, writer: anytype) !void {
        const innerwriter = writer.writer();
        //try color.Goto(1, 1, innerwriter);
        term.GotoTrueCursorOrigin();
        inline for (0..(bheight+1)/2) |row| {
            try self.RenderRow(row, 2*row+1 < bheight, innerwriter);
        }
        try writer.flush();
    }

    pub fn RenderRow(self: Self, row: u16, comptime readbottom: bool, writer: anytype) !void {
        try color.SetFore(255, 255, 255, writer);
        try color.SetBack(0, 0, 0, writer);
        //_ = try writer.write(">");
        var uCol = self.backer[2*row][0];
        var lCol: u4 = if (readbottom) self.backer[2*row+1][0] else 0;
        var state = try Colorpair.CreateWrite(uCol, lCol, self.colors, writer);
        for (1 .. bwidth) |x| {
            uCol = self.backer[2*row][x];
            lCol = if (readbottom) self.backer[2*row+1][x] else 0;
            try state.WritePair(uCol, lCol, self.colors, writer);
        }
        try color.SetFore(255, 255, 255, writer);
        try color.SetBack(0, 0, 0, writer);
        _ = try writer.write("\n");
        
    }
};



fn ToBitMap(str: [] const u8) bitshape {
    var buf: bitshape = 0;
    var rowt: u13 = 0;
    var rowb: u13 = 0;
    var skip: i8 = -1;
    for (str) |char| {
        if (skip >= 0){
            skip -= 1; 
            if (skip > 0) continue;
        }

        //In the case of a multi-byte symbol
        if (skip == 0){
            rowt <<= 1;
            rowb <<= 1;
            if (char == 128) { //▀
                rowt |= 1;
            } else if (char == 132){ //▄
                rowb |= 1;
            } else if (char == 136){ //█
                rowt |= 1;
                rowb |= 1;
            } else {
                @compileError(std.fmt.comptimePrint("Should not occur, found 3rd bytechar: `{c}`, code: {}", .{char, char}));
            }
        } else {
            if (char == '.'){
                continue;
            } else if (char == '\n'){
                buf = std.math.rotl(bitshape, buf, 13);
                buf |= rowt;
                buf = std.math.rotl(bitshape, buf, 13);
                buf |= rowb;
            } else if (char == ' '){
                rowt <<= 1;
                rowb <<= 1;
            } else if (char == 226){
                skip = 2;
            } else {
                @compileError(std.fmt.comptimePrint("Should not occur, found char: `{c}`, code: {}", .{char, char}));
            }
        }
    }
    return @bitReverse(std.math.rotr(bitshape, buf, 13));
}

fn ToTinyBitMap(str: [] const u8) u25 {
    var buf: u25 = 0;
    var rowt: u5 = 0;
    var rowb: u5 = 0;
    var skip: i8 = -1;
    for (str) |char| {
        if (skip >= 0){
            skip -= 1; 
            if (skip > 0) continue;
        }

        //In the case of a multi-byte symbol
        if (skip == 0){
            rowt <<= 1;
            rowb <<= 1;
            if (char == 128) { //▀
                rowt |= 1;
            } else if (char == 132){ //▄
                rowb |= 1;
            } else if (char == 136){ //█
                rowt |= 1;
                rowb |= 1;
            } else {
                @compileError(std.fmt.comptimePrint("Should not occur, found 3rd bytechar: `{c}`, code: {}", .{char, char}));
            }
        } else {
            if (char == '.'){
                continue;
            } else if (char == '\n'){
                buf = std.math.rotl(u25, buf, 5);
                buf |= rowt;
                buf = std.math.rotl(u25, buf, 5);
                buf |= rowb;
            } else if (char == ' '){
                rowt <<= 1;
                rowb <<= 1;
            } else if (char == 226){
                skip = 2;
            } else {
                @compileError(std.fmt.comptimePrint("Should not occur, found char: `{c}`, code: {}", .{char, char}));
            }
        }
    }
    return @bitReverse(std.math.rotr(u25, buf, 5));
}

pub const pawnshape = ToBitMap(
\\.             .
\\.     ▄▄▄     .
\\.    █████    .
\\.     ███     .
\\.   ███████   .
\\.             .
\\
);

pub const rookshape = ToBitMap(
\\.             .
\\.  █▄█▄█▄█▄█  .
\\.   ███████   .
\\.    █████    .
\\.    █████    .
\\.  ▄███████▄  .
\\.             .
\\
);

pub const knightshape = ToBitMap(
\\.   ▄         .
\\.   ██▄████▄  .
\\.   ▄█████▄█  .
\\.   ████▄  ▀  .
\\.  ██████▄▄   .
\\.  █████████  .
\\.             .
\\
);

pub const bishopshape = ToBitMap(
\\.             .
\\.    ▄▄█▄     .
\\.   ████ ▄█   .
\\.   ▀█████▀   .
\\.     ███     .
\\.  █████████  .
\\.             .
\\
);

pub const queenshape = ToBitMap(
\\.      ▄      .
\\.   █▄███▄█   .
\\.    █████    .
\\.     ███     .
\\.    ▄███▄    .
\\. ▄█████████▄ .
\\.             .
\\
);

pub const attackshape = ToBitMap(
\\.             .
\\.             .
\\.    ▄███▄    .
\\.    █████    .
\\.     ▀▀▀     .
\\.             .
\\.             .
\\
);

// pub const doubleshape = ToBitMap(
// \\.             .
// \\.     ▄▄▄     .
// \\.   ▄██▀██▄   .
// \\.   ██▄ ▄██   .
// \\.    ▀███▀    .
// \\.             .
// \\.             .
// \\
// );

// pub const doubleshape = ToBitMap(
// \\. ▄▄       ▄▄ .
// \\. █         █ .
// \\.             .
// \\.             .
// \\.             .
// \\.             .
// \\.             .
// \\
// );


pub const doubleshape = ToBitMap(
\\.     ▄▄▄     .
\\.             .
\\. ▄    ▄    ▄ .
\\. █   ▀█▀   █ .
\\.             .
\\.     ▄▄▄     .
\\.             .
\\
);

pub const kingshape = ToBitMap(
\\.      ▄      .
\\.     ▀█▀     .
\\.   ▀█████▀   .
\\.    ▀███▀    .
\\.    ▄███▄    .
\\.  ▄███████▄  .
\\.             .
\\
);

pub const _A_shape = ToTinyBitMap(
\\. ▄▀▄ .
\\. █▀█ .
\\. ▀ ▀ .
\\
);


pub const _B_shape = ToTinyBitMap(
\\. █▀▄ .
\\. █▀▄ .
\\. ▀▀  .
\\
);


pub const _C_shape = ToTinyBitMap(
\\. █▀█ .
\\. █ ▄ .
\\. ▀▀▀ .
\\
);


pub const _D_shape = ToTinyBitMap(
\\. █▀▄ .
\\. █ █ .
\\. ▀▀  .
\\
);


pub const _E_shape = ToTinyBitMap(
\\. █▀▀ .
\\. █▀▀ .
\\. ▀▀▀ .
\\
);


pub const _F_shape = ToTinyBitMap(
\\. █▀▀ .
\\. █▀  .
\\. ▀   .
\\
);


pub const _G_shape = ToTinyBitMap(
\\. █▀▀ .
\\. █ █ .
\\. ▀▀▀ .
\\
);


pub const _H_shape = ToTinyBitMap(
\\. █ █ .
\\. █▀█ .
\\. ▀ ▀ .
\\
);


pub const _1_shape = ToTinyBitMap(
\\. ▄█  .
\\.  █  .
\\. ▀▀▀ .
\\
);


pub const _2_shape = ToTinyBitMap(
\\. ▀▀█ .
\\. █▀▀ .
\\. ▀▀▀ .
\\
);


pub const _3_shape = ToTinyBitMap(
\\. ▀▀█ .
\\. ▀▀█ .
\\. ▀▀▀ .
\\
);


pub const _4_shape = ToTinyBitMap(
\\. █ █ .
\\. ▀▀█ .
\\.   ▀ .
\\
);


pub const _5_shape = ToTinyBitMap(
\\. █▀▀ .
\\. ▀▀█ .
\\. ▀▀▀ .
\\
);


pub const _6_shape = ToTinyBitMap(
\\. █▀▀ .
\\. █▀█ .
\\. ▀▀▀ .
\\
);


pub const _7_shape = ToTinyBitMap(
\\. ▀▀█ .
\\.  ▀█ .
\\.   ▀ .
\\
);


pub const _8_shape = ToTinyBitMap(
\\. █▀█ .
\\. █▀█ .
\\. ▀▀▀ .
\\
);


pub const _l_arrow_shape = ToTinyBitMap(
\\. ▄█  .
\\.▀██▀▀.
\\.  ▀  .
\\
);

pub const _r_arrow_shape = ToTinyBitMap(
\\.  █▄ .
\\.▀▀██▀.
\\.  ▀  .
\\
);