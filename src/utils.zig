const std = @import("std");
const vec = @import("vector.zig");
const c = @cImport({
    @cInclude("stb_image_write.h");
    @cInclude("stb_image.h");
});

pub const Ray = struct {
    orig: vec.Vector3,
    dir: vec.Vector3,

    pub fn at(r: Ray, t: f64) vec.Vector3 {
        return r.dir.multScalar(t).add(r.orig);
    }
};

pub const Camera = struct {
    focalLength: f64,
    pos: vec.Vector3,

    pub fn calcRay(cam: Camera, u: f64, v: f64) Ray {
        var rayDir: vec.Vector3 = .{.x = u*2.0-1.0, .y = v*2.0-1.0, .z = cam.focalLength};
        rayDir = rayDir.normalize();
        return .{.orig = cam.pos, .dir = rayDir};
    }
};

pub const Image = struct {
    data: []u8,
    width: usize,
    height: usize,
    channels: usize,

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize, channels: usize) !Image {
        var img: Image = .{.data = undefined, .width = width, .height = height, .channels = channels};
        img.data = try allocator.alloc(u8, width*height*channels);
        return img;
    }

    pub fn deinit(self: Image, allocator: std.mem.Allocator) void {
        allocator.free(self.data);
    }

    pub fn load(path: [*c]const u8) Image {
        var out: Image = .{.data = undefined, .width = 0, .height = 0, .channels = 0};

        var n: c_int = 0;
        var width: c_int = 0;
        var height: c_int = 0;
        const data: [*c]u8 = c.stbi_load(path, &width, &height, &n, 3);
        if (data == null) {
            std.debug.print("ERROR: Failed to load \"{s}\"\n", .{path});
            @panic("Panic: Failed to load image\n");
        }

        out.width = @intCast(width);
        out.height = @intCast(height);
        out.channels = 3;
        out.data = data[0..out.width*out.height*3];

        return out;
    }

    pub fn save(img: Image, path: [*c]const u8) void {
        _ = c.stbi_write_png(path, @as(c_int, @intCast(img.width)), @as(c_int, @intCast(img.height)), @as(c_int, @intCast(img.channels)), @ptrCast(img.data), @as(c_int, @intCast(img.width*img.channels)));
    }

    pub fn unload(self: *Image) void {
        c.stbi_image_free(self.data.ptr);
    }
};

//Uniformly distributed float between -1.0 and 1.0
pub fn randomFloat(rng: std.Random) f64 {
    return rng.float(f64) * 2.0 - 1.0;
}

//Rather stupid way of generating a random direction: Generate a random vector, and if it's outside of the unit sphere, try again
pub fn randomUnitVector(rng: std.Random) vec.Vector3 {
    var out: vec.Vector3 = vec.Vector3.zero();
    while (true) {
        out.x = randomFloat(rng);
        out.y = randomFloat(rng);
        out.z = randomFloat(rng);

        if (out.length2() <= 1.0) {
            return out.normalize();
        }
    }
}

//Similarly stupid way of generating a random vector in a hemisphere: Generate a random direction, and if it's not in the hemisphere, try again
pub fn randomHemisphereVector(rng: std.Random, normal: vec.Vector3) vec.Vector3 {
    var out: vec.Vector3 = randomUnitVector(rng);
    while (normal.dot(out) < 0.0) {
        out = randomUnitVector(rng);
    }
    return out;
}