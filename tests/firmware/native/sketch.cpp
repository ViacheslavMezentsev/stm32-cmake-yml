// Sketch for the core main() (spec 4.9.18, TC-73).
#include <Arduino.h>
extern "C" volatile uint32_t native_sketch_marker;
volatile uint32_t native_sketch_marker = 0x5E7C0DEu;
void setup() {
    pinMode(LED_BUILTIN, OUTPUT);
    Serial.begin(115200);
}
void loop() {
    digitalToggle(LED_BUILTIN);
    Serial.println(native_sketch_marker);
    delay(500);
}
