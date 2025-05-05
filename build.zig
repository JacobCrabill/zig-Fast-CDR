const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const linkage = b.option(
        std.builtin.LinkMode,
        "linkage",
        "Specify static or dynamic linkage",
    ) orelse .static;

    const upstream = b.dependency("fastcdr", .{});

    const fastcdr = b.addLibrary(.{
        .name = "fast-cdr",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .link_libcpp = true,
        }),
        .linkage = linkage,
    });

    const native_endian = @import("builtin").target.cpu.arch.endian();
    const is_bigendian: u8 = if (native_endian == .big) 1 else 0;

    const config_h = b.addConfigHeader(.{
        .style = .{ .cmake = upstream.path("include/fastcdr/config.h.in") },
        .include_path = "fastcdr/config.h",
    }, .{
        .PROJECT_VERSION_MAJOR = 2,
        .PROJECT_VERSION_MINOR = 3,
        .PROJECT_VERSION_PATCH = 0,
        .PROJECT_VERSION = "2.3.0",
        .HAVE_CXX11 = 1,
        .FASTCDR_IS_BIG_ENDIAN_TARGET = is_bigendian,
        .FASTCDR_HAVE_FLOAT128 = 0,
        .FASTCDR_SIZEOF_LONG_DOUBLE = 8,
    });
    fastcdr.addConfigHeader(config_h);
    fastcdr.installHeader(config_h.getOutput(), "fastcdr/config.h");

    fastcdr.addIncludePath(upstream.path("include"));
    fastcdr.addCSourceFiles(.{
        .root = upstream.path("src/cpp"),
        .files = &.{
            "Cdr.cpp",
            "CdrSizeCalculator.cpp",
            "FastBuffer.cpp",
            "FastCdr.cpp",
            "exceptions/BadOptionalAccessException.cpp",
            "exceptions/BadParamException.cpp",
            "exceptions/Exception.cpp",
            "exceptions/LockedExternalAccessException.cpp",
            "exceptions/NotEnoughMemoryException.cpp",
        },
        .flags = &.{ "--std=c++17", "-Wall", "-Wextra", "-pedantic", "-Wconversion", "-Wsign-conversion", "-Wdouble-promotion" },
    });
    fastcdr.installHeadersDirectory(upstream.path("include"), "", .{ .include_extensions = &.{ ".h", ".hpp" } });

    b.installArtifact(fastcdr);
}
