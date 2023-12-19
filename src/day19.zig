const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("16", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    const Workflow = struct {
        condition_op: u8,
        condition_value: u16,
        condition_variable: u8,
        branch: []const u8,
    };

    var map = std.StringHashMap(std.ArrayListUnmanaged(Workflow)).init(alloc);
    defer {
        var values = map.valueIterator();
        while (values.next()) |value| {
            value.deinit(alloc);
        }
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
        const entry = try map.getOrPut(name);
        var workflow = entry.value_ptr;
        workflow.* = .{};

        var parts = std.mem.splitScalar(u8, line[i + 1 .. line.len - 1], ',');
        while (parts.next()) |part| {
            const colon = std.mem.indexOfScalar(u8, part, ':');
            if (colon) |c| {
                const value = try std.fmt.parseInt(u16, part[2..c], 10);

                const variable: u8 = switch (part[0]) {
                    'x' => 0,
                    'm' => 1,
                    'a' => 2,
                    else => 3,
                };

                try workflow.append(alloc, .{
                    .condition_op = part[1],
                    .condition_value = value,
                    .condition_variable = variable,
                    .branch = part[c + 1 ..],
                });
            } else {
                try workflow.append(alloc, .{
                    .condition_op = 0,
                    .condition_value = 0,
                    .condition_variable = 0,
                    .branch = part,
                });
            }
        }
    }

    var acceptedParts: usize = 0;
    while (lines.next()) |line| {
        var values = [1]u16{0} ** 4;
        var sum: usize = 0;
        {
            var j: usize = 0;
            var i: usize = 2;
            while (j < values.len) : (j += 1) {
                while (line[i] != '=') : (i += 1) {}
                const start = i + 1;
                while (line[i] != ',' and line[i] != '}') : (i += 1) {}
                const value = try std.fmt.parseInt(u16, line[start..i], 10);
                values[j] = value;
                sum += value;
            }
        }

        var node: []const u8 = "in";
        while (true) {
            const workflow = map.get(node).?;
            for (workflow.items) |item| {
                const value = values[item.condition_variable];
                const condition_value = item.condition_value;
                const condition_op = item.condition_op;
                const branch = item.branch;

                if (condition_op == 0) {
                    node = branch;
                    break;
                } else if (condition_op == '<') {
                    if (value < condition_value) {
                        node = branch;
                        break;
                    }
                } else if (condition_op == '>') {
                    if (value > condition_value) {
                        node = branch;
                        break;
                    }
                }
            }

            if (node.len == 1 and node[0] == 'R' or node[0] == 'A') {
                if (node[0] == 'A') {
                    acceptedParts += sum;
                }
                break;
            }
        }
    }

    return .{ acceptedParts, 0 };
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
}
