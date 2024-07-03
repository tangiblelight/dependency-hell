const std = @import("std");

pub fn build(b: *std.Build) !void {
    const cmake = try b.findProgram(&.{"cmake"}, &.{});
    const cmake_config = b.addSystemCommand(&.{
        cmake,
        "-DBUILD_SHARED_LIBS=ON",
        "-DCMAKE_BUILD_TYPE=Release", // todo zig optimize
        b.fmt("-DCMAKE_INSTALL_PREFIX={s}", .{b.getInstallPath(.prefix, "")}),
    });

    cmake_config.addArg("-S");
    cmake_config.addDirectoryArg(b.path(""));
    cmake_config.addArg("-B");
    const build_dir = cmake_config.addOutputDirectoryArg("dep_build");

    cmake_config.has_side_effects = true;
    _ = cmake_config.captureStdOut();

    const cmake_build = b.addSystemCommand(&.{cmake});
    cmake_build.step.dependOn(&cmake_config.step);
    cmake_build.addArg("--build");
    cmake_build.addDirectoryArg(build_dir);

    cmake_build.has_side_effects = true;
    _ = cmake_build.captureStdOut();

    const cmake_install = b.addSystemCommand(&.{cmake});
    cmake_install.step.dependOn(&cmake_build.step);
    cmake_install.addArg("--install");
    cmake_install.addDirectoryArg(build_dir);

    cmake_install.has_side_effects = true;
    _ = cmake_install.captureStdOut();

    b.getInstallStep().dependOn(&cmake_install.step);
}
