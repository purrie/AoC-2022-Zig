const std = @import("std");
const File = std.fs.File;
const Allocator = std.mem.Allocator;

const BitArray = std.ArrayList(u8);
const Stacks = std.ArrayList(BitArray);

pub fn run(out : anytype) !void {
    const dir = std.fs.cwd();
    const file = try dir.openFile("./inputs/crate-stacks.txt", File.OpenFlags{.mode = .read_only});
    defer file.close();
    var reader = file.reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var stacks = try readStacks(reader, allocator);
    var stacks_9001 = try stacks.clone();
    for (0..stacks_9001.items.len) |i| {
        stacks_9001.items[i] = try stacks_9001.items[i].clone();
    }
    var buff : [128]u8 = undefined;

    while (try reader.readUntilDelimiterOrEof(&buff, '\n')) |line| {
        var inst = try readInstruction(line);
        try move_stack(inst, &stacks);
        try move_stacks(inst, &stacks_9001);
    }

    var top = try get_top_stacks(&stacks, allocator);
    var top_9001 = try get_top_stacks(&stacks_9001, allocator);

    try out.print("Day 5 answer:\n  Part 1: {s}\n  Part 2: {s}\n", .{top.items, top_9001.items});
}

const Instruction = struct {
    from: usize = 0,
    to: usize = 0,
    count: usize = 0,
};

fn readInstruction(line : []const u8) !Instruction {
    var result : Instruction = .{};
    var stream = std.io.fixedBufferStream(line);
    var reader = stream.reader();
    var buff : [10]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&buff, ' ')) |item| {
        if (std.mem.eql(u8, item, "move")) {
            var v = try reader.readUntilDelimiterOrEof(&buff, ' ');
            result.count = try std.fmt.parseInt(usize, v.?, 10);
        } else if (std.mem.eql(u8, item, "from")) {
            var v = try reader.readUntilDelimiterOrEof(&buff, ' ');
            result.from = try std.fmt.parseInt(usize, v.?, 10);
        } else if (std.mem.eql(u8, item, "to")) {
            var v = try reader.readUntilDelimiterOrEof(&buff, ' ');
            result.to = try std.fmt.parseInt(usize, v.?, 10);
        }
    }
    if (result.from == 0 or result.to == 0 or result.count == 0) {
        unreachable;
    }
    return result;
}

fn readStacks(lines : anytype, allocator : Allocator) !Stacks {
    var stacks = try Stacks.initCapacity(allocator, 9);

    var temp : Stacks = try Stacks.initCapacity(allocator, 64);
    defer {
        for (temp.items) |t| {
            t.deinit();
        }
        temp.deinit();
    }
    var buf : [1024]u8 = undefined;

    while (try lines.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len < 3) {
            break;
        }
        var bits = try BitArray.initCapacity(allocator, line.len);
        try bits.appendSlice(line);
        try temp.append(bits);
    }

    const last = temp.pop();
    for (last.items, 0..) |char, i| {
        if (char != ' ') {
            var stack = try BitArray.initCapacity(allocator, temp.items.len);
            for (0..temp.items.len) |index| {
                const row = temp.items.len - index - 1;
                var item = temp.items[row].items[i];
                if (item != ' ') {
                    try stack.append(item);
                } else {
                    break;
                }
            }
            try stacks.append(stack);
        }
    }

    return stacks;
}

fn move_stack(instruction : Instruction, stacks : *Stacks) !void {
    var dest = &stacks.items[instruction.to - 1];
    var sorc = &stacks.items[instruction.from - 1];
    for (0..instruction.count) |_| {
        var item = sorc.pop();
        try dest.append(item);
    }
}

fn move_stacks(instruction : Instruction, stacks : *Stacks) !void {
    var dest = &stacks.items[instruction.to - 1];
    var sorc = &stacks.items[instruction.from - 1];
    var bracket = sorc.items.len - instruction.count;
    try dest.appendSlice(sorc.items[bracket..]);
    sorc.items.len = bracket;
}

fn get_top_stacks(stacks : *Stacks, allocator : Allocator) !BitArray {
    var result = try BitArray.initCapacity(allocator, stacks.items.len);
    for (stacks.items) |stack| {
        var item = stack.items[stack.items.len - 1];
        try result.append(item);
    }
    return result;
}

test "Day 5 part 1" {
    const expectVal = std.testing.expectEqual;
    const expectSlice = std.testing.expectEqualSlices;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const input = "    [D]    \n" ++
                  "[N] [C]    \n" ++
                  "[Z] [M] [P]\n" ++
                  " 1   2   3 \n" ++
                  "\n" ++
                  "move 1 from 2 to 1\n" ++
                  "move 3 from 1 to 3\n" ++
                  "move 2 from 2 to 1\n" ++
                  "move 1 from 1 to 2\n";
    var stream = std.io.fixedBufferStream(input);
    var reader = stream.reader();
    var stacks = try readStacks(reader, allocator);
    try expectVal(stacks.items.len, 3);
    try expectSlice(u8, &[_]u8{'Z', 'N'}, stacks.items[0].items);
    try expectSlice(u8, &[_]u8{'M', 'C', 'D'}, stacks.items[1].items);
    try expectSlice(u8, &[_]u8{'P'}, stacks.items[2].items);

    var buff : [128]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&buff, '\n')) |line| {
        var inst = try readInstruction(line);
        try move_stack(inst, &stacks);
    }
    var top = try get_top_stacks(&stacks, allocator);
    try expectSlice(u8, &[_]u8{'C', 'M', 'Z'}, top.items);
}

test "Day 5 part 2" {
    const expectVal = std.testing.expectEqual;
    const expectSlice = std.testing.expectEqualSlices;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const input = "    [D]    \n" ++
                  "[N] [C]    \n" ++
                  "[Z] [M] [P]\n" ++
                  " 1   2   3 \n" ++
                  "\n" ++
                  "move 1 from 2 to 1\n" ++
                  "move 3 from 1 to 3\n" ++
                  "move 2 from 2 to 1\n" ++
                  "move 1 from 1 to 2\n";
    var stream = std.io.fixedBufferStream(input);
    var reader = stream.reader();
    var stacks = try readStacks(reader, allocator);
    try expectVal(stacks.items.len, 3);
    try expectSlice(u8, &[_]u8{'Z', 'N'}, stacks.items[0].items);
    try expectSlice(u8, &[_]u8{'M', 'C', 'D'}, stacks.items[1].items);
    try expectSlice(u8, &[_]u8{'P'}, stacks.items[2].items);

    var buff : [128]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&buff, '\n')) |line| {
        var inst = try readInstruction(line);
        try move_stacks(inst, &stacks);
    }
    var top = try get_top_stacks(&stacks, allocator);
    try expectSlice(u8, &[_]u8{'M', 'C', 'D'}, top.items);
}
