const std = @import("std");
const c = @import("c");

//Responsible for exporting vector table symbols and startup code
comptime {
    _ = @import("startup.zig");
    _ = @import("vector_table.zig");
}

const Led = struct {
    port: *c.GPIO_TypeDef,
    pin: u16,
};

const leds = [_]Led{
    .{ .port = c.LD3_GPIO_Port, .pin = c.LD3_Pin },
    .{ .port = c.LD4_GPIO_Port, .pin = c.LD4_Pin },
    .{ .port = c.LD6_GPIO_Port, .pin = c.LD6_Pin },
    .{ .port = c.LD5_GPIO_Port, .pin = c.LD5_Pin },
};

export fn zigEntrypoint() callconv(.c) noreturn {
    var current_led: usize = 0;
    var last_change_time: u32 = 0;

    while (true) {
        const now = c.HAL_GetTick();

        // Leds Sequence blink without blocking loop.
        if (now - last_change_time >= 250) {
            last_change_time = now;

            // Turn off current LED
            c.HAL_GPIO_WritePin(leds[current_led].port, leds[current_led].pin, c.GPIO_PIN_RESET);

            // Move to next LED
            current_led = (current_led + 1) % leds.len;

            // Turn on new LED
            c.HAL_GPIO_WritePin(leds[current_led].port, leds[current_led].pin, c.GPIO_PIN_SET);
        }

        // The default board configuration example use USB.
        c.MX_USB_HOST_Process();
    }
}
