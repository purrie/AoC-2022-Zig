const std = @import("std");
const day_1 = @import("day_1.zig");
const day_2 = @import("day_2.zig");
const day_3 = @import("day_3.zig");
const day_4 = @import("day_4.zig");
const day_5 = @import("day_5.zig");

pub fn main() !void {
    std.debug.print("Advent of code 2022!\n\n", .{});

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try day_1.day_1(&stdout);
    try day_2.day_2(&stdout);
    try day_3.day_3(&stdout);
    try day_4.run(&stdout);
    try day_5.run(&stdout);

    try bw.flush(); // don't forget to flush!
}

test {
    std.testing.refAllDecls(@This());
}
