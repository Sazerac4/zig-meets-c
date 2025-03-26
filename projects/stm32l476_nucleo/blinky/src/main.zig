const std = @import("std");
const c = @cImport({
    @cDefine("USE_HAL_DRIVER", {});
    @cDefine("STM32L476xx", {});
    @cDefine("__PROGRAM_START", {}); //bug: https://github.com/ziglang/zig/issues/22671
    @cInclude("main.h");
    @cInclude("usart.h");
});

export fn zigEntrypoint() callconv(.c) noreturn {
    while (true) {
        c.HAL_GPIO_WritePin(c.LD2_GPIO_Port, c.LD2_Pin, c.GPIO_PIN_RESET);
        c.HAL_Delay(200);
        c.HAL_GPIO_WritePin(c.LD2_GPIO_Port, c.LD2_Pin, c.GPIO_PIN_SET);
        c.HAL_Delay(500);
    }
}

// Custom debug Panic implementation that will be used to print on UART.
pub const panic = std.debug.FullPanic(myPanic);

fn myPanic(msg: []const u8, first_trace_addr: ?usize) noreturn {
    // `_disable_irq()` is demoted to extern but don't work. Maybe because it is was a "static inline" function. Need investigation
    asm volatile ("cpsid i" ::: "memory");

    //Start printing, ensure error is impossible or ignore it. We are already on an error state.
    var buffer: [1024]u8 = undefined;
    var size: u16 = 0;
    var result = std.fmt.bufPrint(&buffer, "\n\n", .{}) catch unreachable;
    if (first_trace_addr) |addr| {
        result = std.fmt.bufPrint(buffer[result.len..], "0x{x} / ", .{addr}) catch unreachable;
        size += @intCast(result.len);
    }
    result = std.fmt.bufPrint(buffer[result.len..], "Panic! {s}\n", .{msg}) catch unreachable;
    size += @intCast(result.len);
    _ = c.HAL_UART_Transmit(&c.huart2, buffer[0..], size, 2000);
    while (true) {}
}
