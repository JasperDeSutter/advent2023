const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run(solve);

fn solve(_: std.mem.Allocator, input: []const u8) anyerror!void {
    const result = try calibrationValue(input);
    std.debug.print("calibration value: {}\n", .{result});
}

fn calibrationValue(input: []const u8) !usize {
    var lines = std.mem.split(u8, input, "\n");
    var total: usize = 0;
    while (lines.next()) |line| {
        var start: usize = 0;
        var first_char: u8 = 0;
        for (line, 0..) |c, i| {
            if (c >= '0' and c <= '9') {
                start = i;
                first_char = c - '0';
                break;
            }
        }

        var j = line.len - 1;
        var last_char: u8 = 0;
        while (j >= start) : (j -= 1) {
            const c = line[j];
            if (c >= '0' and c <= '9') {
                last_char = c - '0';
                break;
            }
        }
        total += first_char * 10 + last_char;
    }
    return total;
}

test {
    const input =
        \\1abc2
        \\pqr3stu8vwx
        \\a1b2c3d4e5f
        \\treb7uchet
    ;

    const example_result: usize = 142;
    try std.testing.expectEqual(example_result, try calibrationValue(input));
}
