#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"
#include "smoke_target.h"

/* Standard weak port hook: load, clear, enable (also works on pinned Renode). */
void vPortSetupTimerInterrupt(void) {
    SysTick->CTRL = 0;
    configASSERT(SysTick_Config(configCPU_CLOCK_HZ / configTICK_RATE_HZ) == 0);
}

void smoke_rtos_tasks_finish(unsigned result, unsigned ticks) __attribute__((noreturn));
static QueueHandle_t requests, replies;
static unsigned startup_complete;

static void receiver(void* unused) {
    (void)unused;
    uint32_t value = 0;
    configASSERT(startup_complete);
    configASSERT(xQueueReceive(requests, &value, 1000) == pdPASS);
    configASSERT(value == 17);
    value += 29;
    configASSERT(xQueueSend(replies, &value, 1000) == pdPASS);
    vTaskDelete(NULL);
    configASSERT(0);
}

static void sender(void* unused) {
    (void)unused;
    configASSERT(startup_complete);
    const TickType_t before = xTaskGetTickCount();
    vTaskDelay(2); /* Must wake through the real SysTick/PendSV path. */
    uint32_t value = 17;
    configASSERT(xQueueSend(requests, &value, 1000) == pdPASS);
    configASSERT(xQueueReceive(replies, &value, 1000) == pdPASS);
    const TickType_t elapsed = xTaskGetTickCount() - before;
    configASSERT(value == 46 && elapsed >= 2);
    configASSERT(xTaskGetSchedulerState() == taskSCHEDULER_RUNNING);
    smoke_rtos_tasks_finish(value, elapsed);
}

static void starter(void* unused) {
    (void)unused;
    requests = xQueueCreate(1, sizeof(uint32_t));
    replies = xQueueCreate(1, sizeof(uint32_t));
    configASSERT(requests && replies);
    /* Lower priority keeps both children dormant until the starter deletes itself. */
    configASSERT(xTaskCreate(receiver, "receiver", SMOKE_STACK_RECEIVER, NULL, 1, NULL) == pdPASS);
    configASSERT(xTaskCreate(sender, "sender", SMOKE_STACK_SENDER, NULL, 1, NULL) == pdPASS);
    startup_complete = 1;
    vTaskDelete(NULL);
    configASSERT(0);
}

void smoke_freertos_tasks(void) {
    /* Ports without the weak hook (ARM_CM0 in FreeRTOS V10.0.1 uses a static
       prvSetupTimerInterrupt) clear VAL before writing LOAD; Renode then reloads
       the reset LOAD (0xFFFFFF) and the first tick comes after about 2 s. */
    SysTick->CTRL = 0;
    SysTick->LOAD = configCPU_CLOCK_HZ / configTICK_RATE_HZ - 1UL;
    configASSERT(xTaskCreate(starter, "starter", SMOKE_STACK_STARTER, NULL, 2, NULL) == pdPASS);
    vTaskStartScheduler();
    configASSERT(0); /* Includes failure to allocate the idle task. */
}
const char* smoke_freertos_tasks_version(void) { return tskKERNEL_VERSION_NUMBER; }
