# Test-only message codes (spec 4.16.5: 9xx is never used by the framework).
# I901 checks arguments with ';', quotes and '\', W901 has no English text
# (Russian fallback, spec 4.16.8), E901 stops Configure after both records.
stm32_yml_msg_def(I901
    "Тестовое сообщение: [{1}] [{2}] [{3}]"
    "Test message: [{1}] [{2}] [{3}]")
stm32_yml_msg_def(W901
    "Тестовое предупреждение только на русском: {1}")
stm32_yml_msg_def(E901
    "Тестовая ошибка: {1}"
    "Test error: {1}")

stm32_yml_msg(I901 "a;b" "quote \"x\"" "C:\\path\\to {1}")
stm32_yml_msg(W901 "ok")
if(STM32_YML_TEST_FAIL)
    stm32_yml_msg(E901 "stop")
endif()
