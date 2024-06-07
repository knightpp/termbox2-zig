const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const build_options = b.addOptions();
    build_options.addOption(i32, "attr_w", b.option(i32, "attr_w", "integer width of fg and bg attributes") orelse 0);
    build_options.addOption(bool, "egc", b.option(bool, "egc", "enable extended grapheme cluster support") orelse false);
    build_options.addOption(usize, "printf_buf", b.option(usize, "printf_buf", "buffer size for printf operations") orelse 0);
    build_options.addOption(usize, "read_buf", b.option(usize, "read_buf", "buffer size for tty reads") orelse 0);

    const termbox2_c = b.dependency("termbox2", .{
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addStaticLibrary(.{
        .name = "termbox2-zig",
        .root_source_file = b.path("src/termbox2.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib.root_module.addOptions("build_options", build_options);
    lib.linkLibC();
    lib.installHeader(termbox2_c.path("termbox2.h"), "termbox2.h");
    b.installArtifact(lib);

    const module = b.addModule("termbox2", .{
        .root_source_file = lib.root_module.root_source_file,
        .target = target,
        .optimize = optimize,
    });
    module.addOptions("build_options", build_options);
    module.addIncludePath(termbox2_c.path(""));

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/tests.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib_unit_tests.linkLibrary(lib);

    const test_step = b.step("test", "Run unit tests");
    const build_only = b.option(bool, "build", "Build tests but do not run") orelse false;
    if (build_only) {
        const tests_artifact = b.addInstallArtifact(lib_unit_tests, .{});
        test_step.dependOn(&tests_artifact.step);
    } else {
        const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
        test_step.dependOn(&run_lib_unit_tests.step);
    }

    const cov_step = b.step("cov", "Generate coverage");
    const cov_run = b.addSystemCommand(&.{ "kcov", "--clean", "--include-pattern=src/", "kcov-output" });
    cov_run.addArtifactArg(lib_unit_tests);
    cov_step.dependOn(&cov_run.step);

    const lints_step = b.step("lints", "Run lints");
    const lints = b.addFmt(.{
        .paths = &.{ "src", "build.zig" },
        .check = true,
    });

    lints_step.dependOn(&lints.step);
    b.default_step.dependOn(lints_step);
}
