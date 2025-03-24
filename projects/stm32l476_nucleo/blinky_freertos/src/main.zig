const std = @import("std");
const c = @cImport({
    @cDefine("USE_HAL_DRIVER", {});
    @cDefine("STM32L476xx", {});
    @cDefine("__PROGRAM_START", {}); //bug: https://github.com/ziglang/zig/issues/22671
    @cInclude("main.h");
});

const os = @cImport({
    @cInclude("FreeRTOS.h");
    @cInclude("task.h");
});

export fn zig_task(params: ?*anyopaque) callconv(.c) void {
    _ = params;

    while (true) {
        c.HAL_GPIO_WritePin(c.LD2_GPIO_Port, c.LD2_Pin, c.GPIO_PIN_RESET);
        os.vTaskDelay(200);
        c.HAL_GPIO_WritePin(c.LD2_GPIO_Port, c.LD2_Pin, c.GPIO_PIN_SET);
        os.vTaskDelay(200);
    }
}

export fn zigEntrypoint() callconv(.c) void {

    // Temporary task to initialize the system
    const pvParameters: ?*anyopaque = null;
    const pxCreatedTask: ?*os.TaskHandle_t = null;
    _ = os.xTaskCreate(zig_task, "Blinky", 256, pvParameters, 15, pxCreatedTask);
    // Start application
    os.vTaskStartScheduler();

    unreachable;
}
