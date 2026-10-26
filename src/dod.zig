const std = @import("std");
const cfg = @import("config.zig");

const Entities = struct {
    health: []u32,
    cold: [][cfg.cold]u8,

    fn update(self: *Entities) void {
        for (self.health) |*h| h.* += 1;
    }
};

pub fn main() !void {
    const a = std.heap.page_allocator;
    var es = Entities{
        .cold = try a.alloc([cfg.cold]u8, cfg.n), // big first: under valgrind page_allocator's downward mmap hint underflows otherwise
        .health = try a.alloc(u32, cfg.n),
    };
    @memset(es.health, 0);

    var t0: std.c.timespec = undefined;
    var t1: std.c.timespec = undefined;
    _ = std.c.clock_gettime(.MONOTONIC, &t0);
    for (0..cfg.k) |_| {
        es.update();
        std.mem.doNotOptimizeAway(es.health.ptr);
    }
    _ = std.c.clock_gettime(.MONOTONIC, &t1);

    var sum: u64 = 0;
    for (es.health) |h| sum += h;
    const ns = (t1.sec - t0.sec) * 1_000_000_000 + (t1.nsec - t0.nsec);
    std.debug.print("dod cold={d} sum={d} ms={d}\n", .{ cfg.cold, sum, @divTrunc(ns, 1_000_000) });
}
