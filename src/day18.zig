const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("18", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    _ = alloc;
    var x: isize = 0;
    var y: isize = 0;

    var lines = std.mem.splitScalar(u8, input, '\n');
    var prev = .{ x, y };

    var doubleArea: isize = 0;
    var totalBorder: usize = 0;
    while (lines.next()) |line| {
        const dir = line[0];
        var num: u8 = 0;
        for (line[2..]) |c| {
            if (c == ' ') {
                break;
            }
            num = num * 10 + (c - '0');
        }

        switch (dir) {
            'R' => x += num,
            'L' => x -= num,
            'U' => y -= num,
            'D' => y += num,
            else => unreachable,
        }

        doubleArea += (prev[0] * y) - (prev[1] * x);
        totalBorder += num;

        prev = .{ x, y };
    }

    var area: usize = @intCast(doubleArea);
    area /= 2;
    area += (totalBorder / 2) + 1;

    return .{ @intCast(area), 0 };
}

test {
    const input =
        \\R 6 (#70c710)
        \\D 5 (#0dc571)
        \\L 2 (#5713f0)
        \\D 2 (#d2c081)
        \\R 2 (#59c680)
        \\D 2 (#411b91)
        \\L 5 (#8ceee2)
        \\U 2 (#caa173)
        \\L 1 (#1b58a2)
        \\U 2 (#caa171)
        \\R 2 (#7807d2)
        \\U 3 (#a77fa3)
        \\L 2 (#015232)
        \\U 2 (#7a21e3)
    ;

    const result = try solve(std.testing.allocator, input);
    const example_result: usize = 62;
    try std.testing.expectEqual(example_result, result[0]);
}
