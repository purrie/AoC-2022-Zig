const std = @import("std");
const io = std.io;
const fs = std.fs;
const File = fs.File;

const transformer = generate_map();
const transformer_back = generate_back_map();

pub fn day_3(stdout: anytype) !void {
    const dir = std.fs.cwd();
    const file = try dir.openFile("./src/rugsacks.txt", File.OpenFlags{.mode = .read_only});
    defer file.close();
    var reader = file.reader();

    var buf = [_]u8{0} ** 256;
    var points : u32 = 0;
    var points2 : u32 = 0;
    var set : u64 = 0;
    var count : u32 = 0;

    var line = try reader.readUntilDelimiterOrEof(&buf, '\n');

    while (line != null) : (line = try reader.readUntilDelimiterOrEof(&buf, '\n')) {
        points += process_line(line.?);

        count = (count + 1) % 3;
        switch (count) {
            1 => {
                set = get_set(line.?);
            },
            2 => {
                var s = get_set(line.?);
                set = set & s;
            },
            0 => {
                var s = get_set(line.?);
                set = set & s;
                points2 += extract_item_priority(set);
            },
            else => unreachable,
        }
    }
    try stdout.print("Day 3 answer:\n  Part 1: {}\n  Part 2: {}\n", .{points, points2});
}

fn generate_map() [256]u32 {
    var map = [1]u32{0} ** 256;
    var start : u8 = 'a';
    while (start <= 'z') : (start += 1){
        map[start] = start - 'a' + 1;
    }
    start = 'A';
    while (start <= 'Z') : (start += 1) {
        map[start] = start - 'A' + 27;
    }
    return map;
}

fn generate_back_map() [52]u8 {
    var map = [1]u8{0} ** 52;
    var start : u8 = 'a';
    var index : usize = 0;
    while (start <= 'z') : (start += 1) {
        map[index] = start;
        index += 1;
    }
    start = 'A';
    while (start <= 'Z') : (start += 1) {
        map[index] = start;
        index += 1;
    }
    return map;
}

fn shift (num : u64, amount : u32) u64 {
    if (amount == 0){
        return num;
    } else {
        return shift(num << 1, amount - 1);
    }
}

fn shift_back (num : u64, amount : u32) u64 {
    if (amount == 0){
        return num;
    } else {
        return shift_back(num >> 1, amount - 1);
    }
}

fn process_line(line : []const u8) u32 {
    var result : u32   = 0;
    var mask   : u64   = 0;
    var i      : usize = 0;
    const halfpoint    = line.len / 2;

    while (i < halfpoint) : (i += 1) {
        const item : u64 = shift(1, transformer[line[i]]);
        mask = mask | item;
    }
    while (i < line.len) : (i += 1) {
        const item : u64 = shift(1, transformer[line[i]]);
        if (mask & item > 0) {
            mask = mask & ~item;
            result += transformer[line[i]];
        }
    }
    return result;
}

fn get_set(line : []const u8) u64 {
    var result : u64 = 0;
    var i : usize = 0;
    var one : u64 = 1;
    while (i < line.len) : (i += 1) {
        result = result | shift(one, transformer[line[i]]);
    }
    return result;
}

fn extract_item_priority(set : u64) u32 {
    var i : u32 = 0;
    const mask : u64 = 1;
    while (i < transformer_back.len) : (i += 1) {
        var t = shift_back(set, i + 1);
        t = t & mask;
        if (t == mask) {
            return transformer[transformer_back[i]];
        }
    }
    unreachable;
}

test "Day 3 transformer" {
    var i : u32 = 0;
    while (i < transformer.len) : (i += 1) {
        if (i >= 'a' and i <= 'z') {
            try std.testing.expectEqual(transformer[i], i - 'a' + 1);
        }
        else if (i >= 'A' and i <= 'Z') {
            try std.testing.expectEqual(transformer[i], i - 'A' + 27);
        } else {
            try std.testing.expectEqual(transformer[i], 0);
        }
    }
}

test "Day 3 shifting" {
    var p : u64 = shift(0b1, 2);
    var exp : u64 = 0b100;
    try std.testing.expectEqual(exp, p);
}
test "Day 3 shifting back" {
    var p : u64 = shift_back(0b10000, 2);
    var exp : u64 = 0b100;
    try std.testing.expectEqual(exp, p);
}

test "Day 3 part 1 line 1" {
    var line1 = "vJrwpWtwJgWrhcsFMMfFFhFp";
    var p = process_line(line1[0..]);
    var exp : u32 = 16;
    try std.testing.expectEqual(exp, p);
}
test "Day 3 part 1 line 2" {
    var line2 = "jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL";
	var p = process_line(line2[0..]);
    var exp : u32 = 38;
    try std.testing.expectEqual(exp, p);
}
test "Day 3 part 1 line 3" {
    var line3 = "PmmdzqPrVvPwwTWBwg";
	var p = process_line(line3[0..]);
    var exp : u32 = 42;
    try std.testing.expectEqual(exp, p);
}
test "Day 3 part 1 line 4" {
    var line4 = "wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn";
	var p = process_line(line4[0..]);
    var exp : u32 = 22;
    try std.testing.expectEqual(exp, p);
}
test "Day 3 part 1 line 5" {
    var line5 = "ttgJtRGJQctTZtZT";
	var p = process_line(line5[0..]);
    var exp : u32 = 20;
    try std.testing.expectEqual(exp, p);
}
test "Day 3 part 1 line 6" {
    var line6 = "CrZsJsPPZsGzwwsLwLmpwMDw";
	var p = process_line(line6[0..]);
    var exp : u32 = 19;
    try std.testing.expectEqual(exp, p);
}

test "Day 3 part 2 set 1" {
    var line1 = "vJrwpWtwJgWrhcsFMMfFFhFp";
    var line2 = "jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL";
    var line3 = "PmmdzqPrVvPwwTWBwg";

    var first = get_set(line1[0..line1.len]);
    var secon = get_set(line2[0..line2.len]);
    var third = get_set(line3[0..line3.len]);


    var mask = first & secon & third;
    try std.testing.expect(mask != 0);

    var p = extract_item_priority(mask);
    var exp : u32 = 18;
    try std.testing.expectEqual(exp, p);
}
test "Day 3 part 2 set 2" {
    var line4 = "wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn";
    var line5 = "ttgJtRGJQctTZtZT";
    var line6 = "CrZsJsPPZsGzwwsLwLmpwMDw";

    var mask = get_set(line4[0..]);
    mask &= get_set(line5[0..]);
    mask &= get_set(line6[0..]);
    try std.testing.expect(mask != 0);
    var p = extract_item_priority(mask);
    var exp : u32 = 52;
    try std.testing.expectEqual(exp, p);
}
