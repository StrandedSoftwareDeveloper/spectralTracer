const std = @import("std");
const vec = @import("vector.zig");
const utils = @import("utils.zig");
const c = @cImport({
    @cInclude("stb_image_write.h");
    @cInclude("stb_image.h");
});

fn calcColor(u: f64, v: f64) vec.Vector3 {
    return .{.x = u, .y = v, .z = 0.0};
}

fn render(image: utils.Image) void {
    for (0..image.height) |y| {
        for (0..image.width) |x| {
            const u: f64 = @as(f64, @floatFromInt(x)) / @as(f64, @floatFromInt(image.width));
            const v: f64 = @as(f64, @floatFromInt(y)) / @as(f64, @floatFromInt(image.height));
            const color: vec.Vector3 = calcColor(u, v);
            image.data[(y*image.width+x)*3+0] = @intFromFloat(color.x * 255.0); //r
            image.data[(y*image.width+x)*3+1] = @intFromFloat(color.y * 255.0); //g
            image.data[(y*image.width+x)*3+2] = @intFromFloat(color.z * 255.0); //b
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator: std.mem.Allocator = gpa.allocator();

    var out: utils.Image = try utils.Image.init(allocator, 256, 256, 3);
    defer out.deinit(allocator);
    defer out.save("out.png");

    render(out);

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    _ = stdout;
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
