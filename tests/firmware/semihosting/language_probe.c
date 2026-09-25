#include <stdint.h>
#if !defined(SMOKE_C_ONLY) || defined(SMOKE_CXX_ONLY)
#error Incorrect executable C language definitions
#endif
#ifdef SMOKE_LIBRARY_PRIVATE
#error PRIVATE library definition leaked to the consumer
#endif
uint32_t smoke_language(void) { return 11u; }
