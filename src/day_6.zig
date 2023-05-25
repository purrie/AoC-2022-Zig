const std = @import("std");
const File = std.fs.File;
const os = std.os;
const Breader = std.io.BufferedReader(4096, File.Reader);

pub fn run(stdout : anytype) !void {
    const cwd = std.fs.cwd();
    const file = try cwd.openFile("./inputs/signal-markers.txt", .{ .mode = .read_only });
    defer file.close();

    var breader = Breader{ .unbuffered_reader = file.reader() };
    var reader = breader.reader();
    var cap : Capture = .{};
    var amount : usize = 4;
    var length : usize= 4;
    var packet : usize = 0;
    var message : usize = 0;

    while (try read(&reader, &cap, amount, length)) |check| {
        if (findDuplicate(check)) |dup| {
            amount = dup;
        } else {
            if (packet > 0) {
                message = cap.len;
                break;
            } else {
                packet = cap.len;
                amount = 14 - amount;
                length = 14;
            }
        }
    }

    try stdout.print("Day 6 answer:\n  Part 1: {}\n  Part 2: {}\n", .{packet, message});
}

const Capture = struct {
    buf : [4096]u8 = undefined,
    len : usize = 0,
};

fn read(reader: anytype, cap : *Capture, amount : usize, expected : usize) !?[]u8 {
    const red = try reader.read(cap.buf[cap.len..cap.len + amount]);
    if (red != amount) {
        std.debug.print("Red incorrect amount of bytes. Expected {}, red {}\n", .{amount, red});
        return null;
    }
    cap.len += amount;
    if (cap.len >= expected) {
        return cap.buf[cap.len-expected..cap.len];
    }
    return error.StreamNotLongEnough;
}

fn findDuplicate(val : []u8) ?usize {
    var cur = val.len - 1;
    while (cur > 0) : (cur -= 1) {
        var p = cur;
        while (p > 0) : (p -= 1) {
            const a = val[cur];
            const b = val[p - 1];
            if (a == b) {
                return p;
            }
        }
    }
    return null;
}

test "Day 6 part 1" {
    const t1 = "mjqjpqmgbljsphdztnvjfqwrcgsmlb bvwbjplbgvbhsrlpgdmjqwftvncz nppdvjthqldpwncqszvftbrmjlhg nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw";
    const e1 = [_]usize{7, 5, 6, 10, 11};

    var splits = std.mem.split(u8, t1, " ");
    for (0..e1.len) |i| {
        const part = splits.next().?;
        var stream1 = std.io.fixedBufferStream(part);
        var read1 = stream1.reader();
        var cap : Capture = .{};
        var amount : usize = 4;
        const a1 : usize = while (try read(&read1, &cap, amount, 4)) |check| {
            if (findDuplicate(check)) |dup| {
                amount = dup;
            } else {
                break cap.len;
            }
        } else {
            unreachable;
        };
        const expected1 = e1[i];
        try std.testing.expectEqual(expected1, a1);
    }
}

test "Day 6 part 2" {
    const t1 = "mjqjpqmgbljsphdztnvjfqwrcgsmlb bvwbjplbgvbhsrlpgdmjqwftvncz nppdvjthqldpwncqszvftbrmjlhg nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw";
    const e1 = [_]usize{19, 23, 23, 29, 26};

    var splits = std.mem.split(u8, t1, " ");
    for (0..e1.len) |i| {
        const part = splits.next().?;
        var stream1 = std.io.fixedBufferStream(part);
        var read1 = stream1.reader();
        var cap : Capture = .{};
        var amount : usize = 14;
        const a1 : usize = while (try read(&read1, &cap, amount, 14)) |check| {
            if (findDuplicate(check)) |dup| {
                amount = dup;
            } else {
                break cap.len;
            }
        } else {
            unreachable;
        };
        const expected1 = e1[i];
        try std.testing.expectEqual(expected1, a1);
    }
}
