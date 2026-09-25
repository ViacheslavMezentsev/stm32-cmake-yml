#include <WString.h>
#include <stdint.h>
#include <string.h>
#ifndef SMOKE_ARDUINO
#error Missing Arduino::Definitions usage requirements
#endif
#if defined(__EXCEPTIONS) || defined(__GXX_RTTI)
#error Missing propagated C++ options
#endif
static volatile uint32_t number = 123u;
extern "C" unsigned smoke_arduino_string(char* output, unsigned capacity) {
    String value("STM32:");
    if (!value.reserve(32)) return 0;
    value += String((unsigned long)number);
    String copy(value);
    copy.replace("STM", "ARM");
    copy.toLowerCase();
    if (copy.indexOf(':') != 5 || copy.substring(6).toInt() != 123 || value != "STM32:123") return 0;
    if (capacity <= copy.length()) return 0;
    memcpy(output, copy.c_str(), copy.length() + 1);
    return copy.length();
}
