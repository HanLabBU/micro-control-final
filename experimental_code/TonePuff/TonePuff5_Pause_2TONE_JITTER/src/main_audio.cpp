#include <math.h> //this was included for the sine function
#include <Arduino.h> //this was included for the Serial.readbytes command
#include <elapsedMillis.h>
#include <DigitalIO.h>
#include <IntervalTimer.h>
#include <Audio.h>
#include <Wire.h>
#include <SPI.h>
#include <SD.h>
#include <SerialFlash.h>
#include <main_conf.h>
#include <algorithm>

void getRandomFrames(int *range_ms, uint32_t nreps)
{
  trial_lengths.clear();
  int range_frames[2];
  for (int j=0; j < 2; j++)
  {
    range_frames[j] = static_cast<int>(round((*range_ms)*1000/samp_interval_us_int));
    range_ms++;
  }
  // Serial.println(String(range_frames[0])+','+String(range_frames[1]));
  trial_lengths.push_back(rand() % range_frames[1] + range_frames[0]);
  int element = 1;
  while (trial_lengths.size() < nreps)
  {
    trial_lengths.push_back(trial_lengths[element-1] + rand() % range_frames[1] + range_frames[0]);
    element++;
  }
}

std::vector<int> toneIndsFromLength(std::vector<int> trial_inds, float start_ms, float len_ms) {
  std::vector<int> tone_inds;
  int start_inds = static_cast<int>(round(start_ms/samp_interval_us_int*1000));
  int len_inds = static_cast<int>(round(len_ms/samp_interval_us_int*1000));

  for (int j=0; j < len_inds; j++) {
    tone_inds.push_back(start_inds+j+1);
  }

   for (uint32_t j=0; j < trial_inds.size()-1; j++) {
     for (int i=0; i < len_inds; i++) {
       tone_inds.push_back(trial_inds[j]+start_inds+i+1);
     }
   }
   return tone_inds;
}



std::vector<int> getRandomTrials(int no_trial1, int no_trial2) {
  int total_trials = no_trial1 + no_trial2;
  std::vector<int> trial_list;
  // below with assistance from http://www.cplusplus.com/reference/algorithm/random_shuffle/
  for (int i=1; i<=total_trials; i++) {
    trial_list.push_back(i);
  }
  std::random_shuffle(trial_list.begin(), trial_list.end());
  //
  for (int i=0; i<no_trial2; i++) trial_list.pop_back();
  return trial_list;
}

void setup() {
  fastPinMode(PUFF_PIN, OUTPUT);
  fastPinMode(CAMERA_PIN, OUTPUT);
  fastDigitalWrite(CAMERA_PIN, LOW);
  fastPinMode(LED_PIN, OUTPUT);
  fastPinMode(AMP_PIN, OUTPUT); // add amplifier
  fastDigitalWrite(AMP_PIN, HIGH);
  Serial.begin(115200);
  AudioMemory(128);
  sine1.frequency(FQ1);
  sine1.amplitude(0);
}

void loop(){
 if (!isRunning && (Serial.available() > 0)) {
    // add in Serial comprehension/parsing here once we find out what the user might want
    Serial.readBytes(matlabdata, sizeof(matlabdata)); //used from controller_main_synchronous file
    char *trial_length_str = strtok(matlabdata,",");
    float trial_length = atof(trial_length_str);

    char *trial_jitter_str = strtok(NULL,",");
    float trial_jitter = atof(trial_jitter_str);

    char *no_tone1_trials = strtok(NULL,",");
    long tone1_trials = atol(no_tone1_trials);

    char *no_tone2_trials = strtok(NULL,",");
    long tone2_trials = atol(no_tone2_trials);

    NO_TRIALS = tone1_trials+tone2_trials;
    updateParams();

    range_in_ms[0] = trial_length-trial_jitter;
    range_in_ms[1] = trial_jitter+trial_jitter;

    getRandomFrames(range_in_ms, uint32_t(tone1_trials+tone2_trials));

    getRandomTrials(tone1_trials, tone2_trials);

    TONE_INDS = toneIndsFromLength(trial_lengths, TONE1_START, TONE1_LENGTH);
    PUFF_INDS = toneIndsFromLength(trial_lengths, PUFF_START, PUFF_LENGTH);
    TONE1_TRIALS = getRandomTrials(tone1_trials, tone2_trials);

      Serial.println(String(tone1_trials+tone2_trials) + ',' + String(trial_length) + ',' + String(PUFF_START) +
        ',' + String(PUFF_LENGTH) + ',' + String(TONE1_START) + ',' + String(TONE1_LENGTH) + ',' +
        String(FQ1) + ',' + String(FQ2) + ',' + String(trial_lengths[0])+','+String(trial_lengths[1])+','+String(trial_lengths[2]));

    begin();
    fastDigitalWrite(CAMERA_PIN, !CAMERA_ON_STATE);

  }
}

void begin() {

    delay(10);
    initializeExpParams();
    char stopTrial[50];
    float interval_t = 1000000.0/(float)CAMERA_FQ;

    while (isRunning) {
        while (frame_t < interval_t) {
          ;
        }
        frame_t -= interval_t;
        capture();
        if (Serial.available() > 0) {
          Serial.readBytes(stopTrial,sizeof(stopTrial));
            endCollection();
        }
      }
    }

