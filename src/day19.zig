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

                const result = switch (condition_op) {
                    '<' => value < condition_value,
                    '>' => value > condition_value,
                    else => true,
                };
                if (result) {
                    node = branch;
                    break;
                }
            }

            if (node.len == 1) {
                if (node[0] == 'A') {
                    acceptedParts += sum;
                }
                break;
            }
        }
    }

    var acceptedNumbers: usize = 0;

    var stack = std.ArrayListUnmanaged(struct { []const u8, [4][2]u16 }){};
    defer stack.deinit(alloc);
    try stack.append(alloc, .{ "in", [1][2]u16{.{ 1, 4000 }} ** 4 });

    while (stack.popOrNull()) |item| {
        const node = item.@"0";
        var values = item.@"1";
        if (node.len == 1) {
            if (node[0] == 'A') {
                var result: usize = 1;
                for (values) |v| {
                    result *= (v[1] - v[0] + 1);
                }
                acceptedNumbers += result;
            }
            continue;
        }

        const wf = map.get(node).?;
        for (wf.items) |workflow| {
            if (workflow.condition_op != 0) {
                var right = values[workflow.condition_variable];
                if (workflow.condition_op == '<') {
                    right[0] = workflow.condition_value;
                    values[workflow.condition_variable][1] = workflow.condition_value - 1;
                } else {
                    right[1] = workflow.condition_value;
                    values[workflow.condition_variable][0] = workflow.condition_value + 1;
                }
                try stack.append(alloc, .{
                    workflow.branch,
                    values,
                });
                values[workflow.condition_variable] = right;
            } else {
                try stack.append(alloc, .{
                    workflow.branch,
                    values,
                });
            }
        }
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
