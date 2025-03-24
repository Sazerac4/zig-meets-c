const builtin = @import("builtin");
const std = @import("std");

pub fn build(b: *std.Build) void {
    const executable_name = "blinky_freertos";

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

    // When you perform a Debug Release, the optimization level is set to -O0, which significantly increases the binary output size. This makes the Debug Release unsuitable
    // for devices with limited flash memory. To address this, we will override the optimization level with the -Og flag while leaving the other three optimization modes unchanged.
    const c_optimization = if (optimization == .Debug) "-Og" else if (optimization == .ReleaseSmall) "-Os" else "-O2";

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimization,
        .link_libc = false,
        .strip = false,
        .single_threaded = true, // single core cpu
    });

    const elf = b.addExecutable(.{
        .name = executable_name ++ ".elf",
        .linkage = .static,
        .root_module = exe_mod,
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
    elf.addLibraryPath(.{ .cwd_relative = gcc_arm_lib_path1 });
    elf.addLibraryPath(.{ .cwd_relative = gcc_arm_lib_path2 });
    elf.addSystemIncludePath(.{ .cwd_relative = b.fmt("{s}/include", .{gcc_arm_sysroot_path}) });
    elf.linkSystemLibrary("c_nano"); // Use "g_nano" (a debugging-enabled libc) ?
    elf.linkSystemLibrary("m");

    // Manually include C runtime objects bundled with arm-none-eabi-gcc
    elf.addObjectFile(.{ .cwd_relative = b.fmt("{s}/crt0.o", .{gcc_arm_lib_path2}) });
    elf.addObjectFile(.{ .cwd_relative = b.fmt("{s}/crti.o", .{gcc_arm_lib_path1}) });
    elf.addObjectFile(.{ .cwd_relative = b.fmt("{s}/crtbegin.o", .{gcc_arm_lib_path1}) });
    elf.addObjectFile(.{ .cwd_relative = b.fmt("{s}/crtend.o", .{gcc_arm_lib_path1}) });
    elf.addObjectFile(.{ .cwd_relative = b.fmt("{s}/crtn.o", .{gcc_arm_lib_path1}) });

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    const hal_mod = b.createModule(.{
        .target = target,
        .optimize = optimization,
        .link_libc = false,
        .strip = false,
        .single_threaded = true, // single core cpu
    });

    const hal_includes = [_][]const u8{ "Drivers/STM32L4xx_HAL_Driver/Inc", "Drivers/STM32L4xx_HAL_Driver/Inc/Legacy", "Drivers/CMSIS/Device/ST/STM32L4xx/Include", "Drivers/CMSIS/Include", "Core/Inc" };
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
    const hal_flags = [_][]const u8{ c_optimization, "-std=gnu17", "-Wall", "-Wextra" };

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
    });

    const os_includes = [_][]const u8{ "Middlewares/Third_Party/FreeRTOS/Source/include", "Middlewares/Third_Party/FreeRTOS/Source/CMSIS_RTOS_V2", "Middlewares/Third_Party/FreeRTOS/Source/portable/GCC/ARM_CM4F", "Drivers/STM32L4xx_HAL_Driver/Inc", "Drivers/STM32L4xx_HAL_Driver/Inc/Legacy", "Drivers/CMSIS/Device/ST/STM32L4xx/Include", "Drivers/CMSIS/Include", "Core/Inc" };

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
    const os_flags = [_][]const u8{ c_optimization, "-std=gnu17", "-Wall", "-Wextra" };

    for (os_includes) |path| {
        os_mod.addIncludePath(b.path(path));
    }
    os_mod.addCSourceFiles(.{
        .files = &os_sources,
        .flags = &os_flags,
    });

    //Need libc
    os_mod.addSystemIncludePath(.{ .cwd_relative = b.fmt("{s}/include", .{gcc_arm_sysroot_path}) });
    os_mod.linkSystemLibrary("c_nano", .{ .needed = true, .weak = false, .preferred_link_mode = .static });
    os_mod.addCMacro("USE_HAL_DRIVER", "");
    os_mod.addCMacro("STM32L476xx", "");

    //Add FreeRTOS to the executable
    exe_mod.addImport("FreeRTOS library", os_mod);

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    const app_includes = [_][]const u8{ "Middlewares/Third_Party/FreeRTOS/Source/include", "Middlewares/Third_Party/FreeRTOS/Source/CMSIS_RTOS_V2", "Middlewares/Third_Party/FreeRTOS/Source/portable/GCC/ARM_CM4F", "Drivers/STM32L4xx_HAL_Driver/Inc", "Drivers/STM32L4xx_HAL_Driver/Inc/Legacy", "Drivers/CMSIS/Device/ST/STM32L4xx/Include", "Drivers/CMSIS/Include", "Core/Inc" };
    for (app_includes) |path| {
        exe_mod.addIncludePath(b.path(path));
    }

    const app_sources = [_][]const u8{ "Core/Src/main.c", "Core/Src/gpio.c", "Core/Src/usart.c", "Core/Src/stm32l4xx_hal_timebase_tim.c", "Core/Src/freertos.c", "Core/Src/stm32l4xx_it.c", "Core/Src/stm32l4xx_hal_msp.c", "Core/Src/system_stm32l4xx.c", "Core/Src/sysmem.c", "Core/Src/syscalls.c", "Core/Src/freertos-openocd.c" };
    const app_flags = [_][]const u8{ c_optimization, "-std=gnu17", "-Wall", "-Wextra" };
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
    elf.setLinkerScript(b.path("stm32l476rgtx_flash.ld"));
    elf.want_lto = false; // -flto
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
        const objsize = b.addSystemCommand(&[_][]const u8{
            name,
            "zig-out/bin/" ++ executable_name ++ ".elf",
        });
        objsize.step.dependOn(&elf.step);
        b.default_step.dependOn(&objsize.step);
    } else {
        std.log.warn("'llvm-size' or 'arm-none-eabi-size' program not found", .{});
    }

    // Copy the bin out of the elf
    const bin = b.addObjCopy(elf.getEmittedBin(), .{
        .format = .bin,
    });
    bin.step.dependOn(&elf.step);
    const copy_bin = b.addInstallBinFile(bin.getOutput(), executable_name ++ ".bin");
    b.default_step.dependOn(&copy_bin.step);

    // Copy the bin out of the elf
    const hex = b.addObjCopy(elf.getEmittedBin(), .{
        .format = .hex,
    });
    hex.step.dependOn(&elf.step);
    const copy_hex = b.addInstallBinFile(hex.getOutput(), executable_name ++ ".hex");
    b.default_step.dependOn(&copy_hex.step);

    //Add st-flash command (https://github.com/stlink-org/stlink)
    const flash_cmd = b.addSystemCommand(&[_][]const u8{
        "st-flash",
        "--reset",
        "--freq=4000k",
        "--format=ihex",
        "write",
        "zig-out/bin/" ++ executable_name ++ ".hex",
    });

    flash_cmd.step.dependOn(&bin.step);
    const flash_step = b.step("flash", "Flash and run the app on your Nucleo-64");
    flash_step.dependOn(&flash_cmd.step);

    const clean_step = b.step("clean", "Remove .zig-cache");
    clean_step.dependOn(&b.addRemoveDirTree(.{ .cwd_relative = b.install_path }).step);
    if (builtin.os.tag != .windows) {
        clean_step.dependOn(&b.addRemoveDirTree(.{ .cwd_relative = b.pathFromRoot(".zig-cache") }).step);
    }

    b.default_step.dependOn(&elf.step);
    b.installArtifact(elf);
}
