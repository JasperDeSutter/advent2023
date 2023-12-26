const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("12", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    var solutions: usize = 0;

    var toSolve = std.ArrayListUnmanaged([2]u8){};
    defer toSolve.deinit(alloc);

    var numbers = std.ArrayListUnmanaged(u8){};
    defer numbers.deinit(alloc);

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
        toSolve.items.len = 0;
        solutions += try impl(alloc, &toSolve, left, numbers.items);
    }
    return .{ solutions, 0 };
}

fn impl(alloc: std.mem.Allocator, toSolve: *std.ArrayListUnmanaged([2]u8), inputText: []const u8, inputNumbers: []u8) !u16 {
    var solutions: u16 = 0;
    try toSolve.append(alloc, .{ 0, 0 });

    while (toSolve.popOrNull()) |item| {
        const text = inputText[item[0]..];
        const numbers = inputNumbers[item[1]..];
        if (numbers.len == 0) {
            if (std.mem.indexOf(u8, text, "#") == null) {
                solutions += 1;
            }
            continue;
        }
        if (text.len == 0) {
            continue;
        }

        const c = text[0];
        if (c != '#') {
            var j: u8 = 1;
            while (j < text.len and text[j] == '.') {
                j += 1;
            }
            toSolve.appendAssumeCapacity(.{ item[0] + j, item[1] });
            if (c == '.') continue;
        }
        var n = numbers[0];
        if (text.len >= n) {
            for (text[0..n]) |ch| {
                if (ch != '#' and ch != '?') {
                    break;
                }
            } else {
                if (text.len > n) {
                    if (text[n] == '#') {
                        continue;
                    }
                    n += 1;
                }
                try toSolve.append(alloc, .{ item[0] + n, item[1] + 1 });
            }
        }
    }
    return solutions;
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
}
