// Own main() with arduino.use_core_main: false (spec 4.9.18, TC-85).
#include <Arduino.h>
#include <Wire.h>
extern "C" volatile uint32_t native_main_marker;
volatile uint32_t native_main_marker = 0x3A1D0001u;
int main(void) {
    init();
    initVariant();
    Wire.begin();
    for (;;) {
        Serial.print(native_main_marker);
        delay(100);
    }
}
