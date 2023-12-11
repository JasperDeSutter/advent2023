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

fn impl(alloc: std.mem.Allocator, input: []const u8, increment: usize) !usize {
    var x: usize = 0;
    var y: usize = 0;
    var lineLength: usize = 0;

    var galaxies = std.ArrayList([2]usize).init(alloc);
    defer galaxies.deinit();
    var distances: usize = 0;

    var foundGalaxy = false;
    for (input) |c| {
        if (c == '\n') {
            if (!foundGalaxy) {
                y += increment;
            }
            lineLength = x;
            x = 0;
            y += 1;
            foundGalaxy = false;
            continue;
        }
        if (c == '#') {
            try galaxies.append(.{ x, y });
            foundGalaxy = true;
        }

        x += 1;
    }

    var unfound = std.ArrayList(usize).init(alloc);
    defer unfound.deinit();

    for (0..lineLength) |i| {
        for (galaxies.items) |galaxy| {
            if (galaxy[0] == i) {
                break;
            }
        } else {
            try unfound.append(i + (unfound.items.len * increment));
        }
    }

    for (0..galaxies.items.len) |i| {
        const galaxy = &galaxies.items[i];

        for (unfound.items) |col| {
            if (col > galaxy[0]) break;
            galaxy[0] += increment;
        }

        for (galaxies.items[0..i]) |galaxy2| {
            const dist = distance(galaxy[0], galaxy2[0]) + distance(galaxy[1], galaxy2[1]);
            distances += dist;
        }
    }

    return distances;
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
