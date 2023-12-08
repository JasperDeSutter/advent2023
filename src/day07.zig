const std = @import("std");
const runner = @import("runner.zig");

pub const main = runner.run("07", solve);

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
    kind2: Kind,
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

fn card_value2(card: u8) u8 {
    switch (card) {
        'T' => return 10,
        'Q' => return 12,
        'K' => return 13,
        'A' => return 14,
        'J' => return 1,
        else => return card - '0',
    }
}

fn order_hand2(_: void, lhs: Hand, rhs: Hand) bool {
    if (lhs.kind2 != rhs.kind2) {
        return @intFromEnum(lhs.kind2) < @intFromEnum(rhs.kind2);
    }
    for (&lhs.cards, &rhs.cards) |l, r| {
        if (l != r) {
            return card_value2(l) < card_value2(r);
        }
    }
    return false;
}

fn get_kind(highest: u8, pairs: u8) Kind {
    switch (highest) {
        4, 5 => return Kind.FiveOfAKind,
        3 => return Kind.FourOfAKind,
        2 => {
            if (pairs >= 1) {
                return Kind.FullHouse;
            } else {
                return Kind.ThreeOfAKind;
            }
        },
        1 => {
            if (pairs >= 2) {
                return Kind.TwoPair;
            } else {
                return Kind.OnePair;
            }
        },
        else => return Kind.HighCard,
    }
}

fn solve(alloc: std.mem.Allocator, input: []const u8) anyerror![2]usize {
    var result: [2]usize = .{ 0, 0 };

    var hands = std.ArrayList(Hand).init(alloc);
    defer hands.deinit();

    var i: usize = 0;
    while (i < input.len) : (i += 1) {
        var hand = try hands.addOne();
        for (0..5) |j| {
            hand.cards[j] = input[i + j];
        }

        var dupes = [1]u8{0} ** 5; // fifth is jokers
        for (0..5) |j| {
            if (hand.cards[j] == 'J') {
                dupes[4] += 1;
                continue;
            }
            for (0..j) |k| {
                if (hand.cards[j] == hand.cards[k]) {
                    dupes[k] += 1;
                    break;
                }
            }
        }
        var highest: u8 = 0;
        var pairs: u8 = 0;
        for (dupes[0..4]) |dupe| {
            if (dupe > highest) {
                highest = dupe;
            }
            if (dupe == 1) {
                pairs += 1;
            }
        }
        const pairs2 = if (highest == 1 and dupes[4] != 0) pairs - 1 else pairs;
        hand.kind2 = get_kind(highest + dupes[4], pairs2);
        if (dupes[4] == 2) {
            pairs += 1;
        }
        if (dupes[4] > highest) {
            highest = dupes[4] - 1;
        }
        hand.kind = get_kind(highest, pairs);

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

    std.mem.sortUnstable(Hand, hands.items, {}, order_hand2);

    for (hands.items, 1..) |hand, j| {
        result[1] += hand.bid * j;
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
    const result = try solve(std.testing.allocator, input);
    try std.testing.expectEqual(example_result, result[0]);
    const example_result_range: usize = 5905;
    try std.testing.expectEqual(example_result_range, result[1]);
}

test {
    const input =
        \\2345A 1
        \\Q2KJJ 13
        \\Q2Q2Q 19
        \\T3T3J 17
        \\T3Q33 11
        \\2345J 3
        \\J345A 2
        \\32T3K 5
        \\T55J5 29
        \\KK677 7
        \\KTJJT 34
        \\QQQJA 31
        \\JJJJJ 37
        \\JAAAA 43
        \\AAAAJ 59
        \\AAAAA 61
        \\2AAAA 23
        \\2JJJJ 53
        \\JJJJ2 41
    ;

    const example_result: usize = 6592;
    const result = try solve(std.testing.allocator, input);
    try std.testing.expectEqual(example_result, result[0]);
    const example_result_range: usize = 6839;
    try std.testing.expectEqual(example_result_range, result[1]);
}
