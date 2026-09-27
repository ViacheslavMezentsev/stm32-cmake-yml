# Executable PRIVATE flags do not propagate to a separately compiled library.
add_library(smoke_library STATIC weighted.c transform.cpp)
add_library(Smoke::Library ALIAS smoke_library)
target_include_directories(smoke_library PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}")
target_compile_definitions(smoke_library PUBLIC SMOKE_LIBRARY_PUBLIC=1 PRIVATE SMOKE_LIBRARY_PRIVATE=1)
# The builder passes the target's CPU/ABI flags (SMOKE_CPU_FLAGS); objects of
# another CPU or float ABI would not link with the executable.
if(NOT SMOKE_CPU_FLAGS)
    set(SMOKE_CPU_FLAGS -mcpu=cortex-m3 -mthumb -mfloat-abi=soft)
endif()
target_compile_options(smoke_library PRIVATE ${SMOKE_CPU_FLAGS}
    -ffunction-sections -fdata-sections
    "$<$<COMPILE_LANGUAGE:C>:-Wstrict-prototypes>"
    "$<$<COMPILE_LANGUAGE:CXX>:-fno-exceptions;-fno-rtti>")
set_target_properties(smoke_library PROPERTIES C_STANDARD 11 CXX_STANDARD 17)
if(STM32_YML_PROFILE STREQUAL "cmsisEtl")
    if(NOT EXISTS "${SMOKE_ETL_INCLUDE}/etl/version.h")
        message(FATAL_ERROR "Pass SMOKE_ETL_INCLUDE from the locked dependency")
    endif()
    target_sources(smoke_library PRIVATE etl_probe.cpp)
    target_include_directories(smoke_library PRIVATE "${SMOKE_ETL_INCLUDE}")
endif()
