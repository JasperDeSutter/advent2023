const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("16", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    const visited = try alloc.alloc(bool, input.len);
    defer alloc.free(visited);

    const stride: usize = @intCast(std.mem.indexOfScalar(u8, input, '\n').? + 1);

    var beams = std.ArrayList(Beam).init(alloc);
    defer beams.deinit();

    var skips = std.ArrayListUnmanaged(usize){};
    defer skips.deinit(alloc);

    const firstBeam = try runBeams(visited, &beams, stride, input, .{ .dir = right, .i = std.math.maxInt(usize) }, &skips);
    try skips.append(alloc, std.math.maxInt(usize));

    var highest: usize = 0;

    // beams are checked from top to bottom so skips only need
    for (0..(stride - 1)) |col| {
        const a = try runBeams(visited, &beams, stride, input, .{ .dir = down, .i = col -% stride }, &skips);
        highest = @max(highest, a);
    }

    const rows = (input.len + 1) / stride;
    for (0..rows) |row| {
        const off = row * stride;
        const a = try runBeams(visited, &beams, stride, input, .{ .dir = right, .i = off +% std.math.maxInt(usize) }, &skips);
        const b = try runBeams(visited, &beams, stride, input, .{ .dir = left, .i = off + stride - 1 }, &skips);
        highest = @max(highest, @max(a, b));
    }

    for (0..(stride - 1)) |col| {
        const b = try runBeams(visited, &beams, stride, input, .{ .dir = up, .i = col + input.len + 1 }, &skips);
        highest = @max(highest, b);
    }

    std.debug.print("skips: {any}\n", .{skips.items.len});

    return .{ firstBeam, highest };
}

const right: u8 = 0;
const down: u8 = 1;
const left: u8 = 2;
const up: u8 = 3;

const Beam = struct {
    dir: u8,
    i: usize,
};

fn runBeams(visited: []bool, beams: *std.ArrayList(Beam), stride: usize, input: []const u8, init: Beam, skips: *std.ArrayListUnmanaged(usize)) !usize {
    const skip = find(skips, init.i);
    if (skip < skips.items.len and skips.items[skip] == init.i) return 0;
    try beams.append(init);
    @memset(visited, false);

    var total_visited: usize = 0;

    while (beams.popOrNull()) |beam| {
        var i: usize = beam.i;
        var dir = beam.dir;
        outer: while (true) {
            const inc: usize = switch (dir) {
                right => 1,
                down => stride,
                left => std.math.maxInt(usize),
                up => std.math.maxInt(usize) - stride + 1,
                else => unreachable,
            };
            i +%= inc;
            while (i < input.len) : (i +%= inc) {
                const c = input[i];
                if (c == '\n') {
                    try addSkip(skips, i, beams.allocator);
                    break :outer;
                }

                const v = visited[i];
                if ((c == '-' or c == '|') and v) break :outer;
                if (!v) {
                    total_visited += 1;
                    visited[i] = true;
                }

                if (c == '/') {
                    dir = switch (dir) {
                        right => up,
                        down => left,
                        left => down,
                        up => right,
                        else => unreachable,
                    };
                    break;
                }
                if (c == '\\') {
                    dir = switch (dir) {
                        right => down,
                        down => right,
                        left => up,
                        up => left,
                        else => unreachable,
                    };
                    break;
                }
                if (c == '-' and (dir == up or dir == down)) {
                    try beams.append(.{ .dir = left, .i = i });
                    dir = right;
                    break;
                }
                if (c == '|' and (dir == left or dir == right)) {
                    try beams.append(.{ .dir = up, .i = i });
                    dir = down;
                    break;
                }
            } else {
                try addSkip(skips, i, beams.allocator);
                break;
            }
        }
    }

    return total_visited;
}

fn find(skips: *std.ArrayListUnmanaged(usize), i: usize) usize {
    var l: usize = 0;
    var r = skips.items.len;
    while (l < r) {
        const mid = (l + r) / 2;
        const mid_val = skips.items[mid];
        if (mid_val < i) {
            l = mid + 1;
        } else {
            r = mid;
        }
    }

    return l;
    // var j: usize = 0;
    // while (j < skips.items.len) : (j += 1) {
    //     if (skips.items[j] == i) return j;
    // }
    // return j + 1;
}

fn addSkip(skips: *std.ArrayListUnmanaged(usize), i: usize, alloc: std.mem.Allocator) !void {
    const s = find(skips, i);
    if (s < skips.items.len and skips.items[s] == i) return;
    try skips.insert(alloc, s, i);
    // try skips.append(alloc, i);
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
