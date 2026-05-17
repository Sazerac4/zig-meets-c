cmake_minimum_required(VERSION 3.22)
# Guard from multiple inclusion
include_guard(GLOBAL)
message("Use arm-none-eabi-gcc as compiler")

set(CMAKE_SYSTEM_NAME               Generic-ELF)
set(CMAKE_SYSTEM_PROCESSOR          arm)

set(CMAKE_EXECUTABLE_SUFFIX_ASM     ".elf")
set(CMAKE_EXECUTABLE_SUFFIX_C       ".elf")
set(CMAKE_EXECUTABLE_SUFFIX_CXX     ".elf")

# Optionally reduce compiler sanity check when cross-compiling.
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Some default GCC settings
set(TOOLCHAIN_PREFIX                arm-none-eabi-)

set(CMAKE_AR ${TOOLCHAIN_PREFIX}ar)
set(CMAKE_C_COMPILER ${TOOLCHAIN_PREFIX}gcc)
set(CMAKE_ASM_COMPILER ${CMAKE_C_COMPILER})
set(CMAKE_CXX_COMPILER ${TOOLCHAIN_PREFIX}g++)
set(CMAKE_OBJCOPY ${TOOLCHAIN_PREFIX}objcopy)
set(CMAKE_SIZE ${TOOLCHAIN_PREFIX}size)
set(CMAKE_RANLIB ${TOOLCHAIN_PREFIX}ranlib)
set(CMAKE_LINKER ${TOOLCHAIN_PREFIX}ld)
set(CMAKE_STRIP ${TOOLCHAIN_PREFIX}strip)

# Custom per langage parameters
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-rtti -fno-exceptions -fno-threadsafe-statics")
set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} -x assembler-with-cpp -MMD -MP")

# ##############################################################################
# Create the compiler interface
add_library(compiler INTERFACE)

# Cpu parameters
set(CPU_PARAMETERS -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mcpu=cortex-m4)
target_compile_options(compiler INTERFACE ${CPU_PARAMETERS} -fdata-sections -ffunction-sections -fno-common -fstack-usage)
target_compile_options(compiler INTERFACE -ftrack-macro-expansion=0 -fdiagnostics-color=always)

target_link_options(compiler INTERFACE
  ${CPU_PARAMETERS}
  --specs=nano.specs
  -Wl,--gc-sections
)