void updateParams() {
  char *PUFF_START_char = strtok(NULL,",");
  PUFF_START = atof(PUFF_START_char);
  char *PUFF_LENGTH_char = strtok(NULL,",");
  PUFF_LENGTH = atof(PUFF_LENGTH_char);

  char *TONE1_START_char = strtok(NULL,",");
  TONE1_START = atof(TONE1_START_char);
  char *TONE1_LENGTH_char = strtok(NULL,",");
  TONE1_LENGTH = atof(TONE1_LENGTH_char);

  char *FQ_1_char = strtok(NULL,",");
  FQ1 = strtol(FQ_1_char,NULL,0);
  char *TONE1_AMP_char = strtok(NULL,",");
  TONE1_AMP = atof(TONE1_AMP_char);

  char *FQ_2_char = strtok(NULL,",");
  FQ2 = strtol(FQ_2_char,NULL,0);
  char *TONE2_AMP_char = strtok(NULL,",");
  TONE2_AMP = atof(TONE2_AMP_char);

}

void initializeExpParams() {
  experiment_t = 0;
  trial_t = 0;
  trial_no = 0;
  frame_no = 0;
  frame_t = 0;
  isRunning = true;
  fastDigitalWrite(LED_PIN, LOW);
  fastDigitalWrite(PUFF_PIN, LOW);
  fastDigitalWrite(CAMERA_PIN, LOW);
  TONE1 = false;
  TONE2 = false;
  LED = false;
  PUFF = false;
  sine1.amplitude(0);
}

void endCollection() {
  trial_timer.end();
  fastDigitalWrite(LED_PIN, LOW);
  fastDigitalWrite(PUFF_PIN, LOW);
  fastDigitalWrite(CAMERA_PIN, !CAMERA_ON_STATE);
  TONE1 = false;
  TONE2 = false;
  LED = false;
  PUFF = false;
  sine1.amplitude(0);
  isRunning = false;
  Serial.println("END\n");
}

void capture() {
  curr_t = trial_t;
  exp_t = experiment_t;
  if (trial_no == 0) {
    trial_no++;
    trial_t = 0;
    experiment_t = 0;
    curr_t = trial_t;
    exp_t = experiment_t;
  }
  frame_no++;


  if ((frame_no > trial_lengths[trial_no-1])) {
    trial_no++;
    if (trial_no > NO_TRIALS) {
      endCollection();
      return;
    }
    trial_t = 0;
    curr_t = trial_t;
  }

  toggleTONE(trial_no, frame_no);
  togglePUFF(trial_no, frame_no);

  frame_data curr_frame = {frame_no, curr_t, exp_t, trial_no, PUFF, TONE1, TONE2, LED};
  elapsedMicros campulse_t = 0;
  fastDigitalWrite(CAMERA_PIN, CAMERA_ON_STATE);
  while (campulse_t < CAMERA_PULSE_MIN_MICROS){;}
  fastDigitalWrite(CAMERA_PIN, !CAMERA_ON_STATE);
  sendData(curr_frame);
}

void togglePUFF(int trial_no, int frame_no) {
  if (std::find(PUFF_INDS.begin(), PUFF_INDS.end(),frame_no) != PUFF_INDS.end()) {
    if (std::find(TONE1_TRIALS.begin(), TONE1_TRIALS.end(), trial_no) != TONE1_TRIALS.end()) {
      PUFF = true;
      fastDigitalWrite(PUFF_PIN, HIGH);
    }
  } else if (PUFF) {
    PUFF = false;
    fastDigitalWrite(PUFF_PIN, LOW);
  }

}

void toggleTONE(int trial_no, int frame_no) {
  // update tone
  if (std::find(TONE_INDS.begin(), TONE_INDS.end(),frame_no) != TONE_INDS.end()) {
    if (std::find(TONE1_TRIALS.begin(), TONE1_TRIALS.end(),trial_no) != TONE1_TRIALS.end()) {
       if (!TONE1) {
        TONE1 = true;
        sine1.frequency(FQ1);
        sine1.amplitude(TONE1_AMP);
        LED = true;
        fastDigitalWrite(LED_PIN, HIGH);
      }
    }
    else if (!TONE2) {
        sine1.frequency(FQ2);
        sine1.amplitude(TONE2_AMP);
        TONE2 = true;
    }
  } else if (TONE1 || TONE2) {
      if (std::find(TONE_INDS.begin(), TONE_INDS.end(), frame_no) == TONE_INDS.end()) {
        TONE1 = false;
        TONE2 = false;
        LED = false;
        sine1.amplitude(0);
        fastDigitalWrite(LED_PIN, LOW);
    }
  }
}

void sendData(frame_data frame) {
  String exp_time = String(frame.experiment_time);
  String tri_time = String(frame.trial_time);
  String trial_no = String(frame.trial_number);
  String puff = String(frame.puff_on ? "1": "0");
  String tone1 = String(frame.tone1_on ? "1": "0");
  String tone2 = String(frame.tone2_on ? "1": "0");
  String led = String(frame.led_on ? "1": "0");
  Serial.println( exp_time + delimiter + tri_time + delimiter + trial_no + delimiter + puff + delimiter + tone1 + delimiter + tone2 + delimiter + led);
}
