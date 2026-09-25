#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"

/* All queue operations have zero wait time: no task or scheduler is needed. */
unsigned smoke_freertos_queue(void) {
    void* warmup = pvPortMalloc(16);
    if (!warmup) return 0;
    vPortFree(warmup);
    const size_t initial = xPortGetFreeHeapSize();
    void* block = pvPortMalloc(128);
    if (!block || ((uintptr_t)block % portBYTE_ALIGNMENT) || xPortGetFreeHeapSize() >= initial) return 0;
    vPortFree(block);
    if (xPortGetFreeHeapSize() != initial || pvPortMalloc(configTOTAL_HEAP_SIZE) != NULL) return 0;
    QueueHandle_t queue = xQueueCreate(2, sizeof(uint32_t));
    if (!queue) return 0;
    uint32_t first = 17, second = 29, value = 0;
    if (xQueueSend(queue, &first, 0) != pdPASS || xQueueSend(queue, &second, 0) != pdPASS) return 0;
    if (xQueueSend(queue, &first, 0) != errQUEUE_FULL || uxQueueMessagesWaiting(queue) != 2) return 0;
    if (xQueueReceive(queue, &value, 0) != pdPASS || value != first) return 0;
    if (xQueueReceive(queue, &value, 0) != pdPASS || value != second) return 0;
    if (xQueueReceive(queue, &value, 0) != errQUEUE_EMPTY) return 0;
    vQueueDelete(queue);
    if (xPortGetFreeHeapSize() != initial || xTaskGetSchedulerState() != taskSCHEDULER_NOT_STARTED) return 0;
    return first + second;
}
const char* smoke_freertos_version(void) { return tskKERNEL_VERSION_NUMBER; }
