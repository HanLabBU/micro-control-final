/*

  main.cpp

*/
#include <Arduino.h>

// Arduino Includes
#include <SPI.h>
#include <elapsedMillis.h>
#include <CircularBuffer.h>
#include <DigitalIO.h>
// #include <IntervalTimer.h>
// IntervalTimer timer;
// timer.priority(0);
// timer.begin(fcn,us);
//
// #include <usb_audio.h>
// #include <AudioStream.h>

// Include ADNS Library for ADNS-9800 Sensor
#include "ADNS9800\ADNS.h"

// Pin Settings
#define CS_PIN_A 4
#define CS_PIN_B 5
#define SYNC_OUT_PIN 3
#define SYNC_EVERY_N_PIN 6
#define SYNC_PULSE_WIDTH_MICROS 500
#define SYNC_PULSE_STATE HIGH

// Timing Settings (shooting for 480 fps minimum, sync with camera is nominal at this juncture)
#define CAMERA_FPS 40
#define SAMPLES_PER_CAMERA_FRAME 12

// Buffer Size (comment out CHAR_BUFFER_SIZE_FIXED to try variable size mode)
#define CHAR_BUFFER_NUM_BYTES 44

// Delimiters and Terminators
#define ID_DATA_DELIM ':'
#define DATA_DELIM ','
#define MSG_TERMINATOR '\t'

// Define Left-Right Sensor Pair Structure
typedef struct
{
    ADNS &left;
    ADNS &right;
} sensor_pair_t;

// Create Sensor Objects with Specified Slave-Select Pins
ADNS adnsA(CS_PIN_A);
ADNS adnsB(CS_PIN_B);
sensor_pair_t sensor = {adnsA, adnsB};
typedef struct
{
    char id = 'L';
    displacement_t p;
} labeled_sample_t;

// Specify some Constants for Timing and Unit Conversion/Reporting
const unit_specification_t units = {Unit::Distance::MICROMETER, Unit::Time::MILLISECOND};
const int32_t DISPLACEMENT_FPS = (CAMERA_FPS * SAMPLES_PER_CAMERA_FRAME);
const uint32_t usLoop = 1e6 / DISPLACEMENT_FPS;
volatile int syncEveryNCount = SAMPLES_PER_CAMERA_FRAME;

// Initialize microsecond counter and sample buffer
elapsedMicros usCnt;
CircularBuffer<labeled_sample_t, 3> bufA;
CircularBuffer<labeled_sample_t, 3> bufB;

// Declare Test Functions
static inline void sendAnyUpdate();
static inline void captureDisplacement();
void transmitDisplacementString(const labeled_sample_t);
void transmitDisplacementChar(const labeled_sample_t);

// =============================================================================
//   INITIALIZATION
// =============================================================================
void setup()
{
    // Begin Serial
    Serial.begin(115200);
    while (!Serial)
    {
        ; // may only be needed for native USB port
    }
    delay(10);

    // Begin Sensors
    sensor.left.begin();
    delay(30);
    sensor.right.begin();
    delay(30);

    // Set Sync Out Pin Modes
    fastDigitalWrite(SYNC_OUT_PIN, !SYNC_PULSE_STATE);
    fastDigitalWrite(SYNC_EVERY_N_PIN, !SYNC_PULSE_STATE);
    fastPinMode(SYNC_OUT_PIN, OUTPUT);
    fastPinMode(SYNC_EVERY_N_PIN, OUTPUT);

    // Start Acquisition
    usCnt = 0;
    sensor.left.triggerAcquisitionStart();
    sensor.right.triggerAcquisitionStart();

    // Send Sync-Every-N Pulse (at start of first and every N subsequent frames)
    fastDigitalWrite(SYNC_OUT_PIN, SYNC_PULSE_STATE);
    delayMicroseconds(SYNC_PULSE_WIDTH_MICROS);
    syncEveryNCount = SAMPLES_PER_CAMERA_FRAME;
    fastDigitalWrite(SYNC_OUT_PIN, !SYNC_PULSE_STATE);

    // print units
    const String dunit = getAbbreviation(units.distance);
    const String tunit = getAbbreviation(units.time);
    Serial.println("\n\n\n");
    Serial.println("label\t" + dunit + "\t\t" + dunit + "\t\t" + tunit + "\t" +
                   "label\t" + dunit + "\t\t" + dunit + "\t\t" + tunit);
};

