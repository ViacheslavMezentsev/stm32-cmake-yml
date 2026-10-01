// Sketch for the core main() (spec 4.9.18, TC-70).
#include <Arduino.h>
extern "C" volatile uint32_t native_sketch_marker;
volatile uint32_t native_sketch_marker = 0x5E7C0DEu;
void setup() { pinMode(LED_BUILTIN, OUTPUT); }
void loop() { digitalToggle(LED_BUILTIN); delay(native_sketch_marker & 0xFF); }
