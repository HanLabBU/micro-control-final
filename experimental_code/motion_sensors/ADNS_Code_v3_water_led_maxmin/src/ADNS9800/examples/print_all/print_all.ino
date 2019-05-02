/*

  main.cpp

*/
#include <Arduino.h>

// Arduino Includes
#include <SPI.h>
#include <elapsedMillis.h>
// Include ADNS Library for ADNS-9800 Sensor
#include "ADNS9800\ADNS.h"
// Pin Settings
#define CHIPSELECT_PIN 4

// Create a Sensor Object with Specified Slave-Select Pin
ADNS sensor(CHIPSELECT_PIN);
const uint32_t msLoop = 100;
const uint32_t usLoop = msLoop * 1000;
elapsedMicros usCnt(0);

adns_readout_t index;
adns_readout_t readout;

// Declare Test Functions
void testSingleRegisterRead();
void testBurst();
void printLag();

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
    Serial.println("about to begin sensor");
    sensor.begin();
    // sensor.begin(200, 1000);
    Serial.println("sensor started");
    delay(30);

    // Test
    testSingleRegisterRead();
    testBurst();

    // Start Acquisition
    usCnt = 0;
    Serial.println(sensor.getName());
    sensor.triggerAcquisitionStart();
};

// =============================================================================
//   LOOP
// =============================================================================

int32_t lastLag = 0;
int32_t totalLag;
void loop()
{
    while (usCnt < usLoop)
    {
    }
    // Advance Time Counter for Constant Period Looping
    totalLag = usCnt - usLoop;
    usCnt -= usLoop; // usCnt = totalLag?

    // Print Velocity
    sensor.triggerSampleCapture();
    sensor.printLastMotion();
    // sensor.printLastAdditionalInfo();
}

void printLag()
{
    // Print Loop Time Lag
    Serial.print("Lag (change)[us]:\t");
    Serial.print(totalLag - 4);
    Serial.print("\t (");
    Serial.print(totalLag - lastLag);
    Serial.print(")\t\t");
    lastLag = totalLag;
}

void testSingleRegisterRead()
{
    Serial.println("\nTEST:\tSingle Register Read\n");
    Serial.println(sensor.readRegister(RegisterAddress::Product_ID), BIN);
    Serial.println(sensor.readRegister(RegisterAddress::Revision_ID), BIN);
    Serial.println(sensor.readRegister(RegisterAddress::SQUAL), BIN);
    Serial.println("motion " +
                   String(sensor.readRegister(RegisterAddress::Motion)));
    Serial.println("observation " +
                   String(sensor.readRegister(RegisterAddress::Observation)));
    Serial.println("dxL " +
                   String(sensor.readRegister(RegisterAddress::Delta_X_L)));
    Serial.println("dxH " +
                   String(sensor.readRegister(RegisterAddress::Delta_X_H)));
    Serial.println("dyL " +
                   String(sensor.readRegister(RegisterAddress::Delta_Y_L)));
    Serial.println("dyH " +
                   String(sensor.readRegister(RegisterAddress::Delta_Y_H)));
    Serial.println("surfaceQuality " +
                   String(sensor.readRegister(RegisterAddress::SQUAL)));
    Serial.println("pixelSum " +
                   String(sensor.readRegister(RegisterAddress::Pixel_Sum)));
    Serial.println("maxPixel " +
                   String(sensor.readRegister(RegisterAddress::Maximum_Pixel)));
    Serial.println("minPixel " +
                   String(sensor.readRegister(RegisterAddress::Minimum_Pixel)));
    Serial.println("shutterPeriodL " +
                   String(sensor.readRegister(RegisterAddress::Shutter_Lower)));
    Serial.println("shutterPeriodH " +
                   String(sensor.readRegister(RegisterAddress::Shutter_Upper)));
    Serial.println("framePeriodL " + String(sensor.readRegister(
                                         RegisterAddress::Frame_Period_Lower)));
    Serial.println("framePeriodH " + String(sensor.readRegister(
                                         RegisterAddress::Frame_Period_Upper)));
}

void testBurst()
{
    Serial.println("\nTEST:\tBurst Read\n");
    // test burst readout
    sensor.select();
    SPI.transfer((uint8_t)RegisterAddress::Motion_Burst);
    delayMicroseconds(1000);
    for (int k = 0; k < 14; k++)
    {
        index.data[k] = k;
        readout.data[k] = SPI.transfer(0x00);
    }
    sensor.deselect();
    int k = 0;
    Serial.println("motion \t" + String(index.data[k]) + "\t" +
                   String(readout.data[k]) + "\t(" + String(readout.motion) +
                   ")");
    k++;
    Serial.println("observation \t" + String(index.data[k]) + "\t" +
                   String(readout.data[k]) + "\t(" + String(readout.observation) +
                   ")");
    k++;
    Serial.println("dxL \t" + String(index.data[k]) + "\t" +
                   String(readout.data[k]) + "\t(" + String(readout.dxL) + ")");
    k++;
    Serial.println("dxH \t" + String(index.data[k]) + "\t" +
                   String(readout.data[k]) + "\t(" + String(readout.dxH) + ")");
    k++;
    Serial.println("dyL \t" + String(index.data[k]) + "\t" +
                   String(readout.data[k]) + "\t(" + String(readout.dyL) + ")");
    k++;
    Serial.println("dyH \t" + String(index.data[k]) + "\t" +
                   String(readout.data[k]) + "\t(" + String(readout.dyH) + ")");
    k++;
    Serial.println("surfaceQuality \t" + String(index.data[k]) + "\t" +
                   String(readout.data[k]) + "\t(" +
                   String(readout.surfaceQuality) + ")");
    k++;
    Serial.println("pixelSum \t" + String(index.data[k]) + "\t" +
                   String(readout.data[k]) + "\t(" + String(readout.pixelSum) +
                   ")");
    k++;
    Serial.println("maxPixel \t" + String(index.data[k]) + "\t" +
                   String(readout.data[k]) + "\t(" + String(readout.maxPixel) +
                   ")");
    k++;
    Serial.println("minPixel \t" + String(index.data[k]) + "\t" +
                   String(readout.data[k]) + "\t(" + String(readout.minPixel) +
                   ")");
    k++;
    Serial.println("shutterPeriodL \t" + String(index.data[k]) + "\t" +
                   String(readout.data[k]) + "\t(" +
                   String(readout.shutterPeriodL) + ")");
    k++;
    Serial.println("shutterPeriodH \t" + String(index.data[k]) + "\t" +
                   String(readout.data[k]) + "\t(" +
                   String(readout.shutterPeriodH) + ")");
    k++;
    Serial.println("framePeriodL \t" + String(index.data[k]) + "\t" +
                   String(readout.data[k]) + "\t(" +
                   String(readout.framePeriodL) + ")");
    k++;
    Serial.println("framePeriodH \t" + String(index.data[k]) + "\t" +
                   String(readout.data[k]) + "\t(" +
                   String(readout.framePeriodH) + ")");
    k++;
}
