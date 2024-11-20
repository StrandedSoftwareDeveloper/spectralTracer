const std = @import("std");
const vec = @import("vector.zig");
const utils = @import("utils.zig");
const c = @cImport({
    @cInclude("stb_image_write.h");
    @cInclude("stb_image.h");
});

//Adapted from https://iquilezles.org/articles/intersectors/
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

fn calcSampleColor(cam: utils.Camera, rng: std.Random, u: f64, v: f64, sample: usize, maxBounces: usize) vec.Vector3 {
    _ = sample;
    const sunPos: vec.Vector3 = .{.x = 2.0, .y = 0.0, .z = 0.0};
    var ray: utils.Ray = cam.calcRay(u, v);
    var color: vec.Vector3 = .{.x = 10.0, .y = 10.0, .z = 10.0};

    for (0..maxBounces) |i| {
        _ = i;
        const t: f64 = raySphereIntersect(ray, .{.x = 0.0, .y = 0.0, .z = 2.0}, 1.0);
        if (t < 0.0) {
            if (raySphereIntersect(ray, sunPos, 1.0) < 0.0) { //The sun
                return .{.x = 0.0, .y = 0.0, .z = 0.0};
            }

            return color;
        }

        ray.orig = ray.at(t - 0.01);

        const normal: vec.Vector3 = vec.Vector3.sub(ray.orig, .{.x = 0.0, .y = 0.0, .z = 2.0}).normalize();
        ray.dir = utils.randomHemisphereVector(rng, normal);
        color = color.mul(.{.x = 0.2, .y = 0.05, .z = 0.05});
    }

    return .{.x = 0.0, .y = 0.0, .z = 0.0};
}

fn calcPixelColor(cam: utils.Camera, img: utils.Image, rng: std.Random, u: f64, v: f64, samplesPerPixel: usize, maxBounces: usize) vec.Vector3 {
    var color: vec.Vector3 = vec.Vector3.zero();
    for (0..samplesPerPixel) |sample| { //Samples per pixel
        const uOffset: f64 = (utils.randomFloat(rng) / @as(f64, @floatFromInt(img.width))) * 0.5; //Randomly jitter the uv for anti-aliasing
        const vOffset: f64 = (utils.randomFloat(rng) / @as(f64, @floatFromInt(img.height))) * 0.5;
        color = color.add(calcSampleColor(cam, rng, u + uOffset, v + vOffset, sample, maxBounces));
    }
    return color.divideScalar(@floatFromInt(samplesPerPixel));
}

fn render(image: utils.Image, cam: utils.Camera, rng: std.Random, samplesPerPixel: usize, maxBounces: usize) void {
    for (0..image.height) |y| {
        for (0..image.width) |x| {
            const u: f64 = @as(f64, @floatFromInt(x)) / @as(f64, @floatFromInt(image.width));
            const v: f64 = @as(f64, @floatFromInt(y)) / @as(f64, @floatFromInt(image.height));
            const color: vec.Vector3 = calcPixelColor(cam, image, rng, u, v, samplesPerPixel, maxBounces);
            image.data[(y*image.width+x)*3+0] = @intFromFloat(std.math.clamp(color.x, 0.0, 1.0) * 255.0); //r
            image.data[(y*image.width+x)*3+1] = @intFromFloat(std.math.clamp(color.y, 0.0, 1.0) * 255.0); //g
            image.data[(y*image.width+x)*3+2] = @intFromFloat(std.math.clamp(color.z, 0.0, 1.0) * 255.0); //b
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

    var pcg: std.Random.Pcg = std.Random.Pcg.init(0);
    const rng: std.Random = pcg.random();

    const camera: utils.Camera = .{.focalLength = 1.0, .pos = vec.Vector3.zero()};
    render(out, camera, rng, 10, 10);

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
