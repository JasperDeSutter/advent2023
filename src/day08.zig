const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run(solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror!void {
    const result = try impl(alloc, input);
    std.debug.print("08 part 1: {}\n", .{result[0]});
    std.debug.print("08 part 2: {}\n", .{result[1]});
}

fn id(name: []const u8) u16 {
    var result: u16 = 0;
    for (name[0..3]) |c| {
        result = (result << 5) | (c - 'A');
    }
    return result;
}

fn impl(alloc: std.mem.Allocator, input: []const u8) ![2]usize {
    var result: [2]usize = .{ 0, 1 };

    var lines = std.mem.split(u8, input, "\n");
    const directions = lines.next().?;
    _ = lines.next().?;

    var map = std.AutoHashMap(u16, [2]u16).init(alloc);
    defer map.deinit();

    var steps = std.ArrayList(u16).init(alloc);
    defer steps.deinit();

    while (lines.next()) |line| {
        const node = id(line[0..3]);
        const left = id(line[7..10]);
        const right = id(line[12..15]);
        try map.put(node, .{ left, right });

        if (line[2] == 'A') {
            try steps.append(node);
        }
    }

    const end = 'Z' - 'A';
    for (steps.items) |s| {
        var step = s;
        var loops: usize = 0;
        outer: while (true) {
            for (directions, 0..) |dir, i| {
                const node = map.get(step).?;
                step = switch (dir) {
                    'L' => node[0],
                    else => node[1],
                };
                if (step & 0x1F == end) {
                    loops += i + 1;
                    break :outer;
                }
            }
            loops += directions.len;
        }
        if (s == 0) {
            result[0] = loops;
        }

        const a = result[1];
        const b = loops;
        result[1] = a * b / try gcd(a, b);
    }

    return result;
}

fn gcd(a: usize, b: usize) !usize {
    var b2 = b;
    var a2 = a;
    while (b2 != 0) {
        const t = b2;
        b2 = try std.math.mod(usize, a2, b2);
        a2 = t;
    }
    return a2;
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

    const result = try impl(std.testing.allocator, input);
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

    const result = try impl(std.testing.allocator, input);
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

    const result = try impl(std.testing.allocator, input);
    const example_result: usize = 6;
    try std.testing.expectEqual(example_result, result[1]);
}
