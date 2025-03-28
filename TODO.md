# TODO

- [X] ~~Add a way to generate map file (equivalent to -Wl,-Map=<name>.map,--cref)~~ Option not available with clang
- [ ] Add a memory view if possible equivalent to (-Wl,--print-memory-usage)
- [ ] Generate `compile_commands.json` with Zig
- [ ] Improve libc Integration
- [ ] Create HAL and LL drivers as separate Zig module
- [ ] Improve FreeRTOS example with an interface abstraction to avoid problems with macros translation.
- [ ] Add CI to compile every example.
- [ ] Add more examples code ()
- [ ] Add more target (nrf52, raspberry pi pico)
- [X] Custom Panic function to implement for runtime error (using UART interface)
- [ ] Add Testing unit using Zig
- [ ] Update `.clang-format` to correspond to Zig style guide.
