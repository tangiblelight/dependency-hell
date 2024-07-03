const std = @import("std");

pub fn installDependency(compile: *std.Build.Step.Compile, dep: *std.Build.Dependency) void {
    compile.step.dependOn(dep.builder.getInstallStep());
    compile.linkLibC();
    compile.addLibraryPath(.{ .cwd_relative = dep.builder.getInstallPath(.lib, "") });
    compile.addIncludePath(.{ .cwd_relative = dep.builder.getInstallPath(.header, "") });
    compile.root_module.addRPathSpecial("$ORIGIN/../lib");
}

pub fn installLibs(owner: *std.Build, dep: *std.Build.Dependency) void {
    const install = owner.addInstallDirectory(.{
        .include_extensions = &.{ ".so", ".dll" },
        .install_subdir = "",
        .install_dir = .lib,
        .source_dir = .{
            .cwd_relative = dep.builder.getInstallPath(.lib, ""),
        },
    });
    install.step.dependOn(dep.builder.getInstallStep());
    owner.getInstallStep().dependOn(&install.step);
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dep = b.dependency("dep", .{});

    const app = b.addExecutable(.{
        .name = "main",
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("main.zig"),
    });
    installDependency(app, dep);
    app.linkSystemLibrary("dep");

    b.installArtifact(app);
    installLibs(b, dep);

    const run = b.step("run", "run app");
    const run_app = b.addRunArtifact(app);
    run.dependOn(&run_app.step);
}
