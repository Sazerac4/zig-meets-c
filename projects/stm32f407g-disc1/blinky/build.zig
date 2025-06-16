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

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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
        .sanitize_c = if (optimization == .ReleaseSafe) true else false,
    });

    const hal_includes = [_][]const u8{
        "USB_HOST/App",
        "USB_HOST/Target",
        "Core/Inc",
        "Drivers/STM32F4xx_HAL_Driver/Inc",
        "Drivers/STM32F4xx_HAL_Driver/Inc/Legacy",
        "Middlewares/ST/STM32_USB_Host_Library/Core/Inc",
        "Middlewares/ST/STM32_USB_Host_Library/Class/CDC/Inc",
        "Drivers/CMSIS/Device/ST/STM32F4xx/Include",
        "Drivers/CMSIS/Include",
    };

    for (hal_includes) |path| {
        hal_mod.addIncludePath(b.path(path));
    }

    hal_mod.addCSourceFiles(.{
        .files = &.{
            "Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_hcd.c",
            "Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_ll_usb.c",
            "Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_rcc.c",
            "Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_rcc_ex.c",
            "Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_flash.c",
            "Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_flash_ex.c",
            "Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_flash_ramfunc.c",
            "Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_gpio.c",
            "Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_dma_ex.c",
            "Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_dma.c",
            "Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_pwr.c",
            "Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_pwr_ex.c",
            "Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_cortex.c",
            "Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal.c",
            "Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_exti.c",
            "Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_i2c.c",
            "Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_i2c_ex.c",
            "Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_i2s.c",
            "Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_i2s_ex.c",
            "Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_spi.c",
        },
        .flags = &.{
            c_optimization,
            "-std=gnu17",
            "-Wall",
            "-Wextra",
        },
    });

    exe_mod.addImport("HAL library", hal_mod);
    hal_mod.addCMacro("USE_HAL_DRIVER", "");
    hal_mod.addCMacro("STM32F407xx", "");

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    const mw_mod = b.createModule(.{
        .target = target,
        .optimize = optimization,
        .link_libc = false,
        .strip = false,
        .single_threaded = true, // single core cpu
        .sanitize_c = if (optimization == .ReleaseSafe) true else false,
    });

    const mw_includes = [_][]const u8{
        "USB_HOST/App",
        "USB_HOST/Target",
        "Core/Inc",
        "Drivers/STM32F4xx_HAL_Driver/Inc",
        "Drivers/STM32F4xx_HAL_Driver/Inc/Legacy",
        "Middlewares/ST/STM32_USB_Host_Library/Core/Inc",
        "Middlewares/ST/STM32_USB_Host_Library/Class/CDC/Inc",
        "Drivers/CMSIS/Device/ST/STM32F4xx/Include",
        "Drivers/CMSIS/Include",
    };

    for (mw_includes) |path| {
        mw_mod.addIncludePath(b.path(path));
    }

    mw_mod.addCSourceFiles(.{
        .files = &.{
            "USB_HOST/Target/usbh_conf.c",
            "USB_HOST/Target/usbh_platform.c",
            "USB_HOST/App/usb_host.c",
            "Middlewares/ST/STM32_USB_Host_Library/Core/Src/usbh_core.c",
            "Middlewares/ST/STM32_USB_Host_Library/Core/Src/usbh_ctlreq.c",
            "Middlewares/ST/STM32_USB_Host_Library/Core/Src/usbh_ioreq.c",
            "Middlewares/ST/STM32_USB_Host_Library/Core/Src/usbh_pipes.c",
            "Middlewares/ST/STM32_USB_Host_Library/Class/CDC/Src/usbh_cdc.c",
        },
        .flags = &.{
            c_optimization,
            "-std=gnu17",
            "-Wall",
            "-Wextra",
        },
    });

    exe_mod.addImport("Middlewares library", mw_mod);
    mw_mod.addSystemIncludePath(.{ .cwd_relative = b.fmt("{s}/include", .{gcc_arm_sysroot_path}) }); //Need libc includes
    mw_mod.addCMacro("USE_HAL_DRIVER", "");
    mw_mod.addCMacro("STM32F407xx", "");

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    exe_mod.addCSourceFiles(.{
        .files = &.{
            "Core/Src/main.c",
            "Core/Src/gpio.c",
            "Core/Src/i2c.c",
            "Core/Src/i2s.c",
            "Core/Src/spi.c",
            "Core/Src/stm32f4xx_it.c",
            "Core/Src/stm32f4xx_hal_msp.c",
            "Core/Src/system_stm32f4xx.c",
            "Core/Src/sysmem.c",
            "Core/Src/syscalls.c",
        },
        .flags = &.{
            c_optimization,
            "-std=gnu17",
            "-Wall",
            "-Wextra",
        },
    });

    const app_includes = [_][]const u8{
        "USB_HOST/App",
        "USB_HOST/Target",
        "Core/Inc",
        "Drivers/STM32F4xx_HAL_Driver/Inc",
        "Drivers/STM32F4xx_HAL_Driver/Inc/Legacy",
        "Middlewares/ST/STM32_USB_Host_Library/Core/Inc",
        "Middlewares/ST/STM32_USB_Host_Library/Class/CDC/Inc",
        "Drivers/CMSIS/Device/ST/STM32F4xx/Include",
        "Drivers/CMSIS/Include",
    };

    for (app_includes) |path| {
        exe_mod.addIncludePath(b.path(path));
    }

    exe_mod.addCMacro("USE_HAL_DRIVER", "");
    exe_mod.addCMacro("STM32F407xx", "");
    elf.setLinkerScript(b.path("stm32f407xx_flash.ld"));
    elf.want_lto = false; // -flto. g_pfnVectors will be discarded if set to true.
    elf.link_data_sections = true; // -fdata-sections
    elf.link_function_sections = true; // -ffunction-sections
    elf.link_gc_sections = true; // -Wl,--gc-sections

    // Even if the linker script set the entrypoint, set it here can avoid the symbol to be discarded when want_lto is true.
    elf.entry = .{ .symbol_name = "resetHandler" };

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
        "target/stm32f4x.cfg",
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
