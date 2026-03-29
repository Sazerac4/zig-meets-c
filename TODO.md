# TODO

- [X] ~~Add a way to generate map file (equivalent to -Wl,-Map=<name>.map,--cref)~~ Option not available with clang
- [ ] Add a memory view if possible equivalent to (-Wl,--print-memory-usage) after build an example
- [ ] Generate `compile_commands.json` with Zig
- [ ] Improve libc Integration
- [ ] Create HAL and LL drivers as separate Zig module
- [ ] Improve FreeRTOS example with an interface abstraction to avoid problems with macros translation.
- [X] Add CI to compile every example.
- [ ] Add different examples code (e.g:hello world with UART)
- [X] Custom Panic function to implement for runtime error (using UART interface)
- [ ] Add Testing unit using Zig
- [X] Update `.clang-format` to correspond to Zig style guide.
- [ ] Test with arm gcc from offical website and from packaging system (fedora and debian) 
- [ ] Add NRF52 target. nrf-connect sdk (It use Zephyr)
- [ ] Add ESP32 target. Start with RISC-V target only with esp-idf sdk 
- [ ] Add PI pico target. It is use pico-sdk and picotools. Found an implementation strategy effortless.
