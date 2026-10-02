# ==============================================================================
# Модуль: ВЕРСИИ КОМПОНЕНТОВ (ТЗ 4.2.6, 4.2.7)
# ==============================================================================
# Только функции: модуль подключается и в режиме скрипта (cmake -P) для тестов
# tests/test_component_versions.py.
# ==============================================================================
# Read only the module's own repository (checkout, submodule or worktree).
# A copied directory inside another repository must not inherit its parent's SHA.
function(_stm32_yml_git_query DIR OUT_VAR)
    set(${OUT_VAR} "" PARENT_SCOPE)
    if(NOT EXISTS "${DIR}/.git")
        return()
    endif()
    find_package(Git QUIET)
    if(NOT GIT_FOUND)
        return()
    endif()
    set(_git "${CMAKE_COMMAND}" -E env --unset=GIT_DIR --unset=GIT_WORK_TREE
        --unset=GIT_INDEX_FILE --unset=GIT_COMMON_DIR GIT_OPTIONAL_LOCKS=0
        "${GIT_EXECUTABLE}" --literal-pathspecs -C "${DIR}")
    execute_process(COMMAND ${_git} rev-parse --show-toplevel
        OUTPUT_VARIABLE _top RESULT_VARIABLE _result
        ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE TIMEOUT 5)
    if(NOT _result STREQUAL "0" OR _top STREQUAL "")
        return()
    endif()
    file(REAL_PATH "${DIR}" _directory)
    file(REAL_PATH "${_top}" _top)
    if(CMAKE_HOST_WIN32)
        string(TOLOWER "${_directory}" _directory)
        string(TOLOWER "${_top}" _top)
    endif()
    if(NOT _directory STREQUAL _top)
        return()
    endif()
    execute_process(COMMAND ${_git} ${ARGN}
        OUTPUT_VARIABLE _value RESULT_VARIABLE _result
        ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE TIMEOUT 5)
    if(_result STREQUAL "0")
        set(${OUT_VAR} "${_value}" PARENT_SCOPE)
    endif()
endfunction()

function(_stm32_yml_git_describe DIR OUT_VAR)
    _stm32_yml_git_query("${DIR}" _describe describe --tags --always)
    set(${OUT_VAR} "${_describe}" PARENT_SCOPE)
endfunction()

# Spec 4.2.8: Git identity is separate from the package/configuration version.
function(_stm32_yml_git_suffix DIR OUT_VAR)
    set(${OUT_VAR} "" PARENT_SCOPE)
    _stm32_yml_git_query("${DIR}" _sha rev-parse --short=7 HEAD)
    if(NOT _sha MATCHES "^[0-9a-fA-F]+$")
        return()
    endif()
    _stm32_yml_git_query("${DIR}" _status status --porcelain=v1
        --untracked-files=normal --ignore-submodules=none -- .)
    set(_modified "")
    if(NOT _status STREQUAL "")
        set(_modified ", modified")
    endif()
    set(${OUT_VAR} " (commit: ${_sha}${_modified})" PARENT_SCOPE)
endfunction()

# ==============================================================================
# Версия stm32-cmake: тег из git describe; без тегов — последняя версия из
# CHANGELOG.md с пометкой "+". Git identity is formatted separately.
# Пусто, если версию определить нельзя.
# ==============================================================================
function(stm32_yml_stm32_cmake_version DIR OUT_VAR)
    _stm32_yml_git_describe("${DIR}" _describe)
    set(_changelog "")
    if(EXISTS "${DIR}/CHANGELOG.md")
        file(STRINGS "${DIR}/CHANGELOG.md" _lines REGEX "^## v[0-9]")
        if(_lines)
            list(GET _lines 0 _line)
            string(REGEX MATCH "v[0-9]+(\\.[0-9]+)+" _changelog "${_line}")
        endif()
    endif()
    if(_describe MATCHES "^v?[0-9]+\\.[0-9]")
        set(_version "${_describe}")
    elseif(NOT _changelog STREQUAL "")
        set(_version "${_changelog}+")
    else()
        set(_version "")
    endif()
    set(${OUT_VAR} "${_version}" PARENT_SCOPE)
endfunction()

