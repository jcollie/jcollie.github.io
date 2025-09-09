const std = @import("std");
const zine = @import("zine");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mdi = b.dependency("mdi", .{});
    var build_assets: std.ArrayList(zine.BuildAsset) = .empty;

    {
        const svgtemplater_exe = b.addExecutable(
            .{
                .name = "svgtemplater",
                .root_module = b.createModule(
                    .{
                        .root_source_file = b.path("src/svgtemplater.zig"),
                        .target = target,
                        .optimize = optimize,
                    },
                ),
            },
        );
        const svgtemplater_install = b.addInstallArtifact(svgtemplater_exe, .{});
        b.getInstallStep().dependOn(&svgtemplater_install.step);

        var dir = try b.build_root.handle.openDir("templates", .{ .iterate = true });
        defer dir.close();
        var it = try dir.walk(b.allocator);
        while (try it.next()) |entry| {
            switch (entry.kind) {
                .file => {
                    if (std.mem.endsWith(u8, entry.basename, ".css.in")) {
                        const src_path = try std.fs.path.join(b.allocator, &.{ "templates", entry.path });
                        const dst_path = entry.path[0 .. entry.path.len - 3];
                        const svgtemplate_run = b.addRunArtifact(svgtemplater_exe);
                        svgtemplate_run.addDirectoryArg(mdi.path("."));
                        svgtemplate_run.addFileArg(b.path(src_path));
                        const out = svgtemplate_run.captureStdOut();
                        try build_assets.append(b.allocator, .{
                            .name = b.dupe(dst_path),
                            .install_path = b.dupe(dst_path),
                            .install_always = true,
                            .lp = out,
                        });
                    }
                },
                else => {},
            }
        }
    }

    const release = b.step("release", "Build the website");
    const website = zine.website(
        b,
        .{
            .build_assets = build_assets.items,
        },
    );
    release.dependOn(&website.step);

    const serve = b.step("serve", "Start the Zine development server");
    const run_zine = zine.serve(
        b,
        .{
            .build_assets = build_assets.items,
        },
    );
    serve.dependOn(&run_zine.step);
}
