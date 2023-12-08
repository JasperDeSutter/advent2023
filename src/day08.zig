const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("08", solve);

fn id(name: []const u8) u16 {
    var result: u16 = 0;
    for (name[0..3]) |c| {
        result = (result << 5) | (c - 'A');
    }
    return result;
}

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    var result: [2]usize = .{ 0, 0 };

    var lines = std.mem.split(u8, input, "\n");
    const directions = lines.next().?;
    _ = lines.next().?;

    var map = try alloc.alloc([2]u16, id("ZZZ") + 1);
    defer alloc.free(map);

    var steps = std.ArrayList(u16).init(alloc);
    defer steps.deinit();

    while (lines.next()) |line| {
        const node = id(line[0..3]);
        const left = id(line[7..10]);
        const right = id(line[12..15]);
        map[node] = .{ left, right };

        if (line[2] == 'A') {
            try steps.append(node);
        }
    }

    const end = 'Z' - 'A';
    for (steps.items) |s| {
        var step = s;
        var loops: usize = 0;
        while (step & 0x1F != end) {
            for (directions) |dir| {
                const node = map[step];
                step = switch (dir) {
                    'L' => node[0],
                    else => node[1],
                };
            }
            loops += directions.len;
        }

        const start_p1 = id("AAA");
        if (s == start_p1) {
            result[0] = loops;
        }

        const a = result[1];
        if (a > 0) {
            // loop lengths are always a prime * direction count
            result[1] = a * loops / directions.len;
        } else {
            result[1] = loops;
        }
    }

    return result;
}

test {
    const input =
        \\RL
        \\
        \\AAA = (BBB, CCC)
        \\BBB = (DDD, EEE)
        \\CCC = (ZZZ, GGG)
        \\DDD = (DDD, DDD)
        \\EEE = (EEE, EEE)
        \\GGG = (GGG, GGG)
        \\ZZZ = (ZZZ, ZZZ)
    ;

    const result = try solve(std.testing.allocator, input);
    const example_result: usize = 2;
    try std.testing.expectEqual(example_result, result[0]);
}

test {
    const input =
        \\LLR
        \\
        \\AAA = (BBB, BBB)
        \\BBB = (AAA, ZZZ)
        \\ZZZ = (ZZZ, ZZZ)
    ;

    const result = try solve(std.testing.allocator, input);
    const example_result: usize = 6;
    try std.testing.expectEqual(example_result, result[0]);
}

test {
    const input =
        \\LR
        \\
        \\IIA = (IIB, XXX)
        \\IIB = (XXX, IIZ)
        \\IIZ = (IIB, XXX)
        \\JJA = (JJB, XXX)
        \\JJB = (JJC, JJC)
        \\JJC = (JJZ, JJZ)
        \\JJZ = (JJB, JJB)
        \\XXX = (XXX, XXX)
    ;

    const result = try solve(std.testing.allocator, input);
    const example_result: usize = 6;
    try std.testing.expectEqual(example_result, result[1]);
}