# ==============================================================================
# Версия Arduino Core STM32: version= из platform.txt и коммит, если каталог —
# репозиторий git ("2.12.0 (8c31e50)"). Пусто, если версию определить нельзя.
# ==============================================================================
function(stm32_yml_arduino_core_version DIR OUT_VAR)
    set(_version "")
    if(EXISTS "${DIR}/platform.txt")
        file(STRINGS "${DIR}/platform.txt" _lines REGEX "^version=")
        if(_lines)
            list(GET _lines 0 _line)
            string(REGEX REPLACE "^version=[ \t]*" "" _version "${_line}")
            string(STRIP "${_version}" _version)
        endif()
    endif()
    _stm32_yml_git_describe("${DIR}" _describe)
    if(NOT _version STREQUAL "" AND NOT _describe STREQUAL "")
        set(_version "${_version} (${_describe})")
    elseif(NOT _describe STREQUAL "")
        set(_version "${_describe}")
    endif()
    set(${OUT_VAR} "${_version}" PARENT_SCOPE)
endfunction()

# Выводит строку версии компонента или «версия не определена» без предупреждения.
function(_stm32_yml_print_version NAME VERSION)
    set(_suffix "")
    if(ARGC GREATER 2)
        set(_suffix "${ARGV2}")
    endif()
    if("${VERSION}" STREQUAL "")
        stm32_yml_msg(I044 "${NAME}" "${_suffix}")
    else()
        stm32_yml_msg(I041 "${NAME}" "${VERSION}${_suffix}")
    endif()
endfunction()

# ==============================================================================
# Версии CMake, yq и используемого backend до project(). Каталог stm32-cmake
# определяется по файлу toolchain stm32_gcc.cmake, Arduino Core — по
# arduino.core_path. Версия компилятора выводится после project()
# (stm32_yml_print_compiler_version).
# ==============================================================================
function(stm32_yml_print_component_versions)
    stm32_yml_msg(I040)
    _stm32_yml_print_version("CMake" "${CMAKE_VERSION}")

    set(_yq "")
    find_program(YQ_EXECUTABLE yq)
    if(YQ_EXECUTABLE)
        execute_process(COMMAND "${YQ_EXECUTABLE}" --version
            OUTPUT_VARIABLE _output ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)
        string(REGEX MATCH "v?[0-9]+\\.[0-9]+(\\.[0-9]+)?" _yq "${_output}")
    endif()
    _stm32_yml_print_version("yq" "${_yq}")

    if(toolchain_backend STREQUAL "arduino")
        set(_arduino "")
        if(NOT "${arduino_core_path}" STREQUAL "")
            get_filename_component(_core "${arduino_core_path}" ABSOLUTE BASE_DIR "${CMAKE_SOURCE_DIR}")
            stm32_yml_arduino_core_version("${_core}" _arduino)
        endif()
        _stm32_yml_print_version("Arduino Core STM32" "${_arduino}")
    else()
        set(_stm32_cmake "")
        set(_stm32_cmake_git "")
        if(CMAKE_TOOLCHAIN_FILE MATCHES "stm32_gcc\\.cmake$")
            get_filename_component(_toolchain "${CMAKE_TOOLCHAIN_FILE}" ABSOLUTE BASE_DIR "${CMAKE_BINARY_DIR}")
            get_filename_component(_dir "${_toolchain}" DIRECTORY)
            get_filename_component(_dir "${_dir}" DIRECTORY)
            stm32_yml_stm32_cmake_version("${_dir}" _stm32_cmake)
            _stm32_yml_git_suffix("${_dir}" _stm32_cmake_git)
        endif()
        _stm32_yml_print_version("stm32-cmake" "${_stm32_cmake}" "${_stm32_cmake_git}")
    endif()
endfunction()

# Версия компилятора после project(): первый включённый язык из C, CXX, ASM.
function(stm32_yml_print_compiler_version)
    foreach(_lang IN ITEMS C CXX ASM)
        if(CMAKE_${_lang}_COMPILER_LOADED AND NOT "${CMAKE_${_lang}_COMPILER_VERSION}" STREQUAL "")
            stm32_yml_msg(I042 "${CMAKE_${_lang}_COMPILER_ID}" "${CMAKE_${_lang}_COMPILER_VERSION}")
            return()
        endif()
    endforeach()
    stm32_yml_msg(I043)
endfunction()
