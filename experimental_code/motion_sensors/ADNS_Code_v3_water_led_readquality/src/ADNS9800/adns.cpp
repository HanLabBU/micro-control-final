/*
  ADNS.cpp - Library for communicating with ADNS-9800 laser mouse sensor.
  Created by Mark Bucklin, May 21, 2014.
  Adapted from mrjohnk: https://github.com/mrjohnk/ADNS-9800
  Updated 7/1/2017
*/

#include "adns.h"

// =============================================================================
//   Setup
// =============================================================================
bool ADNS::begin(const uint16_t cpi, const uint16_t hz) {
  _resolutionCountsPerInch = cpi;
  _maxSamplePeriodUs = (uint16_t)(1000000UL / (uint32_t)hz);
  initialize();
  return true;
}

String ADNS::getName() {
  String chip = String(ADNS_NAME);
  String pin = String("_pin") + String(_chipSelectPin, DEC);
  String name = chip + pin;
  return name;
}

// =============================================================================
// Trigger Start, Capture, & Readout
// =============================================================================

void ADNS::triggerAcquisitionStart() {
  // Check Initialized & Running State
  if (!_initializedFlag) initialize();
  if (_runningFlag) triggerAcquisitionStop();

  // Flush Sample Registers -> Write 0 to Motion Register
  noInterrupts();
  select();
  // // SPI.transfer((uint8_t)RegisterAddress::Motion | 0x80);
  // // SPI.transfer(0x00);
  SPI.transfer((uint8_t)RegisterAddress::Motion_Burst & 0x7f);
  SPI.transfer(_readout.data, adns_readout_max_size);

  // Set Start-Time Microsecond Offset
  _microsSinceStart = 0;
  _microsSinceCapture = _microsSinceStart;

  // Zero all Position and Readout Data
  memset(&_position, 0, sizeof(_position));
  memset(&_readout, 0, sizeof(_readout));
  memset(&_sample, 0, sizeof(_sample));

  // Release SPI Bus and Interrupts Hold
  deselect();

  // Set Flag to Indicate Running State
  _runningFlag = true;

  interrupts();
}

// Read from ADNS9800 Sensor and Update _currentCapture & _sample
void ADNS::triggerSampleCapture() {
  // Trigger Start if Not Running
  if (!_runningFlag) triggerAcquisitionStart();

  // Wait if min sample period has not passed
  while (_microsSinceCapture < _minSamplePeriodUs) {
    yield();
  };

  // Disable Interrupts and Lock SPI Bus
  noInterrupts();
  select();

  // Read from Motion or Motion_Burst Address to Latch Data
  SPI.transfer((byte)RegisterAddress::Motion_Burst & 0x7f);

  // Read Latched Data from Sensor Registers
  // while (_microsSinceCapture < _minSamplePeriodUs) {
  //   yield();
  // };
  SPI.transfer(_readout.data, adns_readout_max_size);

  // Latch Elapsed Microseconds at End Of Sample
  uint32_t dtLatch = _microsSinceCapture;

  // Release SPI Bus
  deselect();

  // Update Elapsed-Microsecond-Since-Capture Counter
  _sample.count++;
  _sample.timestamp = _microsSinceStart;  // position.t;
  _microsSinceCapture -= dtLatch;

  // Update Displacement
  _sample.displacement.dx =
      ((int16_t)(_readout.dxL) | ((int16_t)(_readout.dxH) << 8));
  _sample.displacement.dy =
      ((int16_t)(_readout.dyL) | ((int16_t)(_readout.dyH) << 8));
  _sample.displacement.dt = dtLatch;  //((capture.endTime - capture.startTime));
  _sample.displacement.motion = _readout.motion;
  // Update Current Position Data
  _position.x += _sample.displacement.dx;
  _position.y += _sample.displacement.dy;
  _position.t += _sample.displacement.dt;

  interrupts();
}

void ADNS::triggerAcquisitionStop() {
  _runningFlag = false;
}  // todo test shutDownSensor()

// =============================================================================
// Data-Sample Conversion & Access
// =============================================================================
// todo: homogenize and combine these functions
displacement_t ADNS::readDisplacement(const unit_specification_t unit) const {
  // Initialize sample return structure
  displacement_t u;

  // Pre-Compute Conversion Coefficients for Efficiency
  const float distancePerCount =
      Unit::perInch(unit.distance) * _resolutionInchPerCount;
  const float timePerCount = Unit::perMicrosecond(unit.time);

  // Apply Conversion Coefficient
  u.dx = (float)_sample.displacement.dx * distancePerCount;
  u.dy = (float)_sample.displacement.dy * distancePerCount;
  u.dt = (float)_sample.displacement.dt * timePerCount;
  u.motion = _sample.displacement.motion;
  return u;
}

