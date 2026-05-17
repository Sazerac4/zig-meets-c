/// Base58, An easy-to-share set of characters Why base-58 instead of standard base-64 encoding?
/// - Don't want 0OIl characters that look the same in some fonts and could be used to create visually identical looking account numbers or Id
/// - A string with non-alphanumeric characters is not as easily accepted as an account number or Id.
/// - E-mail usually won't line-break if there's no punctuation to break at.
/// - Double clicking selects the whole number as one word if it's all alphanumeric.
///
/// This algorithm is translated from "https://github.com/luke-jr/libbase58/blob/master/base58.c" and https://github.com/miguelmota/cpp-base58/blob/master/base58.cpp
const Error = error{
    InputNoData,
    OutputBufferTooSmall,
    InputInvalidDigit,
    CarryTypeTooSmall,
};

const alphabet: []const u8 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
const alphabet_map = [_]i8{
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, 0,  1,  2,  3,  4,  5,  6,  7,  8,  -1, -1, -1, -1, -1, -1,
    -1, 9,  10, 11, 12, 13, 14, 15, 16, -1, 17, 18, 19, 20, 21, -1,
    22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, -1, -1, -1, -1, -1,
    -1, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, -1, 44, 45, 46,
    47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, -1, -1, -1, -1, -1,
};

pub fn encode(input: []const u8, buffer: []u8) ![]const u8 {
    if (input.len == 0) {
        return error.InputNoData;
    }

    var zcount: usize = 0; //Zero count
    while (zcount < input.len and input[zcount] == 0) {
        zcount += 1;
    }

    const size: usize = (input.len) * 138 / 100 + 1;
    if (buffer.len < size) {
        return error.OutputBufferTooSmall;
    }

    @memset(buffer[0..buffer.len], 0);

    var i: usize = zcount;
    var high = size - 1;
    while (i < input.len) {
        var carry: u32 = input[i];
        var j: usize = size - 1;
        while ((j > high) or carry > 0) {
            carry += @as(u32, 256) * buffer[j];
            buffer[j] = @intCast(@mod(carry, 58));
            carry = @divTrunc(carry, 58);
            if (j == 0) {
                // Otherwise j wraps to max int which is > high
                break;
            }
            j = j - 1;
        }
        i += 1;
        high = j;
    }

    var j: usize = 0;
    while (j < size and buffer[j] == 0) {
        j += 1;
    }

    i = zcount;
    while (j < size) {
        buffer[i] = alphabet[buffer[j]];
        i += 1;
        j += 1;
    }
    buffer[i] = 0;

    if (zcount > 0) //Leading zeroes in the input buffer
    {
        @memset(buffer[0..zcount], '1');
    }

    return buffer[0..i];
}

pub fn decode(input: []const u8, buffer: []u8) ![]const u8 {
    if (input.len == 0) {
        return error.InputNoData;
    }
    buffer[0] = 0;
    var resultlen: u32 = 1;
    for (input) |*value| {
        if ((value.* & 0x80) > 0 or alphabet_map[value.*] == -1) {
            // High-bit set on invalid digit or Invalid base58 digit
            return error.InputInvalidDigit;
        }
        if (resultlen >= buffer.len) {
            return error.OutputBufferTooSmall;
        }
        var carry: u32 = @intCast(alphabet_map[value.*]);
        var j: u32 = 0;
        while (j < resultlen) : (j += 1) {
            carry += @as(u32, (buffer[j])) * 58;
            buffer[j] = @intCast(carry & 0xff);
            carry >>= 8;
        }
        while (carry > 0) {
            buffer[resultlen] = @intCast(carry & 0xff);
            resultlen += 1;
            carry >>= 8;
        }
    }

    var i: u32 = 0;
    while (i < input.len and input[i] == '1') : (i += 1) {
        buffer[resultlen] = 0;
        resultlen += 1;
    }

    i = resultlen - 1;
    const z = (resultlen >> 1) + (resultlen & 1);
    while (i >= z) : (i -= 1) {
        const k = buffer[i];
        buffer[i] = buffer[resultlen - i - 1];
        buffer[resultlen - i - 1] = k;
    }
    return buffer[0..resultlen];
}

const std = @import("std");

test "encoding" {
    var buffer: [50]u8 = undefined;

    //encode
    const str_to_encode = "All your codebase are belong to us";
    var result = try encode(str_to_encode, &buffer);
    std.debug.print("\n\"{s}\" ==> {} / \"{s}\"\n", .{ str_to_encode, result.len, result });
    try std.testing.expect(std.mem.eql(u8, result, "2UnKbm1dQfMJNkgSNCL9uUKoSPnsNSBfwLBmFmGvyBMTWi6") == true);

    //encode
    const bin_to_encode = [_]u8{ 0x00, 0x00, 0x23, 0x82, 0x01, 0x95, 0x00, 0xb5, 0xdf, 0x41, 0x2d, 0x80, 0xd7, 0xb3, 0xd8, 0x81, 0xa7 };
    result = try encode(&bin_to_encode, &buffer);
    std.debug.print("\"{x}\" ==> {} / \"{s}\"\n", .{ bin_to_encode, result.len, result });
    try std.testing.expect(std.mem.eql(u8, result, "11zco8NrJiyqbJYFKJpRGz") == true);
}

test "decoding" {
    var buffer: [50]u8 = undefined;

    //decode
    const str_to_decode = "2UnKbm1dQfMJNkgSNCL9uUKoSPnsNSBfwLBmFmGvyBMTWi6";
    var result = try decode(str_to_decode, &buffer);
    std.debug.print("\n\"{s}\" ==> {} / \"{s}\"\n", .{ str_to_decode, result.len, result });
    try std.testing.expect(std.mem.eql(u8, result, "All your codebase are belong to us") == true);

    //decode
    const str_to_decode_2 = "11zco8NrJiyqbJYFKJpRGz";
    const bin_expect_result = [_]u8{ 0x00, 0x00, 0x23, 0x82, 0x01, 0x95, 0x00, 0xb5, 0xdf, 0x41, 0x2d, 0x80, 0xd7, 0xb3, 0xd8, 0x81, 0xa7 };
    result = try decode(str_to_decode_2, &buffer);
    std.debug.print("\"{s}\" ==> {} / \"{x}\"\n", .{ str_to_decode_2, result.len, result });
    try std.testing.expect(std.mem.eql(u8, result, &bin_expect_result) == true);
}

// //FIXME: Review fuzz testing
test "fuzz_base58" {
    try std.testing.fuzz({}, testOne, .{});
}

fn testOne(context: void, smith: *std.testing.Smith) !void {
    _ = context;
    const gpa = std.testing.allocator;
    var buffer: [256]u8 = undefined;

    const len = smith.value(u8) % 96 + 5;
    const input = try gpa.alloc(u8, len);
    defer gpa.free(input);
    smith.bytes(input);

    const result = encode(input, &buffer) catch {
        return;
    };
    std.debug.print("\n\"{any}\" ==> {} / \"{s}\"\n", .{ input, result.len, result });
}
