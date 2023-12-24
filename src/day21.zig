const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("21", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    var samples = try impl(alloc, input, &.{ 64, 65, 252, 253 });
    defer samples.deinit(alloc);

    const even_corners = samples.items[2] - samples.items[0];
    const odd_corners = samples.items[3] - samples.items[1];

    const even_full = samples.items[2];
    const odd_full = samples.items[3];

    const lineLen = std.mem.indexOfScalar(u8, input, '\n').?;
    const n = ((26501365 - (lineLen / 2)) / lineLen);

    const p2 = ((n + 1) * (n + 1)) * odd_full + (n * n) * even_full - (n + 1) * odd_corners + n * even_corners;

    return .{ samples.items[0], p2 };
}

fn impl(alloc: std.mem.Allocator, input: []const u8, samplePoints: []const u8) anyerror!std.ArrayListUnmanaged(usize) {
    const lineLen: u16 = @intCast(std.mem.indexOfScalar(u8, input, '\n').? + 1);
    const startPos: u16 = @intCast(std.mem.indexOfScalar(u8, input, 'S').?);

    const map = try alloc.alloc(u8, input.len);
    defer alloc.free(map);
    @memset(map, 0);

    const Tuple = struct { i: u16, step: u8 };
    var stack = try std.ArrayListUnmanaged(Tuple).initCapacity(alloc, 4);
    defer stack.deinit(alloc);
    stack.appendAssumeCapacity(.{ .i = startPos, .step = 1 });

    var stackIndex: usize = 0;
    while (stack.items.len > stackIndex) {
        const item = stack.items[stackIndex];
        stackIndex += 1;
        if (map.len <= item.i or map[item.i] != 0 or input[item.i] == '#' or input[item.i] == '\n') continue;

        map[item.i] = item.step;

        if (stack.capacity < stack.items.len + 4) {
            // discard old items while resizing
            var old = stack;
            stack = try std.ArrayListUnmanaged(Tuple).initCapacity(alloc, old.capacity * 2);
            stack.items.len = old.items.len - stackIndex;
            @memcpy(stack.items[0 .. old.items.len - stackIndex], old.items[stackIndex..]);
            old.deinit(alloc);
            stackIndex = 0;
        }

        const nextStep = item.step + 1;
        stack.appendSliceAssumeCapacity(&.{
            .{ .i = item.i -% 1, .step = nextStep },
            // thx zigfmt
            .{ .i = item.i +% 1, .step = nextStep },
            .{ .i = item.i -% lineLen, .step = nextStep },
            .{ .i = item.i +% lineLen, .step = nextStep },
        });
    }

    var samples = try std.ArrayListUnmanaged(usize).initCapacity(alloc, samplePoints.len);
    for (samplePoints) |steps| {
        var result: usize = 0;
        const odd = 1 - (steps % 2);
        for (map) |v| {
            if (v > 0 and v % 2 == odd and v < (steps + 2)) result += 1;
        }
        samples.appendAssumeCapacity(result);
    }

    return samples;
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

    var result = try impl(std.testing.allocator, input, &.{6});
    defer result.deinit(std.testing.allocator);
    const example_result: usize = 16;
    try std.testing.expectEqual(example_result, result.items[0]);
}
