const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("15", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    var sumHashes: usize = 0;
    {
        var current_hash: u8 = 0;

        for (input) |c| {
            if (c == ',') {
                sumHashes += current_hash;
                current_hash = 0;
            } else {
                var tmp: usize = c;
                tmp = ((tmp + current_hash) * 17);
                current_hash = @truncate(tmp);
            }
        }
        sumHashes += current_hash;
    }

    var focusingPower: usize = 0;
    {
        var hashMap = std.StringArrayHashMap(u8).init(alloc);
        defer hashMap.deinit();

        var parts = std.mem.splitScalar(u8, input, ',');
        const tombstone = "";
        while (parts.next()) |part| {
            if (part[part.len - 1] == '-') {
                const key = part[0 .. part.len - 1];
                if (hashMap.getEntry(key)) |entry| {
                    const key_ptr = @constCast(entry.key_ptr);
                    key_ptr.* = tombstone;
                    entry.value_ptr.* = 0;
                }
            } else {
                const key = part[0 .. part.len - 2];
                const value = part[part.len - 1] - '0';
                try hashMap.put(key, value);
            }
        }

        var iter = hashMap.iterator();
        var slots = [1]u8{0} ** 256;
        while (iter.next()) |it| {
            if (it.value_ptr.* == 0) {
                continue;
            }
            var current_hash: usize = 0;
            const name = it.key_ptr.*;
            for (name) |c| {
                current_hash = ((c + current_hash) * 17) % 256;
            }
            slots[current_hash] += 1;

            focusingPower += (current_hash + 1) * it.value_ptr.* * slots[current_hash];
        }
    }

    return .{ sumHashes, focusingPower };
}

test {
    const input =
        \\rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7
    ;

    const result = try solve(std.testing.allocator, input);
    const example_result: usize = 1320;
    try std.testing.expectEqual(example_result, result[0]);
    const example_result2: usize = 145;
    try std.testing.expectEqual(example_result2, result[1]);
}
