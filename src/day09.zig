const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("09", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    var sum: isize = 0;
    var sumStart: isize = 0;

    var numbers = std.ArrayList(i32).init(alloc);
    defer numbers.deinit();

    var starts = std.ArrayList(i32).init(alloc);
    defer starts.deinit();

    var j: usize = 0;
    while (j < input.len) : (j += 1) {
        numbers.items.len = 0;
        starts.items.len = 0;

        var last_num: i32 = 0;
        var neg = false;
        while (j < input.len) : (j += 1) {
            const c = input[j];
            switch (c) {
                '\n' => break,
                ' ' => {
                    if (neg) last_num = -last_num;
                    try numbers.append(last_num);
                    neg = false;
                    last_num = 0;
                },
                '-' => neg = true,
                else => last_num = last_num * 10 + (c - '0'),
            }
        }
        if (neg) last_num = -last_num;
        try numbers.append(last_num);

        var len = numbers.items.len - 1;

        while (len > 0) {
            try starts.append(numbers.items[0]);
            var all_zero = true;
            for (numbers.items[0..len], 0..) |n, i| {
                const num = numbers.items[i + 1] - n;
                if (num != 0) all_zero = false;
                numbers.items[i] = num;
            }
            if (all_zero) break;
            len -= 1;
        }

        while (len < numbers.items.len) {
            numbers.items[len] = numbers.items[len] + numbers.items[len - 1];
            len += 1;
        }
        var i: usize = starts.items.len - 1;
        while (i > 0) : (i -= 1) {
            starts.items[i - 1] = starts.items[i - 1] - starts.items[i];
        }

        sum += numbers.items[len - 1];
        sumStart += starts.items[0];
    }

    return .{ @intCast(sum), @intCast(sumStart) };
}

test {
    const input =
        \\0 3 6 9 12 15
        \\1 3 6 10 15 21
        \\10 13 16 21 30 45
    ;

    const result = try solve(std.testing.allocator, input);
    const example_result: usize = 114;
    try std.testing.expectEqual(example_result, result[0]);
    const example_result2: usize = 2;
    try std.testing.expectEqual(example_result2, result[1]);
}

test {
    const input = "10 13 16 21 30 45";
    const result = try solve(std.testing.allocator, input);
    const example_result2: usize = 5;
    try std.testing.expectEqual(example_result2, result[1]);
}
