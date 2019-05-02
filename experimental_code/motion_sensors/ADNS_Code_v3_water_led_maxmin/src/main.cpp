/*

  main.cpp

*/
// Include Config-file (moved for code clarity)
#include "main_config.h"
#include "vector"
const String fileVersion = __TIMESTAMP__;

// Create Sensor Objects with Specified Slave-Select Pins
ADNS adnsA(CS_PIN_A);
ADNS adnsB(CS_PIN_B);
sensor_pair_t sensor = {adnsA, adnsB};

// Capture Task (on interrupt)
IntervalTimer captureTimer;

// Counter and Timestamp Generator
elapsedMillis millisSinceAcquisitionStart;
elapsedMicros microsSinceFrameStart;
// volatile time_t currentSampleTimestamp;
volatile time_t currentFrameTimestamp;
volatile time_t currentFrameDuration;
volatile uint32_t currentFrameCount;
volatile bool isRunning = false;

//added the next 5 lines for water pin
std::vector<int> waterFrames;
volatile uint32_t waterIndex;
int range_in_seconds[2];
volatile uint16_t waterLength;
volatile uint32_t nreps = 0;
volatile bool waterPinON = false;
// =============================================================================
//   SETUP & LOOP
// =============================================================================
#include "DeviceLib/devicemanager.h"
void setup() {
  delay(400);
  initializeCommunication();

  delay(400);

  initializeSensors();

  initializeTriggering();

  while (Serial.available()) {
    Serial.read();
  }

}

void loop() {
    if ((!isRunning) && (Serial.available() > 0)) {
        char matlab_input[50];
        beginAcquisition(matlab_input, 50);
        while (currentFrameCount < nreps) {
          ;
        }
        endAcquisition();
      }
  }


// =============================================================================
//   TASKS: INITIALIZE
// =============================================================================
inline static bool initializeCommunication() {
  // Begin Serial
  Serial.begin(115200);
  while (!Serial) {
    ;  // may only be needed for native USB port
  }
  delay(10);
  return true;
};

inline static bool initializeSensors() {
  // Begin Sensors
  sensor.left.begin();
  delay(30);
  sensor.right.begin();
  delay(30);
  return true;
};

inline static bool initializeTriggering() {
  fastPinMode(TRIGGER_PIN, OUTPUT);
  fastDigitalWrite(TRIGGER_PIN, LOW);
  fastPinMode(WATER_PIN, OUTPUT);
  fastDigitalWrite(WATER_PIN, LOW);
  fastPinMode(LED_PIN, OUTPUT);
  fastDigitalWrite(LED_PIN, LOW);
  delay(1);
  // Setup Sync/Trigger-Output Timing
  // FrequencyTimer2::setPeriod(1e6 / DISPLACEMENT_SAMPLE_RATE)
  return true;
};

static inline void beginAcquisition(char input[], int8_t length) {
    delay(500);
    Serial.readBytes(input, length);
    //Parse input
    char *trial_length_minutes = strtok(input,",");
    float trial_length_minutes_int = atof(trial_length_minutes);
    char *sampling_interval_ms = strtok(NULL,",");
    float sampling_interval_ms_int = atof(sampling_interval_ms);
    char *water_spacing_s = strtok(NULL,",");
    float water_spacing_s_int = atof(water_spacing_s);
    char *water_jitter_s = strtok(NULL,",");
    float water_jitter_s_int = atof(water_jitter_s);


    nreps = floor(trial_length_minutes_int*60.0*1000.0/sampling_interval_ms_int);
    Serial.println((nreps));
    Serial.println((sampling_interval_ms_int));
    Serial.println(water_jitter_s_int);
    Serial.println(water_spacing_s_int);

    range_in_seconds[0] = water_spacing_s_int-water_jitter_s_int;
    range_in_seconds[1] = water_jitter_s_int+water_jitter_s_int;

    //get random frames for
    getRandomFrames(int(sampling_interval_ms_int), range_in_seconds, int(nreps));
    waterLength = 100/int(sampling_interval_ms_int);

    waterIndex = 0;

    // Print units and Fieldnames (header)
    sendHeader();

    // Trigger start using class methods in ADNS library
    sensor.left.triggerAcquisitionStart();
    sensor.right.triggerAcquisitionStart();

    // Flush sensors (should happen automatically -> needs bug fix)
    sensor.left.triggerSampleCapture();
    sensor.right.triggerSampleCapture();

    // Change State
    isRunning = true;

    // Reset Elapsed Time Counter
    millisSinceAcquisitionStart = 0;

    // currentSampleTimestamp = microsSinceAcquisitionStart;
    currentFrameTimestamp = millisSinceAcquisitionStart;

    currentFrameCount = 0;

    fastDigitalWrite(TRIGGER_PIN,HIGH);

    captureTimer.begin(captureDisplacement, sampling_interval_ms_int*1000);
}

