const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("16", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    const visited = try alloc.alloc(u8, input.len);
    defer alloc.free(visited);
    @memset(visited, 0);

    const stride: usize = @intCast(std.mem.indexOfScalar(u8, input, '\n').? + 1);

    const Beam = struct {
        dir: u8,
        i: usize,
    };
    var beams = std.ArrayListUnmanaged(Beam){};
    defer beams.deinit(alloc);

    const right: u8 = 0;
    const down: u8 = 1;
    const left: u8 = 2;
    const up: u8 = 3;

    try beams.append(alloc, .{ .dir = right, .i = std.math.maxInt(usize) });
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

            const one: u8 = 1;
            const flag = one << @intCast(beam.dir);
            if (visited[i] & flag > 0) break;
            visited[i] |= flag;

            if (c == '/') {
                const newDir = switch (beam.dir) {
                    right => up,
                    down => left,
                    left => down,
                    up => right,
                    else => unreachable,
                };
                try beams.append(alloc, .{ .dir = newDir, .i = i });
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
                try beams.append(alloc, .{ .dir = newDir, .i = i });
                break;
            }
            if (c == '-' and (beam.dir == up or beam.dir == down)) {
                try beams.appendSlice(alloc, &.{ .{ .dir = left, .i = i }, .{ .dir = right, .i = i } });
                break;
            }
            if (c == '|' and (beam.dir == left or beam.dir == right)) {
                try beams.appendSlice(alloc, &.{ .{ .dir = up, .i = i }, .{ .dir = down, .i = i } });
                break;
            }
        }
    }

    var total_visited: usize = 0;
    for (visited) |v| total_visited += @intFromBool(v != 0);

    return .{ total_visited, 0 };
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
}
