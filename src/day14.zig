const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("14", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    var i: usize = 0;

    while (i < input.len) : (i += 1) {
        const c = input[i];
        if (c == '\n') {
            break;
        }
    }
    const lineLength = i + 1;
    i = 0;

    var support = try alloc.alloc(u8, lineLength - 1);
    defer alloc.free(support);
    @memset(support, 0);

    var load: usize = 0;
    const points = (input.len + 1) / lineLength;

    while (i < input.len) : (i += 1) {
        const c = input[i];

        const row = i % lineLength;
        if (c == 'O') {
            load += points - support[row];
            support[row] += 1;
        }
        if (c == '#') {
            support[row] = @intCast(i / lineLength + 1);
        }
    }

    return .{ load, 0 };
}

test {
    const input =
        \\O....#....
        \\O.OO#....#
        \\.....##...
        \\OO.#O....O
        \\.O.....O#.
        \\O.#..O.#.#
        \\..O..#O..O
        \\.......O..
        \\#....###..
        \\#OO..#....
    ;

    const result = try solve(std.testing.allocator, input);
    const example_result: usize = 136;
    try std.testing.expectEqual(example_result, result[0]);
}