void getRandomFrames(int samp_interval_ms_int, int *range_secs, int nreps)
{
  waterFrames.clear();
  int range_frames[2];
  for (int j=0; j < 2; j++)
  {
    range_frames[j] = ((*range_secs)*1000/samp_interval_ms_int);
    range_secs++;
  }
  waterFrames.push_back(rand() % range_frames[1] + range_frames[0]);
  int element = 1;
  while (waterFrames[element-1] < nreps)
  {
    waterFrames.push_back(waterFrames[element-1] + rand() % range_frames[1] + range_frames[0]);
    element++;
  }
}

static inline void endAcquisition() {
    // End IntervalTimer
    captureTimer.end();
    waterFrames.clear();
    waterPinON = false;
    fastDigitalWrite(TRIGGER_PIN, LOW);
    fastDigitalWrite(WATER_PIN, LOW);
    fastDigitalWrite(LED_PIN, LOW);
    // Trigger start using class methods in ADNS library
    sensor.left.triggerAcquisitionStop();
    sensor.right.triggerAcquisitionStop();

    // Change state
    isRunning = false;
}

// =============================================================================
// TASKS: TRIGGERED_ACQUISITION
// =============================================================================
void captureDisplacement() {
  // // Unset Trigger Outputs
  fastDigitalWrite(TRIGGER_PIN,LOW);
  // Initialize container for combined & stamped sample
  sensor_sample_t currentSample;
  currentSample.timestamp = currentFrameTimestamp; // maybe fix this time stamp issue?

  // Trigger capture from each sensor
  sensor.left.triggerSampleCapture();
  sensor.right.triggerSampleCapture();

  // Store timestamp for next frame

  if (currentFrameCount == waterFrames[waterIndex]) {
    fastDigitalWrite(WATER_PIN,HIGH);
    fastDigitalWrite(LED_PIN, HIGH);
    waterPinON = true;
  }
  else if (currentFrameCount == (waterFrames[waterIndex]+waterLength)) {
      fastDigitalWrite(WATER_PIN,LOW);
      fastDigitalWrite(LED_PIN, LOW);
      waterIndex++;
      waterPinON = false;
    }

  currentFrameCount += 1;

  currentSample.left = {'L', sensor.left.readDisplacement(units)};
  currentSample.right = {'R', sensor.right.readDisplacement(units)};

  // Send Data
  sendData(currentSample,waterPinON);
  currentFrameTimestamp = millisSinceAcquisitionStart;

  fastDigitalWrite(TRIGGER_PIN,HIGH);
  delayMicroseconds(500);
  fastDigitalWrite(TRIGGER_PIN,LOW);
}

// =============================================================================
// TASKS: DATA_TRANSFER
// =============================================================================

void sendHeader() {
  const String dunit = getAbbreviation(units.distance);
  const String tunit = getAbbreviation(units.time);
  // Serial.flush();
  Serial.print(String(
      String("timestamp [ms]") + delimiter + flatFieldNames[0] + " [" + dunit +
      "]" + delimiter + flatFieldNames[1] + " [" + dunit + "]" + delimiter +
      flatFieldNames[2] + " [" + tunit + "]" + delimiter + "minL" +
      + delimiter + "maxL" + flatFieldNames[4] + " [" + dunit + "]" +
      delimiter + flatFieldNames[5] + " [" + dunit + "]" + delimiter + flatFieldNames[6] + " [" + tunit + "]" +
      delimiter + "minR" + delimiter + "maxR" + delimiter + " waterPin " "\n"));
}

void sendData(sensor_sample_t sample, bool waterPin) {

    // Convert to String class
    const String timestamp = String(sample.timestamp);
    const String dxL = String(sample.left.p.dx, decimalPlaces);
    const String dyL = String(sample.left.p.dy, decimalPlaces);
    const String dtL = String(sample.left.p.dt, decimalPlaces);
    const String minL = String(sample.left.p.min);
    const String maxL = String(sample.left.p.max);
    const String dxR = String(sample.right.p.dx, decimalPlaces);
    const String dyR = String(sample.right.p.dy, decimalPlaces);
    const String dtR = String(sample.right.p.dt, decimalPlaces);
    const String waterPinVal = (waterPin ? "1" : "0");
    const String endline = String("\n");
    const String minR = String(sample.right.p.min);
    const String maxR = String(sample.right.p.max);

    // Serial.availableForWrite
    // Print ASCII Strings
    Serial.print(timestamp + delimiter + dxL + delimiter + dyL + delimiter +
                 dtL + delimiter + minL + delimiter + maxL +delimiter + dxR + delimiter + dyR + delimiter + dtR + delimiter + minR + delimiter + maxR + delimiter + waterPinVal +
                 endline);
}