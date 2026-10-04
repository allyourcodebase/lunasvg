const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lunasvg_dep = b.dependency("lunasvg", .{});
    const lunasvg_root = lunasvg_dep.path(".");

    const static_lib = addLunasvg(b, target, optimize, .static);
    _ = addLunasvg(b, target, optimize, .dynamic);

    {
        const exe_mod = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .link_libcpp = true,
        });

        exe_mod.addIncludePath(lunasvg_dep.path("3rdparty/stb"));
        exe_mod.addCSourceFiles(.{
            .root = lunasvg_root,
            .files = &.{ "svg2png.cpp" },
        });
        exe_mod.linkLibrary(static_lib);

        const exe = b.addExecutable(.{
            .name = "svg2png",
            .root_module = exe_mod,
        });
        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.addPassthruArgs();
        const run_step = b.step("svg2png", "Run svg2png");
        run_step.dependOn(&run_cmd.step);
    }
}

pub fn addLunasvg(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    linkage: std.lang.LinkMode,
) *std.Build.Step.Compile {
    const lunasvg_dep = b.dependency("lunasvg", .{});

    const module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });

    const lib = b.addLibrary(.{
        .name = "lunasvg-static",
        .root_module = module,
        .linkage = linkage,
    });

    module.addIncludePath(lunasvg_dep.path("include"));
    module.addIncludePath(lunasvg_dep.path("3rdparty/plutovg"));

    switch (linkage) {
        .static => {
            module.addCMacro("LUNASVG_BUILD_STATIC", "");
            lib.installHeader(
                lunasvg_dep.path("include/lunasvg.h"),
                "lunasvg-unconfigured.h",
            );
            const w = b.addWriteFiles();
            lib.installHeader(
                w.add("lunasvg.h", (
                    "#define LUNASVG_BUILD_STATIC\n" ++
                    "#include \"lunasvg-unconfigured.h\"\n"
                )),
                "lunasvg.h",
            );
        },
        .dynamic => {
            module.addCMacro("LUNASVG_BUILD", "");
        },
    }
    module.addCSourceFiles(.{
        .root = lunasvg_dep.path("."),
        .files = &lunasvg_files,
    });
    b.installArtifact(lib);
    return lib;
}

const lunasvg_files = [_][]const u8{
    "source/lunasvg.cpp",
    "source/element.cpp",
    "source/property.cpp",
    "source/parser.cpp",
    "source/layoutcontext.cpp",
    "source/canvas.cpp",
    "source/clippathelement.cpp",
    "source/defselement.cpp",
    "source/gelement.cpp",
    "source/geometryelement.cpp",
    "source/graphicselement.cpp",
    "source/maskelement.cpp",
    "source/markerelement.cpp",
    "source/paintelement.cpp",
    "source/stopelement.cpp",
    "source/styledelement.cpp",
    "source/styleelement.cpp",
    "source/svgelement.cpp",
    "source/symbolelement.cpp",
    "source/useelement.cpp",

    "3rdparty/plutovg/plutovg.c",
    "3rdparty/plutovg/plutovg-paint.c",
    "3rdparty/plutovg/plutovg-geometry.c",
    "3rdparty/plutovg/plutovg-blend.c",
    "3rdparty/plutovg/plutovg-rle.c",
    "3rdparty/plutovg/plutovg-dash.c",
    "3rdparty/plutovg/plutovg-ft-raster.c",
    "3rdparty/plutovg/plutovg-ft-stroker.c",
    "3rdparty/plutovg/plutovg-ft-math.c",
};
