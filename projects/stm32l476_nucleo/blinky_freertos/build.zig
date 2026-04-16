const builtin = @import("builtin");
const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe_name = "blinky_freertos";

    // Target
    const query: std.Target.Query = .{
        .cpu_arch = .thumb,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m4 },
        .cpu_features_add = std.Target.arm.featureSet(&[_]std.Target.arm.Feature{std.Target.arm.Feature.vfp4d16sp}),
        .os_tag = .freestanding,
        .abi = .eabihf,
        .glibc_version = null,
    };
    const target = b.resolveTargetQuery(query);

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const optimization = b.standardOptimizeOption(.{});

    // In Debug Release, the default optimization level is set to -O0, which significantly increases the binary size.
    // We override the optimization level with -Og while keeping the other three optimization modes unchanged.
    const c_optimization = if (optimization == .Debug) "-Og" else if (optimization == .ReleaseSmall) "-Os" else "-O2";

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimization,
        .link_libc = false,
        .strip = false,
        .single_threaded = true, // single core cpu
        .sanitize_c = .trap,
    });

    const elf = b.addExecutable(.{
        .name = exe_name ++ ".elf",
        .linkage = .static,
        .root_module = exe_mod,
        .use_lld = true,
        .use_llvm = true,
    });

    //////////////////////////////////////////////////////////////////
    // User Options
    // Try to find arm-none-eabi-gcc program at a user specified path, or PATH variable if none provided
    const arm_gcc_pgm = if (b.option([]const u8, "ARM_GCC_PATH", "Path to arm-none-eabi-gcc compiler")) |arm_gcc_path|
        b.findProgram(&.{"arm-none-eabi-gcc"}, &.{arm_gcc_path}) catch {
            std.log.err("Couldn't find arm-none-eabi-gcc at provided path: {s}\n", .{arm_gcc_path});
            return;
        }
    else
        b.findProgram(&.{"arm-none-eabi-gcc"}, &.{}) catch {
            std.log.err("Couldn't find arm-none-eabi-gcc in PATH, try manually providing the path to this executable with -Darmgcc=[path]\n", .{});
            return;
        };

    // Allow user to enable float formatting in newlib (printf, sprintf, ...)
    if (b.option(bool, "NEWLIB_PRINTF_FLOAT", "Force newlib to include float support for printf and variants functions")) |_| {
        elf.forceUndefinedSymbol("_printf_float"); // GCC equivalent : "-u _printf_float"
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //  Use gcc-arm-none-eabi to figure out where library paths are
    const gcc_arm_sysroot_path = std.mem.trim(u8, b.run(&.{ arm_gcc_pgm, "-print-sysroot" }), "\r\n");
    const gcc_arm_multidir_relative_path = std.mem.trim(u8, b.run(&.{ arm_gcc_pgm, "-mcpu=cortex-m4", "-mfpu=fpv4-sp-d16", "-mfloat-abi=hard", "-print-multi-directory" }), "\r\n");
    const gcc_arm_version = std.mem.trim(u8, b.run(&.{ arm_gcc_pgm, "-dumpversion" }), "\r\n");
    const gcc_arm_lib_path1 = b.fmt("{s}/../lib/gcc/arm-none-eabi/{s}/{s}", .{ gcc_arm_sysroot_path, gcc_arm_version, gcc_arm_multidir_relative_path });
    const gcc_arm_lib_path2 = b.fmt("{s}/lib/{s}", .{ gcc_arm_sysroot_path, gcc_arm_multidir_relative_path });

    // Manually add "nano" variant newlib C standard lib from arm-none-eabi-gcc library folders
    exe_mod.addLibraryPath(.{ .cwd_relative = gcc_arm_lib_path1 });
    exe_mod.addLibraryPath(.{ .cwd_relative = gcc_arm_lib_path2 });
    exe_mod.addSystemIncludePath(.{ .cwd_relative = b.fmt("{s}/include", .{gcc_arm_sysroot_path}) });
    exe_mod.addObjectFile(.{ .cwd_relative = b.fmt("{s}/crt0.o", .{gcc_arm_lib_path2}) });
    exe_mod.addObjectFile(.{ .cwd_relative = b.fmt("{s}/crti.o", .{gcc_arm_lib_path1}) });
    exe_mod.addObjectFile(.{ .cwd_relative = b.fmt("{s}/crtbegin.o", .{gcc_arm_lib_path1}) });
    exe_mod.addObjectFile(.{ .cwd_relative = b.fmt("{s}/crtend.o", .{gcc_arm_lib_path1}) });
    exe_mod.addObjectFile(.{ .cwd_relative = b.fmt("{s}/crtn.o", .{gcc_arm_lib_path1}) });
    exe_mod.linkSystemLibrary("c_nano", .{ // Use "g_nano" (a debugging-enabled libc) ?
        .needed = true,
        .preferred_link_mode = .static,
        .use_pkg_config = .no,
    });
    exe_mod.linkSystemLibrary("m", .{
        .needed = true,
        .preferred_link_mode = .static,
        .use_pkg_config = .no,
    });

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    const hal_mod = b.createModule(.{
        .target = target,
        .optimize = optimization,
        .link_libc = false,
        .strip = false,
        .single_threaded = true, // single core cpu
        .sanitize_c = .trap,
    });

    const hal_includes = [_][]const u8{
        "Drivers/STM32L4xx_HAL_Driver/Inc",
        "Drivers/STM32L4xx_HAL_Driver/Inc/Legacy",
        "Drivers/CMSIS/Device/ST/STM32L4xx/Include",
        "Drivers/CMSIS/Include",
        "Core/Inc",
    };

    const hal_sources = [_][]const u8{
        "Drivers/STM32L4xx_HAL_Driver/Src/stm32l4xx_hal_tim.c",
        "Drivers/STM32L4xx_HAL_Driver/Src/stm32l4xx_hal_tim_ex.c",
        "Drivers/STM32L4xx_HAL_Driver/Src/stm32l4xx_hal_uart.c",
        "Drivers/STM32L4xx_HAL_Driver/Src/stm32l4xx_hal_uart_ex.c",
        "Drivers/STM32L4xx_HAL_Driver/Src/stm32l4xx_hal.c",
        "Drivers/STM32L4xx_HAL_Driver/Src/stm32l4xx_hal_rcc.c",
        "Drivers/STM32L4xx_HAL_Driver/Src/stm32l4xx_hal_rcc_ex.c",
        "Drivers/STM32L4xx_HAL_Driver/Src/stm32l4xx_hal_flash.c",
        "Drivers/STM32L4xx_HAL_Driver/Src/stm32l4xx_hal_flash_ex.c",
        "Drivers/STM32L4xx_HAL_Driver/Src/stm32l4xx_hal_flash_ramfunc.c",
        "Drivers/STM32L4xx_HAL_Driver/Src/stm32l4xx_hal_gpio.c",
        "Drivers/STM32L4xx_HAL_Driver/Src/stm32l4xx_hal_i2c.c",
        "Drivers/STM32L4xx_HAL_Driver/Src/stm32l4xx_hal_i2c_ex.c",
        "Drivers/STM32L4xx_HAL_Driver/Src/stm32l4xx_hal_dma.c",
        "Drivers/STM32L4xx_HAL_Driver/Src/stm32l4xx_hal_dma_ex.c",
        "Drivers/STM32L4xx_HAL_Driver/Src/stm32l4xx_hal_pwr.c",
        "Drivers/STM32L4xx_HAL_Driver/Src/stm32l4xx_hal_pwr_ex.c",
        "Drivers/STM32L4xx_HAL_Driver/Src/stm32l4xx_hal_cortex.c",
        "Drivers/STM32L4xx_HAL_Driver/Src/stm32l4xx_hal_exti.c",
    };
    const hal_flags = [_][]const u8{
        c_optimization,
        "-std=gnu17",
        "-Wall",
        "-Wextra",
    };

    for (hal_includes) |path| {
        hal_mod.addIncludePath(b.path(path));
    }

    hal_mod.addCSourceFiles(.{
        .files = &hal_sources,
        .flags = &hal_flags,
    });

    hal_mod.addCMacro("USE_HAL_DRIVER", "");
    hal_mod.addCMacro("STM32L476xx", "");

    exe_mod.addImport("HAL library", hal_mod);

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // FreeRTOS source code
    const os_mod = b.createModule(.{
        .target = target,
        .optimize = optimization,
        .link_libc = false,
        .strip = false,
        .single_threaded = true, // single core cpu
        .sanitize_c = .trap,
    });

    const os_includes = [_][]const u8{
        "Middlewares/Third_Party/FreeRTOS/Source/include",
        "Middlewares/Third_Party/FreeRTOS/Source/CMSIS_RTOS_V2",
        "Middlewares/Third_Party/FreeRTOS/Source/portable/GCC/ARM_CM4F",
        "Drivers/STM32L4xx_HAL_Driver/Inc",
        "Drivers/STM32L4xx_HAL_Driver/Inc/Legacy",
        "Drivers/CMSIS/Device/ST/STM32L4xx/Include",
        "Drivers/CMSIS/Include",
        "Core/Inc",
    };

    const os_sources = [_][]const u8{
        "Middlewares/Third_Party/FreeRTOS/Source/croutine.c",
        "Middlewares/Third_Party/FreeRTOS/Source/event_groups.c",
        "Middlewares/Third_Party/FreeRTOS/Source/list.c",
        "Middlewares/Third_Party/FreeRTOS/Source/queue.c",
        "Middlewares/Third_Party/FreeRTOS/Source/stream_buffer.c",
        "Middlewares/Third_Party/FreeRTOS/Source/tasks.c",
        "Middlewares/Third_Party/FreeRTOS/Source/timers.c",
        "Middlewares/Third_Party/FreeRTOS/Source/CMSIS_RTOS_V2/cmsis_os2.c",
        "Middlewares/Third_Party/FreeRTOS/Source/portable/MemMang/heap_4.c",
        "Middlewares/Third_Party/FreeRTOS/Source/portable/GCC/ARM_CM4F/port.c",
    };
    const os_flags = [_][]const u8{
        c_optimization,
        "-std=gnu17",
        "-Wall",
        "-Wextra",
    };

    for (os_includes) |path| {
        os_mod.addIncludePath(b.path(path));
    }
    os_mod.addCSourceFiles(.{
        .files = &os_sources,
        .flags = &os_flags,
    });

    os_mod.addSystemIncludePath(.{ .cwd_relative = b.fmt("{s}/include", .{gcc_arm_sysroot_path}) }); //Need libc includes
    os_mod.addCMacro("USE_HAL_DRIVER", "");
    os_mod.addCMacro("STM32L476xx", "");

    //Add FreeRTOS to the executable
    exe_mod.addImport("FreeRTOS library", os_mod);

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    const app_includes = [_][]const u8{
        "Middlewares/Third_Party/FreeRTOS/Source/include",
        "Middlewares/Third_Party/FreeRTOS/Source/CMSIS_RTOS_V2",
        "Middlewares/Third_Party/FreeRTOS/Source/portable/GCC/ARM_CM4F",
        "Drivers/STM32L4xx_HAL_Driver/Inc",
        "Drivers/STM32L4xx_HAL_Driver/Inc/Legacy",
        "Drivers/CMSIS/Device/ST/STM32L4xx/Include",
        "Drivers/CMSIS/Include",
        "Core/Inc",
    };
    for (app_includes) |path| {
        exe_mod.addIncludePath(b.path(path));
    }

    const app_sources = [_][]const u8{
        "Core/Src/main.c",
        "Core/Src/gpio.c",
        "Core/Src/usart.c",
        "Core/Src/stm32l4xx_hal_timebase_tim.c",
        "Core/Src/freertos.c",
        "Core/Src/stm32l4xx_it.c",
        "Core/Src/stm32l4xx_hal_msp.c",
        "Core/Src/system_stm32l4xx.c",
        "Core/Src/sysmem.c",
        "Core/Src/syscalls.c",
        "Core/Src/freertos-openocd.c",
    };
    const app_flags = [_][]const u8{
        c_optimization,
        "-std=gnu17",
        "-Wall",
        "-Wextra",
    };
    exe_mod.addCSourceFiles(.{
        .files = &app_sources,
        .flags = &app_flags,
    });

    const c_includes_core = [_][]const u8{"Core/Inc"};
    for (c_includes_core) |path| {
        exe_mod.addIncludePath(b.path(path));
    }

    exe_mod.addAssemblyFile(b.path("startup_stm32l476xx.s"));
    exe_mod.addCMacro("USE_HAL_DRIVER", "");
    exe_mod.addCMacro("STM32L476xx", "");

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    elf.setLinkerScript(b.path("stm32l476xx_flash.ld"));
    elf.lto = .none; // -flto. undefined symbol: vTaskSwitchContext when true.
    elf.link_data_sections = true; // -fdata-sections
    elf.link_function_sections = true; // -ffunction-sections
    elf.link_gc_sections = true; // -Wl,--gc-sections

    // Used for FreeRTOS when debugging with gdb/openocd
    elf.forceUndefinedSymbol("uxTopUsedPriority");

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Show section sizes inside binary files
    const size_prog: ?[]const u8 = b.findProgram(&.{"arm-none-eabi-size"}, &.{}) catch
        b.findProgram(&.{"llvm-size"}, &.{}) catch null;
    if (size_prog) |name| {
        const size_run = b.addSystemCommand(&[_][]const u8{
            name,
            "zig-out/bin/" ++ exe_name ++ ".elf",
        });
        const elf_install = b.addInstallArtifact(elf, .{});
        size_run.step.dependOn(&elf_install.step);
        b.getInstallStep().dependOn(&size_run.step);
    } else {
        std.log.warn("Could not find arm-none-eabi-size or llvm-size, skipping size step", .{});
    }

    // NOTE: There's currently some bugs with Zig's implementation of objcopy: https://github.com/ziglang/zig/issues/25653

    // Copy the bin out of the elf
    // const bin = b.addObjCopy(elf.getEmittedBin(), .{
    //     .format = .bin,
    // });
    // bin.step.dependOn(&elf.step);
    // const copy_bin = b.addInstallBinFile(bin.getOutput(), exe_name ++ ".bin");
    // b.getInstallStep().dependOn(&copy_bin.step);

    // // Copy the bin out of the elf
    // const hex = b.addObjCopy(elf.getEmittedBin(), .{
    //     .format = .hex,
    // });
    // hex.step.dependOn(&elf.step);
    // const copy_hex = b.addInstallBinFile(hex.getOutput(), exe_name ++ ".hex");
    // b.getInstallStep().dependOn(&copy_hex.step);

    // //Add st-flash command (https://github.com/stlink-org/stlink)
    // const flash_stlink = b.addSystemCommand(&[_][]const u8{
    //     "st-flash",
    //     "--reset",
    //     "--freq=4000k",
    //     "--format=ihex",
    //     "write",
    //     "zig-out/bin/" ++ exe_name ++ ".hex",
    // });

    // flash_stlink.step.dependOn(&bin.step);
    // const flash_step = b.step("flash", "Flash and run the firmware (stlink)");
    // flash_step.dependOn(&flash_stlink.step);

    const flash_openocd = b.addSystemCommand(&[_][]const u8{
        "openocd",
        "-c",
        "adapter speed 4000",
        "-f",
        "interface/stlink.cfg",
        "-f",
        "target/stm32l4x.cfg",
        "-c",
        "program zig-out/bin/" ++ exe_name ++ ".elf verify reset exit",
    });

    flash_openocd.step.dependOn(&elf.step);
    const flash_step_openocd = b.step("flash_openocd", "Flash and run the firmware (openocd)");
    flash_step_openocd.dependOn(&flash_openocd.step);

    // const clean_step = b.step("clean", "Remove .zig-cache");
    // clean_step.dependOn(&b.addRemoveDirTree(.{ .cwd_relative = b.install_path }).step);
    // if (builtin.os.tag != .windows) {
    //     clean_step.dependOn(&b.addRemoveDirTree(.{ .cwd_relative = b.pathFromRoot(".zig-cache") }).step);
    // }

    b.getInstallStep().dependOn(&elf.step);
    b.installArtifact(elf);
}