position_t ADNS::readPosition(const unit_specification_t unit) const {
  // Initialize sample return structure
  position_t p;

  // Pre-Compute Conversion Coefficients for Efficiency
  const float distancePerCount =
      Unit::perInch(unit.distance) * _resolutionInchPerCount;
  const float timePerCount = Unit::perMicrosecond(unit.time);

  // Apply Conversion Coefficient
  p.x = (float)_position.x * distancePerCount;
  p.y = (float)_position.y * distancePerCount;
  p.t = (float)_position.t * timePerCount;
  return p;
}

velocity_t ADNS::readVelocity(const unit_specification_t unit) const {
  // Initialize sample return structure
  velocity_t v;

  // Pre-Compute Conversion Coefficients for Efficiency
  const float distancePerCount =
      Unit::perInch(unit.distance) * _resolutionInchPerCount;
  const float timePerCount = Unit::perMicrosecond(unit.time);
  const float distancePerTimeInterval =
      distancePerCount * 1 / (timePerCount * (float)_sample.displacement.dt);

  // Apply Conversion Coefficient
  v.x = (float)_sample.displacement.dx * distancePerTimeInterval;
  v.y = (float)_sample.displacement.dy * distancePerTimeInterval;
  return v;
}

adns_additional_info_t ADNS::readAdditionalInfo() const {
  // Initialize output structure and ref to most recent raw readout
  adns_additional_info_t info;

  // Status in Raw Bit-Fields from Sensor Registers
  info.status.motion = _readout.motion;
  info.status.observation = _readout.observation;

  // Pixel statistics from image sensor
  static const float PXSUM_UPPER7BITS_TO_PIXELMEAN = (1 / 1.76);
  info.pixel.min = _readout.minPixel;
  info.pixel.mean =
      (uint8_t)((float)_readout.pixelSum * PXSUM_UPPER7BITS_TO_PIXELMEAN);
  info.pixel.max = _readout.maxPixel;
  info.pixel.features = _readout.surfaceQuality;

  // Period of Image Sensor Operation - Frame & Shutter (variable by default)
  static const float MICROS_PER_TICK = 1.0 / ADNS_CHIP_FREQ_MHZ;
  info.period.shutter =
      (float)makeWord(_readout.shutterPeriodH, _readout.shutterPeriodL) *
      MICROS_PER_TICK;  // microseconds
  info.period.frame =
      (float)makeWord(_readout.framePeriodH, _readout.framePeriodL) *
      MICROS_PER_TICK;  // microseconds

  // Return additional info structure
  return info;
}

void ADNS::printLastMotion() {
  // Ensure Serial Stream has Started
  if (!Serial) {
    Serial.begin(115200);
    delay(50);
  }
  // Print Timestamp of Last Sample
  Serial.print("\ntimestamp [us]:\t");
  Serial.println(_sample.timestamp);

  // Initialize Unit-Specification and Description Variables
  unit_specification_t unitType;
  String xyUnit;
  String tUnit;

  // Print Displacement
  unitType = {Unit::Distance::MILLIMETER, Unit::Time::MILLISECOND};
  xyUnit = Unit::getAbbreviation(unitType.distance);
  tUnit = Unit::getAbbreviation(unitType.time);
  displacement_t u = readDisplacement(unitType);
  Serial.print("<dx,dy,dt> [" + xyUnit + "," + xyUnit + "," + tUnit + "]\t<");
  Serial.print(u.dx, 3);
  Serial.print(",");
  Serial.print(u.dy, 3);
  Serial.print(",");
  Serial.print(u.dt, 3);
  Serial.println(">\t");

  // Print Position
  unitType = {Unit::Distance::MILLIMETER, Unit::Time::MILLISECOND};
  xyUnit = Unit::getAbbreviation(unitType.distance);
  tUnit = Unit::getAbbreviation(unitType.time);
  position_t p = readPosition(unitType);
  Serial.print("<x,y,t> [" + xyUnit + "," + xyUnit + "," + tUnit + "]\t<");
  Serial.print(p.x, 3);
  Serial.print(",");
  Serial.print(p.y, 3);
  Serial.print(",");
  Serial.print(p.t, 3);
  Serial.println(">\t");

  // Print Velocity
  unitType = {Unit::Distance::METER, Unit::Time::SECOND};
  xyUnit = Unit::getAbbreviation(unitType.distance);
  tUnit = Unit::getAbbreviation(unitType.time);
  velocity_t v = readVelocity(unitType);
  Serial.print("<Vx,Vy> [" + xyUnit + "/" + tUnit + "," + xyUnit + "/" + tUnit +
               "]\t<");
  Serial.print(v.x, 3);
  Serial.print(",");
  Serial.print(v.y, 3);
  Serial.println(">\t");
}

