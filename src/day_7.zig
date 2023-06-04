const std = @import("std");
const Allocator = std.mem.Allocator;
const Breader = std.io.BufferedReader(4096, std.fs.File.Reader);

pub fn run(stdout : anytype) !void {
    var cwd = std.fs.cwd();
    var file = try cwd.openFile("./inputs/space-on-device.txt", std.fs.File.OpenFlags{ .mode = .read_only });
    defer file.close();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var tree = try Tree.create(arena.allocator());

    var breader = Breader{ .unbuffered_reader = file.reader() };
    var reader = breader.reader();

    var buf : [128]u8 = undefined;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |cmd| {
        const inp = interpretCmd(cmd);
        try buildFileTree(&tree, inp);
    }

    var sum : u64 = 0;
    calculateSize(try tree.getRoot(), &sum, 100000);

    const total_size : u64 = 70_000_000;
    const update_size : u64 = 30_000_000;

    const root_size = tree.root.?.totalSize();
    const unused_space = total_size - root_size;
    const needed_space = update_size - unused_space;

    const result : u64 = calculateSmallest(&tree.root.?, needed_space);

    try stdout.print("Day 7 answer:\n Part 1: {d}\n Part 2: {d}\n", .{sum, result});
}

const Tree = struct {
    const FileSize  = u64;
    const DirArray  = std.ArrayList(Dir);
    const FileArray = std.ArrayList(File);

    const File = struct {
        allocator : Allocator,
        name : []u8,
        size : FileSize,

        pub fn create(name : []const u8, size : FileSize, allocator : Allocator) !File {
            var file = .{
                .name = try allocator.alloc(u8, name.len),
                .size = size,
                .allocator = allocator,
            };
            std.mem.copyForwards(u8, file.name, name);
            return file;
        }
        pub fn deinit(self : *File) void {
            self.allocator.free(self.name);
        }
    };

    const Dir = struct {
        const Self = @This();

        parent    : ?*Self = null,
        allocator : Allocator,
        name      : []u8,
        subdir    : DirArray,
        files     : FileArray,

        size : ?FileSize = null,

        pub fn totalSize(self : *Self) FileSize {
            if (self.size) |s| {
                return s;
            }
            self.size = 0;
            for (0..self.files.items.len) |i| {
                self.size.? += self.files.items[i].size;
            }
            for (0..self.subdir.items.len) |i| {
                self.size.? += self.subdir.items[i].totalSize();
            }
            return self.size.?;
        }

        pub fn isRoot(self : *Self) bool {
            return self.parent == null;
        }

        pub fn addFile(self : *Self, name: []const u8, size : []const u8) !void {
            var s = try std.fmt.parseUnsigned(FileSize, size, 10);
            var file = try File.create(name, s, self.allocator);
            try self.files.append(file);
            self.invalidateSize();
        }

        fn invalidateSize(self : *Self) void {
            self.size = null;
            if (self.parent) |p| {
                p.invalidateSize();
            }
        }

        pub fn getParent(self : *Self) ?*Self {
            return self.parent;
        }

        pub fn getSubdir(self : *Self, name : []const u8) !*Self {
            for (0..self.subdir.items.len) |i| {
                var child : *Self = &self.subdir.items[i];
                if (std.mem.eql(u8, child.name, name)) {
                    return child;
                }
            }
            return self.createSubdir(name);
        }

        fn createSubdir(self : *Self, name : []const u8) !*Self {
            var sub : *Self = try self.subdir.addOne();
            sub.* = .{
                .allocator = self.allocator,
                .parent = self,
                .name = try self.allocator.alloc(u8, name.len),
                .subdir = DirArray.init(self.allocator),
                .files = FileArray.init(self.allocator),
            };

            std.mem.copyForwards(u8, sub.name, name);

            return sub;
        }

        pub fn create(name : []const u8, allocator : Allocator) !Self {
            var dir : Self = .{
                .allocator = allocator,
                .name = try allocator.alloc(u8, name.len),
                .subdir = DirArray.init(allocator),
                .files = FileArray.init(allocator),
            };
            std.mem.copyForwards(u8, dir.name, name);
            return dir;
        }

        pub fn deinit(self : *Self) void {
            self.invalidateSize();
            for (self.subdir.items) |child| {
                child.deinit();
            }
            for (self.files.items) |file| {
                file.deinit();
            }
            self.subdir.deinit();
            self.files.deinit();
            self.allocator.free(self.name);
        }
    };

    root : ?Dir = null,
    allocator : Allocator,
    cwd : ?*Dir = null,

    pub fn getRoot(self : *@This()) !*Dir {
        if (self.root != null) {
            return &self.root.?;
        } else {
            self.root = try Dir.create("/", self.allocator);
            return &self.root.?;
        }
    }

    pub fn deinit(self : *@This()) void {
        if (self.root) |root| {
            root.deinit();
            self.root = null;
        }
    }

    pub fn create(allocator : Allocator) !@This() {
        var self : @This() = .{ .allocator = allocator };
        self.cwd = try self.getRoot();
        return self;
    }
};

