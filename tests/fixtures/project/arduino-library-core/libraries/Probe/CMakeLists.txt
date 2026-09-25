add_library(ArduinoLibraryProbe STATIC probe.cpp)
add_library(Arduino::LibraryProbe ALIAS ArduinoLibraryProbe)
target_link_libraries(ArduinoLibraryProbe PUBLIC Arduino::Definitions)
target_compile_definitions(ArduinoLibraryProbe PUBLIC LIBRARY_PROBE=1)
