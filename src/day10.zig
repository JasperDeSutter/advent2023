const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("10", solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    var lineLength: usize = 0;
    while (input[lineLength] != '\n') : (lineLength += 1) {}
    lineLength += 1;

    var start: usize = 0;
    while (input[start] != 'S') : (start += 1) {}

    var toCheck = std.ArrayList([2]usize).init(alloc);
    defer toCheck.deinit();

    if (start > 0) try toCheck.append(.{ start, start - 1 });
    if (start < input.len) try toCheck.append(.{ start, start + 1 });
    if (start > lineLength) try toCheck.append(.{ start, start - lineLength });
    if (start < input.len - lineLength) try toCheck.append(.{ start, start + lineLength });

    var visited = try std.ArrayList(bool).initCapacity(alloc, input.len);
    defer visited.deinit();
    visited.expandToCapacity();

    visited.items[start] = true;

    var iterations: usize = 0;
    while (toCheck.items.len > 0) : (iterations += 1) {
        var j: usize = 0;
        while (j < toCheck.items.len) : (j += 1) {
            const i = &toCheck.items[j];
            const c = input[i[1]];
            var match = false;
            const prev = i[0];
            i[0] = i[1];
            switch (c) {
                '-' => {
                    if (i[1] == prev + 1 and i[1] < input.len) {
                        match = true;
                        i[1] += 1;
                    } else if (i[1] + 1 == prev and i[1] > 0) {
                        match = true;
                        i[1] -= 1;
                    }
                },
                '|' => {
                    if (i[1] == prev + lineLength and i[1] + lineLength < input.len) {
                        match = true;
                        i[1] += lineLength;
                    } else if (i[1] + lineLength == prev and i[1] > lineLength) {
                        match = true;
                        i[1] -= lineLength;
                    }
                },
                '7' => {
                    if (i[1] == prev + 1 and i[1] + lineLength < input.len) {
                        match = true;
                        i[1] += lineLength;
                    } else if (i[1] + lineLength == prev and i[1] > 0) {
                        match = true;
                        i[1] -= 1;
                    }
                },
                'L' => {
                    if (i[1] == prev + lineLength and i[1] < input.len) {
                        match = true;
                        i[1] += 1;
                    } else if (i[1] + 1 == prev and i[1] > lineLength) {
                        match = true;
                        i[1] -= lineLength;
                    }
                },
                'J' => {
                    if (i[1] == prev + lineLength) {
                        match = true;
                        i[1] -= 1;
                    } else if (i[1] == prev + 1) {
                        match = true;
                        i[1] -= lineLength;
                    }
                },
                'F' => {
                    if (i[1] + 1 == prev) {
                        match = true;
                        i[1] += lineLength;
                    } else if (i[1] + lineLength == prev) {
                        match = true;
                        i[1] += 1;
                    }
                },
                else => {},
            }
            if (!match or visited.items[i[0]]) {
                _ = toCheck.swapRemove(j);
            } else {
                visited.items[i[0]] = true;
            }
        }
    }

    return .{ iterations - 2, 0 };
}

test {
    const input =
        \\.....
        \\.S-7.
        \\.|.|.
        \\.L-J.
        \\.....
    ;

    const result = try solve(std.testing.allocator, input);
    const example_result: usize = 4;
    try std.testing.expectEqual(example_result, result[0]);
}

test {
    const input =
        \\..F7.
        \\.FJ|.
        \\SJ.L7
        \\|F--J
        \\LJ...
    ;
    const result = try solve(std.testing.allocator, input);
    const example_result2: usize = 8;
    try std.testing.expectEqual(example_result2, result[0]);
}
