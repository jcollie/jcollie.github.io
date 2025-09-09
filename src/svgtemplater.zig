const std = @import("std");

const log = std.log.scoped(.svgtemplater);

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

pub fn main() !void {
    const alloc = debug_allocator.allocator();
    defer _ = debug_allocator.deinit();

    var args = try std.process.argsWithAllocator(alloc);
    defer args.deinit();
    _ = args.skip();

    const mdi_base = args.next() orelse return error.NoMdiBase;
    const template_filename = args.next() orelse return error.NoTemplateFilename;

    log.warn("{s}", .{mdi_base});
    log.warn("{s}", .{template_filename});

    var output_write_buffer: [1024]u8 = undefined;
    const stdout = std.fs.File.stdout();
    var stdout_writer = stdout.writer(&output_write_buffer);
    const output = &stdout_writer.interface;

    var template_read_buffer: [1024]u8 = undefined;
    var template = try std.fs.cwd().openFile(template_filename, .{ .mode = .read_only });
    defer template.close();
    var template_reader = template.reader(&template_read_buffer);
    const input = &template_reader.interface;
    while (true) {
        _ = try input.streamDelimiterEnding(output, 'u');
        const n = input.peekDelimiterInclusive(')') catch |err| switch (err) {
            error.EndOfStream => {
                _ = try input.streamRemaining(output);
                break;
            },
            else => |e| return e,
        };
        // log.warn("{s}", .{n});
        if (!std.mem.startsWith(u8, n, "url(\"")) {
            try output.writeByte('u');
            input.toss(1);
            continue;
        }
        if (!std.mem.endsWith(u8, n, "\")")) {
            try output.writeByte('u');
            input.toss(1);
            continue;
        }
        input.toss(n.len);
        const svg_filename = n[5 .. n.len - 2];
        const svg_pathname = try std.fs.path.join(alloc, &.{ mdi_base, svg_filename });
        defer alloc.free(svg_pathname);
        var svg_file = std.fs.cwd().openFile(svg_pathname, .{ .mode = .read_only }) catch {
            try output.writeAll(n);
            continue;
        };
        defer svg_file.close();
        const source = try svg_file.readToEndAlloc(alloc, std.math.maxInt(usize));
        defer alloc.free(source);
        try output.writeAll("url(\"data:image/svg+xml;base64,");
        try std.base64.standard.Encoder.encodeWriter(output, source);
        try output.writeAll("\")");
    }
    try output.flush();
}
