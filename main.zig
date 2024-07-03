const dep = @cImport({
    @cInclude("dep.h");
});

pub fn main() !void {
    dep.greet("app");
}
