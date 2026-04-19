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
    const optimize = b.standardOptimizeOption(.{});

    // In Debug Release, the default optimization level is set to -O0, which significantly increases the binary size.
    // We override the optimization level with -Og while keeping the other three optimization modes unchanged.
    const c_optimize = if (optimize == .Debug) "-Og" else if (optimize == .ReleaseSmall) "-Os" else "-O2";

    const translate_c = b.addTranslateC(.{
        .root_source_file = b.path("src/stm_interface.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = false,
    });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = false,
        .strip = false,
        .single_threaded = true, // single core cpu
        .sanitize_c = .trap,
        .imports = &.{
            .{
                .name = "c",
                .module = translate_c.createModule(),
            },
        },
    });

    const elf = b.addExecutable(.{
        .name = exe_name ++ ".elf",
        .linkage = .static,
        .root_module = exe_mod,
        .use_lld = true,
        .use_llvm = true,
    });

    // Libc integration
    exe_mod.addLibraryPath(.{ .cwd_relative = "../../../libraries/picolibc/thumbv7e+fp/lib/" });
    exe_mod.addSystemIncludePath(.{ .cwd_relative = "../../../libraries/picolibc/thumbv7e+fp/include" });
    exe_mod.linkSystemLibrary("c_pico", .{
        .needed = true,
        .preferred_link_mode = .static,
        .use_pkg_config = .no,
    });
    exe_mod.linkSystemLibrary("crt0", .{
        .needed = true,
        .preferred_link_mode = .static,
        .use_pkg_config = .no,
    });

    const c_sources_compile_flags = [_][]const u8{
        c_optimize,
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
        exe_mod.addIncludePath(b.path(path));
        translate_c.addIncludePath(b.path(path));
    }

    exe_mod.addCSourceFiles(.{
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

    exe_mod.addCSourceFiles(.{
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
        exe_mod.addIncludePath(b.path(path));
        translate_c.addIncludePath(b.path(path));
    }

    exe_mod.addCMacro("USE_HAL_DRIVER", "");
    exe_mod.addCMacro("STM32L476xx", "");
    exe_mod.addCMacro("_PICOLIBC_PRINTF", "m");
    exe_mod.addCMacro("_PICOLIBC_SCANF", "m");

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    elf.setLinkerScript(b.path("stm32l476_picolibc.ld"));
    elf.entry = .{ .symbol_name = "_start" }; // Set Entry Point of the firmware (Already set in the linker script)
    elf.lto = .none; // -flto
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
    // const flash_step = b.step("flash", "Flash and run the firmware");
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
    const flash_step_openocd = b.step("flash_openocd", "Flash and run the firmware");
    flash_step_openocd.dependOn(&flash_openocd.step);

    b.getInstallStep().dependOn(&elf.step);
    b.installArtifact(elf);
}
