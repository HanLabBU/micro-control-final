/*
  adns.h - Library for communicating with ADNS-9800 laser mouse sensor.
  Created by Mark Bucklin, May 21, 2014.
*/

#ifndef ADNS_h
#define ADNS_h

#include <Arduino.h>
#include <DigitalIO.h>
#include <SPI.h>
#include <elapsedMillis.h>
#include <glcd_delay.h>
#include <stdint.h>

// Sensor Register Include - ADNS-9800
#include "adns_config.h"
#include "adns_types.h"

// Common Include
//#include "../NavSensorLib/navsensor.h"

// =============================================================================
// ADNS Class Declaration
// =============================================================================
class ADNS {
 public:
  // Constructor
  ADNS(const int chipSelectPin = 4) : _chipSelectPin(chipSelectPin){};

  // Setup
  bool begin(
      const uint16_t resolutionCPI = ADNS_DEFAULT_SENSOR_RESOLUTION,
      const uint16_t minSampleRateHz = ADNS_DEFAULT_SENSOR_MINSAMPLERATE);

  String getName();
  // String getId() { return chipSelectPin; }; //todo
  // adns_sample_t getValues(){}; //todo
  // getUnits() //todo
  // getResolution()
  // getConfig() //todo

  // Trigger Start, Capture, & Readout
  void triggerAcquisitionStart();
  void triggerSampleCapture();
  void triggerAcquisitionStop();

  // Convert & Return Captured Data
  displacement_t readDisplacement(
      const unit_specification_t = DEFAULT_UNIT) const;
  position_t readPosition(const unit_specification_t = DEFAULT_UNIT) const;
  velocity_t readVelocity(const unit_specification_t = DEFAULT_UNIT) const;
  adns_additional_info_t readAdditionalInfo() const;
  void printLastMotion();
  void printLastAdditionalInfo();

  // Sensor Settings
  void setResolutionCountsPerInch(const uint16_t cpi);
  uint16_t getResolutionCountsPerInch();
  void setMaxSamplePeriodUs(const uint16_t us);
  uint16_t getMaxSamplePeriodUs();
  void setMinSamplePeriodUs(const uint16_t us);
  uint16_t getMinSamplePeriodUs();

  // Sensor Status
  uint16_t getSamplePeriodUs();
  uint16_t getSampleRateHz();

  // Sensor Communication (SPI)
  void select();
  void deselect();
  uint8_t readRegister(const RegisterAddress address);
  void writeRegister(const RegisterAddress address, const uint8_t data);

  // Mode Settings
  void setMotionSensePinInterruptMode(const int pin);

 protected:
  // Configuration
  void initialize();
  void powerUpSensor();
  void shutDownSensor();
  void resetSensor();
  void uploadFirmware();
  void enableLaser();
  void delaySleepTimeout();
  void disableSleepTimeout();
  void setMaxLiftDetectionThreshold();

  // Status Flags
  bool _configuredFlag = false;
  bool _initializedFlag = false;
  volatile bool _runningFlag = false;
  volatile bool _selectedFlag = false;

  // Hardware Configuration (Pins) //todo should be made all const
  const int _chipSelectPin;
  const size_t _readoutSize = adns_readout_max_size;
  int _motionSensePin;

  // Current Sensor Settings
  String _firmwareRevision;
  uint16_t _resolutionCountsPerInch;  // Counts-Per-Inch
  uint16_t _maxSamplePeriodUs;        // Microseconds
  uint16_t _minSamplePeriodUs;        // Microseconds

  // Unit Conversions
  float _resolutionInchPerCount;
  // // unit_specification_t _unitSpec = DEFAULT_UNIT;

  // Readout Data
  elapsedMicros _microsSinceStart;
  elapsedMicros _microsSinceCapture;
  adns_position_t _position;
  adns_readout_t _readout;
  adns_sample_t _sample;
};

#endif
