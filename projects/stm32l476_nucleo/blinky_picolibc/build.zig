const builtin = @import("builtin");
const std = @import("std");

pub fn build(b: *std.Build) void {
    const executable_name = "blinky";

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
        .sanitize_c = if (optimization == .Debug) false else true,
    });

    const elf = b.addExecutable(.{
        .name = executable_name ++ ".elf",
        .linkage = .static,
        .root_module = exe_mod,
    });

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    elf.addLibraryPath(.{ .cwd_relative = "libc/lib/" });
    elf.addSystemIncludePath(.{ .cwd_relative = "libc/include" });
    elf.linkSystemLibrary("c_pico");
    elf.linkSystemLibrary("crt0");

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    const c_includes = [_][]const u8{ "Drivers/STM32L4xx_HAL_Driver/Inc", "Drivers/STM32L4xx_HAL_Driver/Inc/Legacy", "Drivers/CMSIS/Device/ST/STM32L4xx/Include", "Drivers/CMSIS/Include" };
    const c_sources_drivers = [_][]const u8{
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
    const c_sources_compile_flags = [_][]const u8{ c_optimization, "-std=gnu17", "-Wall", "-Wextra" };

    //////////////////////////////////////////////////////////////////
    for (c_includes) |path| {
        elf.addIncludePath(b.path(path));
    }

    elf.addCSourceFiles(.{
        .files = &c_sources_drivers,
        .flags = &c_sources_compile_flags,
    });

    //////////////////////////////////////////////////////////////////
    const c_sources_core = [_][]const u8{
        "Core/Src/main.c",
        "Core/Src/gpio.c",
        "Core/Src/usart.c",
        "Core/Src/stm32l4xx_it.c",
        "Core/Src/stm32l4xx_hal_msp.c",
        "Core/Src/system_stm32l4xx.c",
        "Core/Src/syscalls.c",
    };
    elf.addCSourceFiles(.{
        .files = &c_sources_core,
        .flags = &c_sources_compile_flags,
    });

    const c_includes_core = [_][]const u8{"Core/Inc"};
    for (c_includes_core) |path| {
        elf.addIncludePath(b.path(path));
    }

    //////////////////////////////////////////////////////////////////
    exe_mod.addCMacro("USE_HAL_DRIVER", "");
    exe_mod.addCMacro("STM32L476xx", "");

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    elf.setLinkerScript(b.path("stm32l476rgtx_flash.ld"));
    elf.entry = .{ .symbol_name = "_start" }; // Set Entry Point of the firmware (Already set in the linker script)
    elf.want_lto = true; // -flto
    elf.link_data_sections = true; // -fdata-sections
    elf.link_function_sections = true; // -ffunction-sections
    elf.link_gc_sections = true; // -Wl,--gc-sections

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
    const flash_step = b.step("flash", "Flash and run the firmware");
    flash_step.dependOn(&flash_cmd.step);

    const clean_step = b.step("clean", "Remove .zig-cache");
    clean_step.dependOn(&b.addRemoveDirTree(.{ .cwd_relative = b.install_path }).step);
    if (builtin.os.tag != .windows) {
        clean_step.dependOn(&b.addRemoveDirTree(.{ .cwd_relative = b.pathFromRoot(".zig-cache") }).step);
    }

    b.default_step.dependOn(&elf.step);
    b.installArtifact(elf);
}
