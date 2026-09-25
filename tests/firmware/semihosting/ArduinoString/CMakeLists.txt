# Deliberately selected software components, not the complete board core.
if(USE_CORE_MAIN OR NOT MCU_TARGET STREQUAL "F103")
    message(FATAL_ERROR "Arduino String smoke requires own main and F103")
endif()
add_library(ArduinoCore STATIC
    "${ARDUINO_CORE_DIR}/cores/arduino/WString.cpp"
    "${ARDUINO_CORE_DIR}/cores/arduino/itoa.c")
add_library(Arduino::Core ALIAS ArduinoCore)
target_include_directories(ArduinoCore PUBLIC "${ARDUINO_CORE_DIR}/cores/arduino")
target_link_libraries(ArduinoCore PUBLIC Arduino::Definitions)
set_target_properties(ArduinoCore PROPERTIES C_STANDARD 11 CXX_STANDARD 17)
