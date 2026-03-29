## Picolibc Build 

### Prerequisite

The container is used to build picolibc. See the prerequisites in the `Containerfile`.

### Build with container

```bash
# Go to the library folder
cd libraries/picolibc
# Create the image
podman build -f ContainerFile --tag=picolibc .
# Run a container
podman run --rm -it -v ./:/workspace --name=picolibc picolibc
# Configure
mkdir -p build && cd build
meson setup --cross-file /workspace/cross-clang-thumbv7e+fp-custom.txt \
    --prefix=/workspace/thumbv7e+fp \
    -Dtests=false \
    -Dpicocrt=true \
    -Ddebug=false \
    -Doptimization=s \
    -Dinitfini=true \
    /picolibc

# Install
ninja install
# Rename the libc (The following line is explained below)
mv /workspace/thumbv7e+fp/lib/libc.a /workspace/thumbv7e+fp/lib/libc_pico.a
```

### Build it with other CPU Parameters

You need to create a Meson configuration file, such as mine `cross-clang-thumbv7e+fp-custom.txt`, and modify these parameters according to your needs:

```
-mcpu=cortex-m4
-mfloat-abi=hard
-mfpu=fpv4-sp-d16
```

### Integrating the libc with Your Zig Script

If you compile your Zig program using `elf.linkSystemLibrary("c");` or if your module has the option `.link_libc = true,`, you may encounter the following error:

```bash
error: libc not available
    note: run 'zig libc -h' to learn about libc installations
    note: run 'zig targets' to see the targets for which zig can always provide libc
```

Zig does not currently allow you to customize your own libc implementation. For more details, see this [GitHub issue](https://github.com/ziglang/zig/issues/20327) discussing the topic. However, there is a workaround: you can rename the libc library and link it manually.

For example:
```bash
mv libc/lib/libc.a libc/lib/libc_pico.a
```

Then, change `elf.linkSystemLibrary("c");` to `elf.linkSystemLibrary("c_pico");`.

Now it is compile, however zig code will not benefit of libc implementation, only the `C` sources files.

### Picolibc Linker Script

Picolibc provides two linker script `picolibc.ld` and `picolibcpp.ld` that is used during the linking process. You can use it with Zig's linker (`lld`) without modification because we have build picolibc with clang/lld.
A minimal linker script for Our target is simpler:

```ld
/* This will override default value provided by picolibc (mandatory) */
__flash = 0x08000000;
__flash_size = 1024K;
__ram = 0x20000000;
__ram_size = 96K;
__stack_size = 512;

INCLUDE libc/lib/picolibc.ld
```

Picolibc got some options to choices for `printf` and `scanf`. You need to use `-Wl,--defsym` or `-Wl,-alias` linker arguments. With Zig, the linker script will be preferred :

```ld
/* Printf and Scanf Options. Equivalent to --defsym  */
vfprintf = __m_vfprintf; /*disable*/
vfscanf = __m_vfscanf; /*disable*/

/* Printf and Scanf Options. Equivalent to -alias */
/* PROVIDE(vfprintf = __m_vfprintf); */
/* PROVIDE(vfscanf = __m_vfscanf); */
```

Picolibc requires the preprocessor definitions `-D_PICOLIBC_PRINTF='m'` and `-D_PICOLIBC_SCANF='m'`. These can be set using the `addCMacro` function.

```zig
exe_mod.addCMacro("_PICOLIBC_PRINTF", "m");
exe_mod.addCMacro("_PICOLIBC_SCANF", "m");
```
The configuration above disables floating-point printf/scanf support during application builds. You can modify this option as needed. [Reference](https://github.com/picolibc/picolibc/blob/1.8.10/doc/printf.md).

**Adapt the linker script from STM32CubeMX**

Target linker script now can just specify flash memory option, extra section and so on. See the new linker script `stm32l476rgtx_flash.ld` that add information about the second ram section `.ram2` and set formatting options.

### Update the startup and the Vector Table

I created my own startup file `vector_table.zig` with modifications for picolibc integration. You can see the assembler and C implementations under the folder `vector_table_examples`. Here is what needs to be changed from the original file `startup_stm32l476xx.s`:

1. Rename `g_pfnVectors` to `__interrupt_vector`. The reference can be used by picolibc
2. Rename `.isr_vector` section to `.text.init.enter`
3. Rename stack start  `_estack`  by `__stack`
4. Rename the entrypoint  `Reset_Handler` to `_start` in the `__interrupt_vector` table
5. Remove the `Reset_Handler` and `LoopForever` function.
6. Remove symbol `_sidata`, `_sdata`, `_edata`, `_sbss`, `_ebss`

---

You can note that the instruction `ldr   sp, =__stack` is not used anymore . This instruction is used by ARM architecture to initialize the stack pointer.
For STM32 microcontrollers (and many other ARM Cortex-M-based microcontrollers), the stack pointer is automatically initialized by the hardware using a specific memory address defined in the vector table (here `0x08000000`)

I don’t know exactly why this instruction is in the template (it might be for historical or compatibility reasons), but you can remove it without any issues.
One example where it might be needed is when you have a bootloader and your starting address changes (e.g., `0x08010000`). However, in such cases, you would typically set the new vector table before jumping to the application in the bootloader.

## Notes

- Main article about this picolibc implementation: [Ziggit topic](https://ziggit.dev/t/adding-picolibc-for-embedded-stm32-example/8421)
- For an interesting discussion on integrating Picolibc or alternative libc implementations for embedded systems, check out this [Ziggit topic](https://ziggit.dev/t/adding-picolibc-or-alternative-for-embedded/).
- For more context on integrating custom libc implementations, see this [GitHub issue](https://github.com/ziglang/zig/issues/20327).
- Effort to make compatible Zig with meson build system. [GitHub issue](https://github.com/mesonbuild/meson/issues/12652)
