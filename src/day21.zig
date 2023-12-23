const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("21", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    return impl(alloc, input, 64);
}

fn impl(alloc: std.mem.Allocator, input: []const u8, steps: u8) anyerror![2]usize {
    const map = try alloc.alloc(u8, input.len);
    defer alloc.free(map);
    @memset(map, 0);

    const lineLen = std.mem.indexOfScalar(u8, input, '\n').? + 1;
    const startPos = std.mem.indexOfScalar(u8, input, 'S').?;
    map[startPos] = 1;

    for (2..(steps + 2)) |stepU| {
        const step: u8 = @intCast(stepU);
        for (0..input.len) |i| {
            if (input[i] == '#' or input[i] == '\n') continue;
            if (map[i] != 0) continue;

            const prev = step - 1;

            if (i > 0 and map[i - 1] == prev) {
                map[i] = step;
            }
            if (i < map.len - 1 and map[i + 1] == prev) {
                map[i] = step;
            }
            if (i >= lineLen and map[i - lineLen] == prev) {
                map[i] = step;
            }
            if (i + lineLen < map.len and map[i + lineLen] == prev) {
                map[i] = step;
            }
        }
    }

    var result: usize = 0;
    const odd = steps % 2 == 0;
    for (map) |v| {
        if (v != 0 and ((odd and v % 2 == 1) or (!odd and v % 2 == 0))) {
            result += 1;
        }
    }

    return .{ result, 0 };
}

test {
    const input =
        \\...........
        \\.....###.#.
        \\.###.##..#.
        \\..#.#...#..
        \\....#.#....
        \\.##..S####.
        \\.##..#...#.
        \\.......##..
        \\.##.#.####.
        \\.##..##.##.
        \\...........
    ;

    const result = try impl(std.testing.allocator, input, 6);
    const example_result: usize = 16;
    try std.testing.expectEqual(example_result, result[0]);
}