const FileInfo = struct {
    name : []const u8,
    size : []const u8,
};

const Command = union(enum) {
    cd    : []const u8,
    cd_up : void,
    ls    : void,
    root  : void,
};

const Output = union(enum) {
    dir  : []const u8,
    file : FileInfo,
};

const CmdLine = union(enum) {
    command : Command,
    output  : Output,
};

fn interpretCmd(line : []const u8) CmdLine {
    const eql = std.mem.eql;

    var args = std.mem.split(u8, line, " ");
    var first = args.next().?;
    if (eql(u8, first, "$")) {
        var cmd = args.next().?;

        if (eql(u8, cmd, "ls")) {
            return .{ .command = .ls };
        }

        else if (eql(u8, cmd, "cd")) {
            var target = args.next().?;
            if (eql(u8, target, "/")) {
                return .{ .command = .root };
            }
            else if(eql(u8, target, "..")) {
                return .{ .command = .cd_up };
            }
            else {
                return .{ .command = .{ .cd = target } };
            }
        }

        else {
            std.debug.print("Unexpected command: {s}\n", .{cmd});
            unreachable;
        }
    }
    else if (eql(u8, first, "dir")) {
        var target = args.next().?;
        return .{ .output = .{ .dir = target } };
    }
    else {
        var name = args.next().?;
        return .{ .output = .{ .file = .{ .name = name, .size = first } } };
    }
}

fn buildFileTree(tree : *Tree, cmd : CmdLine) !void {
    switch (cmd) {
        .command => |comm| {
            switch (comm) {
                .cd => |dir| {
                    tree.cwd = try tree.cwd.?.getSubdir(dir);
                },
                .cd_up => {
                    tree.cwd = tree.cwd.?.parent;
                },
                .root => {
                    tree.cwd = try tree.getRoot();
                },
                .ls => {}
            }
        },
        .output => |o| {
            switch (o) {
                .dir => |name| {
                    _ = name;
                },
                .file => |info| {
                    try tree.cwd.?.addFile(info.name, info.size);
                }
            }
        }
    }
}

fn calculateSize(dir : *Tree.Dir, sum : *u64, threshold : u64) void {
    var size = dir.totalSize();
    if (size <= threshold) {
        sum.* += size;
    }
    for (0..dir.subdir.items.len) |i| {
        var subdir : *Tree.Dir = &dir.subdir.items[i];
        calculateSize(subdir, sum, threshold);
    }
}

fn calculateSmallest(dir : *Tree.Dir, at_least : u64) u64 {
    var my_size = dir.totalSize();

    for (0..dir.subdir.items.len) |i| {
        var subdir : *Tree.Dir = &dir.subdir.items[i];
        var s = calculateSmallest(subdir, at_least);
        if (s >= at_least and s < my_size) {
            my_size = s;
        }
    }

    return my_size;
}

