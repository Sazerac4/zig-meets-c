const std = @import("std");

// Responsible for exporting vector table symbols
comptime {
    _ = @import("vector_table.zig");
}

const c = @cImport({
    @cDefine("USE_HAL_DRIVER", {});
    @cDefine("STM32L476xx", {});
    @cDefine("__PROGRAM_START", {}); //bug: https://github.com/ziglang/zig/issues/22671
    @cInclude("main.h");
});

export fn zigEntrypoint() callconv(.c) noreturn {
    while (true) {
        c.HAL_GPIO_WritePin(c.LD2_GPIO_Port, c.LD2_Pin, c.GPIO_PIN_RESET);
        c.HAL_Delay(200);
        c.HAL_GPIO_WritePin(c.LD2_GPIO_Port, c.LD2_Pin, c.GPIO_PIN_SET);
        c.HAL_Delay(500);
    }
}
