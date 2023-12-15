const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("15", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    _ = alloc;
    var total: usize = 0;
    var current_hash: usize = 0;

    for (input) |c| {
        if (c == ',') {
            total += current_hash;
            current_hash = 0;
        } else {
            current_hash += c;
            current_hash *= 17;
            current_hash %= 256;
        }
    }
    total += current_hash;

    return .{ total, 0 };
}

test {
    const input =
        \\rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7
    ;

    const result = try solve(std.testing.allocator, input);
    const example_result: usize = 1320;
    try std.testing.expectEqual(example_result, result[0]);
}
