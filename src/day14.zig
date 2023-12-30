const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("14", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    // x, y
    var roundStones = [_]std.ArrayListUnmanaged(u7){.{}} ** 2;

    // north, west, south, east
    var distanceMap = [_]std.ArrayListUnmanaged(i8){.{}} ** 4;
    defer {
        for (0..roundStones.len) |stone| roundStones[stone].deinit(alloc);
        for (0..distanceMap.len) |stone| distanceMap[stone].deinit(alloc);
    }

    const lineLength = std.mem.indexOfScalar(u8, input, '\n').? + 1;
    const rows = (input.len + 1) / lineLength;
    const cols = lineLength - 1;

    for (0..distanceMap.len) |i| {
        try distanceMap[i].ensureTotalCapacity(alloc, rows * cols);
    }

    for (input, 0..) |c, i| {
        if (c == '\n') continue;
        const row: u7 = @intCast(i / lineLength);
        const col: u7 = @intCast(i % lineLength);
        if (c == 'O') {
            try roundStones[0].append(alloc, (col));
            try roundStones[1].append(alloc, (row));
        }

        var north: i8 = row + 1;
        north = -north;
        var south: i8 = @intCast(rows - row);
        for (0..rows) |j| {
            const off = j * lineLength + col;
            if (input[off] == '#') {
                var dist: i8 = @intCast(j);
                dist -= row;
                if (dist <= 0) {
                    north = dist;
                }
                if (dist >= 0) {
                    south = dist;
                    break;
                }
            }
        }
        var west: i8 = col + 1;
        west = -west;
        var east: i8 = @intCast(cols - col);
        for (0..cols) |j| {
            const off = row * lineLength + j;
            if (input[off] == '#') {
                var dist: i8 = @intCast(j);
                dist -= col;
                if (dist <= 0) {
                    west = dist;
                }
                if (dist >= 0) {
                    east = dist;
                    break;
                }
            }
        }

        distanceMap[0].appendAssumeCapacity(@intCast(north));
        distanceMap[1].appendAssumeCapacity(@intCast(west));
        distanceMap[2].appendAssumeCapacity(@intCast(south));
        distanceMap[3].appendAssumeCapacity(@intCast(east));
    }

    const stacks = try alloc.alloc(u7, rows * cols);
    defer alloc.free(stacks);

    tilt(stacks, roundStones[1].items, roundStones[0].items, distanceMap[0].items, cols, false);
    const loadSingleTilt = load(roundStones[1].items, rows);

    var map = std.AutoHashMapUnmanaged(u64, u16){};
    defer map.deinit(alloc);

    var tilts: u16 = 1;
    try map.put(alloc, cycle(stacks, &roundStones, &distanceMap, cols, rows, true), tilts);

    const looped = while (true) {
        tilts += 1;
        const key = cycle(stacks, &roundStones, &distanceMap, cols, rows, false);
        const res = try map.getOrPut(alloc, key);

        if (res.found_existing) {
            break tilts - res.value_ptr.*;
        } else {
            res.value_ptr.* = tilts;
        }
    };

    const t: usize = @intCast(tilts);
    const remainder = @rem(1_000_000_000 - t, looped);
    for (0..remainder) |_| {
        _ = cycle(stacks, &roundStones, &distanceMap, cols, rows, false);
    }

    return .{ loadSingleTilt, load(roundStones[1].items, rows) };
}

fn cycle(stacks: []u7, roundStones: *[2]std.ArrayListUnmanaged(u7), distanceMap: *[4]std.ArrayListUnmanaged(i8), cols: usize, rows: usize, comptime skipFirst: bool) u64 {
    if (!skipFirst) {
        tilt(stacks, roundStones[1].items, roundStones[0].items, distanceMap[0].items, cols, false);
    }
    const tiltN: u64 = @intCast(load(roundStones[1].items, rows));
    tilt(stacks, roundStones[0].items, roundStones[1].items, distanceMap[1].items, cols, true);
    tilt(stacks, roundStones[1].items, roundStones[0].items, distanceMap[2].items, cols, false);
    const tiltS = load(roundStones[1].items, rows);
    tilt(stacks, roundStones[0].items, roundStones[1].items, distanceMap[3].items, cols, true);
    return (tiltN << 32) | tiltS;
}

fn load(ys: []const u7, rows: usize) usize {
    var ret: usize = 0;
    for (ys) |y| ret += (rows - y);
    return ret;
}

fn tilt(stacks: []u7, co1: []u7, co2: []const u7, distanceMap: []const i8, stride: usize, comptime xy: bool) void {
    @memset(stacks, 0);
    for (co1, co2, 0..) |c1, c2, i| {
        const off = if (xy) c1 + c2 * stride else c1 * stride + c2;
        const dist = distanceMap[off];
        const square: usize = @intCast(@min(stride - 1, @max(0, c1 + dist)));
        const stack = &stacks[if (xy) square + c2 * stride else square * stride + c2];
        const s = stack.* + 1;
        stack.* = s;

        const adist: u7 = @intCast(@abs(dist));
        const move = if (s > adist) m: { // TODO: this can be simplified
            const m: i8 = @intCast(s - adist);
            if (dist < 0) {
                break :m m;
            }
            break :m -m;
        } else m: {
            const m: i8 = @intCast(adist - s);
            if (dist < 0) {
                break :m -m;
            }
            break :m m;
        };
        if (move != 0) {
            co1[i] = @intCast(c1 + move);
        }
    }
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
    const example_result2: usize = 64;
    try std.testing.expectEqual(example_result2, result[1]);
}
