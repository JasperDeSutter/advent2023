const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run(solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror!void {
    const result = try impl(alloc, input);
    std.debug.print("06 part 1: {}\n", .{result[0]});
    std.debug.print("06 part 2: {}\n", .{result[1]});
}

fn impl(alloc: std.mem.Allocator, input: []const u8) ![2]usize {
    _ = alloc;
    var result: [2]usize = .{ 1, 0 };

    var lines = std.mem.split(u8, input, "\n");
    var times = std.mem.tokenizeScalar(u8, lines.next().?, ' ');
    var distances = std.mem.tokenizeScalar(u8, lines.next().?, ' ');

    _ = times.next().?;
    _ = distances.next().?;

    var actual_time: usize = 0;
    var actual_distance: usize = 0;
    while (times.next()) |time_s| {
        var time: usize = 0;
        for (time_s) |c| {
            time *= 10;
            time += c - '0';
            actual_time *= 10;
        }

        const distance_s = distances.next().?;
        var distance: usize = 0;
        for (distance_s) |c| {
            distance *= 10;
            distance += c - '0';
            actual_distance *= 10;
        }

        actual_time += time;
        actual_distance += distance;

        result[0] *= theThing(time, distance);
    }
    result[1] = theThing(actual_time, actual_distance);

    return result;
}

fn theThing(time: usize, distance: usize) usize {
    var left: usize = 0;
    var right = time / 2;

    // binary search for first time that works
    while (left < right) {
        const mid = (left + right) / 2;
        if ((time - mid) * mid <= distance) {
            left = mid + 1;
        } else {
            right = mid;
        }
    }

    // the inverse is the same, so apply twice
    return time - (right * 2) + 1;
}

test {
    const input =
        \\Time:      7  15   30
        \\Distance:  9  40  200
    ;

    const example_result: usize = 288;
    const result = try impl(std.testing.allocator, input);
    try std.testing.expectEqual(example_result, result[0]);
    const example_result_range: usize = 71503;
    try std.testing.expectEqual(example_result_range, result[1]);
}
