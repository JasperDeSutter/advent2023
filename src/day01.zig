const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("01", solve);

fn solve(_: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    const result = try calibrationValue(input);
    const result2 = try calibrationValue2(input);
    return .{ result, result2 };
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

const digits: [10][]const u8 = .{
    "",
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
};

fn digitMatch(line: []const u8) u8 {
    const c = line[0];
    if (c >= '0' and c <= '9') {
        return c - '0';
    }

    // reduce work below by skipping digits that don't match the first character
    const start = inline for (digits[1..], 1..) |digit, i| {
        if (c == digit[0]) break i;
    } else {
        return 0;
    };

    for (digits[start..], start..) |digit, value| {
        if (line.len >= digit.len and std.mem.eql(u8, line[0..digit.len], digit)) {
            return @intCast(value);
        }
    }
    return 0;
}

fn calibrationValue2(input: []const u8) !usize {
    var lines = std.mem.split(u8, input, "\n");
    var total: usize = 0;
    while (lines.next()) |line| {
        var start: usize = 0;
        var first_char: u8 = 0;
        for (0..line.len) |i| {
            const digit = digitMatch(line[i..]);
            if (digit != 0) {
                start = i;
                first_char = digit;
                break;
            }
        }

        var j = line.len - 1;
        var last_char: u8 = first_char;
        while (j > start) : (j -= 1) {
            const digit = digitMatch(line[j..]);
            if (digit != 0) {
                last_char = digit;
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

    const input2 =
        \\two1nine
        \\eightwothree
        \\abcone2threexyz
        \\xtwone3four
        \\4nineeightseven2
        \\zoneight234
        \\7pqrstsixteen
    ;

    const example_result2: usize = 281;
    try std.testing.expectEqual(example_result2, try calibrationValue2(input2));
}