test "Day 7 interpretation correctness" {
    const input =
        \\$ cd /
        \\$ ls
        \\dir a
        \\14848514 b.txt
        \\8504156 c.dat
        \\dir d
        \\$ cd a
        \\$ ls
        \\dir e
        \\29116 f
        \\2557 g
        \\62596 h.lst
        \\$ cd e
        \\$ ls
        \\584 i
        \\$ cd ..
        \\$ cd ..
        \\$ cd d
        \\$ ls
        \\4060174 j
        \\8033020 d.log
        \\5626152 d.ext
        \\7214296 k
    ;
    const commands = [_]CmdLine {
        .{ .command = .root},
        .{ .command = .ls },
        .{ .output = .{ .dir = "a" } },
        .{ .output = .{ .file = .{ .name = "b.txt", .size = "14848514" } } },
        .{ .output = .{ .file = .{ .size = "8504156", .name = "c.dat" } } },
        .{ .output = .{ .dir = "d" } },
        .{ .command = .{ .cd = "a" } },
        .{ .command = .ls },
        .{ .output = .{ .dir = "e" } },
        .{ .output = .{ .file = .{ .size = "29116", .name = "f" } } },
        .{ .output = .{ .file = .{ .size = "2557", .name = "g" } } },
        .{ .output = .{ .file = .{ .size = "62596", .name = "h.lst" } } },
        .{ .command = .{ .cd = "e" } },
        .{ .command = .ls },
        .{ .output = .{ .file = .{ .size = "584", .name = "i" } } },
        .{ .command = .cd_up },
        .{ .command = .cd_up },
        .{ .command = .{ .cd = "d" } },
        .{ .command = .ls },
        .{ .output = .{ .file = .{ .size = "4060174", .name = "j" } } },
        .{ .output = .{ .file = .{ .size = "8033020", .name = "d.log" } } },
        .{ .output = .{ .file = .{ .size = "5626152", .name = "d.ext" } } },
        .{ .output = .{ .file = .{ .size = "7214296", .name = "k" } } },
    };
    var iter = std.mem.split(u8, input, "\n");
    for (commands) |cmd| {
        const line = iter.next().?;
        const inp = interpretCmd(line);
        try std.testing.expectEqualDeep(cmd, inp);
    }
}

test "Day 7 calculate size" {
    const input =
        \\$ cd /
        \\$ ls
        \\dir a
        \\14848514 b.txt
        \\8504156 c.dat
        \\dir d
        \\$ cd a
        \\$ ls
        \\dir e
        \\29116 f
        \\2557 g
        \\62596 h.lst
        \\$ cd e
        \\$ ls
        \\584 i
        \\$ cd ..
        \\$ cd ..
        \\$ cd d
        \\$ ls
        \\4060174 j
        \\8033020 d.log
        \\5626152 d.ext
        \\7214296 k
    ;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var tree = try Tree.create(arena.allocator());

    var iter = std.mem.split(u8, input, "\n");
    while (iter.next()) |cmd| {
        const inp = interpretCmd(cmd);
        try buildFileTree(&tree, inp);
    }
    var sum : u64 = 0;
    calculateSize(try tree.getRoot(), &sum, 100000);
    const expected : u64 = 95437;
    try std.testing.expectEqual(expected, sum);
}

test "Day 7 calculate smallest enough dir" {
    const input =
        \\$ cd /
        \\$ ls
        \\dir a
        \\14848514 b.txt
        \\8504156 c.dat
        \\dir d
        \\$ cd a
        \\$ ls
        \\dir e
        \\29116 f
        \\2557 g
        \\62596 h.lst
        \\$ cd e
        \\$ ls
        \\584 i
        \\$ cd ..
        \\$ cd ..
        \\$ cd d
        \\$ ls
        \\4060174 j
        \\8033020 d.log
        \\5626152 d.ext
        \\7214296 k
    ;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var tree = try Tree.create(arena.allocator());

    var iter = std.mem.split(u8, input, "\n");
    while (iter.next()) |cmd| {
        const inp = interpretCmd(cmd);
        try buildFileTree(&tree, inp);
    }
    var total_size : u64 = 70000000;
    var update_size : u64 = 30000000;

    var root_size = tree.root.?.totalSize();
    const expected_root_size : u64 = 48381165;
    try std.testing.expectEqual(expected_root_size, root_size);

    var unused_space = total_size - root_size;
    const expected_unused_space : u64 = 21618835;
    try std.testing.expectEqual(expected_unused_space, unused_space);

    var needed_space = update_size - unused_space;

    var result : u64 = calculateSmallest(&tree.root.?, needed_space);

    const expected : u64 = 24933642;
    try std.testing.expectEqual(expected, result);
}
