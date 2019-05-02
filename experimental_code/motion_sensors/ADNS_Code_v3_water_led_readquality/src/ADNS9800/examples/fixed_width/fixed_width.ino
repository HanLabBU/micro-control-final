/*

  main.cpp

*/
#include <Arduino.h>

// Arduino Includes
#include <SPI.h>
#include <elapsedMillis.h>
#include <CircularBuffer.h>
#include <DigitalIO.h>

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
#define FIXED_SIZE_ID_DELIM ':'
#define FIXED_SIZE_DATA_DELIM ','
#define FIXED_SIZE_MSG_TERMINATOR '\t'

enum class TransmitFormat
{
    FIXED,
    DELIMITED,
    JSON,
    BINARY //todo binary stream
};

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
const int32_t DISPLACEMENT_FPS = (CAMERA_FPS * SAMPLES_PER_CAMERA_FRAME);
const uint32_t usLoop = 1e6 / DISPLACEMENT_FPS;
volatile int syncEveryNCount = SAMPLES_PER_CAMERA_FRAME;

// Delimiter & Precision for Conversion to String
const TransmitFormat format = TransmitFormat::FIXED;
const unit_specification_t units = {
    Unit::Distance::MICROMETER,
    Unit::Time::MICROSECOND};
const char delimiter = '\t';
const unsigned char decimalPlaces = 3;
const bool waitBeforeStart = false;

// Sensor and Field Names
typedef String sensor_name_t;
typedef String field_name_t;
const sensor_name_t sensorNames[] = {"left", "right"};
const field_name_t fieldNames[] = {"dx", "dy", "dt"};
const String flatFieldNames[] =
    {
        sensorNames[0] + '_' + fieldNames[0],
        sensorNames[0] + '_' + fieldNames[1],
        sensorNames[0] + '_' + fieldNames[2],
        sensorNames[1] + '_' + fieldNames[0],
        sensorNames[1] + '_' + fieldNames[1],
        sensorNames[1] + '_' + fieldNames[2]};

// Initialize microsecond counter and sample buffer
elapsedMicros usCnt;
CircularBuffer<labeled_sample_t, 3> bufA;
CircularBuffer<labeled_sample_t, 3> bufB;
uint32_t sensorSampleCnt = 0;
uint32_t cameraFrameCnt = 0;
uint32_t sampleCntTarget = 0;

// Declare Test Functions
static inline void sendFormat();
static inline void sendAnyUpdate();
static inline void checkCmd();
static inline void captureDisplacement();
void transmitDisplacementBinary(const labeled_sample_t);
void transmitDisplacementDelimitedString(const labeled_sample_t);
void transmitDisplacementFixedSize(const labeled_sample_t);

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

    // Print units and Fieldnames (header)
    sendFormat();

    checkCmd();

    // Start Acquisition
    usCnt = 0;
    sensor.left.triggerAcquisitionStart();
    sensor.right.triggerAcquisitionStart();

    // Send Sync-Every-N Pulse (at start of first and every N subsequent frames)
    fastDigitalWrite(SYNC_OUT_PIN, SYNC_PULSE_STATE);
    fastDigitalWrite(SYNC_EVERY_N_PIN, SYNC_PULSE_STATE);
    syncEveryNCount = SAMPLES_PER_CAMERA_FRAME;
};

// =============================================================================
//   LOOP
// =============================================================================
void loop()
{
    sendAnyUpdate();

    // Reset Trigger Outputs
    static bool needSyncOutReset = true;
    while (usCnt < usLoop)
    {
        if (needSyncOutReset && (usCnt > SYNC_PULSE_WIDTH_MICROS))
        {
            fastDigitalWrite(SYNC_OUT_PIN, !SYNC_PULSE_STATE);
            fastDigitalWrite(SYNC_EVERY_N_PIN, !SYNC_PULSE_STATE);
            needSyncOutReset = false;
        }
    }

    checkCmd();

    // Set Downsampled ("Camera") Trigger Output Every N Samples
    if (--syncEveryNCount <= 0)
    {
        fastDigitalWrite(SYNC_EVERY_N_PIN, SYNC_PULSE_STATE);
        syncEveryNCount = SAMPLES_PER_CAMERA_FRAME;
    }

    // Initiate Sample Capture
    fastDigitalWrite(SYNC_OUT_PIN, SYNC_PULSE_STATE);
    captureDisplacement();
    usCnt -= usLoop; // usCnt = totalLag?

    needSyncOutReset = true;
}

