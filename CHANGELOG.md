# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- New exemple project code  `juicy_hello_world_cmake`

### Changed

- Move `@cImport` to the build system
- Set `.lto = .none`

### Removed

- [#25653](https://github.com/ziglang/zig/issues/25653). Objcopy not used temporarily.
- `@cImport` references removed


## [0.15.2] - 2026-03-29

### Changed

- `docker` used as default command
- Add missing `.editorconfig` files
- Regenerate every file with recent STM32CubeMX
- Container use `fedora:43` base image
- gcc-arm-none-eabi source change to ARM provider version to 15.2-rel1
- Picolibc bump version to 1.8.11
- Zig bump version to 0.15.2
- `.sanitize_c = .trap` used for all build type for smaller footprint

## [0.14.1] - 2025-08-21

### Added

- STM32F407 blinky example. Startup and vector table written in Zig.
- `@breakpoint();` to `defaultHandler` function.
- VSCode tasks for small and fast releases.
- `build.zig.zon` for all examples.
- CI workflow and script to build all projects.
- OpenOCD flash operations.
- Per-project `.clang-format-ignore` files (to exclude specific paths from formatting).

### Changed

- Enable the sanitizers only for safe release builds.
- Zig bump version to 0.14.1
- Picolibc bump version to 1.8.10
- Move picolibc into libraries folder.
- Set `want_lto=false` by default, as FreeRTOS and STM32F407 example experience symbol removal issues.
- Use `comptime` block to export vector table and startup code instead of exported functions 
- Updated STM32F407 example: First instruction now calls `ldr sp, =_estack` (matches assembler version behavior).
- Update the `ContainerFile` to mount the entire workspace. (Update `.gdbinit` files accordingly.)
- Update `.clangd`, `.clang-format` and `.clang-tidy` configurations.

### Fixed

- Change incorrect option from `-mfpu=fpv5-sp-d16` to `-mfpu=fpv4-sp-d16` when build picolibc for Cortex-M4.
- `@cDefine("__PROGRAM_START", {});` not needed anymore (fixed with Zig 0.14.1).
- Picolibc archive is now properly tracked (updated .gitignore).

### Removed

- Structure tree visualization: Removed due to useless maintenance effort.


## [0.14.0] - 2025-05-24

### Added

- Documentation for Windows and Vs Code has been started.
- A new example to demonstrate how to build and integrate the libc (picolibc).
- LICENSE file (MIT)
- `c_optimize` to override `-O0` in debug mode in the `build.zig` script.  
- `-Wextra` to C flags in the `build.zig` script.
- `myPanic` function for each example
- `arm-none-eabi-size` or `llvm-size` command to be executed after build.
- Safe build task with Vscode
- Description paragraph for each example
- Disable the sanitizer to reduce binary size in certain release configurations. `.sanitize_c = if (optimization == .Debug or optimization == .ReleaseFast) false else true,`.

### Changed

- This release updates examples to the most recent version of Zig. (0.14.0)
- Update Softwares, Drivers and Tools
- The container image has been improved (reduced image size, enhanced flash device support, and ELF debug capability).
- The general documentation and examples documentation have been improved.
- The organization of project examples has been changed. The project is now open to other platforms/targets.
- `addCMacro` is used for defining macros instead of using C flags.
- `callconv(.C)` to `callconv(.c)`
- `zigEntrypoint` with `callconv(.c)` attribute
- Use `b.getInstallStep()` instead of `b.default_step`

### Removed

- CMake is no longer used. The objective of this repository is to stay focused on Zig project integration.
- libc test Code in examples.

## [0.13.0] - 2024-06-11

- Tag 0.13.0 build version

### Added

- `cpu_features_add` added for each build.zig script.

### Removed

- `os_version_min` and `os_version_max` from build.zig
- `libfreertos.a`. We can build FreeRTOS now !
