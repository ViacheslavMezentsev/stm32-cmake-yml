set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
set(CMAKE_C_COMPILER "$ENV{STM32_TOOLCHAIN_PATH}/bin/arm-none-eabi-gcc")
set(CMAKE_CXX_COMPILER "$ENV{STM32_TOOLCHAIN_PATH}/bin/arm-none-eabi-g++")
set(CMAKE_ASM_COMPILER "${CMAKE_C_COMPILER}")
find_program(CMAKE_OBJCOPY arm-none-eabi-objcopy REQUIRED)
find_program(CMAKE_SIZE arm-none-eabi-size REQUIRED)

# The framework expects this helper from the consumer's toolchain, as in the
# mcu_lts_board example. Keep an actual size target, not a no-op test stub.
function(stm32_print_size_of_target TARGET)
    add_custom_target(${TARGET}_always_display_size ALL
        COMMAND "${CMAKE_SIZE}" "$<TARGET_FILE:${TARGET}>"
        DEPENDS ${TARGET} VERBATIM)
endfunction()
