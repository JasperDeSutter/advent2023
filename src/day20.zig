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

        const outputs = line[i + 4 ..];
        const name = line[1..i];

        try map.put(alloc, name, .{
            .outputs = outputs,
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
            var module = map.getPtr(output) orelse continue;

            if (module.value == .conjunction) {
                try module.value.conjunction.inputs.append(
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
    for (0..1000) |iteration| {
        try queue.append(alloc, .{ "roadcaster", "button", false });

        while (popFront(QueueItem, &queue)) |item| {
            if (iteration < 1000) {
                pulses[@intFromBool(item.@"2")] += 1;
            }

            var module = map.getPtr(item.@"0") orelse continue;

            var outputs = std.mem.splitSequence(u8, module.outputs, ", ");

            var pulse = item.@"2";
            if (module.value == .flipflop) {
                if (pulse) {
                    continue;
                }
                pulse = !module.value.flipflop.state;
                module.value.flipflop.state = pulse;
            }
            if (module.value == .conjunction) {
                var i: usize = 0;
                var items = module.value.conjunction.inputs.items;
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

    var singleLowPulse: usize = 1;
    {
        var chainStarts = std.mem.split(u8, map.getPtr("roadcaster").?.outputs, ", ");
        while (chainStarts.next()) |root| {
            var bit: usize = 1;
            var num: usize = 0;
            var curr = root;
            while (true) {
                var next: ?[]const u8 = null;
                var outputs = std.mem.split(u8, map.getPtr(curr).?.outputs, ", ");
                while (outputs.next()) |f| {
                    switch (map.getPtr(f).?.value) {
                        .flipflop => next = f,
                        .conjunction => num |= bit,
                        else => {},
                    }
                }
                if (next == null) break;
                curr = next.?;
                bit = bit << 1;
            }
            singleLowPulse *= num;
        }
    }

    return .{ pulses[0] * pulses[1], singleLowPulse };
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
