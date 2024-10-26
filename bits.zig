const std = @import("std");

const one = @as(u64, 1);
const zero = @as(u64, 1);

///Assumes the value is nonzero

pub fn LogHSB(val: u64) u6 {
    @setRuntimeSafety(false);
    return @intCast(63 - @clz(val));
}

test LogHSB {
    const expect = @import("std").testing.expect;

    try expect(LogHSB((1 << 6) + 1) == 6);
    try expect(LogHSB(1 << 0) == 0);
    try expect(LogHSB((1 << 63) + (1 << 62)) == 63);
}

pub fn LSB(val: u64) u64 {
    return val & (~val +% 1);
}


//Thanks to: https://gist.github.com/Validark/a45d57c18f290031cd41126ef142fe3e
inline fn Pext(src: anytype, mask: @TypeOf(src)) @TypeOf(src) {
    switch (@TypeOf(src)) {
        u32, u64 => {},
        else => @compileError(std.fmt.comptimePrint("pext called with a bad type: {}\n", .{@TypeOf(src)})),
    }

    if (@inComptime()) {
        @setEvalBranchQuota(std.math.maxInt(u32));
        var result: @TypeOf(src) = 0;
        var m = mask;
        var i: std.math.Log2Int(@TypeOf(src)) = 0;
        while (m > 0) : ({
            m &= m -% 1;
            i += 1;
        }) {
            result |= ((src >> @ctz(m)) & 1) << i;
        }
        return result;
    }

    return asm ("pext %[mask], %[src], %[ret]"
        : [ret] "=r" (-> @TypeOf(src)),
        : [src] "r" (src),
          [mask] "r" (mask),
    );
}