// =============================================================================
//   LOOP
// =============================================================================
void loop()
{
    static bool needSyncOutReset = true;
    sendAnyUpdate();
    while (usCnt < usLoop)
    {
        if (needSyncOutReset && (usCnt > SYNC_PULSE_WIDTH_MICROS))
        {
            fastDigitalWrite(SYNC_OUT_PIN, !SYNC_PULSE_STATE);
            fastDigitalWrite(SYNC_EVERY_N_PIN, !SYNC_PULSE_STATE);
            needSyncOutReset = false;
        }
    }
    fastDigitalWrite(SYNC_OUT_PIN, SYNC_PULSE_STATE);
    captureDisplacement();
    usCnt -= usLoop; // usCnt = totalLag?

    if (--syncEveryNCount <= 0)
    {
        fastDigitalWrite(SYNC_EVERY_N_PIN, SYNC_PULSE_STATE);
        syncEveryNCount = SAMPLES_PER_CAMERA_FRAME;
    }
    needSyncOutReset = true;
}

static inline void sendAnyUpdate()
{
    // Print Velocity
    while ((!bufA.isEmpty()) && (!(bufB.isEmpty())))
    {
        transmitDisplacementChar(bufA.shift());
        transmitDisplacementChar(bufB.shift());
        Serial.write('\r');
    }
}

static inline void captureDisplacement()
{
    sensor.left.triggerSampleCapture();
    sensor.right.triggerSampleCapture();
    const labeled_sample_t sampleA = {'L', sensor.left.readDisplacement(units)};
    const labeled_sample_t sampleB = {'R', sensor.right.readDisplacement(units)};
    bufA.push(sampleA);
    bufB.push(sampleB);
}

// Fixed-Size Buffer Conversion to ASCII char array
void transmitDisplacementChar(const labeled_sample_t sample)
{
    // Precision and Max-Width of String Representation of Floats
    static const unsigned char decimalPlaces = 3;
    static const signed char width = ((CHAR_BUFFER_NUM_BYTES - 2) / 3) - 2;
    static const size_t increment = width + 2;

    // Initialize Char-array and Char-Pointer Representation of Buffer
    char cbufArray[CHAR_BUFFER_NUM_BYTES];
    char *cbuf = (char *)cbufArray;

    // Initialize with ASCII Space (32)
    memset(cbuf, (int)(' '), CHAR_BUFFER_NUM_BYTES);

    // Set first Char with ID
    cbufArray[0] = sample.id;
    cbufArray[1] = ID_DATA_DELIM;

    // Jump by Increment and Fill with Limited Width Float->ASCII
    size_t offset = 2;
    dtostrf(sample.p.dx, width, decimalPlaces, cbuf + offset);
    cbufArray[offset + width] = DATA_DELIM;
    offset += increment;
    dtostrf(sample.p.dy, width, decimalPlaces, cbuf + offset);
    cbufArray[offset + width] = DATA_DELIM;
    offset += increment;
    dtostrf(sample.p.dt, width, decimalPlaces, cbuf + offset);

    // Print Buffered Array to Serial
    cbufArray[offset + width] = MSG_TERMINATOR;
    // cbufArray[offset + width + 1] = '\0';
    Serial.write(cbufArray, CHAR_BUFFER_NUM_BYTES - 1);
}

//  Variable-Size Conversion to ASCII Strings
void transmitDisplacementString(const labeled_sample_t sample)
{
    // Precision
    const unsigned char decimalPlaces = 3;

    // Convert to String class
    const String dx = String(sample.p.dx, decimalPlaces);
    const String dy = String(sample.p.dy, decimalPlaces);
    const String dt = String(sample.p.dt, decimalPlaces);

    // Print ASCII Strings
    Serial.print(sample.id + ID_DATA_DELIM + dx + DATA_DELIM + dy + DATA_DELIM + dt + MSG_TERMINATOR);
}