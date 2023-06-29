const std = @import("std");
const Allocator = std.mem.Allocator;

const Breader = std.io.BufferedReader(4096, std.fs.File.Reader);

pub fn run (stdout : anytype) !void {
    var cwd = std.fs.cwd();
    var file = try cwd.openFile("./inputs/tree-house-forest.txt", .{ .mode = .read_only });
    defer file.close();


    var memory = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer memory.deinit();
    const alloc = memory.allocator();


    var forest = Forest.init(alloc);
    defer forest.deinit();

    var breader = Breader{ .unbuffered_reader = file.reader() };
    var reader = breader.reader();
    var raw_buff : [512]u8 = undefined;
    var buff = std.io.fixedBufferStream(&raw_buff);

    while (true) {
        reader.streamUntilDelimiter(buff.writer(), '\n', raw_buff.len) catch |err| {
            switch (err) {
                error.EndOfStream => break,
                else => return err,
            }
        };
        defer buff.reset();

        const size = buff.getWritten();
        try forest.appendRow(size);
    }

    try forest.updateLimits();
    const count = forest.countVisible();
    const scenic = forest.getScenicScore();

    try stdout.print("Day 8 answer: \n  Part 1: {}\n  Part 2: {}\n", .{count, scenic});
}

const Direction = enum {
    top, bottom, left, right,
};

const Trees  = std.ArrayList(u8);
const Visited = std.ArrayList(bool);
const Limits = std.ArrayList([4]u8);

