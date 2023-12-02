const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run(solve);

fn solve(_: std.mem.Allocator, input: []const u8) anyerror!void {
    const result = try possibleGames(input);
    std.debug.print("possible games: {}\n", .{result});
}

fn possibleGames(input: []const u8) !usize {
    var lines = std.mem.split(u8, input, "\n");
    var result: usize = 0;

    const total_cubes = .{ 12, 13, 14 };

    while (lines.next()) |line| {
        var l = line[5..];
        var i: usize = 0;

        var game: usize = 0;
        while (l[i] != ':') : (i += 1) {
            game *= 10;
            game += l[i] - '0';
        }

        l = l[i + 2 ..];
        i = 0;

        var last_num: usize = 0;
        const impossible = impossible: while (i < l.len) : (i += 1) {
            const c = l[i];
            switch (c) {
                'r' => {
                    if (last_num > total_cubes[0]) {
                        break :impossible true;
                    }
                    i += 2; // skip "red"
                },
                'g' => {
                    if (last_num > total_cubes[1]) {
                        break :impossible true;
                    }
                    i += 4; // skip "green"
                },
                'b' => {
                    if (last_num > total_cubes[2]) {
                        break :impossible true;
                    }
                    i += 3; // skip "blue"
                },
                ',', ';' => last_num = 0,
                '0'...'9' => {
                    last_num *= 10;
                    last_num += c - '0';
                },
                else => {},
            }
        } else false;

        if (!impossible) {
            result += game;
        }
    }

    return result;
}

test {
    const input =
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    ;

    const example_result: usize = 8;
    try std.testing.expectEqual(example_result, try possibleGames(input));
}
