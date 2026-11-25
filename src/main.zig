//! Cache Hunt - a grid deduction game in Zig.
//!
//! Three supply caches are hidden on a 6x6 grid. You have 12 probes.
//! Probe a cell by typing its coordinates ("x y", each 0-5). A miss
//! tells you the Manhattan distance to the nearest remaining cache.
//! Find all three before the probes run out.
//! Commands: "<x> <y>" to probe, 'quit'. Usage: cache-hunt [--seed N]

const std = @import("std");

const SIZE = 6;
const CACHES = 3;
const PROBES = 12;

const Cell = struct { x: i32, y: i32 };

fn manhattan(a: Cell, b: Cell) i32 {
    const dx = if (a.x > b.x) a.x - b.x else b.x - a.x;
    const dy = if (a.y > b.y) a.y - b.y else b.y - a.y;
    return dx + dy;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    var seed: u64 = 20261125;
    var args = std.process.args();
    _ = args.next();
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--seed")) {
            if (args.next()) |v| seed = std.fmt.parseInt(u64, v, 10) catch seed;
        }
    }
    var prng = std.Random.DefaultPrng.init(seed);
    const rng = prng.random();

    // Place caches on distinct cells.
    var caches: [CACHES]Cell = undefined;
    var placed: usize = 0;
    while (placed < CACHES) {
        const c = Cell{
            .x = @intCast(rng.uintLessThan(u32, SIZE)),
            .y = @intCast(rng.uintLessThan(u32, SIZE)),
        };
        var dup = false;
        for (caches[0..placed]) |o| {
            if (o.x == c.x and o.y == c.y) dup = true;
        }
        if (!dup) {
            caches[placed] = c;
            placed += 1;
        }
    }

    var found = [_]bool{false} ** CACHES;
    var probed = [_][SIZE]bool{ [_]bool{false} ** SIZE } ** SIZE;
    var found_count: usize = 0;

    try stdout.print("=== CACHE HUNT ===\n", .{});
    try stdout.print("{d} caches hidden on a {d}x{d} grid. You have {d} probes.\n", .{ CACHES, SIZE, SIZE, PROBES });
    try stdout.print("Probe with \"x y\" (0-{d}). Misses report the distance to the nearest cache.\n\n", .{SIZE - 1});

    var buf: [128]u8 = undefined;
    var probes_left: i32 = PROBES;
    var won = false;

    while (probes_left > 0) {
        // Draw grid.
        try stdout.print("    0 1 2 3 4 5\n", .{});
        for (0..SIZE) |y| {
            try stdout.print("  {d} ", .{y});
            for (0..SIZE) |x| {
                var ch: u8 = '.';
                for (caches, 0..) |c, ci| {
                    if (found[ci] and c.x == @as(i32, @intCast(x)) and c.y == @as(i32, @intCast(y))) ch = 'C';
                }
                if (ch == '.' and probed[y][x]) ch = 'x';
                try stdout.print("{c} ", .{ch});
            }
            try stdout.print("\n", .{});
        }
        try stdout.print("Probes left: {d} | Caches found: {d}/{d}\n> ", .{ probes_left, found_count, CACHES });

        const line = stdin.readUntilDelimiterOrEof(&buf, '\n') catch break;
        if (line == null) {
            try stdout.print("\n", .{});
            break;
        }
        const trimmed = std.mem.trim(u8, line.?, " \t\r");
        if (std.mem.eql(u8, trimmed, "quit") or std.mem.eql(u8, trimmed, "q")) break;
        var it = std.mem.tokenizeAny(u8, trimmed, " ,");
        const xs = it.next() orelse continue;
        const ys = it.next() orelse {
            try stdout.print("Type two numbers: \"x y\".\n\n", .{});
            continue;
        };
        const gx = std.fmt.parseInt(i32, xs, 10) catch {
            try stdout.print("Coordinates must be numbers 0-{d}.\n\n", .{SIZE - 1});
            continue;
        };
        const gy = std.fmt.parseInt(i32, ys, 10) catch {
            try stdout.print("Coordinates must be numbers 0-{d}.\n\n", .{SIZE - 1});
            continue;
        };
        if (gx < 0 or gx >= SIZE or gy < 0 or gy >= SIZE) {
            try stdout.print("Off the grid - coordinates are 0-{d}.\n\n", .{SIZE - 1});
            continue;
        }
        if (probed[@intCast(gy)][@intCast(gx)]) {
            try stdout.print("Already probed there.\n\n", .{});
            continue;
        }
        probed[@intCast(gy)][@intCast(gx)] = true;
        probes_left -= 1;

        var hit = false;
        for (caches, 0..) |c, ci| {
            if (!found[ci] and c.x == gx and c.y == gy) {
                found[ci] = true;
                found_count += 1;
                hit = true;
                try stdout.print("Cache found at ({d},{d})! {d}/{d}\n\n", .{ gx, gy, found_count, CACHES });
            }
        }
        if (!hit) {
            var best: i32 = 99;
            for (caches, 0..) |c, ci| {
                if (found[ci]) continue;
                const d = manhattan(.{ .x = gx, .y = gy }, c);
                if (d < best) best = d;
            }
            try stdout.print("Empty. Nearest cache is {d} step(s) away.\n\n", .{best});
        }
        if (found_count == CACHES) {
            won = true;
            break;
        }
    }

    try stdout.print("\n=== GAME OVER ===\n", .{});
    if (won) {
        try stdout.print("All {d} caches recovered with {d} probe(s) to spare. Clean sweep!\n", .{ CACHES, probes_left });
    } else {
        try stdout.print("Out of probes. Caches found: {d}/{d}. The rest stay buried.\n", .{ found_count, CACHES });
    }
}
