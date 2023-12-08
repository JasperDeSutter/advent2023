const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("02", solve);

fn solve(_: std.mem.Allocator, input: []const u8) ![2]usize {
    var lines = std.mem.split(u8, input, "\n");
    var possible_result: usize = 0;
    var power_result: usize = 0;

    while (lines.next()) |line| {
        var l = line[5..];
        var i: usize = 0;

        var game: usize = 0;
        while (l[i] != ':') : (i += 1) {
            game *= 10;
            game += l[i] - '0';
        }

        l = l[i + 2 ..];

        const colors = .{ "red", "green", "blue" };
        const total_cubes: [colors.len]usize = .{ 12, 13, 14 };
        var min_cubes = [1]usize{0} ** total_cubes.len;

        var last_num: usize = 0;
        i = 0;
        while (i < l.len) : (i += 1) {
            const c = l[i];

            inline for (colors, 0..) |color, j| {
                if (c == color[0]) {
                    min_cubes[j] = @max(last_num, min_cubes[j]);
                    i += color.len - 1;
                }
            } else switch (c) {
                ',', ';' => last_num = 0,
                '0'...'9' => {
                    last_num *= 10;
                    last_num += c - '0';
                },
                else => {},
            }
        }

        var c: usize = 0;
        var possible = true;
        var power: usize = 1;
        while (c < total_cubes.len) : (c += 1) {
            if (min_cubes[c] > total_cubes[c]) {
                possible = false;
            }
            power *= min_cubes[c];
        }

        if (possible) {
            possible_result += game;
        }

        power_result += power;
    }

    return .{ possible_result, power_result };
}

test {
    const input =
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    ;

    const result = try solve(std.testing.allocator, input);
    const example_result: usize = 8;
    try std.testing.expectEqual(example_result, result[0]);
    const example_result2: usize = 2286;
    try std.testing.expectEqual(example_result2, result[1]);
}
