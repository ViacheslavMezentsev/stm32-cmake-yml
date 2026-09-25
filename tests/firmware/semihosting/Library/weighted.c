#include "smoke_library.h"
#ifndef SMOKE_LIBRARY_PRIVATE
#error Missing PRIVATE library definition
#endif
#if defined(SMOKE_CXX_ONLY) || defined(SMOKE_C_ONLY)
#error Executable PRIVATE definitions leaked to the library
#endif
uint32_t smoke_weighted(const volatile uint32_t* data, unsigned size) {
    uint32_t result = 0;
    for (unsigned i = 0; i < size; ++i) result += data[i] * (i + 1);
    return result;
}
