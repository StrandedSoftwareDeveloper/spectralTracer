const std = @import("std");
const c = @cImport({
    @cInclude("stb_image_write.h");
    @cInclude("stb_image.h");
});

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
