const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("12", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    var solutionsPt1: usize = 0;
    var solutionsPt2: usize = 0;

    var text = std.ArrayListUnmanaged(u8){};
    defer text.deinit(alloc);

    var numbers = std.ArrayListUnmanaged(u8){};
    defer numbers.deinit(alloc);

    var table = std.ArrayListUnmanaged(u64){};
    defer table.deinit(alloc);

    var i: usize = 0;
    while (i < input.len) {
        numbers.items.len = 0;

        const start = i;
        while (i < input.len and input[i] != ' ') : (i += 1) {}
        const left = input[start..i];
        i += 1;

        var current_number: u8 = 0;
        while (i < input.len) : (i += 1) {
            const c = input[i];
            switch (c) {
                '\n' => break,
                ',' => {
                    try numbers.append(alloc, current_number);
                    current_number = 0;
                },
                else => {
                    current_number *= 10;
                    current_number += c - '0';
                },
            }
        }
        try numbers.append(alloc, current_number);

        {
            try text.resize(alloc, left.len + 1);
            @memcpy(text.items[1..], left);
            text.items[0] = '.';

            try table.resize(alloc, (text.items.len + 1) * 2);

            solutionsPt1 += impl(table.items, text.items, numbers.items);
        }

        {
            try text.resize(alloc, (left.len + 1) * 5);
            for (0..5) |j| {
                @memcpy(text.items[1 + j * (left.len + 1) .. (j + 1) * (left.len + 1)], left);
                text.items[j * (left.len + 1)] = '?';
            }
            text.items[0] = '.';

            try table.resize(alloc, (text.items.len + 1) * 2);

            const len = numbers.items.len;
            if (numbers.capacity >= len * 5) {
                for (0..4) |_| {
                    numbers.appendSliceAssumeCapacity(numbers.items[0..len]);
                }
            } else {
                var tmp = numbers;
                defer tmp.deinit(alloc);
                numbers = try std.ArrayListUnmanaged(u8).initCapacity(alloc, len * 5);
                for (0..5) |_| {
                    numbers.appendSliceAssumeCapacity(tmp.items);
                }
            }

            solutionsPt2 += impl(table.items, text.items, numbers.items);
        }

        i += 1;
    }
    return .{ solutionsPt1, solutionsPt2 };
}

fn impl(table: []u64, text: []const u8, numbers: []u8) u64 {
    var cachePrev = table[0 .. text.len + 1];
    var cache = table[text.len + 1 .. (text.len + 1) * 2];
    @memset(cachePrev, 0);
    cachePrev[0] = 1;

    for (text, 0..) |c, i| {
        if (c == '#') {
            break;
        }
        cachePrev[i + 1] = 1;
    }

    for (numbers) |number| {
        @memset(cache, 0);
        var chunk: u8 = 0;

        for (text, 0..) |c, i| {
            if (c != '.') {
                chunk += 1;
            } else {
                chunk = 0;
            }

            if (c != '#') {
                cache[i + 1] += cache[i];
            }

            if (chunk >= number and text[i - number] != '#') {
                cache[i + 1] += cachePrev[i - number];
            }
        }

        std.mem.swap([]u64, &cachePrev, &cache);
    }

    return cachePrev[cachePrev.len - 1];
}

test {
    const input =
        \\???.### 1,1,3
        \\.??..??...?##. 1,1,3
        \\?#?#?#?#?#?#?#? 1,3,1,6
        \\????.#...#... 4,1,1
        \\????.######..#####. 1,6,5
        \\?###???????? 3,2,1
    ;

    const result = try solve(std.testing.allocator, input);
    const example_result: usize = 21;
    try std.testing.expectEqual(example_result, result[0]);
    const example_result2: usize = 525152;
    try std.testing.expectEqual(example_result2, result[1]);
}
