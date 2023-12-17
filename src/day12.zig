const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("12", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    var solutions: usize = 0;

    var toSolve = std.ArrayListUnmanaged(struct { []const u8, std.ArrayListUnmanaged(u8) }){};
    defer {
        var j: usize = 0;
        while (j < toSolve.items.len) : (j += 1) {
            toSolve.items[j].@"1".deinit(alloc);
        }
        toSolve.deinit(alloc);
    }

    var i: usize = 0;
    while (i < input.len) {
        var numbers = std.ArrayListUnmanaged(u8){};

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

        std.mem.reverse(u8, numbers.items);

        try toSolve.append(alloc, .{ left, numbers });
    }

    while (toSolve.popOrNull()) |item| {
        const text = item.@"0";
        var numbers = item.@"1";
        if (numbers.items.len == 0) {
            if (std.mem.indexOf(u8, text, "#") == null) {
                solutions += 1;
            }
            numbers.deinit(alloc);
            continue;
        }
        if (text.len < 1) {
            numbers.deinit(alloc);
            continue;
        }

        var appended = false;
        const c = text[0];
        if (c != '#') {
            var j: usize = 1;
            while (j < text.len and text[j] == '.') {
                j += 1;
            }
            toSolve.appendAssumeCapacity(.{ text[j..], numbers });
            if (c == '.') continue;
            appended = true;
        }

        if (numbers.popOrNull()) |number| {
            if (text.len >= number) {
                for (text[0..number]) |ch| {
                    if (ch != '#' and ch != '?') {
                        break;
                    }
                } else {
                    if (text.len > number) {
                        if (text[number] == '#') {
                            if (!appended) numbers.deinit(alloc);
                            continue;
                        }
                        if (appended) {
                            numbers = try numbers.clone(alloc);
                            try toSolve.append(alloc, .{ text[(number + 1)..], numbers });
                        } else {
                            toSolve.appendAssumeCapacity(.{ text[(number + 1)..], numbers });
                        }
                    } else {
                        if (appended) {
                            numbers = try numbers.clone(alloc);
                            try toSolve.append(alloc, .{ text[number..], numbers });
                        } else {
                            toSolve.appendAssumeCapacity(.{ text[number..], numbers });
                        }
                    }
                    appended = true;
                }
            }
        }

        if (!appended)
            numbers.deinit(alloc);
    }

    return .{ solutions, 0 };
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