void ADNS::printLastAdditionalInfo() {
  // Read additional info
  const adns_additional_info_t info = readAdditionalInfo();

  // Status in Raw Bit-Fields from Sensor Registers
  Serial.print("\tmotion: ");
  Serial.print(info.status.motion, HEX);
  Serial.print("\tobservation: ");
  Serial.println(info.status.observation, HEX);

  // Pixel statistics from image sensor
  Serial.print("\tmin: ");
  Serial.print(info.pixel.min);
  Serial.print("\tmean: ");
  Serial.print(info.pixel.mean);
  Serial.print("\tmax: ");
  Serial.print(info.pixel.max);
  Serial.print("\tfeatures: ");
  Serial.println(info.pixel.features);

  // Period of Image Sensor Operation - Frame & Shutter (variable by default)
  Serial.print("\tshutter: ");
  Serial.print(info.period.shutter);
  Serial.print("\tframe: ");
  Serial.println(info.period.frame);
}

// =============================================================================
// Sensor Settings
// =============================================================================
void ADNS::setResolutionCountsPerInch(const uint16_t cpi) {
  // Input may take any value between 50 and 8200 (will be rounded to nearest 50
  // cpi)
  uint16_t cpiValid =
      constrain(cpi, ADNS_RESOLUTION_MIN_CPI, ADNS_RESOLUTION_MAX_CPI);
  // uint8_t data = readRegister(RegisterAddress::Configuration_I);
  // Keep current values from reserved bits (0x3f = B00111111) note: data sheet
  // has error, mask is 0xFF uint8_t mask = ADNS_RESOLUTION_REGISTER_MASK; data
  // = (data & ~mask) | (((uint8_t)(cpi / (uint16_t)ADNS_RESOLUTION_MIN_CPI)) &
  // mask);
  uint8_t data = (uint8_t)(cpiValid / (uint16_t)ADNS_RESOLUTION_MIN_CPI);
  writeRegister(RegisterAddress::Configuration_I, data);
  // Read back resolution from same register to confirm and store in cached
  // property
  getResolutionCountsPerInch();  // todo: check resolution matches assigned
                                 // resolution -> report
}

uint16_t ADNS::getResolutionCountsPerInch() {
  uint8_t mask = ADNS_RESOLUTION_REGISTER_MASK;
  uint8_t data = readRegister(RegisterAddress::Configuration_I);
  data = data & mask;
  uint16_t cpi = (uint16_t)data * (uint16_t)ADNS_RESOLUTION_MIN_CPI;
  _resolutionCountsPerInch = cpi;
  _resolutionInchPerCount = 1.0f / (float)cpi;
  return cpi;
}

void ADNS::setMaxSamplePeriodUs(const uint16_t us) {
  /* Configures sensor hardware -> sets the maximum frame period (minimum frame
rate) that can be selected by the automatic frame rate control, OR the actual
frame rate if the sensor is placed in manual frame rate control mode
*/
  uint8_t dataL, dataH;
  uint16_t delayNumCyles = us * ADNS_CHIP_FREQ_MHZ;
  dataL = lowByte(delayNumCyles);
  dataH = highByte(delayNumCyles);
  writeRegister(RegisterAddress::Frame_Period_Max_Bound_Lower, dataL);
  writeRegister(RegisterAddress::Frame_Period_Max_Bound_Upper, dataH);
  getMaxSamplePeriodUs();
}

uint16_t ADNS::getMaxSamplePeriodUs() {
  uint8_t dataL, dataH;
  dataH = readRegister(RegisterAddress::Frame_Period_Max_Bound_Upper);
  dataL = readRegister(RegisterAddress::Frame_Period_Max_Bound_Lower);
  uint16_t us = makeWord(dataH, dataL) / ADNS_CHIP_FREQ_MHZ;
  _maxSamplePeriodUs = us;
  return us;
}

