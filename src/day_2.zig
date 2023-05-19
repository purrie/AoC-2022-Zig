const std = @import("std");
const fs = std.fs;
const io = std.io;
const File = std.fs.File;

pub fn day_2(stdout: anytype) !void {
    const dir = std.fs.cwd();
    const file = try dir.openFile("./inputs/rock-paper-scisors.txt", File.OpenFlags{.mode = .read_only});
    defer file.close();
    var reader = file.reader();

    var buf = [_]u8{0} ** 4;
    var points : u32 = 0;
    var points2 : u32 = 0;

    var line = try reader.readUntilDelimiterOrEof(&buf, '\n');

    while (line != null) : (line = try reader.readUntilDelimiterOrEof(&buf, '\n')) {
        var hands  = get_hands(&buf);
        var hands2 = get_results(&buf);
        points  += get_points(hands);
        points2 += get_points(hands2);
    }
    try stdout.print("Day 2 answer:\n  Part 1: {}\n  Part 2: {}\n", .{points, points2});
}

const Hand = enum {
    Rock, Paper, Scisors,
};

const Result = enum {
    Loss, Draw, Win,
};

const Hands = struct {
    opponent: Hand,
    you: Hand,
};

fn get_hands(line: []u8) Hands {
    var ret : Hands = undefined;
    ret.opponent = switch (line[0]) {
        'A' => Hand.Rock,
        'B' => Hand.Paper,
        'C' => Hand.Scisors,
        else => unreachable,
    };
    ret.you = switch (line[2]) {
        'X' => Hand.Rock,
        'Y' => Hand.Paper,
        'Z' => Hand.Scisors,
        else => unreachable,
    };

    return ret;
}

fn get_results(line: []u8) Hands {
    var ret : Hands = undefined;
    ret.opponent = switch (line[0]) {
        'A' => Hand.Rock,
        'B' => Hand.Paper,
        'C' => Hand.Scisors,
        else => unreachable,
    };
    ret.you = switch (line[2]) {
        'X' => switch (ret.opponent) {
            Hand.Paper => Hand.Rock,
            Hand.Rock => Hand.Scisors,
            Hand.Scisors => Hand.Paper,
        },
        'Y' => ret.opponent,
        'Z' => switch (ret.opponent) {
            Hand.Paper => Hand.Scisors,
            Hand.Rock => Hand.Paper,
            Hand.Scisors => Hand.Rock,
        },
        else => unreachable,
    };
    return ret;
}

fn get_points(hands: Hands) u32 {
    var res : u32 = switch (get_result(hands)) {
        Result.Loss => 0,
        Result.Draw => 3,
        Result.Win  => 6,
    };
    res += switch (hands.you) {
        Hand.Rock    => 1,
        Hand.Paper   => 2,
        Hand.Scisors => 3,
    };

    return res;
}

fn get_result(hands: Hands) Result {
    if (hands.opponent == hands.you) {
        return Result.Draw;
    }
    return switch (hands.opponent) {
        Hand.Paper   => if (hands.you == Hand.Rock) Result.Loss else Result.Win,
        Hand.Rock    => if (hands.you == Hand.Scisors) Result.Loss else Result.Win,
        Hand.Scisors => if (hands.you == Hand.Paper) Result.Loss else Result.Win,
    };
}

test "Condition 1 from part 1" {
    var hand = [_]u8{'A', ' ', 'Y'};
    const hands = get_hands(&hand);
    const points = get_points(hands);
    try std.testing.expect(8 == points);
}
test "Condition 2 from part 1" {
    var hand = [_]u8{'B', ' ', 'X'};
    var hands = get_hands(&hand);
    var points = get_points(hands);
    try std.testing.expect(1 == points);
}
test "Condition 3 from part 1" {
    var hand = [_]u8{'C', ' ', 'Z'};
    var hands = get_hands(&hand);
    var points = get_points(hands);
    try std.testing.expect(6 == points);
}

test "Condition 1 from part 2" {
    var hand = [_]u8{'A', ' ', 'Y'};
    var hands = get_results(&hand);
    var points = get_points(hands);
    try std.testing.expect(4 == points);
}
test "Condition 2 from part 2" {
    var hand = [_]u8{'B', ' ', 'X'};
    var hands = get_results(&hand);
    var points = get_points(hands);
    try std.testing.expect(1 == points);
}
test "Condition 3 from part 2" {
    var hand = [_]u8{'C', ' ', 'Z'};
    var hands = get_results(&hand);
    var points = get_points(hands);
    try std.testing.expect(7 == points);
}
