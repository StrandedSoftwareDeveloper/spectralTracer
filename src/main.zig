const std = @import("std");
const vec = @import("vector.zig");
const utils = @import("utils.zig");
const c = @cImport({
    @cInclude("stb_image_write.h");
    @cInclude("stb_image.h");
});

const Sphere = struct {
    center: vec.Vector3,
    radius: f64,
    emissive: bool,
};

const HitRecord = struct {
    hit: bool,
    t: f64,
    objIndex: usize,
};

//Adapted from https://iquilezles.org/articles/intersectors/
// sphere of size ra centered at point ce
fn raySphereIntersect(r: utils.Ray, sph: Sphere) f64 {
    const oc: vec.Vector3 = r.orig.sub(sph.center);
    const b: f64 = vec.Vector3.dot(oc, r.dir);
    const cl: f64 = vec.Vector3.dot(oc, oc) - sph.radius*sph.radius;
    var h: f64 = b*b - cl;
    if (h < 0.0) { // no intersection
        return -1.0;
    }

    h = @sqrt( h );
    return -b-h;
}

fn raySceneIntersect(r: utils.Ray, scene: []const Sphere) HitRecord {
    var hit: HitRecord = .{.hit = false, .t = 9999999999.0, .objIndex = 0};
    
    for (0..scene.len) |i| {
        const sphere: Sphere = scene[i];
        const t: f64 = raySphereIntersect(r, sphere);
        if (t >= 0.0) { //Hit
            hit.hit = true;
            if (t < hit.t) {
                hit.t = t;
                hit.objIndex = i;
            }
        }
    }
    
    return hit;
}

fn calcSampleColor(cam: utils.Camera, rng: std.Random, u: f64, v: f64, sample: usize, maxBounces: usize) vec.Vector3 {
    _ = sample;
    const sun: Sphere = .{.center = .{.x = 2.0, .y = 0.0, .z = 0.0}, .radius = 1.0, .emissive = true};
    const planet: Sphere = .{.center = .{.x = 0.0, .y = 0.0, .z = 2.0}, .radius = 1.0, .emissive = false};
    const scene: []const Sphere = &[_]Sphere{
        sun,
        planet,
    };
    
    var ray: utils.Ray = cam.calcRay(u, v);
    var color: vec.Vector3 = .{.x = 10.0, .y = 10.0, .z = 10.0};

    for (0..maxBounces) |i| {
        _ = i;
        const hit: HitRecord = raySceneIntersect(ray, scene);
        if (!hit.hit) {
            return .{.x = 0.0, .y = 0.0, .z = 0.0};
        }
        
        if (scene[hit.objIndex].emissive) {
            return color;
        }

        ray.orig = ray.at(hit.t - 0.01);

        const normal: vec.Vector3 = vec.Vector3.sub(ray.orig, scene[hit.objIndex].center).normalize();
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
    std.debug.print("Rendering...\n", .{});
    render(out, camera, rng, 16, 10);
    std.debug.print("Done!\n", .{});

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
