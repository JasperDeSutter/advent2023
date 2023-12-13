const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("13", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    _ = alloc;
    var matches: usize = 0;

    var i: usize = 0;
    blocks: while (i < input.len) : (i += 1) {
        const start = i;
        var lineLen: usize = 0;
        while (i < input.len) : (i += 1) {
            if (input[i] == '\n') {
                if (input[i - 1] == '\n') {
                    i -= 1;
                    break;
                }
                if (lineLen == 0) {
                    lineLen = i - start + 1;
                }
            }
        }
        const grid = input[start..i];
        i += 1;

        const rows = (grid.len + 1) / lineLen;
        const cols = lineLen - 1;
        for (1..rows) |row| {
            var rowUp = row - 1;
            var rowDown = row;
            while (rowUp < rows and rowDown < rows) : ({
                rowUp -%= 1;
                rowDown += 1;
            }) {
                const up = grid[rowUp * lineLen .. (rowUp + 1) * lineLen - 1];
                const down = grid[rowDown * lineLen .. (rowDown + 1) * lineLen - 1];
                if (!std.mem.eql(u8, up, down)) {
                    break;
                }
            } else {
                matches += 100 * row;
                continue :blocks;
            }
        }

        for (1..cols) |col| {
            var colLeft = col - 1;
            var colRight = col;
            check: while (colLeft < cols and colRight < cols) : ({
                colLeft -%= 1;
                colRight += 1;
            }) {
                for (0..rows) |row| {
                    const left = grid[row * lineLen + colLeft];
                    const right = grid[row * lineLen + colRight];
                    if (left != right) {
                        break :check;
                    }
                }
            } else {
                matches += col;
                continue :blocks;
            }
        }
    }

    return .{ matches, 0 };
}

test {
    const input =
        \\#.##..##.
        \\..#.##.#.
        \\##......#
        \\##......#
        \\..#.##.#.
        \\..##..##.
        \\#.#.##.#.
        \\
        \\#...##..#
        \\#....#..#
        \\..##..###
        \\#####.##.
        \\#####.##.
        \\..##..###
        \\#....#..#
    ;

    const result = try solve(std.testing.allocator, input);
    const example_result: usize = 405;
    try std.testing.expectEqual(example_result, result[0]);
}
