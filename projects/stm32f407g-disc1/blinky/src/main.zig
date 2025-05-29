const std = @import("std");

//Responsible for exporting vector table symbols and startup code
comptime {
    _ = @import("startup.zig");
    _ = @import("vector_table.zig");
}

const c = @cImport({
    @cDefine("USE_HAL_DRIVER", {});
    @cDefine("STM32F407xx", {});
    @cInclude("main.h");
});

export fn zigEntrypoint() callconv(.c) noreturn {
    while (true) {
        c.HAL_GPIO_WritePin(c.LD3_GPIO_Port, c.LD3_Pin, c.GPIO_PIN_SET);
        c.HAL_Delay(100);
        c.HAL_GPIO_WritePin(c.LD3_GPIO_Port, c.LD3_Pin, c.GPIO_PIN_RESET);
        c.HAL_Delay(100);
        c.HAL_GPIO_WritePin(c.LD4_GPIO_Port, c.LD4_Pin, c.GPIO_PIN_SET);
        c.HAL_Delay(100);
        c.HAL_GPIO_WritePin(c.LD4_GPIO_Port, c.LD4_Pin, c.GPIO_PIN_RESET);
        c.HAL_Delay(100);
        c.HAL_GPIO_WritePin(c.LD6_GPIO_Port, c.LD6_Pin, c.GPIO_PIN_SET);
        c.HAL_Delay(100);
        c.HAL_GPIO_WritePin(c.LD6_GPIO_Port, c.LD6_Pin, c.GPIO_PIN_RESET);
        c.HAL_Delay(100);
        c.HAL_GPIO_WritePin(c.LD5_GPIO_Port, c.LD5_Pin, c.GPIO_PIN_SET);
        c.HAL_Delay(100);
        c.HAL_GPIO_WritePin(c.LD5_GPIO_Port, c.LD5_Pin, c.GPIO_PIN_RESET);
        c.HAL_Delay(100);
    }
}
