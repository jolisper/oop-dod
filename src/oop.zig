const std = @import("std");
const cfg = @import("config.zig");

const Entity = struct {
    health: u32,
    cold: [cfg.cold]u8,

    fn update(self: *Entity) void {
        self.health += 1;
    }
};

pub fn main() !void {
    const items = try std.heap.page_allocator.alloc(Entity, cfg.n);
    for (items) |*e| e.* = .{ .health = 0, .cold = undefined };

    var t0: std.c.timespec = undefined;
    var t1: std.c.timespec = undefined;
    _ = std.c.clock_gettime(.MONOTONIC, &t0);
    for (0..cfg.k) |_| {
        for (items) |*e| e.update();
        std.mem.doNotOptimizeAway(items.ptr);
    }
    _ = std.c.clock_gettime(.MONOTONIC, &t1);

    var sum: u64 = 0;
    for (items) |e| sum += e.health;
    const ns = (t1.sec - t0.sec) * 1_000_000_000 + (t1.nsec - t0.nsec);
    std.debug.print("oop cold={d} sum={d} ms={d}\n", .{ cfg.cold, sum, @divTrunc(ns, 1_000_000) });
}