void ADNS::setMinSamplePeriodUs(const uint16_t us) {
  // todo ensure frameperiod_maxbound >= frameperiod_minbound + shutter_maxbound
  uint8_t dataL, dataH;
  uint16_t delayNumCyles = us * ADNS_CHIP_FREQ_MHZ;
  dataL = lowByte(delayNumCyles);
  dataH = highByte(delayNumCyles);
  writeRegister(RegisterAddress::Frame_Period_Min_Bound_Lower, dataL);
  writeRegister(RegisterAddress::Frame_Period_Min_Bound_Upper, dataH);
  getMinSamplePeriodUs();
}

uint16_t ADNS::getMinSamplePeriodUs() {
  uint8_t dataL, dataH;
  dataH = readRegister(RegisterAddress::Frame_Period_Min_Bound_Upper);
  dataL = readRegister(RegisterAddress::Frame_Period_Min_Bound_Lower);
  uint16_t us = makeWord(dataH, dataL) / ADNS_CHIP_FREQ_MHZ;
  _minSamplePeriodUs = us;
  return us;
}

// =============================================================================
// Sensor Status
// =============================================================================
uint16_t ADNS::getSamplePeriodUs() {
  uint8_t dataL, dataH;
  dataH = readRegister(RegisterAddress::Frame_Period_Upper);
  dataL = readRegister(RegisterAddress::Frame_Period_Lower);
  uint16_t us = makeWord(dataH, dataL) / ADNS_CHIP_FREQ_MHZ;
  return us;
}

uint16_t ADNS::getSampleRateHz() {
  uint16_t us = getSamplePeriodUs();
  return (uint16_t)(1000000UL / (uint32_t)us);
}

// =============================================================================
// Sensor Communication (SPI)
// =============================================================================
void ADNS::select() {
  if (_selectedFlag == false) {
    SPI.beginTransaction(SPISettings(ADNS_SPI_MAX_SPEED, ADNS_SPI_BIT_ORDER,
                                     ADNS_SPI_DATA_MODE));
    fastDigitalWrite(_chipSelectPin, LOW);
    _selectedFlag = 1;
    _delayNanoseconds(ADNS_DELAYNANOS_NCS_SCLKACTIVE);
  }
}

void ADNS::deselect() {
  if (_selectedFlag == true) {
    // delayMicroseconds(1); // tSCLK-NCS
    fastDigitalWrite(_chipSelectPin, HIGH);
    // alternative is to make member variable -->  DigitalPin
    // pin(_chipSelectPin); pin.high();
    SPI.endTransaction();
    _selectedFlag = 0;
  }
}

uint8_t ADNS::readRegister(const RegisterAddress address) {
  // Send 7-bit address with msb=0, clock for 1 uint8_t to receive 1 uint8_t
  select();
  SPI.transfer((uint8_t)address & 0x7f);
  delayMicroseconds(ADNS_DELAYMICROS_READ_ADDR_DATA);  // tSRAD
  uint8_t data = SPI.transfer(0);
  _delayNanoseconds(ADNS_DELAYNANOS_NCSINACTIVE_POST_READ);
  deselect();
  delayMicroseconds(ADNS_DELAYMICROS_POST_READ);
  return data;
}

void ADNS::writeRegister(const RegisterAddress address, const uint8_t data) {
  // Send 7-bit address with msb=1 followed by data to write
  select();
  SPI.transfer((uint8_t)address | 0x80);
  SPI.transfer(data);
  delayMicroseconds(ADNS_DELAYMICROS_NCSINACTIVE_POST_WRITE);
  deselect();
  delayMicroseconds(ADNS_DELAYMICROS_POST_WRITE);
}

// =============================================================================
// Mode
// =============================================================================
void ADNS::setMotionSensePinInterruptMode(const int pin) {
  _motionSensePin = pin;
  // todo: set flag and use timer to poll if using this mode??
  // fastPinMode(pin, INPUT_PULLUP);
  // attachInterrupt(digitalPinToInterrupt(pin), triggerSampleCapture, LOW);
  // todo: interrupt requires a static member function
  // SPI.usingInterrupt(digitalPinToInterrupt(pin));
}

// =============================================================================
// Configuration
// =============================================================================
void ADNS::initialize() {
  if (!_initializedFlag) {
    // Set up Serial Peripheral Interface (SPI) & specified chip-select pin
    fastPinMode(_chipSelectPin, OUTPUT);
    SPI.begin();
    delay(100);
  }
  if (!_configuredFlag) {
    // Power-Up Sensor & Set/Confirm Settings on Sensor Device
    powerUpSensor();
    setResolutionCountsPerInch(_resolutionCountsPerInch);
    setMaxSamplePeriodUs(_maxSamplePeriodUs);
    getMinSamplePeriodUs();  // todo update period and resolution in single fcn
    delaySleepTimeout();
    setMaxLiftDetectionThreshold();
    _configuredFlag = true;
  }
  _initializedFlag = true;
}

