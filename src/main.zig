const std = @import("std");
const vec = @import("vector.zig");
const utils = @import("utils.zig");
const c = @cImport({
    @cInclude("stb_image_write.h");
    @cInclude("stb_image.h");
});

// sphere of size ra centered at point ce
fn raySphereIntersect(r: utils.Ray, ce: vec.Vector3, ra: f64) f64 {
    const oc: vec.Vector3 = r.orig.sub(ce);
    const b: f64 = vec.Vector3.dot(oc, r.dir);
    const cl: f64 = vec.Vector3.dot(oc, oc) - ra*ra;
    var h: f64 = b*b - cl;
    if (h < 0.0) { // no intersection
        return -1.0;
    }

    h = @sqrt( h );
    return -b-h;
}

fn calcSampleColor(cam: utils.Camera, u: f64, v: f64, sample: usize) vec.Vector3 {
    _ = sample;
    const ray: utils.Ray = cam.calcRay(u, v);
    const t: f64 = raySphereIntersect(ray, .{.x = 0.0, .y = 0.0, .z = 2.0}, 1.0);
    if (t < 0.0) {
        return .{.x = 0.0, .y = 0.0, .z = 0.0};
    } else {
        return .{.x = 1.0, .y = 0.0, .z = 0.0};
    }
}

fn calcPixelColor(cam: utils.Camera, u: f64, v: f64, samplesPerPixel: usize) vec.Vector3 {
    var color: vec.Vector3 = vec.Vector3.zero();
    for (0..samplesPerPixel) |sample| { //Samples per pixel
        color = color.add(calcSampleColor(cam, u, v, sample));
    }
    return color.divideScalar(@floatFromInt(samplesPerPixel));
}

fn render(image: utils.Image, cam: utils.Camera, samplesPerPixel: usize) void {
    for (0..image.height) |y| {
        for (0..image.width) |x| {
            const u: f64 = @as(f64, @floatFromInt(x)) / @as(f64, @floatFromInt(image.width));
            const v: f64 = @as(f64, @floatFromInt(y)) / @as(f64, @floatFromInt(image.height));
            const color: vec.Vector3 = calcPixelColor(cam, u, v, samplesPerPixel);
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

    const camera: utils.Camera = .{.focalLength = 1.0, .pos = vec.Vector3.zero()};
    render(out, camera, 1);

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
