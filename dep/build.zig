const std = @import("std");

const AfterGenerate = struct {
    const Self = @This();

    step: std.Build.Step,
    src: std.Build.LazyPath,
    file: *std.Build.GeneratedFile,

    pub fn create(owner: *std.Build, path: std.Build.LazyPath) *Self {
        const res = owner.allocator.create(Self) catch @panic("OOM");
        res.* = .{
            .step = std.Build.Step.init(.{
                .owner = owner,
                .name = "post-gen",
                .id = .custom,
                .makeFn = make,
            }),
            .src = path.dupe(owner),
            .file = owner.allocator.create(std.Build.GeneratedFile) catch @panic("OOM"),
        };
        res.file.step = &res.step;
        return res;
    }

    pub fn make(step: *std.Build.Step, prog: std.Progress.Node) !void {
        const self: *Self = @fieldParentPtr("step", step);
        self.file.path = self.src.getPath2(step.owner, step);
        _ = prog;
    }

    pub fn getPath(self: AfterGenerate) std.Build.LazyPath {
        return std.Build.LazyPath{ .generated = .{ .file = self.file } };
    }
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const cmake = try b.findProgram(&.{"cmake"}, &.{});
    const cmake_config = b.addSystemCommand(&.{
        cmake,
        "-DBUILD_SHARED_LIBS=ON",
        "-DCMAKE_BUILD_TYPE=Release", // todo zig optimize
        b.fmt("-DCMAKE_INSTALL_PREFIX={s}", .{b.getInstallPath(.prefix, "")}),
    });

    cmake_config.addArg("-S");
    cmake_config.addDirectoryArg(b.path("."));
    cmake_config.addArg("-B");
    const build_dir = cmake_config.addOutputDirectoryArg("dep_build");

    const cmake_build = b.addSystemCommand(&.{cmake});
    cmake_build.step.dependOn(&cmake_config.step);
    cmake_build.addArg("--build");
    cmake_build.addDirectoryArg(build_dir);

    const post_build = AfterGenerate.create(b, build_dir);
    post_build.step.dependOn(&cmake_build.step);

    const module = b.addModule("dep", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("root.zig"),
        .link_libc = true,
    });
    module.addIncludePath(b.path("include"));
    module.addLibraryPath(post_build.getPath());
    module.linkSystemLibrary("dep", .{ .needed = true });
}