void ADNS::powerUpSensor() {
  deselect();
  select();
  deselect();
  writeRegister(RegisterAddress::Power_Up_Reset, 0x5a);
  delay(50);
  readRegister(RegisterAddress::Motion);
  readRegister(RegisterAddress::Delta_X_L);
  readRegister(RegisterAddress::Delta_X_H);
  readRegister(RegisterAddress::Delta_Y_L);
  readRegister(RegisterAddress::Delta_Y_H);
  uploadFirmware();
  delay(10);
  enableLaser();
  delay(1);
}

void ADNS::shutDownSensor() {
  // todo: test
  writeRegister(RegisterAddress::Shutdown, 0xB6);
  _configuredFlag = false;
}

void ADNS::resetSensor() {
  // todo: test
  deselect();
  select();
  deselect();
  writeRegister(RegisterAddress::Power_Up_Reset, 0x5a);
  delay(50);
  writeRegister(RegisterAddress::Observation, 0x00);
  delayMicroseconds(max(2000, _maxSamplePeriodUs));
  // uint8_t obs = readRegister(RegisterAddress::Observation);
  // should then check bits 0:5 are set
  readRegister(RegisterAddress::Motion);
  readRegister(RegisterAddress::Delta_X_L);
  readRegister(RegisterAddress::Delta_X_H);
  readRegister(RegisterAddress::Delta_Y_L);
  readRegister(RegisterAddress::Delta_Y_H);
  delay(10);
  enableLaser();
  delay(1);
}

void ADNS::uploadFirmware() {
  // Firmware supplied by chip manufacturer (Pixart) as a hex file must be
  // uploaded each time the sensor is powered on. Hex-file is defined in array &
  // stored in flash ram in simple header-file ("firmware/adns9800_srom_A6.h")
  // and can easily be interchangeable with updated firmware. Put sensor in
  // firmware upload mode
  writeRegister(RegisterAddress::Configuration_IV, 0x02);
  writeRegister(RegisterAddress::SROM_Enable, 0x1d);
  delay(10);
  writeRegister(RegisterAddress::SROM_Enable, 0x18);
  // SROM Load Burst Sequence
  select();
  SPI.transfer((uint8_t)RegisterAddress::SROM_Load_Burst | 0x80);
  // Write firmware from latest version
  uint8_t c;
  for (uint16_t i = 0; i < firmware_length; i++) {
    c = (uint8_t)pgm_read_byte(firmware_data + i);
    delayMicroseconds(15);
    SPI.transfer(c);
    // Store firmware-revision from 2nd uint8_t in hex file array
    if (i == 1) _firmwareRevision = String(c, HEX);
  }
  delayMicroseconds(10);
  deselect();
  delayMicroseconds(160);
}

void ADNS::enableLaser() {
  // Set Force_Disabled bit (bit0) to 0 in LAS ER_CTRL0 register
  uint8_t data = readRegister(RegisterAddress::LASER_CTRL0);
  data = (data & ADNS_LASER_CTRL0_REGISTER_MASK);  // TODO NOT RIGHT SCREW IT
  writeRegister(RegisterAddress::LASER_CTRL0, data);
  delay(1);
}

void ADNS::delaySleepTimeout() {
  writeRegister(RegisterAddress::Run_Downshift, 0xFF);
  writeRegister(RegisterAddress::Rest1_Downshift, 0xFF);
  writeRegister(RegisterAddress::Rest2_Downshift, 0xFF);
}

void ADNS::disableSleepTimeout() {
  // write 0 to bit 5 and also write zeros in bits 0 and 1;
  uint8_t data = readRegister(RegisterAddress::Configuration_II);
  data &= (~bit(5) & ~0x03);
  writeRegister(RegisterAddress::Configuration_II, data);
}

void ADNS::setMaxLiftDetectionThreshold() {
  uint8_t data = readRegister(RegisterAddress::Lift_Detection_Thr);
  data = (data & ~ADNS_LIFT_DETECTION_REGISTER_MASK) |
         (0xFF & ADNS_LIFT_DETECTION_REGISTER_MASK);
  writeRegister(RegisterAddress::Lift_Detection_Thr, data);
}
