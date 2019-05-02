// #include <math.h> //this was included for the sine function
// #include <Arduino.h> //this was included for the Serial.readbytes command
// #include <elapsedMillis.h>
// #include <DigitalIO.h>
// #include <IntervalTimer.h>
//
// 
// char matlabdata[50];
// char delimiter = ',';
// const uint8_t decimals = 10;
// const float TRIAL_LENGTH = 30000; // ms
// const uint8_t NO_TRIALS = 10;
//
// const uint8_t PUFF_PIN = 3; // pin to use for PUFF
// const float PUFF_START = 11700; // ms
// const float PUFF_LENGTH = 100.0; //in ms
// bool PUFF = false;
//
// const uint8_t TONE_PIN = 4;
// const float TONE_START = 11100; // ms
// const float TONE_LENGTH = 350.0; //in ms
// bool TONE = false;
//
// const uint8_t CAMERA_PIN = 5;
// const uint8_t CAMERA_FQ = 20; // Hz
// elapsedMillis experiment_t;
// elapsedMillis trial_t;
// IntervalTimer trial_timer;
//
// int frame_no;
// int trial_no;
//
// typedef struct {
//   uint16_t frame_in_trial = 0;
//   float trial_time = 0;
//   float experiment_time = 0;
//   uint8_t trial_number = 0;
//   bool puff_on = false;
//   bool tone_on = false;
//
// } frame_data;
//
// void sendData(frame_data frame);
// void begin();
// void capture();
//
// void setup() {
//   fastPinMode(PUFF_PIN, OUTPUT);
//   fastPinMode(TONE_PIN, OUTPUT);
//   fastPinMode(CAMERA_PIN, OUTPUT);
//   Serial.begin(115200);
//   begin();
//
// }
//
// void loop(){
// //  if (!isRunning && !Serial.read()) {
//     //add in Serial comprehension/parsing here once we find out what the user might want
//     //Serial.readBytes(matlabdata, sizeof(matlabdata)); //used from controller_main_synchronous file
//     //samplefreq = strtok(matlabdata,",");
//     //float samplefreq = atof(samplefreq);
//     //loopfreq = strtok(NULL,",");
//     //float loopfreq = atof(loopfreq);
//   //}
// }
//
// void begin() {
//     experiment_t = 0;
//     trial_t = 0;
//     trial_no = 1;
//     frame_no = 0;
//     trial_timer.begin(capture,1000000.0/(float)CAMERA_FQ);
// }
// void endCollection() {
//   trial_timer.end();
// }
//
// void capture() {
//   frame_no++;
//   if (trial_t > TRIAL_LENGTH) {
//     trial_no++;
//     trial_t = 0;
//   }
//   // update tone
//   if ((trial_t > TONE_START) && (trial_t < (TONE_START+TONE_LENGTH))) {
//     TONE = true;
//     fastDigitalWrite(TONE_PIN,HIGH);
//   } else if ((trial_t > (TONE_START + TONE_LENGTH)) && TONE) {
//     TONE = false;
//     fastDigitalWrite(TONE_PIN, LOW);
//   }
//   if ((trial_t > PUFF_START) && (trial_t < (PUFF_START+PUFF_LENGTH))) {
//     PUFF = true;
//     fastDigitalWrite(PUFF_PIN, HIGH);
//   } else if ((trial_t > (PUFF_START + PUFF_LENGTH)) && PUFF) {
//     PUFF = false;
//     fastDigitalWrite(PUFF_PIN, LOW);
//   }
//
//   fastDigitalWrite(CAMERA_PIN,HIGH);
//   delay(1);
//   fastDigitalWrite(CAMERA_PIN,LOW);
//
//   // create output struct
//   frame_data curr_frame = {frame_no, trial_t, experiment_t, trial_no, PUFF, TONE};
//   sendData(curr_frame);
// }
//
// void sendData(frame_data frame) {
//   String exp_time = String(frame.experiment_time, decimals);
//   String tri_time = String(frame.trial_time, decimals);
//   String trial_no = String(frame.trial_number);
//   String puff = String(frame.puff_on ? "true": "false");
//   String tone = String(frame.tone_on ? "true": "false");
//   Serial.println( exp_time + delimiter + tri_time + delimiter + trial_no + delimiter + puff + delimiter + tone);
// }
