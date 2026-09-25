#pragma once
#include <stdint.h>
#ifndef SMOKE_LIBRARY_PUBLIC
#error Missing PUBLIC library usage requirements
#endif
#ifdef __cplusplus
extern "C" {
#endif
uint32_t smoke_weighted(const volatile uint32_t* data, unsigned size);
uint32_t smoke_transform(const volatile uint32_t* data, unsigned size);
uint32_t smoke_language(void);
uint32_t smoke_etl(const volatile uint32_t* data, unsigned size);
const char* smoke_etl_text(void);
const char* smoke_etl_version(void);
#ifdef __cplusplus
}
#endif
