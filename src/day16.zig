const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("16", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    const visited = try alloc.alloc(bool, input.len);
    defer alloc.free(visited);

    const stride: usize = @intCast(std.mem.indexOfScalar(u8, input, '\n').? + 1);

    var beams = std.ArrayList(Beam).init(alloc);
    defer beams.deinit();

    var highest: usize = 0;

    const rows = (input.len + 1) / stride;
    for (0..rows) |row| {
        const off = row * stride;
        const a = try runBeams(visited, &beams, stride, input, .{ .dir = right, .i = off +% std.math.maxInt(usize) });
        const b = try runBeams(visited, &beams, stride, input, .{ .dir = left, .i = off + stride - 1 });
        highest = @max(highest, @max(a, b));
    }

    for (0..(stride - 1)) |col| {
        const a = try runBeams(visited, &beams, stride, input, .{ .dir = down, .i = col -% stride });
        const b = try runBeams(visited, &beams, stride, input, .{ .dir = up, .i = col + input.len + 1 });
        highest = @max(highest, @max(a, b));
    }

    return .{ try runBeams(visited, &beams, stride, input, .{ .dir = right, .i = std.math.maxInt(usize) }), highest };
}

const right: u8 = 0;
const down: u8 = 1;
const left: u8 = 2;
const up: u8 = 3;

const Beam = struct {
    dir: u8,
    i: usize,
};

fn runBeams(visited: []bool, beams: *std.ArrayList(Beam), stride: usize, input: []const u8, init: Beam) !usize {
    // std.debug.print("init: {}, {}\n", .{ init.dir, init.i });
    try beams.append(init);
    @memset(visited, false);

    while (beams.popOrNull()) |beam| {
        const inc: usize = switch (beam.dir) {
            right => 1,
            down => stride,
            left => std.math.maxInt(usize),
            up => std.math.maxInt(usize) - stride + 1,
            else => unreachable,
        };
        var i: usize = beam.i;
        i +%= inc;
        while (i < input.len) : (i +%= inc) {
            const c = input[i];
            if (c == '\n') break;

            if ((c == '-' or c == '|') and visited[i]) break;
            visited[i] = true;

            if (c == '/') {
                const newDir = switch (beam.dir) {
                    right => up,
                    down => left,
                    left => down,
                    up => right,
                    else => unreachable,
                };
                try beams.append(.{ .dir = newDir, .i = i });
                break;
            }
            if (c == '\\') {
                const newDir = switch (beam.dir) {
                    right => down,
                    down => right,
                    left => up,
                    up => left,
                    else => unreachable,
                };
                try beams.append(.{ .dir = newDir, .i = i });
                break;
            }
            if (c == '-' and (beam.dir == up or beam.dir == down)) {
                try beams.appendSlice(&.{ .{ .dir = left, .i = i }, .{ .dir = right, .i = i } });
                break;
            }
            if (c == '|' and (beam.dir == left or beam.dir == right)) {
                try beams.appendSlice(&.{ .{ .dir = up, .i = i }, .{ .dir = down, .i = i } });
                break;
            }
        }
    }

    var total_visited: usize = 0;
    for (visited) |v| total_visited += @intFromBool(v);
    return total_visited;
}

test {
    const input =
        \\.|...\....
        \\|.-.\.....
        \\.....|-...
        \\........|.
        \\..........
        \\.........\
        \\..../.\\..
        \\.-.-/..|..
        \\.|....-|.\
        \\..//.|....
    ;

    const result = try solve(std.testing.allocator, input);
    const example_result: usize = 46;
    try std.testing.expectEqual(example_result, result[0]);
    const example_result2: usize = 51;
    try std.testing.expectEqual(example_result2, result[1]);
}
