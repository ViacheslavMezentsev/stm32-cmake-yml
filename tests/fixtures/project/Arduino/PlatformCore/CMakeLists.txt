# Wrapper linked only to Arduino::Platform (spec 4.9.15, TC-72): family-independent.
if(TARGET Arduino::Platform)
    add_library(ArduinoCore STATIC
        "${ARDUINO_CORE_DIR}/cores/arduino/wiring_digital.c"
        "${ARDUINO_CORE_DIR}/cores/arduino/WString.cpp")
    target_link_libraries(ArduinoCore PUBLIC Arduino::Platform)
else()
    add_library(ArduinoCore INTERFACE)
    target_link_libraries(ArduinoCore INTERFACE Arduino::Definitions)
endif()
add_library(Arduino::Core ALIAS ArduinoCore)
