const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run(solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror!void {
    const result = try lowestLocation(alloc, input);
    std.debug.print("05 lowest location: {}\n", .{result});
}

fn lowestLocation(alloc: std.mem.Allocator, input: []const u8) !usize {
    var result: usize = std.math.maxInt(usize);

    var lines = std.mem.split(u8, input, "\n");
    const seedsLine = lines.next().?;

    var mapping = std.ArrayList(std.ArrayList([3]usize)).init(alloc);
    defer {
        for (mapping.items) |item| {
            item.deinit();
        }
        mapping.deinit();
    }
    var last: *std.ArrayList([3]usize) = undefined;

    while (lines.next()) |line| {
        if (line.len == 0) {
            last = try mapping.addOne();
            last.* = std.ArrayList([3]usize).init(alloc);
        } else if (std.ascii.isDigit(line[0])) {
            var nums = std.mem.split(u8, line, " ");
            const first = try std.fmt.parseInt(usize, nums.next().?, 10);
            const second = try std.fmt.parseInt(usize, nums.next().?, 10);
            const third = try std.fmt.parseInt(usize, nums.next().?, 10);
            try last.append(.{ first, second, second + third });
        }
    }

    var seeds = std.mem.split(u8, seedsLine[7..], " ");
    while (seeds.next()) |seed| {
        var value = try std.fmt.parseInt(usize, seed, 10);

        for (mapping.items) |item| {
            for (item.items) |map| {
                if (map[1] <= value and map[2] > value) {
                    value += map[0];
                    value -= map[1];
                    break;
                }
            }
        }

        if (value < result) result = value;
    }

    return result;
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
    try std.testing.expectEqual(example_result, result);
}
