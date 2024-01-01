const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("18", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    _ = alloc;
    var x: isize = 0;
    var y: isize = 0;
    var x2: isize = 0;
    var y2: isize = 0;

    var lines = std.mem.splitScalar(u8, input, '\n');
    var prev1 = .{ x, y };
    var prev2 = .{ x, y };

    var doubleArea: isize = 0;
    var totalBorder: usize = 0;
    var doubleArea2: isize = 0;
    var totalBorder2: usize = 0;
    while (lines.next()) |line| {
        const dir = line[0];
        var num: u8 = 0;
        const i = for (line[2..], 2..) |c, i| {
            if (c == ' ') {
                break i;
            }
            num = num * 10 + (c - '0');
        } else unreachable;

        switch (dir) {
            'R' => x += num,
            'D' => y += num,
            'L' => x -= num,
            'U' => y -= num,
            else => unreachable,
        }

        doubleArea += (prev1[0] * y) - (prev1[1] * x);
        totalBorder += num;

        prev1 = .{ x, y };

        const num2 = try std.fmt.parseInt(u32, line[i + 3 .. line.len - 2], 16);
        switch (line[line.len - 2]) {
            '0' => x2 += num2,
            '1' => y2 += num2,
            '2' => x2 -= num2,
            '3' => y2 -= num2,
            else => unreachable,
        }

        doubleArea2 += (prev2[0] * y2) - (prev2[1] * x2);
        totalBorder2 += num2;

        prev2 = .{ x2, y2 };
    }

    return .{ makeArea(doubleArea, totalBorder), makeArea(doubleArea2, totalBorder2) };
}

fn makeArea(doubleArea: isize, totalBorder: usize) usize {
    var area: usize = @intCast(doubleArea);
    area /= 2;
    area += (totalBorder / 2) + 1;
    return area;
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
    const example_result2: usize = 952408144115;
    try std.testing.expectEqual(example_result2, result[1]);
}
