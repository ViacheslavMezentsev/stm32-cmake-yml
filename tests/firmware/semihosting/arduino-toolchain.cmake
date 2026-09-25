# Standalone consumer toolchain: no stm32-cmake dependency.
include("${CMAKE_CURRENT_LIST_DIR}/../../toolchains/arduino.cmake")
find_program(CMAKE_OBJDUMP arm-none-eabi-objdump REQUIRED)
function(smoke_artifact TARGET EXT FORMAT)
    add_custom_command(TARGET ${TARGET} POST_BUILD
        COMMAND "${CMAKE_OBJCOPY}" -O ${FORMAT} "$<TARGET_FILE:${TARGET}>" "${TARGET}.${EXT}"
        BYPRODUCTS "${TARGET}.${EXT}" VERBATIM)
endfunction()
function(stm32_generate_binary_file TARGET)
    smoke_artifact(${TARGET} bin binary)
endfunction()
function(stm32_generate_hex_file TARGET)
    smoke_artifact(${TARGET} hex ihex)
endfunction()
