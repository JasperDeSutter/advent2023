const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("20", solve);

const ModuleTag = enum {
    flipflop,
    conjunction,
    broadcaster,
};

const Module = struct {
    outputs: std.ArrayListUnmanaged([2]u8),
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
    inputs: std.ArrayListUnmanaged(struct { [2]u8, bool }),
};

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    var map = std.AutoHashMapUnmanaged([2]u8, Module){};
    defer {
        var values = map.valueIterator();
        while (values.next()) |it| {
            it.outputs.deinit(alloc);
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

        var name: [2]u8 = .{ 0, 0 };
        const nameTxt = line[1..i];
        if (nameTxt.len < 3) {
            name[0] = nameTxt[0];
            name[1] = nameTxt[1];
        }

        i += 4;
        var outputs = std.ArrayListUnmanaged([2]u8){};
        while (i < line.len) : (i += 4) {
            try outputs.append(alloc, .{ line[i], line[i + 1] });
        }

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
        for (it.value_ptr.outputs.items) |output| {
            var module = map.getPtr(output) orelse continue;

            if (module.value == .conjunction) {
                try module.value.conjunction.inputs.append(
                    alloc,
                    .{ it.key_ptr.*, false },
                );
            }
        }
    }

    const QueueItem = struct { [2]u8, [2]u8, bool };
    var queue = std.ArrayListUnmanaged(QueueItem){};
    defer queue.deinit(alloc);

    var pulses = [2]usize{ 0, 0 };
    for (0..1000) |iteration| {
        try queue.append(alloc, .{ .{ 0, 0 }, .{ 0, 0 }, false });

        var idx: usize = 0;
        while (idx < queue.items.len) : (idx += 1) {
            const item = queue.items[idx];
            if (iteration < 1000) {
                pulses[@intFromBool(item.@"2")] += 1;
            }

            var module = map.getPtr(item.@"0") orelse continue;

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
                    if (it.@"0"[0] == item.@"1"[0] and it.@"0"[1] == item.@"1"[1]) {
                        it.@"1" = pulse;
                    }
                    if (!it.@"1") {
                        break true;
                    }
                } else false;
            }

            for (module.outputs.items) |output| {
                try queue.append(alloc, .{ output, item.@"0", pulse });
            }
        }
        queue.items.len = 0;
    }

    var singleLowPulse: usize = 1;
    {
        for (map.getPtr(.{ 0, 0 }).?.outputs.items) |root| {
            var bit: usize = 1;
            var num: usize = 0;
            var curr = root;
            while (true) {
                var next: ?[2]u8 = null;
                for (map.getPtr(curr).?.outputs.items) |f| {
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

test {
    const input =
        \\broadcaster -> aa, bb, cc
        \\%aa -> bb
        \\%bb -> cc
        \\%cc -> in
        \\&in -> aa
    ;

    const result = try solve(std.testing.allocator, input);
    const example_result: usize = 32000000;
    try std.testing.expectEqual(example_result, result[0]);
}

test {
    const input =
        \\broadcaster -> aa
        \\%aa -> in, co
        \\&in -> bb
        \\%bb -> co
        \\&co -> ou
    ;

    const result = try solve(std.testing.allocator, input);
    const example_result: usize = 11687500;
    try std.testing.expectEqual(example_result, result[0]);
}
