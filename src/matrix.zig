const std = @import("std");
const vec = @import("vector.zig");

//TODO: Test all of this
pub const Mat4 = struct {
    r0: vec.Vector4,
    r1: vec.Vector4,
    r2: vec.Vector4,
    r3: vec.Vector4,

    pub fn multVector4(self: Mat4, v: vec.Vector4) vec.Vector4 {
        var out: vec.Vector4 = vec.Vector4.zero();

        out.x = self.r0.x * v.x + self.r0.y * v.y + self.r0.z * v.z + self.r0.w * v.w;
        out.y = self.r1.x * v.x + self.r1.y * v.y + self.r1.z * v.z + self.r1.w * v.w;
        out.z = self.r2.x * v.x + self.r2.y * v.y + self.r2.z * v.z + self.r2.w * v.w;
        out.w = self.r3.x * v.x + self.r3.y * v.y + self.r3.z * v.z + self.r3.w * v.w;

        return out;
    }

    pub fn identity() Mat4 {
        return .{
            .r0 = .{.x = 1.0, .y = 0.0, .z = 0.0, .w = 0.0},
            .r1 = .{.x = 0.0, .y = 1.0, .z = 0.0, .w = 0.0},
            .r2 = .{.x = 0.0, .y = 0.0, .z = 1.0, .w = 0.0},
            .r3 = .{.x = 0.0, .y = 0.0, .z = 0.0, .w = 1.0},
        };
    }

    pub fn translate(mat: Mat4, v: vec.Vector3) Mat4 {
        var out: Mat4 = mat;
        out.r0.w = v.x;
        out.r1.w = v.y;
        out.r2.w = v.z;
        return out;
    }

    pub fn debug_print_matrix(mat: Mat4) void {
        std.debug.print("\n{d:.2} {d:.2} {d:.2} {d:.2}\n", .{mat.r0.x, mat.r0.y, mat.r0.z, mat.r0.w});
        std.debug.print("{d:.2} {d:.2} {d:.2} {d:.2}\n", .{mat.r1.x, mat.r1.y, mat.r1.z, mat.r1.w});
        std.debug.print("{d:.2} {d:.2} {d:.2} {d:.2}\n", .{mat.r2.x, mat.r2.y, mat.r2.z, mat.r2.w});
        std.debug.print("{d:.2} {d:.2} {d:.2} {d:.2}\n", .{mat.r3.x, mat.r3.y, mat.r3.z, mat.r3.w});
    }

    //From https://en.wikipedia.org/wiki/Quaternions_and_spatial_rotation#Quaternion-derived_rotation_matrix
    pub fn fromQuat(q: vec.Vector4) Mat4 {
        return .{ //r=w, i=x, j=y, k=z
            .r0 = .{.x = 1.0-2*(q.y*q.y + q.z*q.z), .y = 2*(q.x*q.y - q.z*q.w),     .z = 2*(q.x*q.z + q.y*q.w),     .w = 0.0},
            .r1 = .{.x = 2*(q.x*q.y + q.z*q.w),     .y = 1.0-2*(q.x*q.x + q.z*q.z), .z = 2*(q.y*q.z - q.x*q.w),     .w = 0.0},
            .r2 = .{.x = 2*(q.x*q.z - q.y*q.w),     .y = 2*(q.y*q.z + q.x*q.w),     .z = 1.0-2*(q.x*q.x + q.y*q.y), .w = 0.0},
            .r3 = .{.x = 0.0,                       .y = 0.0,                       .z = 0.0,                       .w = 1.0},
        };
    }

    pub fn fromQuatAndPos(quat: vec.Vector4, pos: vec.Vector3) Mat4 {
        var out: Mat4 = fromQuat(quat);

        out.r0.w = pos.x;
        out.r1.w = pos.y;
        out.r2.w = pos.z;

        return out;
    }
};

test "Identity test" {
    var matrix: Mat4 = Mat4.identity();
    const vector: vec.Vector4 = .{.w = 1.0, .x = 2.0, .y = 1.0, .z = 0.0};
    const result: vec.Vector4 = matrix.multVector4(vector);
    try result.expectEqual(.{.w = 1.0, .x = 2.0, .y = 1.0, .z = 0.0}, 0.01);
}

test "Translation test" {
    var matrix: Mat4 = Mat4.identity();
    matrix = matrix.translate(.{.x = 7.0, .y = -2.0, .z = 1.5});
    //matrix.debug_print_matrix();
    const vector: vec.Vector4 = .{.w = 1.0, .x = 2.0, .y = 1.0, .z = 0.0};
    const result: vec.Vector4 = matrix.multVector4(vector);
    //std.debug.print("\n\nResult: w:{d:.2} x:{d:.2} y:{d:.2} z:{d:.2}\n\n", .{result.w, result.x, result.y, result.z});
    try result.expectEqual(.{.w = 1.0, .x = 9.0, .y = -1.0, .z = 1.5}, 0.01);
}

test "Rotation test 1" {
    var matrix: Mat4 = Mat4.fromQuat(.{.w = 0.0, .x = 0.0, .y = 0.0, .z = 1.0}); //Rotate 180 degrees on the Z axis
    const vector: vec.Vector4 = .{.w = 1.0, .x = 2.0, .y = 1.0, .z = 0.0};
    const result: vec.Vector4 = matrix.multVector4(vector);
    try result.expectEqual(.{.w = 1.0, .x = -2.0, .y = -1.0, .z = 0.0}, 0.01);
}

test "Rotation test 2" {
    var matrix: Mat4 = Mat4.fromQuat(.{.w = 0.707, .x = 0.0, .y = 0.707, .z = 0.0}); //Rotate 90 degrees on the Y axis
    const vector: vec.Vector4 = .{.w = 1.0, .x = 2.0, .y = 1.0, .z = 0.0};
    const result: vec.Vector4 = matrix.multVector4(vector);
    try result.expectEqual(.{.w = 1.0, .x = 0.0, .y = 1.0, .z = -2.0}, 0.01);
}

test "Rotation and translation test" {
    var matrix: Mat4 = Mat4.fromQuat(.{.w = 0.707, .x = 0.0, .y = 0.707, .z = 0.0}); //Rotate 90 degrees on the Y axis
    const vector: vec.Vector4 = .{.w = 1.0, .x = 2.0, .y = 1.0, .z = 0.0};
    const result: vec.Vector4 = matrix.multVector4(vector);
    try result.expectEqual(.{.w = 1.0, .x = 0.0, .y = 1.0, .z = -2.0}, 0.01);
}