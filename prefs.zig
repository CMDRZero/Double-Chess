pub const color = @import("color.zig");
const Color = color.Color;

pub const colors: [16] Color = .{
    D_Grey,     //0
    Warning,    //1
    TileBlack,  //2
    TileWhite,  //3
    PieceBlack, //4
    PieceWhite, //5
    HighlightBlack,    //6
    HighlightWhite,    //7
    LegalMoveBlack,    //8
    LegalMoveWhite,    //9
    CaptureBlack,    //A
    CaptureWhite,    //B
    DoubleBlack,    //C
    DoubleWhite,    //D
    Warning,    //E
    PureWhite,  //F
};

//Color, Tile, Piece, Highlight, Move, Capture, Move, Illegal

pub const TileWhite = Color.RGB(0xF0, 0xD9, 0xB4);
pub const TileBlack = Color.RGB(0xB5, 0x88, 0x63);

pub const PieceBlack = Color.RGB(0x56, 0x53, 0x52);
pub const PieceWhite = Color.RGB(0xF8, 0xF8, 0xF8);

pub const HighlightBlack = Color.RGB(246, 235, 114);
pub const HighlightWhite = Color.RGB(246, 235, 114);

pub const LegalMoveBlack = Color.RGB(158, 116, 84);
pub const LegalMoveWhite = Color.RGB(204, 184, 151);

pub const DoubleBlack = Color.RGB(180, 116, 100);
pub const DoubleWhite = Color.RGB(230, 184, 170);

pub const CaptureBlack = Color.RGB(225, 105, 84);
pub const CaptureWhite = Color.RGB(235, 121, 99);

pub const PureWhite = Color.RGB(0xFF, 0xFF, 0xFF);
pub const D_Grey = Color.RGB(0x10, 0x10, 0x10);
pub const Warning = Color.RGB(0xFF, 0x20, 0xE0);