#include <Audio.h>
#include <Wire.h>
#include <SPI.h>
#include <SD.h>
#include <SerialFlash.h>

// GUItool: begin automatically generated code
AudioSynthWaveformSine   sine1;          //xy=189,176
AudioOutputAnalog        dac1;           //xy=552,179
AudioConnection patchCord1(sine1,dac1);
//
const uint8_t TONE_LENGTH = 30000; //ms
const uint8_t START_PIN = 4;
const float FQ = 9500; //Hz

void setup() {
  Serial.begin(9600);
  AudioMemory(20);
  dac1.analogReference(INTERNAL);
  sine1.frequency(FQ);
  sine1.amplitude(0.05);
}

void loop() {
}
