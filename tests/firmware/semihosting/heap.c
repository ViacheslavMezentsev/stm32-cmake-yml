/* Bounded newlib heap: no SYS_HEAPINFO dependency on the simulator. */
#include <errno.h>
#include <stddef.h>
#include <stdint.h>
extern char end[], _Min_Heap_Size[];
void* _sbrk(ptrdiff_t increment) {
    static uintptr_t current;
    const uintptr_t base = (uintptr_t)end;
    const uintptr_t limit = base + (uintptr_t)_Min_Heap_Size;
    if (!current) current = base;
    if ((increment >= 0 && (uintptr_t)increment > limit - current) ||
        (increment < 0 && (uintptr_t)(-(increment + 1)) + 1 > current - base)) {
        errno = ENOMEM;
        return (void*)-1;
    }
    const uintptr_t previous = current;
    current += increment;
    return (void*)previous;
}
