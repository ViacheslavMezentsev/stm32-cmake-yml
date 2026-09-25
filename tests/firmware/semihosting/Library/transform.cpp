#include "smoke_library.h"
#ifndef SMOKE_LIBRARY_PRIVATE
#error Missing PRIVATE library definition
#endif
#if defined(__EXCEPTIONS) || defined(__GXX_RTTI)
#error Missing library C++ options
#endif
extern "C" uint32_t smoke_transform(const volatile uint32_t* data, unsigned size) {
    return smoke_weighted(data, size) ^ 0x55u;
}
