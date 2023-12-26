const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("10", solve);

const Dir = enum {
    Up,
    Down,
    Left,
    Right,
};

const directions = .{
    .{ '-', .Left, .Right, .{.Up}, .{.Down} },
    .{ '|', .Up, .Down, .{.Right}, .{.Left} },
    .{ '7', .Left, .Down, .{ .Up, .Right }, .{} },
    .{ 'L', .Up, .Right, .{}, .{ .Left, .Down } },
    .{ 'J', .Left, .Up, .{}, .{ .Right, .Down } },
    .{ 'F', .Down, .Right, .{ .Left, .Up }, .{} },
};

fn match(cur: usize, prev: usize, lineLength: usize, dir: Dir) bool {
    switch (dir) {
        Dir.Left => return cur == prev + 1,
        Dir.Right => return cur + 1 == prev,
        Dir.Down => return cur + lineLength == prev,
        Dir.Up => return cur == prev + lineLength,
    }
}

fn apply(cur: usize, lineLength: usize, dir: Dir) usize {
    switch (dir) {
        Dir.Left => return cur - 1,
        Dir.Right => return cur + 1,
        Dir.Down => return cur + lineLength,
        Dir.Up => return cur - lineLength,
    }
}

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    _ = alloc;
    var lineLength: usize = 0;
    while (input[lineLength] != '\n') : (lineLength += 1) {}
    lineLength += 1;

    var start: usize = 0;
    while (input[start] != 'S') : (start += 1) {}

    const options: [3]usize = .{ start + 1, start - 1, start + lineLength };
    const steps = outer: for (&options) |opt| {
        var prev = start;
        var cur = opt;
        var steps: usize = 0;

        opt: while (true) {
            steps += 1;
            if (cur == start) {
                break :outer steps;
            }
            const c = input[cur];
            const p = prev;
            prev = cur;
            var newDir: Dir = undefined;
            inline for (directions) |dir| {
                if (dir[0] == c) {
                    if (match(cur, p, lineLength, dir[1])) {
                        newDir = dir[2];
                    } else if (match(cur, p, lineLength, dir[2])) {
                        newDir = dir[1];
                    } else {
                        break :opt;
                    }
                }
            }
            cur = apply(cur, lineLength, newDir);
        }
    } else 0;

    return .{ steps / 2, 0 };
}

test "part1 ex1" {
    const input =
        \\.....
        \\.S-7.
        \\.|.|.
        \\.L-J.
        \\.....
    ;

    const result = try solve(std.testing.allocator, input);
    const example_result: usize = 4;
    try std.testing.expectEqual(example_result, result[0]);
}

test "part1 ex2" {
    const input =
        \\..F7.
        \\.FJ|.
        \\SJ.L7
        \\|F--J
        \\LJ...
    ;
    const result = try solve(std.testing.allocator, input);
    const example_result2: usize = 8;
    try std.testing.expectEqual(example_result2, result[0]);
}

test "part2 ex1" {
    const input =
        \\...........
        \\.S-------7.
        \\.|F-----7|.
        \\.||.....||.
        \\.||.....||.
        \\.|L-7.F-J|.
        \\.|..|.|..|.
        \\.L--J.L--J.
        \\...........
    ;
    const result = try solve(std.testing.allocator, input);
    const example_result2: usize = 4;
    try std.testing.expectEqual(example_result2, result[1]);
}

test "part2 ex2" {
    const input =
        \\.F----7F7F7F7F-7....
        \\.|F--7||||||||FJ....
        \\.||.FJ||||||||L7....
        \\FJL7L7LJLJ||LJ.L-7..
        \\L--J.L7...LJS7F-7L7.
        \\....F-J..F7FJ|L7L7L7
        \\....L7.F7||L7|.L7L7|
        \\.....|FJLJ|FJ|F7|.LJ
        \\....FJL-7.||.||||...
        \\....L---J.LJ.LJLJ...
    ;
    const result = try solve(std.testing.allocator, input);
    const example_result2: usize = 8;
    try std.testing.expectEqual(example_result2, result[1]);
}

test "part2 ex3" {
    const input =
        \\FF7FSF7F7F7F7F7F---7
        \\L|LJ||||||||||||F--J
        \\FL-7LJLJ||||||LJL-77
        \\F--JF--7||LJLJ7F7FJ-
        \\L---JF-JLJ.||-FJLJJ7
        \\|F|F-JF---7F7-L7L|7|
        \\|FFJF7L7F-JF7|JL---7
        \\7-L-JL7||F7|L7F-7F7|
        \\L.L7LFJ|||||FJL7||LJ
        \\L7JLJL-JLJLJL--JLJ.L
    ;
    const result = try solve(std.testing.allocator, input);
    const example_result2: usize = 10;
    try std.testing.expectEqual(example_result2, result[1]);
}
