# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Documentation for Windows and Vs Code has been started.
- A new example to demonstrate how to build and integrate the libc (picolibc).
- LICENSE file (MIT)
- `c_optimization` to override `-O0` in debug mode in the `build.zig` script.  
- `-Wextra` to C flags in the `build.zig` script.
- `myPanic` function for each example
- `arm-none-eabi-size` or `llvm-size` command to be executed after build.
- Safe build task with Vscode
- Description paragraph for each example

### Changed

- This release updates examples to the most recent version of Zig. (0.14.0)
- Update Softwares, Drivers and Tools
- The container image has been improved (reduced image size, enhanced flash device support, and ELF debug capability).
- The general documentation and examples documentation have been improved.
- The organization of project examples has been changed. The project is now open to other platforms/targets.
- `addCMacro` is used for defining macros instead of using C flags.
- `callconv(.C)` to `callconv(.c)`
- `zigEntrypoint` with `callconv(.c)` attribute

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
