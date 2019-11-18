/*

  main.cpp

*/

// Arduino Includes
#include <Arduino.h>
#include <SPI.h>
#include <elapsedMillis.h>
#include <glcd_delay.h>
#include <CircularBuffer.h>

// Include ADNS Library for ADNS-9800 Sensor
#include "ADNS9800\ADNS.h"
// Pin Settings
#define CHIPSELECT_PIN 4

// Create a Sensor Object with Specified Slave-Select Pin
ADNS sensor(CHIPSELECT_PIN);
const unit_specification_t units = {Unit::Distance::MICROMETER, Unit::Time::MICROSECOND};
// // const uint32_t msLoop = 100;
// // const uint32_t usLoop = msLoop * 1000;
elapsedMicros usCnt(0);
uint32_t usLoop;
CircularBuffer<displacement_t, 12> buf;

// Declare Test Functions
void printDisplacement(const displacement_t p);
void onTrigger();

// =============================================================================
//   INITIALIZATION
// =============================================================================
void setup()
{
  // Serial.begin(9600);
  Serial.begin(115200);
  while (!Serial)
  {
    ; // may only be needed for native USB port
  }
  delay(10);
  sensor.begin();
  delay(30);

  // Start Acquisition
  usCnt = 0;
  Serial.print("\nname: ");
  Serial.println(sensor.getName());
  sensor.triggerAcquisitionStart();
  attachInterrupt(digitalPinToInterrupt(2), onTrigger, RISING);
};

// =============================================================================
//   LOOP
// =============================================================================

void loop()
{
  // // while (usCnt < usLoop)
  // // {
  // // }
  // //

  // Print Velocity
  while (!buf.isEmpty())
  {
    usLoop = usCnt;
    Serial.print(usLoop);
    Serial.println("\t");
    displacement_t p = buf.shift();
    printDisplacement(p);
    usCnt -= usLoop;
    }
}

void printDisplacement(const displacement_t p)
{
  Serial.print(p.dx);
  Serial.print('\t');
  Serial.print(p.dy);
  Serial.print('\t');
  Serial.println(p.dt);
}

void onTrigger()
{
  sensor.triggerSampleCapture();
  buf.push(sensor.readDisplacement(units));
}