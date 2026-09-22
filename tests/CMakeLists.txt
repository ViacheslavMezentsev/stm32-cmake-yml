cmake_minimum_required(VERSION 3.19)
project(stm32_yml_configure_tests LANGUAGES NONE)

enable_testing()
find_package(Python3 REQUIRED COMPONENTS Interpreter)
get_filename_component(FRAMEWORK_DIR "${CMAKE_CURRENT_SOURCE_DIR}/.." ABSOLUTE)
file(READ "${CMAKE_CURRENT_SOURCE_DIR}/cases.json" CASES)
string(JSON CASE_COUNT LENGTH "${CASES}")
math(EXPR LAST_CASE "${CASE_COUNT} - 1")
foreach(INDEX RANGE ${LAST_CASE})
    string(JSON CASE_NAME GET "${CASES}" ${INDEX} name)
    add_test(NAME "configure.${CASE_NAME}"
        COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/run_case.py"
            --case "${CASE_NAME}" --cmake "${CMAKE_COMMAND}"
            --framework "${FRAMEWORK_DIR}" --work-dir "${CMAKE_CURRENT_BINARY_DIR}/cases")
    string(JSON STEP_COUNT ERROR_VARIABLE NO_STEPS LENGTH "${CASES}" ${INDEX} steps)
    if(NO_STEPS)
        set(STEP_COUNT 1)
    endif()
    math(EXPR CASE_TIMEOUT "120 * ${STEP_COUNT}")
    set_tests_properties("configure.${CASE_NAME}" PROPERTIES TIMEOUT ${CASE_TIMEOUT} LABELS configure)
endforeach()
