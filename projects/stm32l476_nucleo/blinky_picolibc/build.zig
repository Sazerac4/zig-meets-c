const builtin = @import("builtin");
const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe_name = "blinky";

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
        .sanitize_c = if (optimization == .ReleaseSafe) true else false,
    });

    const elf = b.addExecutable(.{
        .name = exe_name ++ ".elf",
        .linkage = .static,
        .root_module = exe_mod,
    });

    // Libc integration
    elf.addLibraryPath(.{ .cwd_relative = "../../../libraries/picolibc/thumbv7e+fp/lib/" });
    elf.addSystemIncludePath(.{ .cwd_relative = "../../../libraries/picolibc/thumbv7e+fp/include" });
    elf.linkSystemLibrary("c_pico");
    elf.linkSystemLibrary("crt0");

    const c_sources_compile_flags = [_][]const u8{
        c_optimization,
        "-std=gnu17",
        "-Wall",
        "-Wextra",
    };

    const c_includes = [_][]const u8{
        "Drivers/STM32L4xx_HAL_Driver/Inc",
        "Drivers/STM32L4xx_HAL_Driver/Inc/Legacy",
        "Drivers/CMSIS/Device/ST/STM32L4xx/Include",
        "Drivers/CMSIS/Include",
    };

    for (c_includes) |path| {
        elf.addIncludePath(b.path(path));
    }

    elf.addCSourceFiles(.{
        .files = &.{
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
        },
        .flags = &c_sources_compile_flags,
    });

    elf.addCSourceFiles(.{
        .files = &.{
            "Core/Src/main.c",
            "Core/Src/gpio.c",
            "Core/Src/usart.c",
            "Core/Src/stm32l4xx_it.c",
            "Core/Src/stm32l4xx_hal_msp.c",
            "Core/Src/system_stm32l4xx.c",
            "Core/Src/syscalls.c",
        },
        .flags = &c_sources_compile_flags,
    });

    const c_includes_core = [_][]const u8{"Core/Inc"};
    for (c_includes_core) |path| {
        elf.addIncludePath(b.path(path));
    }

    exe_mod.addCMacro("USE_HAL_DRIVER", "");
    exe_mod.addCMacro("STM32L476xx", "");
    exe_mod.addCMacro("_PICOLIBC_PRINTF", "m");
    exe_mod.addCMacro("_PICOLIBC_SCANF", "m");

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    elf.setLinkerScript(b.path("stm32l476_picolibc.ld"));
    elf.entry = .{ .symbol_name = "_start" }; // Set Entry Point of the firmware (Already set in the linker script)
    elf.want_lto = false; // -flto
    elf.link_data_sections = true; // -fdata-sections
    elf.link_function_sections = true; // -ffunction-sections
    elf.link_gc_sections = true; // -Wl,--gc-sections

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

    // Copy the bin out of the elf
    const bin = b.addObjCopy(elf.getEmittedBin(), .{
        .format = .bin,
    });
    bin.step.dependOn(&elf.step);
    const copy_bin = b.addInstallBinFile(bin.getOutput(), exe_name ++ ".bin");
    b.getInstallStep().dependOn(&copy_bin.step);

    // Copy the bin out of the elf
    const hex = b.addObjCopy(elf.getEmittedBin(), .{
        .format = .hex,
    });
    hex.step.dependOn(&elf.step);
    const copy_hex = b.addInstallBinFile(hex.getOutput(), exe_name ++ ".hex");
    b.getInstallStep().dependOn(&copy_hex.step);

    //Add st-flash command (https://github.com/stlink-org/stlink)
    const flash_stlink = b.addSystemCommand(&[_][]const u8{
        "st-flash",
        "--reset",
        "--freq=4000k",
        "--format=ihex",
        "write",
        "zig-out/bin/" ++ exe_name ++ ".hex",
    });

    flash_stlink.step.dependOn(&bin.step);
    const flash_step = b.step("flash", "Flash and run the firmware");
    flash_step.dependOn(&flash_stlink.step);

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

    flash_openocd.step.dependOn(&bin.step);
    const flash_step_openocd = b.step("flash_openocd", "Flash and run the firmware");
    flash_step_openocd.dependOn(&flash_openocd.step);

    const clean_step = b.step("clean", "Remove .zig-cache");
    clean_step.dependOn(&b.addRemoveDirTree(.{ .cwd_relative = b.install_path }).step);
    if (builtin.os.tag != .windows) {
        clean_step.dependOn(&b.addRemoveDirTree(.{ .cwd_relative = b.pathFromRoot(".zig-cache") }).step);
    }

    b.getInstallStep().dependOn(&elf.step);
    b.installArtifact(elf);
}
