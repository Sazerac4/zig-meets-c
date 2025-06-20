#!/bin/sh
set -e
set -x

for project in \
    "projects/stm32f407g-disc1/blinky" \
    "projects/stm32l476_nucleo/blinky" \
    "projects/stm32l476_nucleo/blinky_freertos" \
    "projects/stm32l476_nucleo/blinky_picolibc"
do
    cd "${project}"
    #If you use local container to build, delete the current cache.
    rm -rf -- ./.zig-cache 
    zig build
    zig build --release=safe 
    zig build --release=small
    zig build --release=fast
    cd - >/dev/null
done
