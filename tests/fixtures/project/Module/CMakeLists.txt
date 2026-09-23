# Explicit shared settings, not inherited from the executable's PRIVATE options.
add_library(probe_settings INTERFACE)
add_library(Probe::Settings ALIAS probe_settings)
target_compile_options(probe_settings INTERFACE -mcpu=cortex-m3 -mthumb
    "$<$<COMPILE_LANGUAGE:C>:-Wstrict-prototypes>"
    "$<$<COMPILE_LANGUAGE:CXX>:-fno-exceptions>")
target_compile_definitions(probe_settings INTERFACE SHARED_SETTING=1)

# Target name deliberately differs from the directory name.
add_library(probe_module STATIC Src/module.c Src/module.cpp)
add_library(Probe::Module ALIAS probe_module)
target_include_directories(probe_module PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/Inc")
target_compile_definitions(probe_module PUBLIC MODULE_PUBLIC=1 PRIVATE MODULE_PRIVATE=1)
target_link_libraries(probe_module PRIVATE Probe::Settings)
