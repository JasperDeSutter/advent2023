const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("16", solve);

fn fastParse(comptime T: type, s: []const u8) T {
    var result: T = 0;
    var i: usize = 0;
    while (std.ascii.isDigit(s[i])) : (i += 1) {
        result *= 10;
        result += s[i] - '0';
    }
    return result;
}

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    var map = std.StringHashMap([]const u8).init(alloc);
    defer {
        map.deinit();
    }

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }
        var i: usize = 0;
        while (line[i] != '{') : (i += 1) {}

        const name = line[0..i];
        try map.put(name, line[i + 1 .. line.len - 1]);
    }

    const Ranges = [4][2]u16;
    var stack = std.ArrayListUnmanaged(struct { []const u8, Ranges }){};
    defer stack.deinit(alloc);

    var accepted = std.ArrayListUnmanaged(Ranges){};
    defer accepted.deinit(alloc);

    try stack.append(alloc, .{ "in", [1][2]u16{.{ 1, 4000 }} ** 4 });

    while (stack.popOrNull()) |item| {
        var values = item.@"1";

        const line = map.get(item.@"0").?;

        var parts = std.mem.splitScalar(u8, line, ',');
        while (parts.next()) |part| {
            const colon = std.mem.indexOfScalar(u8, part, ':');
            const new = if (colon) |c| lbl: {
                const value = fastParse(u16, part[2..]);

                const variable: u8 = switch (part[0]) {
                    'x' => 0,
                    'm' => 1,
                    'a' => 2,
                    else => 3,
                };

                const op = part[1];
                const branch = part[c + 1 ..];

                var right = values[variable];
                if (op == '<') {
                    right[0] = value;
                    values[variable][1] = value - 1;
                } else {
                    right[1] = value;
                    values[variable][0] = value + 1;
                }
                const new = .{
                    branch,
                    values,
                };
                values[variable] = right;
                break :lbl new;
            } else .{
                part,
                values,
            };

            if (new.@"0".len == 1) {
                if (new.@"0"[0] == 'A') {
                    try accepted.append(alloc, new.@"1");
                }
            } else {
                try stack.append(alloc, new);
            }
        }
    }

    // const ctx = struct {
    //     fn lessThan(_: void, l: Ranges, r: Ranges) bool {
    //         inline for (0..4) |i| {
    //             const first = std.math.order(l[i][0], r[i][0]);
    //             if (first != .eq) {
    //                 return first == .lt;
    //             }
    //             const second = std.math.order(l[i][1], r[i][1]);
    //             if (second != .eq) {
    //                 return second == .lt;
    //             }
    //         } else unreachable;
    //     }
    // };

    // std.mem.sortUnstable(Ranges, accepted.items, {}, ctx.lessThan);

    var acceptedParts: usize = 0;
    while (lines.next()) |line| {
        var values = [1]u16{0} ** 4;
        var sum: usize = 0;
        {
            var j: usize = 0;
            var i: usize = 2;
            while (j < values.len) : (j += 1) {
                while (line[i] != '=') : (i += 1) {}
                i += 1;
                const value = fastParse(u16, line[i..]);
                values[j] = value;
                sum += value;
            }
        }

        for (accepted.items) |item| {
            for (0..4) |i| {
                if (values[i] < item[i][0] or values[i] > item[i][1]) {
                    break;
                }
            } else {
                acceptedParts += sum;
            }
        }

        // const srch = struct {
        //     fn compareFn(_: void, key: [4]u16, item: Ranges) std.math.Order {
        //         inline for (0..4) |i| {
        //             if (key[i] < item[i][0]) {
        //                 return .lt;
        //             }
        //             if (key[i] > item[i][1]) {
        //                 return .gt;
        //             }
        //         } else return .eq;
        //     }
        // };

        // if (std.sort.binarySearch(Ranges, values, accepted.items, {}, srch.compareFn)) |_| {
        //     acceptedParts += sum;
        // }
    }

    var acceptedNumbers: usize = 0;
    for (accepted.items) |a| {
        var result: usize = 1;
        for (a) |v| {
            result *= (v[1] - v[0] + 1);
        }
        acceptedNumbers += result;
    }

    return .{ acceptedParts, acceptedNumbers };
}

test {
    const input =
        \\px{a<2006:qkq,m>2090:A,rfg}
        \\pv{a>1716:R,A}
        \\lnx{m>1548:A,A}
        \\rfg{s<537:gd,x>2440:R,A}
        \\qs{s>3448:A,lnx}
        \\qkq{x<1416:A,crn}
        \\crn{x>2662:A,R}
        \\in{s<1351:px,qqz}
        \\qqz{s>2770:qs,m<1801:hdj,R}
        \\gd{a>3333:R,R}
        \\hdj{m>838:A,pv}
        \\
        \\{x=787,m=2655,a=1222,s=2876}
        \\{x=1679,m=44,a=2067,s=496}
        \\{x=2036,m=264,a=79,s=2244}
        \\{x=2461,m=1339,a=466,s=291}
        \\{x=2127,m=1623,a=2188,s=1013}
    ;

    const result = try solve(std.testing.allocator, input);
    const example_result: usize = 19114;
    try std.testing.expectEqual(example_result, result[0]);
    const example_result2: usize = 167409079868000;
    try std.testing.expectEqual(example_result2, result[1]);
}
