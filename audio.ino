#include <Audio.h>
#include <Wire.h>
#include <SPI.h>
#include <SD.h>
#include <SerialFlash.h>

// GUItool: begin automatically generated code
AudioSynthWaveformSine   sine1;          //xy=189,176
AudioEffectFade          fade1;          //xy=380,177
AudioOutputAnalog        dac1;           //xy=552,179
AudioConnection          patchCord1(sine1, fade1);
AudioConnection          patchCord2(fade1, dac1);

//

const uint8_t START_PIN = 4;
const float FQ = 10000; //Hz
const uint16_t FADE_MS = 500; // ms


void setup() {
  AudioMemory(20);
  pinMode(START_PIN,INPUT);
  sine1.frequency(FQ);
  sine1.height(0);
}

void loop() {
  //if (digitalRead(START_PIN)) {
    AudioNoInterrupts();
    sine1.height(1);
    fade1.fadeIn(FADE_MS)
    AudioInterrupts();
    while (digitalRead(START_PIN) {
      ;
    }
    fade1.fadeout(FADE_MS);
    sine1.height(0);
  //}
}
