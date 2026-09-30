# ==============================================================================
# Модуль: КОНТРОЛЬ КАЧЕСТВА КОДА (Code Quality)
# ==============================================================================

function(stm32_yml_setup_code_quality TARGET_NAME)

    stm32_yml_ensure_default_value(cppcheck_enable "false")

    if(NOT DEFINED cppcheck_enable OR "${cppcheck_enable}" STREQUAL "")
        set(cppcheck_enable "false")
    endif()

    if(cppcheck_enable)
        find_program(CPPCHECK_EXECUTABLE NAMES cppcheck)

        if(CPPCHECK_EXECUTABLE)
            stm32_yml_msg(I820 "${CPPCHECK_EXECUTABLE}")

            # 1. Базовые аргументы
            if(NOT DEFINED cppcheck_args OR "${cppcheck_args}" STREQUAL "")
                set(LOCAL_CPPCHECK_ARGS
                    "--enable=warning,performance,portability,style"
                    "--inline-suppr"
                    "--suppress=missingInclude"
                    "--suppress=unmatchedSuppression"
                )
            else()
                set(LOCAL_CPPCHECK_ARGS ${cppcheck_args})
            endif()

            # 2. Подавляем предупреждения ИСКЛЮЧИТЕЛЬНО из списка в YAML
            if(DEFINED cppcheck_ignores)
                foreach(ignore_dir IN LISTS cppcheck_ignores)
                    list(APPEND LOCAL_CPPCHECK_ARGS "--suppress=*:*${ignore_dir}/*")
                    # Вывод в консоль можно закомментировать, если он слишком длинный
                    stm32_yml_msg(I821 "${ignore_dir}")
                endforeach()
            endif()

            # 3. Формируем команду и навешиваем на таргет
            set(CPPCHECK_COMMAND ${CPPCHECK_EXECUTABLE} ${LOCAL_CPPCHECK_ARGS})

            set_target_properties(${TARGET_NAME} PROPERTIES
                C_CPPCHECK "${CPPCHECK_COMMAND}"
                CXX_CPPCHECK "${CPPCHECK_COMMAND}"
            )

            stm32_yml_msg(I822)
        else()
            stm32_yml_msg(W802)
        endif()
    endif()

endfunction()
