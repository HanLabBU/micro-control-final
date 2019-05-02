#  Romano et al. (2019), https://www.ncbi.nlm.nih.gov/pubmed/30946877

This is the repository that corresponds with Romano et al. (2019). Various experiments are located in experimental_code, divided into "motion_sensors" and "tone_puff"

## in order to use
* download [Atom](https://atom.io/) and add platform.io
* build folder
* slight modifications are needed in order to use DigitalIO: open .piolibdeps, navigate to DigitalIO
* open .piolibdeps/DigitalIO_ID200/src/DigitalPin.h
* scroll to line 278
* replace `inline void fastPinMode(pin, mode)` with `inline void fastPinMode(uint8_t pin, uint8_t mode)` and rebuild
* upload folder to Teensy 3.2
* open MATLAB (>= v2017b)
* read the README.txt file in the corresponding folder, and run the Userpopup* that is necessary
* the most recent tested versions for motion sensor are ADNS_Code_v4_PAUSE (If extra pins are desired at random intervals, use ADNS_Code_v3_water_led*)
* the most recent tested versions for tone puff design are TonePuff5_Pause_2TONE_JITTER. In order to use only a single tone, set one of the tones to duration 0. In order to have un-jittered trials, set jitter to 0.
