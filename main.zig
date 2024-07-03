const cmake_dep = @import("dep");

pub fn main() !void {
    cmake_dep.greet("app");
}
