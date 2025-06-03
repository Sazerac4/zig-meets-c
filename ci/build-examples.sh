#!/bin/sh
set -e
set -x

for project in \
    "projects/stm32f407g-disc1/blinky" \
    "projects/stm32l476_nucleo/blinky" \
    "projects/stm32l476_nucleo/blinky_freertos" \
    "projects/stm32l476_nucleo/blinky_picolibc"
do
    cd "${project}" || exit 1
    zig build || exit 1
    zig build --release=safe || exit 1
    zig build --release=small || exit 1
    zig build --release=fast || exit 1
    cd - >/dev/null
done
