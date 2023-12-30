const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("14", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    var state = try State.init(alloc, input);
    defer state.deinit(alloc);

    state.tiltNorth();
    const loadSingleTilt = state.load();

    var map = std.AutoHashMapUnmanaged(u32, u16){};
    defer map.deinit(alloc);

    var tilts: u16 = 1;
    try map.put(alloc, state.cycle(true), tilts);

    const looped = while (true) {
        tilts += 1;
        const key = state.cycle(false);
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
        _ = state.cycle(false);
    }

    return .{ loadSingleTilt, state.load() };
}

const State = struct {
    // x, y
    roundStones: [2]std.ArrayListUnmanaged(u8) = [_]std.ArrayListUnmanaged(u8){.{}} ** 2,
    // north, west, south, east
    distanceMap: [4]std.ArrayListUnmanaged(i8) = [_]std.ArrayListUnmanaged(i8){.{}} ** 4,
    stacks: []u8,
    rows: usize,
    cols: usize,

    fn init(alloc: std.mem.Allocator, input: []const u8) !@This() {
        const lineLength = std.mem.indexOfScalar(u8, input, '\n').? + 1;
        const rows = (input.len + 1) / lineLength;
        const cols = lineLength - 1;

        var self = @This(){
            .stacks = try alloc.alloc(u8, rows * cols),
            .rows = rows,
            .cols = cols,
        };
        errdefer self.deinit(alloc);

        for (0..self.distanceMap.len) |i| {
            try self.distanceMap[i].ensureTotalCapacity(alloc, rows * cols);
        }

        for (input, 0..) |c, i| {
            if (c == '\n') continue;
            const row: u7 = @intCast(i / lineLength);
            const col: u7 = @intCast(i % lineLength);
            if (c == 'O') {
                try self.roundStones[0].append(alloc, col);
                try self.roundStones[1].append(alloc, row);
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

            self.distanceMap[0].appendAssumeCapacity(@intCast(north));
            self.distanceMap[1].appendAssumeCapacity(@intCast(west));
            self.distanceMap[2].appendAssumeCapacity(@intCast(south));
            self.distanceMap[3].appendAssumeCapacity(@intCast(east));
        }

        return self;
    }

    fn deinit(self: *@This(), alloc: std.mem.Allocator) void {
        for (0..self.roundStones.len) |stone| self.roundStones[stone].deinit(alloc);
        for (0..self.distanceMap.len) |stone| self.distanceMap[stone].deinit(alloc);
        alloc.free(self.stacks);
    }

    fn cycle(self: *@This(), skipFirst: bool) u32 {
        if (!skipFirst) {
            self.tilt2(self.roundStones[1].items, self.roundStones[0].items, self.distanceMap[0].items, false);
        }
        self.tilt2(self.roundStones[0].items, self.roundStones[1].items, self.distanceMap[1].items, true);
        const tiltN = self.load2();
        self.tilt2(self.roundStones[1].items, self.roundStones[0].items, self.distanceMap[2].items, false);
        self.tilt2(self.roundStones[0].items, self.roundStones[1].items, self.distanceMap[3].items, true);
        const tiltS = self.load2();
        return tiltN ^ @byteSwap(tiltS);
    }

    fn tilt2(self: *@This(), co1: []u8, co2: []const u8, distanceMap: []const i8, comptime xy: bool) void {
        tilt(co1, co2, distanceMap, self.stacks, self.cols, xy);
    }

    fn tiltNorth(self: *@This()) void {
        self.tilt2(self.roundStones[1].items, self.roundStones[0].items, self.distanceMap[0].items, false);
    }

    fn load(self: *@This()) u32 {
        var ret: u32 = 0;
        const rows: u32 = @intCast(self.rows);
        for (self.roundStones[1].items) |y| ret += (rows - y);
        return ret;
    }

    fn load2(self: *@This()) u32 {
        var ret: u32 = 0;
        for (self.roundStones[1].items) |y| ret += y;
        return ret;
    }
};

fn tilt(co1: []u8, co2: []const u8, distanceMap: []const i8, stacks: []u8, stride: usize, comptime xy: bool) void {
    @memset(stacks, 0);
    for (co1, co2, 0..) |c1, c2, i| {
        const off = if (xy) c1 + c2 * stride else c1 * stride + c2;
        const dist: u8 = @bitCast(distanceMap[off]);
        const square: usize = @min(stride - 1, c1 +% dist);
        const stack = &stacks[if (xy) square + c2 * stride else square * stride + c2];

        const add: u8 = if (dist > 127) 255 else 1;
        const s = stack.* +% add;
        stack.* = s;
        co1[i] = c1 +% dist -% s;
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
