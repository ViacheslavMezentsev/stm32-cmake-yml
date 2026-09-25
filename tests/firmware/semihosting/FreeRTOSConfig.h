#pragma once
#include <stdint.h>
#define configUSE_PREEMPTION 1
#define configUSE_IDLE_HOOK 0
#define configUSE_TICK_HOOK 0
#define configCPU_CLOCK_HZ 8000000UL
#define configTICK_RATE_HZ 1000
#define configMAX_PRIORITIES 3
#define configMINIMAL_STACK_SIZE 128
#ifdef SMOKE_RTOS_TASKS
#define configTOTAL_HEAP_SIZE 8192
#define INCLUDE_vTaskDelete 1
#define INCLUDE_vTaskDelay 1
#define vPortSVCHandler SVC_Handler
#define xPortPendSVHandler PendSV_Handler
#define xPortSysTickHandler SysTick_Handler
#else
#define configTOTAL_HEAP_SIZE 4096
#endif
#define configMAX_TASK_NAME_LEN 16
#define configUSE_16_BIT_TICKS 0
#define configIDLE_SHOULD_YIELD 1
#define configUSE_TIMERS 0
#define configSUPPORT_DYNAMIC_ALLOCATION 1
#define configSUPPORT_STATIC_ALLOCATION 0
#define configUSE_MUTEXES 0
#define configUSE_CO_ROUTINES 0
#define configMAX_CO_ROUTINE_PRIORITIES 1
#define configKERNEL_INTERRUPT_PRIORITY 240
#define configMAX_SYSCALL_INTERRUPT_PRIORITY 80
#define INCLUDE_xTaskGetSchedulerState 1
#ifdef __cplusplus
extern "C" {
#endif
void smoke_rtos_assert(void);
#ifdef __cplusplus
}
#endif
#define configASSERT(condition) do { if (!(condition)) smoke_rtos_assert(); } while (0)
