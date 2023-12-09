const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("09", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    var sum: isize = 0;

    var lines = std.mem.split(u8, input, "\n");
    var numbers = std.ArrayList(i32).init(alloc);
    defer numbers.deinit();

    while (lines.next()) |line| {
        numbers.items.len = 0;
        var parts = std.mem.split(u8, line, " ");
        while (parts.next()) |part| {
            const num = try std.fmt.parseInt(i32, part, 10);
            try numbers.append(num);
        }

        var len = numbers.items.len - 1;

        while (len > 0) {
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
        sum += numbers.items[len - 1];
    }

    return .{ @intCast(sum), 0 };
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
}
