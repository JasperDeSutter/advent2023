const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("11", solve);

fn distance(a: u16, b: u16) u16 {
    if (b < a) return a - b;
    return b - a;
}

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    var x: u16 = 0;
    var y: u16 = 0;
    var lineLength: usize = 0;

    var galaxies = std.ArrayList([2]u16).init(alloc);
    defer galaxies.deinit();
    var distances: usize = 0;

    var foundGalaxy = false;
    for (input) |c| {
        if (c == '\n') {
            if (!foundGalaxy) {
                y += 1;
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
            try unfound.append(i + unfound.items.len);
        }
    }

    for (0..galaxies.items.len) |i| {
        const galaxy = &galaxies.items[i];

        for (unfound.items) |col| {
            if (col > galaxy[0]) break;
            galaxy[0] += 1;
        }

        for (galaxies.items[0..i]) |galaxy2| {
            const dist = distance(galaxy[0], galaxy2[0]) + distance(galaxy[1], galaxy2[1]);
            distances += dist;
        }
    }

    return .{ distances, 0 };
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

    const result = try solve(std.testing.allocator, input);
    const example_result: usize = 374;
    try std.testing.expectEqual(example_result, result[0]);
}
