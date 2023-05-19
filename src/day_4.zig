const std = @import("std");
const File = std.fs.File;

pub fn run(stdout: anytype) !void {
    const dir = std.fs.cwd();
    const file = try dir.openFile("./inputs/camp-cleanup.txt", File.OpenFlags{.mode = .read_only});
    defer file.close();
    var reader = file.reader();

    var buf : [256]u8 = undefined;
    var full_overlaps : u32 = 0;
    var part_overlaps : u32 = 0;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var pair = try processLine(line);
        if (isFullOverlap(pair)) {
            full_overlaps += 1;
        }
        if (isPartialOverlap(pair)) {
            part_overlaps += 1;
        }
    }

    try stdout.print("Day 4 answer:\n  Part 1: {d}\n  Part 2: {d}\n", .{full_overlaps, part_overlaps});
}

const Range = struct {
    min: u32,
    max: u32,
};

const Pair = struct {
    first: Range,
    second: Range,
};

fn find(in: []const u8, byte: u8, startfrom: usize) usize {
    for (startfrom..in.len) |i| {
        if (in[i] == byte) {
            return i;
        }
    }
    return in.len;
}

fn processLine(line : []const u8) !Pair {
    var pair : Pair = undefined;
    var start : usize = 0;
    var end   : usize = 0;
    end = find(line, '-', start);
    pair.first.min = try std.fmt.parseInt(u32, line[start..end], 10);
    start = end+1;
    end = find(line, ',', start);
    pair.first.max = try std.fmt.parseInt(u32, line[start..end], 10);
    start = end+1;
    end = find(line, '-', start);
    pair.second.min = try std.fmt.parseInt(u32, line[start..end], 10);
    pair.second.max = try std.fmt.parseInt(u32, line[end+1..], 10);
    return pair;
}

fn isFullOverlap(pair: Pair) bool {
    if (pair.first.min >= pair.second.min and pair.first.max <= pair.second.max) {
        return true;
    }
    if (pair.second.min >= pair.first.min and pair.second.max <= pair.first.max) {
        return true;
    }
    return false;
}

fn isPartialOverlap(pair: Pair) bool {
    if (pair.first.min <= pair.second.max and pair.first.max >= pair.second.min) {
        return true;
    }
    if (pair.second.min <= pair.first.max and pair.second.max >= pair.first.min) {
        return true;
    }
    return false;
}

test "Day 4 part 1" {
    const input = [6][]const u8{
        "2-4,6-8",
        "2-3,4-5",
        "5-7,7-9",
        "2-8,3-7",
        "6-6,4-6",
        "2-6,4-8",
    };
    var count : u32 = 0;
    for (input) |line| {
        const pair = try processLine(line);
        if (isFullOverlap(pair)) {
            count += 1;
        }
    }
    try std.testing.expectEqual(count, 2);
}

test "Day 4 part 2" {
    const input = [6][]const u8{
        "2-4,6-8",
        "2-3,4-5",
        "5-7,7-9",
        "2-8,3-7",
        "6-6,4-6",
        "2-6,4-8",
    };
    var count : u32 = 0;
    for (input) |line| {
        const pair = try processLine(line);
        if (isPartialOverlap(pair)) {
            count += 1;
        }
    }
    try std.testing.expectEqual(count, 4);
}
