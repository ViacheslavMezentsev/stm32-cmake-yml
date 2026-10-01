# Standalone consumer toolchain: no stm32-cmake dependency. The framework builds
# bin, hex and srec itself (spec 4.14.2, 5.2.2); no stm32_generate_* functions.
include("${CMAKE_CURRENT_LIST_DIR}/../../toolchains/arduino.cmake")
find_program(CMAKE_OBJDUMP arm-none-eabi-objdump REQUIRED)
