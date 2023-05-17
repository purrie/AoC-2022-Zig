const std = @import("std");
const fs = std.fs;
const io = std.io;
const File = std.fs.File;

pub fn day_1(stdout: anytype) !void {
    const dir = std.fs.cwd();
    const file = try dir.openFile("./src/calories.txt", File.OpenFlags{.mode = .read_only});
    defer file.close();
    var reader = file.reader();

    var buf = [_]u8{0} ** 64;
    var line = try reader.readUntilDelimiterOrEof(&buf, '\n');
    var top = [_]u32{0} ** 3;
    var candidate: u32 = 0;

    while (line != null) : (line = try reader.readUntilDelimiterOrEof(&buf, '\n')) {
        var nr = parse_string(line.?);
        if (nr) |n| {
            candidate += n;
        } else |er| {
            switch (er) {
                ParseStringError.EmptyString => {
                    const last = top.len - 1;
                    if (top[last] < candidate) {
                        top[last] = candidate;
                        var i: u32 = 1;
                        while (i < top.len) : (i += 1) {
                            const back = top.len - i;
                            if (top[back] > top[back - 1]) {
                                candidate = top[back];
                                top[back] = top[back - 1];
                                top[back - 1] = candidate;
                            } else { break; }
                        }
                    }
                    candidate = 0;
                    continue;
                },
                else => {
                    std.debug.print("Error: {}", .{er});
                }
            }
        }
    }

    var sum: u32 = 0;
    for (top) |t| {
        sum += t;
    }

    try stdout.print("Day 1 answer:\n  Top: {}\n  Top 3: {}\n", .{top[0], sum});
}

const ParseStringError = error {
    EmptyString,
    Overflow,
    NotANumber,
};

fn parse_string(str: []u8) ParseStringError!u32 {
    if (str.len == 0) {
        return ParseStringError.EmptyString;
    }
    var r : u32 = 0;
    for (str) |c| {
        switch (c) {
            '0'...'9' => {
                var cast: u32 = undefined;
                if (@mulWithOverflow(u32, r, 10, &cast)) { return ParseStringError.Overflow; }
                r = cast + (c - '0');
            },
            else => return ParseStringError.NotANumber,
        }
    }
    return r;
}
