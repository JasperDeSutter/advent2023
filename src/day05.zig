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

    var mapping = std.ArrayListUnmanaged(std.ArrayListUnmanaged([3]usize)){};
    defer {
        for (0..mapping.items.len) |i| {
            mapping.items[i].deinit(alloc);
        }
        mapping.deinit(alloc);
    }
    var last: *std.ArrayListUnmanaged([3]usize) = undefined;

    while (lines.next()) |line| {
        if (line.len == 0) {
            last = try mapping.addOne(alloc);
            last.* = .{};
        } else if (std.ascii.isDigit(line[0])) {
            const arr = try last.addOne(alloc);
            var slice: []usize = arr;

            var num: usize = 0;
            for (line) |i| {
                if (i == ' ') {
                    slice[0] = num;
                    slice = slice[1..];
                    num = 0;
                } else {
                    num *= 10;
                    num += i - '0';
                }
            }
            arr[2] = num + arr[1];
        }
    }

    var seeds = std.mem.split(u8, seedsLine[7..], " ");
    var prev: ?usize = null;
    while (seeds.next()) |seed_str| {
        const seed = try std.fmt.parseInt(usize, seed_str, 10);
        const single = mapValue(.{ seed, 1 }, mapping.items);
        if (single < result) result = single;

        if (prev) |start| {
            const value = mapValue(.{ start, seed }, mapping.items);
            if (value < resultRange) {
                resultRange = value;
            }

            prev = null;
        } else {
            prev = seed;
        }
    }

    return .{ result, resultRange };
}

fn mapValue(range: [2]usize, mapping: []const std.ArrayListUnmanaged([3]usize)) usize {
    var min: usize = std.math.maxInt(usize);
    var mapped: usize = 0;

    while (mapped < range[1]) {
        var value = range[0] + mapped;
        var active = range[1] - mapped;
        for (mapping) |item| {
            for (item.items) |map| {
                const mappable = map[2] -| value;
                if (map[1] <= value and mappable > 0) {
                    if (mappable < active) {
                        active = mappable;
                    }

                    value += map[0];
                    value -= map[1];
                    break;
                }
            }
        }
        mapped += active;
        if (value < min) min = value;
    }

    return min;
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
