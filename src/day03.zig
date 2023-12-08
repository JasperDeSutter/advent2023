const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("03", solve);

const Gears = std.MultiArrayList(struct {
    offset: usize,
    ratios: [2]u16,
});

const State = struct {
    gears: Gears,
    current_num: u16,
    match: bool,
    alloc: std.mem.Allocator,
};

fn checkPart(c: u8, offset: usize, state: *State) !void {
    switch (c) {
        '0'...'9' => return,
        '.', '\n' => return,
        '*' => {
            if (state.gears.len > 0) {
                const slice = state.gears.slice();
                const gears = slice.items(.offset);
                var i = state.gears.len - 1;
                while (i < state.gears.len) : (i -%= 1) {
                    const gear = gears[i];
                    if (gear == offset) {
                        var arr = &slice.items(.ratios)[i];
                        if (arr[1] != 0) {
                            arr[0] = 0;
                        } else {
                            arr[1] = state.current_num;
                        }
                        state.match = true;
                        return;
                    }
                }
            }
            try state.gears.append(state.alloc, .{ .offset = offset, .ratios = .{ state.current_num, 0 } });
        },
        else => {},
    }
    state.match = true;
}

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    var part_numbers: usize = 0;
    var gear_ratios: usize = 0;

    const line_len = std.mem.indexOfPosLinear(u8, input, 0, "\n").? + 1;
    var state = State{
        .alloc = alloc,
        .gears = Gears{},
        .current_num = 0,
        .match = false,
    };
    defer state.gears.deinit(alloc);

    var num_start: usize = 0;
    for (input, 0..) |c, i| {
        if (c <= '9' and c >= '0') {
            if (num_start == 0) {
                num_start = i;
            }
            state.current_num *= 10;
            state.current_num += (c - '0');
        } else if (state.current_num > 0) {
            if (i > line_len) {
                const start = num_start - line_len;
                if (start > 0) {
                    for (input[(start - 1)..(i - line_len + 1)], (start - 1)..) |c2, j| {
                        try checkPart(c2, j, &state);
                    }
                } else {
                    // top left corner
                    for (input[start..(i - line_len + 1)], start..) |c2, j| {
                        try checkPart(c2, j, &state);
                    }
                }
            }
            if (i < input.len - line_len) {
                const start = num_start + line_len - 1;
                for (input[start..(i + line_len + 1)], start..) |c2, j| {
                    try checkPart(c2, j, &state);
                }
            }
            if (num_start > 0) {
                try checkPart(input[num_start - 1], num_start - 1, &state);
            }
            try checkPart(c, i, &state);

            if (state.match) {
                part_numbers += state.current_num;
            }

            num_start = 0;
            state.current_num = 0;
            state.match = false;
        }
    }
    const ratios = state.gears.items(.ratios);
    for (ratios) |ratio| {
        const r1: usize = ratio[0];
        gear_ratios += r1 * ratio[1];
    }
    return .{ part_numbers, gear_ratios };
}

test {
    const input =
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\......755.
        \\...$.*....
        \\.664.598..
    ;

    const result = try solve(std.testing.allocator, input);
    const example_result: usize = 4361;
    try std.testing.expectEqual(example_result, result[0]);
    const example_result2: usize = 467835;
    try std.testing.expectEqual(example_result2, result[1]);
}
