const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run(solve);

fn solve(_: std.mem.Allocator, input: []const u8) anyerror!void {
    const result = try partNumbers(input);
    std.debug.print("03 part numbers: {}\n", .{result});
}

fn isPart(input: []const u8, offset: isize) bool {
    if (offset < 0 or offset >= input.len) {
        return false;
    }
    const c = input[@intCast(offset)];
    return switch (c) {
        '0'...'9' => false,
        '.', '\n' => false,
        else => true,
    };
}

fn partNumbers(input: []const u8) !usize {
    var result: usize = 0;

    const line_len: isize = @intCast(std.mem.indexOfPosLinear(u8, input, 0, "\n").? + 1);

    var current_num: usize = 0;
    var match = false;
    for (input, 0..) |c, j| {
        const i: isize = @intCast(j);
        if (c <= '9' and c >= '0') {
            match = match or isPart(input, i - line_len) or isPart(input, i + line_len);
            if (!match and current_num == 0) {
                match = isPart(input, i - 1) or isPart(input, i - line_len - 1) or isPart(input, i + line_len - 1);
            }
            current_num *= 10;
            current_num += (c - '0');
        } else {
            if (current_num > 0) {
                match = match or isPart(input, i) or isPart(input, i - line_len) or isPart(input, i + line_len);
                if (match) {
                    result += current_num;
                }
                match = false;
                current_num = 0;
            }
        }
    }
    return result;
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

    const example_result: usize = 4361;
    const result = try partNumbers(input);
    try std.testing.expectEqual(example_result, result);
}
