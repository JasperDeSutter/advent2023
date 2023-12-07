const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run(solve);

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror!void {
    const result = try impl(alloc, input);
    std.debug.print("07 part 1: {}\n", .{result[0]});
    std.debug.print("07 part 2: {}\n", .{result[1]});
}

const Kind = enum(u8) {
    HighCard,
    OnePair,
    TwoPair,
    ThreeOfAKind,
    FullHouse,
    FourOfAKind,
    FiveOfAKind,
};

const Hand = struct {
    cards: [5]u8,
    kind: Kind,
    bid: u16,
};

fn card_value(card: u8) u8 {
    switch (card) {
        'T' => return 10,
        'J' => return 11,
        'Q' => return 12,
        'K' => return 13,
        'A' => return 14,
        else => return card - '0',
    }
}

fn order_hand(_: void, lhs: Hand, rhs: Hand) bool {
    if (lhs.kind != rhs.kind) {
        return @intFromEnum(lhs.kind) < @intFromEnum(rhs.kind);
    }
    for (&lhs.cards, &rhs.cards) |l, r| {
        if (l != r) {
            return card_value(l) < card_value(r);
        }
    }
    return false;
}

fn impl(alloc: std.mem.Allocator, input: []const u8) ![2]usize {
    var result: [2]usize = .{ 0, 0 };

    var hands = std.ArrayList(Hand).init(alloc);
    defer hands.deinit();

    var i: usize = 0;
    while (i < input.len) : (i += 1) {
        var hand = try hands.addOne();
        for (0..5) |j| {
            hand.cards[j] = input[i + j];
        }

        var dupes = [1]u8{0} ** 4;
        for (1..5) |j| {
            for (0..j) |k| {
                if (hand.cards[j] == hand.cards[k]) {
                    dupes[k] += 1;
                    break;
                }
            }
        }

        var kind = Kind.HighCard;
        for (dupes) |dupe| {
            switch (dupe) {
                4 => kind = Kind.FiveOfAKind,
                3 => kind = Kind.FourOfAKind,
                2 => {
                    if (kind == Kind.OnePair) {
                        kind = Kind.FullHouse;
                    } else {
                        kind = Kind.ThreeOfAKind;
                    }
                },
                1 => {
                    if (kind == Kind.ThreeOfAKind) {
                        kind = Kind.FullHouse;
                    } else if (kind == Kind.OnePair) {
                        kind = Kind.TwoPair;
                    } else {
                        kind = Kind.OnePair;
                    }
                },
                else => {},
            }
        }
        hand.kind = kind;

        i += 7;
        hand.bid = input[i - 1] - '0';
        while (i < input.len and input[i] != '\n') : (i += 1) {
            hand.bid = hand.bid * 10 + (input[i] - '0');
        }
    }

    std.mem.sortUnstable(Hand, hands.items, {}, order_hand);

    for (hands.items, 1..) |hand, j| {
        result[0] += hand.bid * j;
    }

    return result;
}

test {
    const input =
        \\32T3K 765
        \\T55J5 684
        \\KK677 28
        \\KTJJT 220
        \\QQQJA 483
    ;

    const example_result: usize = 6440;
    const result = try impl(std.testing.allocator, input);
    try std.testing.expectEqual(example_result, result[0]);
    // const example_result_range: usize = 71503;
    // try std.testing.expectEqual(example_result_range, result[1]);
}
