const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("13", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    _ = alloc;
    var matchesWithoutDefect: usize = 0;
    var matchesWithDefect: usize = 0;

    var i: usize = 0;
    while (i < input.len) : (i += 1) {
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

        const res = findMirror(grid, lineLen, 0);
        if (res[0] != 0) {
            matchesWithoutDefect += 100 * res[0];
        } else {
            matchesWithoutDefect += res[1];
        }

        const res2 = findMirror(grid, lineLen, 1);
        if (res2[0] != 0) {
            matchesWithDefect += 100 * res2[0];
        } else {
            matchesWithDefect += res2[1];
        }
    }

    return .{ matchesWithoutDefect, matchesWithDefect };
}

fn findMirror(grid: []const u8, lineLen: usize, maxDefects: u8) [2]usize {
    const rows = (grid.len + 1) / lineLen;
    const cols = lineLen - 1;

    check: for (1..rows) |row| {
        var rowUp = row - 1;
        var rowDown = row;
        var defects: u8 = 0;

        while (rowUp < rows and rowDown < rows) : ({
            rowUp -%= 1;
            rowDown += 1;
        }) {
            for (0..cols) |col| {
                const up = grid[rowUp * lineLen + col];
                const down = grid[rowDown * lineLen + col];
                if (up != down) {
                    defects += 1;
                    if (defects > maxDefects) {
                        continue :check;
                    }
                }
            }
        }
        if (defects == maxDefects) {
            return .{ row, 0 };
        }
    }

    check: for (1..cols) |col| {
        var colLeft = col - 1;
        var colRight = col;
        var defects: u8 = 0;

        while (colLeft < cols and colRight < cols) : ({
            colLeft -%= 1;
            colRight += 1;
        }) {
            for (0..rows) |row| {
                const left = grid[row * lineLen + colLeft];
                const right = grid[row * lineLen + colRight];
                if (left != right) {
                    defects += 1;
                    if (defects > maxDefects) {
                        continue :check;
                    }
                }
            }
        }
        if (defects == maxDefects) {
            return .{ 0, col };
        }
    }

    return .{ 0, 0 };
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
    const example_result2: usize = 400;
    try std.testing.expectEqual(example_result2, result[1]);
}