static inline void sendFormat()
{
    const String dunit = getAbbreviation(units.distance);
    const String tunit = getAbbreviation(units.time);
    if (format == TransmitFormat::FIXED)
    {
        Serial.println("\n\n\n");
        Serial.println("label\t" + dunit + "\t\t" + dunit + "\t\t" + tunit + "\t" +
                       "label\t" + dunit + "\t\t" + dunit + "\t\t" + tunit);
    }
    else
    {

        Serial.print(
            String(
                flatFieldNames[0] + " [" + dunit + "]" + delimiter +
                flatFieldNames[1] + " [" + dunit + "]" + delimiter +
                flatFieldNames[2] + " [" + tunit + "]" + delimiter +
                flatFieldNames[3] + " [" + dunit + "]" + delimiter +
                flatFieldNames[4] + " [" + dunit + "]" + delimiter +
                flatFieldNames[5] + " [" + tunit + "]" + delimiter +
                '\n'));
    }
}

static inline void checkCmd()
{
    // Read Serial to see if request for more frames has been sent
    if (waitBeforeStart)
    {
        if (Serial.available() || (sampleCntTarget < 0))
        {
            while (!Serial.available())
                delayMicroseconds(100);

            uint32_t moreFramesCnt = Serial.parseInt();
            sampleCntTarget += (SAMPLES_PER_CAMERA_FRAME * moreFramesCnt);
            //todo pause
        }
        sampleCntTarget--;
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

static inline void sendAnyUpdate()
{
    // Print Velocity
    while ((!bufA.isEmpty()) && (!(bufB.isEmpty())))
    {
        switch (format)
        {
        case (TransmitFormat::FIXED):
            transmitDisplacementFixedSize(bufA.shift());
            transmitDisplacementFixedSize(bufB.shift());
            Serial.write('\r');
            break;
        case (TransmitFormat::DELIMITED):
            transmitDisplacementDelimitedString(bufA.shift());
            transmitDisplacementDelimitedString(bufB.shift());
            Serial.print('\n');
            break;
        case (TransmitFormat::BINARY):
            transmitDisplacementBinary(bufA.shift());
            transmitDisplacementBinary(bufB.shift());
            break;
        case (TransmitFormat::JSON):
            //todo
            break;
        default:
            break;
        }
    }
}

void transmitDisplacementBinary(const labeled_sample_t sample)
{
    //todo not working -> serialize with standard library
    // cast floats to bytes todo: make architecture invariant
    const size_t numBytes = 12;
    char buf[12];
    typedef union {
        float real;
        uint32_t base;
    } f2u;
    const f2u dxyt[3] = {sample.p.dx, sample.p.dy, sample.p.dt};
    for (int f = 0; f < 3; f++)
    {
        for (int b = 0; b < 4; b++)
        {
            *(buf + (f * b)) = ((dxyt[3 - f].base) >> (8 * b)) & 0xFF;
        }
    }
    Serial.write(buf, numBytes);
}

//  Variable-Size Conversion to ASCII Strings
void transmitDisplacementDelimitedString(const labeled_sample_t sample)
{
    // Convert to String class
    const String dx = String(sample.p.dx, decimalPlaces);
    const String dy = String(sample.p.dy, decimalPlaces);
    const String dt = String(sample.p.dt, decimalPlaces);

    // Print ASCII Strings
    Serial.print(
        dx + delimiter +
        dy + delimiter +
        dt + delimiter);
}

// Fixed-Size Buffer Conversion to ASCII char array
void transmitDisplacementFixedSize(const labeled_sample_t sample)
{
    static const signed char width = ((CHAR_BUFFER_NUM_BYTES - 2) / 3) - 2;
    static const size_t increment = width + 2;

    // Initialize Char-array and Char-Pointer Representation of Buffer
    char cbufArray[CHAR_BUFFER_NUM_BYTES];
    char *cbuf = (char *)cbufArray;

    // Initialize with ASCII Space (32)
    memset(cbuf, (int)(' '), CHAR_BUFFER_NUM_BYTES);

    // Set first Char with ID
    cbufArray[0] = sample.id;
    cbufArray[1] = FIXED_SIZE_ID_DELIM;

    // Jump by Increment and Fill with Limited Width Float->ASCII
    size_t offset = 2;
    dtostrf(sample.p.dx, width, decimalPlaces, cbuf + offset);
    cbufArray[offset + width] = FIXED_SIZE_DATA_DELIM;
    offset += increment;
    dtostrf(sample.p.dy, width, decimalPlaces, cbuf + offset);
    cbufArray[offset + width] = FIXED_SIZE_DATA_DELIM;
    offset += increment;
    dtostrf(sample.p.dt, width, decimalPlaces, cbuf + offset);

    // Print Buffered Array to Serial
    cbufArray[offset + width] = FIXED_SIZE_MSG_TERMINATOR;
    // cbufArray[offset + width + 1] = '\0';
    Serial.write(cbufArray, CHAR_BUFFER_NUM_BYTES - 1);
}
