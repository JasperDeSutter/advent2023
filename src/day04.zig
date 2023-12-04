const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run(solve);

fn solve(_: std.mem.Allocator, input: []const u8) anyerror!void {
    const result = try scratchcards(input);
    std.debug.print("04 scratch card points: {}\n", .{result[0]});
    std.debug.print("04 scratch cards total: {}\n", .{result[1]});
}

fn scratchcards(input: []const u8) ![2]usize {
    var points: usize = 0;
    var total_scratchcards: usize = 0;

    var i: usize = 0;
    while (input[i] != ':') {
        i += 1;
    }
    const winning_start = i + 1;
    i += 2;
    while (input[i] != '|') {
        i += 1;
    }
    const separator = i + 1;

    var buffer = [_]usize{0} ** 10;
    var buffer_idx: usize = 0;

    var lines = std.mem.split(u8, input, "\n");
    while (lines.next()) |line| {
        const winning = line[winning_start..(separator - 2)];
        const numbers = line[separator..];

        var matches: u6 = 0;
        i = 0;
        while (i < numbers.len) : (i += 3) {
            const a = numbers[i + 1];
            const b = numbers[i + 2];
            var j: usize = 0;
            while (j < winning.len) : (j += 3) {
                if (winning[j + 1] == a and winning[j + 2] == b) {
                    matches += 1;
                    break;
                }
            }
        }
        if (matches > 0) {
            const one: usize = 1;
            points += (one << (matches - 1));
        }

        const count = 1 + buffer[buffer_idx];
        total_scratchcards += count;
        buffer[buffer_idx] = 0;
        buffer_idx = (buffer_idx + 1) % buffer.len;
        for (0..matches) |j| {
            buffer[(buffer_idx + j) % buffer.len] += count;
        }
    }

    return .{ points, total_scratchcards };
}

test {
    const input =
        \\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
        \\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
        \\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
        \\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
        \\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
        \\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
    ;

    const example_result: usize = 13;
    const result = try scratchcards(input);
    try std.testing.expectEqual(example_result, result[0]);

    const example_result2: usize = 30;
    try std.testing.expectEqual(example_result2, result[1]);
}
