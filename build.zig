const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dep = b.dependency("dep", .{});
    const module = dep.module("dep");

    const app = b.addExecutable(.{
        .name = "main",
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("main.zig"),
    });
    app.root_module.addImport("dep", module);

    b.installArtifact(app);

    const run = b.step("run", "run app");
    const run_app = b.addRunArtifact(app);
    run.dependOn(&run_app.step);
}
