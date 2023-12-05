const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run(solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror!void {
    const result = try lowestLocation(alloc, input);
    std.debug.print("05 lowest location: {}\n", .{result[0]});
    std.debug.print("05 lowest location range: {}\n", .{result[1]});
}

fn lowestLocation(alloc: std.mem.Allocator, input: []const u8) ![2]usize {
    var result: usize = std.math.maxInt(usize);
    var resultRange: usize = std.math.maxInt(usize);

    var lines = std.mem.split(u8, input, "\n");
    const seedsLine = lines.next().?;

    var mapping = std.ArrayList(std.ArrayList([3]usize)).init(alloc);
    defer {
        for (mapping.items) |item| {
            item.deinit();
        }
        mapping.deinit();
    }
    var last: ?*std.ArrayList([3]usize) = null;

    while (lines.next()) |line| {
        if (line.len == 0) {
            const ptr = try mapping.addOne();
            ptr.* = std.ArrayList([3]usize).init(alloc);
            last = ptr;
        } else if (std.ascii.isDigit(line[0])) {
            var nums = std.mem.split(u8, line, " ");
            const first = try std.fmt.parseInt(usize, nums.next().?, 10);
            const second = try std.fmt.parseInt(usize, nums.next().?, 10);
            const third = second + try std.fmt.parseInt(usize, nums.next().?, 10);

            var l = last.?;
            for (l.items, 0..) |item, i| {
                if (item[1] > second) {
                    try l.insert(i, .{ first, second, third });
                    break;
                }
            } else {
                try l.append(.{ first, second, third });
            }
        }
    }

    var seeds = std.mem.split(u8, seedsLine[7..], " ");
    var prev: ?usize = null;
    while (seeds.next()) |seed_str| {
        const seed = try std.fmt.parseInt(usize, seed_str, 10);
        const single = mapValue(seed, mapping.items);
        if (single < result) result = single;

        if (prev) |start| {
            for (start..start + seed) |i| {
                const value = mapValue(i, mapping.items);
                if (value < resultRange) {
                    resultRange = value;
                }
            }

            prev = null;
        } else {
            prev = seed;
        }
    }

    return .{ result, resultRange };
}

fn mapValue(startValue: usize, mapping: []const std.ArrayList([3]usize)) usize {
    var value = startValue;
    for (mapping) |item| {
        if (item.items[0][1] < value and item.items[item.items.len - 1][2] < value) {
            continue;
        }
        var left: usize = 0;
        var right: usize = item.items.len;

        while (left < right) {
            const mid = left + (right - left) / 2;

            const map = item.items[mid];
            if (map[1] <= value) {
                if (map[2] > value) {
                    value += map[0];
                    value -= map[1];
                    break;
                }
                left = mid + 1;
            } else {
                right = mid;
            }
        }
    }
    return value;
}

test {
    const input =
        \\seeds: 79 14 55 13
        \\
        \\seed-to-soil map:
        \\50 98 2
        \\52 50 48
        \\
        \\soil-to-fertilizer map:
        \\0 15 37
        \\37 52 2
        \\39 0 15
        \\
        \\fertilizer-to-water map:
        \\49 53 8
        \\0 11 42
        \\42 0 7
        \\57 7 4
        \\
        \\water-to-light map:
        \\88 18 7
        \\18 25 70
        \\
        \\light-to-temperature map:
        \\45 77 23
        \\81 45 19
        \\68 64 13
        \\
        \\temperature-to-humidity map:
        \\0 69 1
        \\1 0 69
        \\
        \\humidity-to-location map:
        \\60 56 37
        \\56 93 4
    ;

    const example_result: usize = 35;
    const result = try lowestLocation(std.testing.allocator, input);
    try std.testing.expectEqual(example_result, result[0]);
    const example_result_range: usize = 46;
    try std.testing.expectEqual(example_result_range, result[1]);
}
