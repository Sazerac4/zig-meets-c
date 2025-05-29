// Startup code modified from https://github.com/haydenridd/stm32-baremetal-zig/blob/main/src/startup.zig
extern fn SystemInit() callconv(.c) void;
extern fn __libc_init_array() callconv(.c) void;
extern fn main() callconv(.c) noreturn;

comptime {
    @export(&resetHandler, .{
        .name = "resetHandler",
        .linkage = .strong,
    });
}

extern const _estack: anyopaque;

pub fn resetHandler() callconv(.c) noreturn {
    const startup_locations = struct {
        extern var _sbss: u8;
        extern var _ebss: u8;
        extern var _sdata: u8;
        extern var _edata: u8;
        extern const _sidata: u8;
    };

    // Explicitly initialize stack pointer to _estack (defined in linker script)
    // Note: While Cortex-M cores automatically load SP from vector table at startup, this provides redundancy.
    asm volatile ("ldr sp, =_estack");

    // Setup the microcontroller system, Initialize the FPU setting, vector table location and External memory configuration
    SystemInit();

    // fill .bss with zeroes
    {
        const bss_start: [*]u8 = @ptrCast(&startup_locations._sbss);
        const bss_end: [*]u8 = @ptrCast(&startup_locations._ebss);
        const bss_len = @intFromPtr(bss_end) - @intFromPtr(bss_start);

        @memset(bss_start[0..bss_len], 0);
    }

    // load .data from flash
    {
        const data_start: [*]u8 = @ptrCast(&startup_locations._sdata);
        const data_end: [*]u8 = @ptrCast(&startup_locations._edata);
        const data_len = @intFromPtr(data_end) - @intFromPtr(data_start);
        const data_src: [*]const u8 = @ptrCast(&startup_locations._sidata);

        @memcpy(data_start[0..data_len], data_src[0..data_len]);
    }

    // Call static constructors (newlib)
    __libc_init_array();

    main();
}
