#include "smoke_library.h"
#include <etl/vector.h>
#include <etl/string.h>
#include <etl/version.h>
static etl::string<16> text;
extern "C" uint32_t smoke_etl(const volatile uint32_t* data, unsigned size) {
    etl::vector<uint32_t, 8> values;
    for (unsigned i = 0; i < size; ++i) values.push_back(uint32_t(data[i]));
    uint32_t sum = 0;
    while (!values.empty()) { sum += values.back(); values.pop_back(); }
    text = "etl:";
    text.push_back(char('0' + sum / 10));
    text.push_back(char('0' + sum % 10));
    return sum;
}
extern "C" const char* smoke_etl_text(void) { return text.c_str(); }
extern "C" const char* smoke_etl_version(void) { return ETL_VERSION; }
