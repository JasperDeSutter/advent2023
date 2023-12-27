const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("11", solve);

fn distance(a: usize, b: usize) usize {
    if (b < a) return a - b;
    return b - a;
}

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    return .{ try impl(alloc, input, 1), try impl(alloc, input, 1000000 - 1) };
}

fn impl(alloc: std.mem.Allocator, input: []const u8, increment: u32) !usize {
    // const lineLength = 140;
    // var mem: [lineLength + lineLength]u8 = undefined;
    const lineLength = std.mem.indexOfScalar(u8, input, '\n').?;
    var mem = try alloc.alloc(u8, lineLength + lineLength);
    defer alloc.free(mem);

    var rowCounts = mem[0..lineLength];
    var colCounts = mem[lineLength..];
    @memset(colCounts, 0);

    var rowCount: u8 = 0;
    var row: usize = 0;
    for (input, 0..) |c, i| {
        if (c == '#') {
            rowCount += 1;
            colCounts[i % (lineLength + 1)] += 1;
        }
        if (c == '\n') {
            rowCounts[row] = rowCount;
            rowCount = 0;
            row += 1;
        }
    }
    rowCounts[row] = rowCount;

    return prefix_sum(rowCounts, increment) + prefix_sum(colCounts, increment);
}

fn prefix_sum(counts: []const u8, increment: u32) u64 {
    var result: u64 = 0;
    var total_sum: u64 = 0;
    var offset: u64 = 0;
    var galaxy: usize = 0;
    for (counts, 0..) |c, i| {
        const expanded_rowcol_index = i + offset;
        for (0..c) |_| {
            result += galaxy * expanded_rowcol_index - total_sum;
            total_sum += expanded_rowcol_index;
            galaxy +%= 1;
        }
        if (c == 0) {
            offset += increment;
        }
    }
    return result;
}

test {
    const input =
        \\...#......
        \\.......#..
        \\#.........
        \\..........
        \\......#...
        \\.#........
        \\.........#
        \\..........
        \\.......#..
        \\#...#.....
    ;

    var example_result: usize = 374;
    try std.testing.expectEqual(example_result, try impl(std.testing.allocator, input, 1));
    example_result = 1030;
    try std.testing.expectEqual(example_result, try impl(std.testing.allocator, input, 10 - 1));
    example_result = 8410;
    try std.testing.expectEqual(example_result, try impl(std.testing.allocator, input, 100 - 1));
}
