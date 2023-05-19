const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardOptimizeOption(.{});

    const src = std.build.FileSource.relative("src/main.zig");

    const options = std.build.ExecutableOptions {
        .root_source_file = src,
        .target = target,
        .optimize = mode,
        .name = "AoC-2022-Zig"
    };
    const exe = b.addExecutable(options);
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const test_options = std.build.TestOptions {
        .root_source_file = src,
        .target = target,
        .optimize = mode,
        .name = "AoC-2022-Zig-Test"
    };
    const exe_tests = b.addTest(test_options);

    const run_unit_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
