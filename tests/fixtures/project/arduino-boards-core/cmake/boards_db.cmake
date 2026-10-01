# Test board database in the format of Arduino_Core_STM32 cmake/boards_db.cmake
# (spec 4.9.10, TC-70): two candidates for one MCU and a malformed block.

# GENERIC_X123ABCXA
# -----------------------------------------------------------------------------

add_library(GENERIC_X123ABCXA INTERFACE)


# GENERIC_X123ABCXB
# -----------------------------------------------------------------------------

add_library(GENERIC_X123ABCXB INTERFACE)


# BROKEN_BOARD
# -----------------------------------------------------------------------------

set(BROKEN_BOARD_MCU cortex-m0)