const Forest = struct {
    width   : usize,
    height  : usize,
    trees   : Trees,
    limits  : Limits,
    visible : Visited,

    fn init (allocator : Allocator) @This() {
        return .{
            .width = 0,
            .height = 0,
            .trees = Trees.init(allocator),
            .limits = Limits.init(allocator),
            .visible = Visited.init(allocator),
        };
    }

    fn deinit (self : *@This()) void {
        self.trees.deinit();
        self.limits.deinit();
        self.visible.deinit();
    }

    fn print_trees (self : *@This()) void {
        const print = std.debug.print;
        var point : usize = 0;
        print("Items:\n", .{});
        while (point < self.trees.items.len) {
            print("{s}\n", .{self.trees.items[point..point + self.width]});
            point += self.width;
        }
    }

    fn getTallest (self : *const @This(), direction : Direction, index : usize) u8 {
        return self.limits.items[index][@intFromEnum(direction)];
    }
    fn setTallest (self : *@This(), direction : Direction, index : usize, value : u8) void {
        self.limits.items[index][@intFromEnum(direction)] = value;
    }

    fn appendRow (self : *@This(), data : []const u8) !void {
        if (self.width == 0) {
            self.width = data.len;
        }
        else if (self.width != data.len) {
            return error.MismatchedDataLength;
        }

        try self.trees.appendSlice(data);
        try self.visible.appendNTimes(false, data.len);

        self.height += 1;
    }

    fn updateLimits (self : *@This()) !void {
        var larger : usize = undefined;
        if (self.width > self.height) {
            larger = self.width;
        }
        else {
            larger = self.height;
        }

        try self.limits.appendNTimes(.{0,0,0,0}, larger);
    }

    fn countVisible (self : *@This()) usize {
        var count : usize = 0;

        for (0..self.height) |row| {
            const start = row * self.width;
            const end = start + self.width;
            var data = self.trees.items[start..end];
            var visi = self.visible.items[start..end];

            for (0..data.len) |col| {
                const tree_height = data[col];

                if (row == 0) {
                    count += 1;
                    self.setTallest(.top, col, tree_height);
                    visi[col] = true;
                }
                else if (col == 0) {
                    count += 1;
                    self.setTallest(.left, row, tree_height);
                    visi[0] = true;
                }
                else {
                    const left = self.getTallest(.left, row);
                    const visible = left < tree_height;
                    if (visible) {
                        self.setTallest(.left, row, tree_height);
                        count += 1;
                        visi[col] = true;
                    }

                    const top = self.getTallest(.top, col);
                    if (top < tree_height) {
                        self.setTallest(.top, col, tree_height);
                        if (!visible) {
                            count += 1;
                            visi[col] = true;
                        }
                    }
                }
            }
        }

        const last_row = self.height - 1;
        const last_col = self.width - 1;

        for (0..self.height) |row| {
            const r_row = self.height - row - 1;

            const start = r_row * self.width;
            const end = start + self.width;
            var data = self.trees.items[start..end];
            var visi = self.visible.items[start..end];

            for (0..data.len) |col| {
                const c_col = data.len - col - 1;
                const tree_height = data[c_col];
                var visible = visi[c_col];

                if (r_row == last_row) {
                    self.setTallest(.bottom, c_col, tree_height);
                    if (!visible)
                        count += 1;
                }
                else if (c_col == last_col) {
                    self.setTallest(.right, r_row, tree_height);
                    if (!visible)
                        count += 1;
                }
                else {
                    const right = self.getTallest(.right, r_row);
                    if (right < tree_height) {
                        self.setTallest(.right, r_row, tree_height);
                        if (!visible) {
                            count += 1;
                            visible = true;
                        }
                    }

                    const bottom = self.getTallest(.bottom, c_col);
                    if (bottom < tree_height) {
                        self.setTallest(.bottom, c_col, tree_height);
                        if (!visible) {
                            count += 1;
                        }
                    }
                }
            }
        }

        return count;
    }

    fn getScenicScore (self : *@This()) usize {
        var highest_score : usize = 0;

        var x = self.width / 2;
        var y = self.height / 2;
        var direction : Direction = .top;
        var distance_total : usize = 1;
        var distance_left : usize = 1;

        while (x > 0 and x < self.width - 1 and y > 0 and y < self.height - 1) {
            var dist_top = y;
            var dist_bot = self.height - y - 1;
            var dist_left = x;
            var dist_right = self.width - x - 1;

            const potential_score = dist_top * dist_bot * dist_left * dist_right;

            if (highest_score <= potential_score) {
                const height = self.trees.items[y * self.width + x];
                var distances = [1]usize{1} ** 4;

                top: for (1..dist_top) |top| {
                    const yp = y - top;
                    const tree = self.trees.items[yp * self.width + x];
                    if (tree < height) {
                        distances[0] += 1;
                    } else {
                        break :top;
                    }
                }

                bot: for (1..dist_bot) |bot| {
                    const yb = y + bot;
                    const tree = self.trees.items[yb * self.width + x];
                    if (tree < height) {
                        distances[1] += 1;
                    } else {
                        break :bot;
                    }
                }

                left: for (1..dist_left) |left| {
                    const xl = x - left;
                    const tree = self.trees.items[xl + y * self.width];
                    if (tree < height) {
                        distances[2] += 1;
                    } else {
                        break :left;
                    }
                }

                right: for (1..dist_right) |right| {
                    const xr = x + right;
                    const tree = self.trees.items[xr + y * self.width];
                    if (tree < height) {
                        distances[3] += 1;
                    } else {
                        break :right;
                    }
                }

                const score = distances[0] * distances[1] * distances[2] * distances[3];
                if (score > highest_score) {
                    highest_score = score;
                }
            }

            if (distance_left == 0) {
                switch (direction) {
                    .top => direction = .right,
                    .right => {
                        direction = .bottom;
                        distance_total += 1;
                    },
                    .bottom => direction = .left,
                    .left => {
                        direction = .top;
                        distance_total += 1;
                    }
                }
                distance_left = distance_total;
            }

            switch (direction) {
                .top    => y -= 1,
                .right  => x += 1,
                .bottom => y += 1,
                .left   => x -= 1,
            }
            distance_left -= 1;
        }

        return highest_score;
    }
};

test "Day 8 part 1" {
    var data =
        \\30373
        \\25512
        \\65332
        \\33549
        \\35390
    ;
    var memory = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer memory.deinit();
    const alloc = memory.allocator();

    var lines = std.mem.splitScalar(u8, data, '\n');
    var forest = Forest.init(alloc);
    defer forest.deinit();

    while (lines.next()) |line| {
        try forest.appendRow(line);
    }

    try forest.updateLimits();
    const count = forest.countVisible();
    const expected : usize = 21;

    try std.testing.expectEqual(expected, count);
}

test "Day 8 part 2" {
    var data =
        \\30373
        \\25512
        \\65332
        \\33549
        \\35390
    ;
    var memory = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer memory.deinit();
    const alloc = memory.allocator();

    var lines = std.mem.splitScalar(u8, data, '\n');
    var forest = Forest.init(alloc);
    defer forest.deinit();

    while (lines.next()) |line| {
        try forest.appendRow(line);
    }

    try forest.updateLimits();
    const count = forest.getScenicScore();
    const expected : usize = 8;

    try std.testing.expectEqual(expected, count);
}
