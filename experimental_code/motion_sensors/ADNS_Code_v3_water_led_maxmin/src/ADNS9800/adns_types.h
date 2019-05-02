/*
  adns_types.h
  -> Defines data structures and types used for interaction with ADNS9800 chip
*/

#ifndef ADNS_TYPES_h
#define ADNS_TYPES_h

#include <Arduino.h>
#include <stdint.h>
#include "../NavSensorLib/navsensor.h"
#include "adns_config.h"

// =============================================================================
// Structured Data-Storage Typedefs with Internal (ADNS-Specific) Units
// =============================================================================

// Time
typedef uint32_t adns_time_t;
typedef uint32_t adns_duration_t;

// Position <x,y> in 'Counts' and Elapsed-Time in Microseconds
typedef struct {
  int32_t x;        // counts
  int32_t y;        // counts
  adns_time_t t;    // microseconds
} adns_position_t;  // todo change adns_time_t to {sec,nsec}

// Raw-Readout Array
const size_t adns_readout_max_size = 14;  // size in bytes
typedef uint8_t adns_readout_buffer_t[adns_readout_max_size];
typedef union {
  adns_readout_buffer_t data;
  struct {
    uint8_t motion;
    uint8_t observation;
    uint8_t dxL;
    uint8_t dxH;
    uint8_t dyL;
    uint8_t dyH;
    uint8_t surfaceQuality;
    uint8_t pixelSum;
    uint8_t maxPixel;
    uint8_t minPixel;
    uint8_t shutterPeriodL;
    uint8_t shutterPeriodH;
    uint8_t framePeriodL;
    uint8_t framePeriodH;
  };
} adns_readout_t;

// Displacement <dx,dy> in 'Counts' and <dy> in Microseconds
typedef struct {
  int16_t dx;          // counts
  int16_t dy;          // counts
  adns_duration_t dt;  // microseconds
  uint8_t max;
  uint8_t min;
} adns_displacement_t;

typedef struct {
  uint8_t motion;  // [mot|fault|LaserPowerValid|opmode1,opmode0|framepixfirst]
  uint8_t observation;  // 0xFF = running, 0x00 = no response
} adns_sensor_status_t;

typedef struct {
  uint8_t min;   // min pixel intensity : [0,127]
  uint8_t mean;  // mean = sumH * 512/900  or sumH/1.76 : [0,223]
  uint8_t max;   // max intensity : [0,127]
  uint8_t
      features;  // number of features (actual count = feature * 4) : [0,169]
} adns_pixel_statistics_t;

typedef struct {
  uint16_t shutter;  // microseconds
  uint16_t frame;    // microseconds
} adns_period_micros_t;

typedef struct {
  adns_sensor_status_t status;    // raw bitfields from status registers
  adns_pixel_statistics_t pixel;  // image-stats -> min,mean,max,features
  adns_period_micros_t
      period;  // length of shutter and frame period in microseconds
} adns_additional_info_t;

typedef struct {
  int32_t count;
  adns_time_t timestamp;
  adns_displacement_t displacement;
} adns_sample_t;

#endif
