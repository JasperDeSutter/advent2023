const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("20", solve);

const ModuleTag = enum {
    flipflop,
    conjunction,
    broadcaster,
};

const Module = struct {
    outputs: []const u8,
    value: union(ModuleTag) {
        flipflop: FlipFlop,
        conjunction: Conjunction,
        broadcaster: void,
    },
};

const FlipFlop = struct {
    state: bool,
};

const Conjunction = struct {
    inputs: std.ArrayListUnmanaged(struct { []const u8, bool }),
};

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    var map = std.StringHashMapUnmanaged(Module){};
    defer {
        var values = map.valueIterator();
        while (values.next()) |it| {
            if (it.value == .conjunction) {
                it.value.conjunction.inputs.deinit(alloc);
            }
        }
        map.deinit(alloc);
    }

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const typ = line[0];

        var i: usize = 1;
        while (line[i] != ' ') : (i += 1) {}

        try map.put(alloc, line[1..i], .{
            .outputs = line[i + 4 ..],
            .value = switch (typ) {
                'b' => .{ .broadcaster = {} },
                '%' => .{ .flipflop = .{
                    .state = false,
                } },
                else => .{ .conjunction = .{
                    .inputs = .{},
                } },
            },
        });
    }

    var values = map.iterator();
    while (values.next()) |it| {
        var outputs = std.mem.splitSequence(u8, it.value_ptr.outputs, ", ");

        while (outputs.next()) |output| {
            var module = map.getEntry(output) orelse continue;

            if (module.value_ptr.value == .conjunction) {
                try module.value_ptr.value.conjunction.inputs.append(
                    alloc,
                    .{ it.key_ptr.*, false },
                );
            }
        }
    }

    const QueueItem = struct { []const u8, []const u8, bool };
    var queue = std.ArrayListUnmanaged(QueueItem){};
    defer queue.deinit(alloc);

    var pulses = [2]usize{ 0, 0 };
    for (0..1000) |_| {
        try queue.append(alloc, .{ "roadcaster", "button", false });

        while (popFront(QueueItem, &queue)) |item| {
            pulses[@intFromBool(item.@"2")] += 1;

            var module = map.getEntry(item.@"0") orelse continue;

            var outputs = std.mem.splitSequence(u8, module.value_ptr.outputs, ", ");

            var pulse = item.@"2";
            if (module.value_ptr.value == .flipflop) {
                if (pulse) {
                    continue;
                }
                pulse = !module.value_ptr.value.flipflop.state;
                module.value_ptr.value.flipflop.state = pulse;
            }
            if (module.value_ptr.value == .conjunction) {
                var i: usize = 0;
                var items = module.value_ptr.value.conjunction.inputs.items;
                pulse = while (i < items.len) : (i += 1) {
                    var it = &items[i];
                    if (std.mem.eql(u8, it.@"0", item.@"1")) {
                        it.@"1" = pulse;
                    }
                    if (!it.@"1") {
                        break true;
                    }
                } else false;
            }
            while (outputs.next()) |output| {
                try queue.append(alloc, .{ output, item.@"0", pulse });
            }
        }
    }

    return .{ pulses[0] * pulses[1], 0 };
}

fn popFront(comptime T: type, list: *std.ArrayListUnmanaged(T)) ?T {
    if (list.items.len == 0) {
        return null;
    }
    const res = list.items[0];
    std.mem.copyForwards(T, list.items[0 .. list.items.len - 1], list.items[1..]);
    list.items.len -= 1;
    return res;
}

test {
    const input =
        \\broadcaster -> a, b, c
        \\%a -> b
        \\%b -> c
        \\%c -> inv
        \\&inv -> a
    ;

    const result = try solve(std.testing.allocator, input);
    const example_result: usize = 32000000;
    try std.testing.expectEqual(example_result, result[0]);
}

test {
    const input =
        \\broadcaster -> a
        \\%a -> inv, con
        \\&inv -> b
        \\%b -> con
        \\&con -> output
    ;

    const result = try solve(std.testing.allocator, input);
    const example_result: usize = 11687500;
    try std.testing.expectEqual(example_result, result[0]);
}
