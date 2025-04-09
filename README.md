# Zig Meets C: Cross-Language Development for Embedded Microcontrollers

- [Zig Meets C: Cross-Language Development for Embedded Microcontrollers](#zig-meets-c-cross-language-development-for-embedded-microcontrollers)
  - [Description](#description)
  - [Embedded Related Point](#embedded-related-point)
  - [Examples List](#examples-list)
  - [Installation](#installation)
    - [Linux](#linux)
    - [Windows](#windows)
    - [Vs Code / Vs Codium](#vs-code--vs-codium)
    - [Containers (Podman or Docker)](#containers-podman-or-docker)
  - [SVD Files](#svd-files)
  - [Build](#build)
  - [Resources](#resources)


## Description

[Zig](https://ziglang.org/) is a language that seems perfect for embedded systems programming, and you might be considering incorporating Zig code into your embedded development projects. However, there are several reasons why you might not want just to start a project with it.

- You use a manufacturer-specific software generator (e.g., STM32CubeMX) to simplify device initialization and peripheral configuration. The generated code is in C.
- The project already exists, and rewriting it is not an option.
- Your future project rely heavily on C-based components, such as operating systems (e.g., FreeRTOS), filesystems (e.g., LittleFS), libraries, drivers, etc. You don’t want to rewrite initialization or configuration routines that already work well and are widely used elsewhere.
- You work with coworkers who will maintain, update, and/or test parts of the project's C code. They may not use Zig—either not yet or never.

This repository explores the integration of Zig into microcontroller development projects that are already written in C, covering both bare-metal and OS-based environments. It provides practical examples, tutorials, and tools to help developers combine the power of Zig's modern features with the established C ecosystem.

This is a work in progress, and help is welcome to add more examples, improve documentation, or provide corrections.

## Embedded Related Point 

- Using the libc with C code is currently a workaround, and Zig code will ignore it for now. However, this will likely be possible in the near future ([Zig Issue](https://github.com/ziglang/zig/issues/20327)).  
- JSON Compilation Database, which is used with many C tools (e.g., linters, LSPs, IDE,etc.), will soon be supported. [Zig issue](https://github.com/ziglang/zig/pull/22012).  
- `@cImport` is planned to work differently in the future. For more details, see this [Zig issue](https://github.com/ziglang/zig/issues/20630).
- [Translate-C](https://github.com/ziglang/zig/labels/translate-c) command (and `@cImport`) has difficulty translating some C declarations and macros found in Embedded Drivers or CMSIS files.
- `Debug` Release mode without optimizations can make binary too huge to fit in the device.
- Huge binary in debug Mode. No option to have ubsan with trap instead of runtime (0.14.0). See this [issue](https://github.com/ziglang/zig/issues/23216) and this [topic](https://ziggit.dev/t/huge-binary-freestanding-stm32-zig-0-14-0/9308)

## Examples List

The examples are built for a specific target. However, the documentation will try to explain enough about what Zig implies to change in an example so that you can figure out what you need to change when applying it to other targets (with more or less difficulty).

1. Blinky Example 
2. Blinky Example with PicolibC build
3. Blinky Example with FreeRTOS 

**Project tree**

```
projects/
└── stm32l476_nucleo/
    ├── blinky/
    ├── blinky_picolibc/
    └── blinky_freertos/
```

## Installation

List of tools that is used around examples

| Name              | Version   | Description                                                             |
| :---------------- | --------- | :---------------------------------------------------------------------- |
| Zig               | `0.14.0`  | For compiling C and Zig code                                            |
| ZLS               | `0.14.0`  | Language Server Protocol for Zig                                        |
| Arm GNU Toolchain | `14.2.1`  | Tools for C development (gdb, binutils) and libc                        |
| LLVM+Clang        | `19.1.7`  | Tools for C development (clang-format, clang-tidy, clangd)              |
| ST link           | `v1.8.0`  | For flashing firmware                                                   |
| OpenOCD           | `v0.12.0` | To provide debugging                                                    |
| STM32CubeMX       | `6.13.0`  | For the generation of the corresponding initialization C code for STM32 |


Some of theses tools are downloaded from the [xPack Binary Development Tools](https://xpack-dev-tools.github.io/) project.

### Linux

```bash
#Fedora
yum install wget stlink openocd clang-tools-extra clang
#Debian
apt install xz-utils wget stlink-tools openocd clang-tools clang-tidy clang-format

#Create tools folder
mkdir -vp /opt/tools

#Install Arm GNU Toolchain (xpack version)
GCC_VERSION="14.2.1-1.1"
cd /tmp && wget https://github.com/xpack-dev-tools/arm-none-eabi-gcc-xpack/releases/download/v${GCC_VERSION}/xpack-arm-none-eabi-gcc-${GCC_VERSION}-linux-x64.tar.gz \
    && tar -xf /tmp/xpack-arm-none-eabi-gcc-*-linux-x64.tar.gz -C /opt/tools/ \
    && ln -s /opt/tools/xpack-arm-none-eabi-gcc-*/bin/arm-none-eabi-*  ~/.local/bin

#Install Zig
ZIG_VERSION="0.14.0"
cd /tmp && wget https://ziglang.org/builds/zig-linux-x86_64-${ZIG_VERSION}.tar.xz && \
    tar -xf /tmp/zig-linux-x86_64-*.tar.xz -C /opt/tools/ && \
    ln -s /opt/tools/zig-linux-x86_64-*/zig ~/.local/bin

#Install ZLS
ZLS_VERSION="0.14.0"
cd /tmp && wget https://github.com/zigtools/zls/releases/download/${ZLS_VERSION}/zls-linux-x86_64-${ZLS_VERSION}.tar.xz && \
    mkdir -p /opt/tools/zls-linux-x86_64-${ZLS_VERSION} && tar -xf /tmp/zls-linux-x86_64-${ZLS_VERSION}.tar.xz -C /opt/tools/zls-linux-x86_64-${ZLS_VERSION} && \
    ln -s /opt/tools/zls-linux-x86_64-${ZLS_VERSION}/zls ~/.local/bin
```

### Windows

For Windows users,  Information available in this [document](docs/windows.md) to setup your environnement.

### Vs Code / Vs Codium

For Vs Code users, Information available in this [document](docs/vscode.md) for configurations

### Containers (Podman or Docker)

Instead of installing the various tools in your system, you can use containers to build or flash the firmware.
Two technologies exist, both CLI APIs are mostly compatible: Docker and Podman. I use `podman` for my examples, but you can simply replace it with `docker` if you prefer.

```bash
#Create the image
podman build -f ContainerFile --tag=zig_and_c:0.14.0 .
#Run a container
podman run --rm -it --privileged -v ./projects:/apps --name=zig_and_c zig_and_c:0.14.0
# Navigate to a project (example blinky)
cd stm32l476_nucleo/blinky
# Build the firmware
zig build
# Flash the device (Linux only)
zig build flash
```

Remove dangling image if needed `podman image prune`

## SVD Files

The CMSIS System View Description format(CMSIS-SVD) formalizes the description of the system contained in Arm Cortex-M processor-based microcontrollers, in particular, the memory mapped registers of peripherals.

- You can use [regz](https://github.com/ZigEmbeddedGroup/microzig/tree/main/tools/regz) to generate `registers` code in Zig.
- You can use it with VS Code in debugging mode.

<img src="docs/images/vscode1.png" alt="drawing" width="50%"/>

You can found stm32 SVD files in this [Github repository](https://github.com/modm-io/cmsis-svd-stm32)

## Build

All projects use the [Zig Build System](https://ziglang.org/learn/build-system/).  
Check the `README.md` of an project example for additional specific information.

## Resources

- [Zig Guide: working with C](https://zig.guide/working-with-c/abi/) A Guide to learn the Zig Programming Language
- [Ziggit](https://ziggit.dev/) A community for anyone interested in the Zig Programming Language.
- [STM32 Guide](https://github.com/haydenridd/stm32-zig-porting-guide) will help you to understand and port your current project with different level of Zig integration.  [Ziggit topic](https://ziggit.dev/t/stm32-porting-guide-first-pass/4414).
- [Zig Embedded Group](https://github.com/ZigEmbeddedGroup) A group of people dedicated to improve the Zig Embedded Experience
- [All Your Codebase](https://github.com/allyourcodebase) is an organization that package C/C++ projects for the Zig build system so that you can reliably compile (and cross-compile!) them with ease.
- [Awesome Zig](https://github.com/zigcc/awesome-zig?tab=readme-ov-file) This repository lists "awesome" projects written in Zig, maintained by ZigCC community.
