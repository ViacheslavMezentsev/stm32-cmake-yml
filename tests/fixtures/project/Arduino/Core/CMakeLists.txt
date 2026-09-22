# Minimal consumer-owned wrapper: tests wiring to real core sources, not a full
# Arduino board implementation. Full firmware compilation is a later stage.
add_library(ArduinoCore STATIC "${ARDUINO_CORE_DIR}/cores/arduino/wiring_digital.c")
add_library(Arduino::Core ALIAS ArduinoCore)
target_include_directories(ArduinoCore PUBLIC "${ARDUINO_CORE_DIR}/cores/arduino")
target_link_libraries(ArduinoCore PUBLIC Arduino::Definitions)
