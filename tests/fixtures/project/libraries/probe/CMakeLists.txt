add_library(ArduinoProbe STATIC probe.cpp)
add_library(Arduino::Probe ALIAS ArduinoProbe)
target_link_libraries(ArduinoProbe PUBLIC Arduino::Definitions)
