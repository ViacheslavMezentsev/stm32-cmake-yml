# ==============================================================================
# Модуль: КАТАЛОГИ СБОРКИ ПОДКЛЮЧАЕМЫХ КАТАЛОГОВ (ТЗ 4.6.8)
# ==============================================================================
# Каталог внутри проекта собирается в build/<относительный путь>, как по
# умолчанию в CMake. Каталог вне проекта — в build/_deps/<ключ>, где ключ —
# путь от корня проекта без ведущих «..» (другой диск Windows — без буквы
# диска). Совпавшие ключи и ключи, один из которых начинается с другого по
# границе сегмента, получают суффикс -<4 символа SHA-1 относительного пути>.
# План строится один раз по всем каталогам Configure, поэтому имя каталога
# сборки не зависит от порядка подключения.
# ==============================================================================

include_guard(GLOBAL)

# Относительный путь от корня проекта и ключ каталога сборки.
function(_stm32_yml_build_dir_key DIR OUT_REL OUT_KEY OUT_EXTERNAL)
    file(RELATIVE_PATH _rel "${CMAKE_SOURCE_DIR}" "${DIR}")
    string(REGEX REPLACE "/$" "" _rel "${_rel}")
    set(_external FALSE)
    set(_key "${_rel}")
    if(_rel MATCHES "^\\.\\.(/|$)")
        set(_external TRUE)
        string(REGEX REPLACE "^(\\.\\./)+" "" _key "${_rel}")
    elseif(IS_ABSOLUTE "${_rel}")
        # Другой диск Windows: RELATIVE_PATH возвращает абсолютный путь.
        set(_external TRUE)
        string(REGEX REPLACE "^[A-Za-z]:/|^/+" "" _key "${_rel}")
    endif()
    set(${OUT_REL} "${_rel}" PARENT_SCOPE)
    set(${OUT_KEY} "${_key}" PARENT_SCOPE)
    set(${OUT_EXTERNAL} ${_external} PARENT_SCOPE)
endfunction()

# stm32_yml_plan_build_dirs(<каталог>...)
# Назначает каталоги сборки всем каталогам, подключаемым через add_subdirectory
# в этом Configure. Каталоги — абсолютные пути или пути от корня проекта.
function(stm32_yml_plan_build_dirs)
    set(_dirs "")
    set(_rels "")
    set(_keys "")
    set(_externals "")
    foreach(_item IN LISTS ARGN)
        get_filename_component(_dir "${_item}" ABSOLUTE BASE_DIR "${CMAKE_SOURCE_DIR}")
        if(NOT IS_DIRECTORY "${_dir}" OR "${_dir}" IN_LIST _dirs)
            continue()
        endif()
        _stm32_yml_build_dir_key("${_dir}" _rel _key _external)
        list(APPEND _dirs "${_dir}")
        list(APPEND _rels "${_rel}")
        list(APPEND _keys "${_key}")
        list(APPEND _externals ${_external})
    endforeach()

    list(LENGTH _dirs _count)
    set(_bins "")
    set(_have_external FALSE)
    if(_count GREATER 0)
        math(EXPR _last "${_count} - 1")
        foreach(_i RANGE ${_last})
            list(GET _externals ${_i} _external)
            list(GET _keys ${_i} _key)
            list(GET _rels ${_i} _rel)
            if(NOT _external)
                list(APPEND _bins "${_key}")
                continue()
            endif()
            set(_have_external TRUE)
            # Совпадение или вложенность ключей среди внешних каталогов.
            set(_clash FALSE)
            foreach(_j RANGE ${_last})
                list(GET _externals ${_j} _other_external)
                if(_j EQUAL _i OR NOT _other_external)
                    continue()
                endif()
                list(GET _keys ${_j} _other)
                string(FIND "${_key}/" "${_other}/" _pos_a)
                string(FIND "${_other}/" "${_key}/" _pos_b)
                if(_pos_a EQUAL 0 OR _pos_b EQUAL 0)
                    set(_clash TRUE)
                endif()
            endforeach()
            if(_clash)
                string(SHA1 _hash "${_rel}")
                string(SUBSTRING "${_hash}" 0 4 _hash)
                set(_key "${_key}-${_hash}")
            endif()
            list(APPEND _bins "_deps/${_key}")
            stm32_yml_msg(I304 "${_rel}" "_deps/${_key}")
        endforeach()
    endif()

    # Каталог проекта _deps/… занял бы место внешних зависимостей (ТЗ 4.6.8(г)).
    if(_have_external)
        foreach(_i RANGE ${_last})
            list(GET _externals ${_i} _external)
            list(GET _keys ${_i} _key)
            if(NOT _external AND _key MATCHES "^_deps(/|$)")
                stm32_yml_msg(E302 "${_key}")
            endif()
        endforeach()
    endif()

    set_property(GLOBAL PROPERTY _STM32_YML_BUILD_DIR_SOURCES "${_dirs}")
    set_property(GLOBAL PROPERTY _STM32_YML_BUILD_DIR_BINARIES "${_bins}")
endfunction()

# stm32_yml_add_subdirectory(<каталог>)
# add_subdirectory с каталогом сборки по плану stm32_yml_plan_build_dirs.
function(stm32_yml_add_subdirectory DIR)
    get_filename_component(_dir "${DIR}" ABSOLUTE BASE_DIR "${CMAKE_SOURCE_DIR}")
    get_property(_dirs GLOBAL PROPERTY _STM32_YML_BUILD_DIR_SOURCES)
    get_property(_bins GLOBAL PROPERTY _STM32_YML_BUILD_DIR_BINARIES)
    list(FIND _dirs "${_dir}" _index)
    if(_index EQUAL -1)
        # Каталог вне плана: тот же ключ без проверки совпадений.
        _stm32_yml_build_dir_key("${_dir}" _rel _bin _external)
        if(_external)
            set(_bin "_deps/${_bin}")
        endif()
    else()
        list(GET _bins ${_index} _bin)
    endif()
    add_subdirectory("${_dir}" "${CMAKE_BINARY_DIR}/${_bin}")
endfunction()
