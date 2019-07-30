/*
  adns_config.h
  -> Stores string titles for each readable register in ADNS9800 chip
*/

#ifndef ADNS_CONFIG_h
#define ADNS_CONFIG_h

#include <Arduino.h>
#include <stdint.h>

// Include Common NavigationSensor Library
// // #include "NavigationSensorLib\NavigationSensor.h" //todo: make common
// settings or functions
#define ADNS_NAME ("ADNS9800")

// Include Updateable File with ADNS Sensor Firmware
#ifndef ADNS_FIRMWARE_INCLUDE_FILENAME
#define ADNS_FIRMWARE_INCLUDE_FILENAME "firmware/adns9800_srom_A6.h"
#endif
#include ADNS_FIRMWARE_INCLUDE_FILENAME

// SPI Settings for ADNS-9800 Sensor
#define ADNS_SPI_DATA_MODE SPI_MODE3
#define ADNS_SPI_BIT_ORDER MSBFIRST
#define ADNS_SPI_MAX_SPEED 2000000

// Other Settings/Properties Specific to ADNS-9800
#define ADNS_RESOLUTION_MIN_CPI 50   // 0x01
#define ADNS_RESOLUTION_MAX_CPI 8200 // 0xA4
#define ADNS_MAX_SAMPLE_RATE_HZ 12000
#define ADNS_CHIP_FREQ_MHZ 50

// SPI Communication Timing
#define ADNS_DELAYMICROS_POST_READ 20
#define ADNS_DELAYMICROS_POST_WRITE 120
#define ADNS_DELAYMICROS_POST_RESET 30000
#define ADNS_DELAYMICROS_READ_ADDR_DATA 100
#define ADNS_DELAYMICROS_NCSINACTIVE_POST_WRITE 20
#define ADNS_DELAYNANOS_NCSINACTIVE_POST_READ 120 // 120ns
#define ADNS_DELAYNANOS_NCS_SCLKACTIVE 120
// todo: macro functions to implement SPI_DELAY_****
//#define ADNS_SQUAL2NUMFEATURES(v)	((uint32_t) v* 4)

// Register Masks
#define ADNS_RESOLUTION_REGISTER_MASK 0xFF
#define ADNS_LIFT_DETECTION_REGISTER_MASK B00011111
// 0xA4
// 0x3f
#define ADNS_LASER_CTRL0_REGISTER_MASK 0xf0
#define ADNS_LASER_DISABLE 0x00
#define ADNS_LASER_CONTINUOUS_ON B00000100

// Data Description
#define ADNS_RAW_READOUT_MAX_BYTES 14

// Default Sensor Configuration Settings (common)
#define ADNS_DEFAULT_SENSOR_RESOLUTION 3400
#define ADNS_DEFAULT_SENSOR_MINSAMPLERATE 1000

// SPI Alternate Pins [SS, MOSI, MISO, SCK]
// uno and teensy: [10, 11, 12, 13]
// teensy alternate: [__, 7, 8, 14]
// SPI.setMOSI(7), SPI.setMISO(8), and SPI.setSCK(14)

// External Constants for Firmware
extern const unsigned short firmware_length;
extern const unsigned char firmware_data[] PROGMEM;

// Register Address -> Implement w/ Enumeration
enum class RegisterAddress: uint8_t
{
  Product_ID                   = 0x00,    // 0x33}
  Revision_ID                  = 0x01,    // 0x03}
  Motion                       = 0x02,    // 0x00}
  Delta_X_L                    = 0x03,    // 0x00}
  Delta_X_H                    = 0x04,    // 0x00}
  Delta_Y_L                    = 0x05,    // 0x00}
  Delta_Y_H                    = 0x06,    // 0x00}
  SQUAL                        = 0x07,    // 0x00}
  Pixel_Sum                    = 0x08,    // 0x00}
  Maximum_Pixel                = 0x09,    // 0x00}
  Minimum_Pixel                = 0x0a,    // 0x00}
  Shutter_Lower                = 0x0b,    // 0xE8}
  Shutter_Upper                = 0x0c,    // 0x03}
  Frame_Period_Lower           = 0x0d,    // 0xc0}
  Frame_Period_Upper           = 0x0e,    // 0x5d}
  Configuration_I              = 0x0f,    // 0x44}
  Configuration_II             = 0x10,    // 0x00}
  Frame_Capture                = 0x12,    // 0x00}
  SROM_Enable                  = 0x13,    // 0x00}
  Run_Downshift                = 0x14,    // 0x32}
  Rest1_Rate                   = 0x15,    // 0x01}
  Rest1_Downshift              = 0x16,    // 0x1f}
  Rest2_Rate                   = 0x17,    // 0x09}
  Rest2_Downshift              = 0x18,    // 0xbc}
  Rest3_Rate                   = 0x19,    // 0x31}
  Frame_Period_Max_Bound_Lower = 0x1a,    // 0xc0}
  Frame_Period_Max_Bound_Upper = 0x1b,    // 0x5d}
  Frame_Period_Min_Bound_Lower = 0x1c,    // 0xa0}
  Frame_Period_Min_Bound_Upper = 0x1d,    // 0x0f}
  Shutter_Max_Bound_Lower      = 0x1e,    // 0xE8}
  Shutter_Max_Bound_Upper      = 0x1f,    // 0x03}
  LASER_CTRL0                  = 0x20,    // 0x81}
  Observation                  = 0x24,    // 0x00}
  Data_Out_Lower               = 0x25,    // ADNS_DEFAULT_UNDEFINED}
  Data_Out_Upper               = 0x26,    // ADNS_DEFAULT_UNDEFINED}
  SROM_ID                      = 0x2a,    // 0x00}
  Lift_Detection_Thr           = 0x2e,    // 0x10}
  Configuration_V              = 0x2f,    // 0x44}
  Configuration_IV             = 0x39,    // 0x00}
  Power_Up_Reset               = 0x3a,    // NA}
  Shutdown                     = 0x3b,    // ADNS_DEFAULT_UNDEFINED}
  Inverse_Product_ID           = 0x3f,    // 0xcc}
  Snap_Angle                   = 0x42,    // 0x06}
  Motion_Burst                 = 0x50,    // 0x00}
  SROM_Load_Burst              = 0x62     // ADNS_DEFAULT_UNDEFINED}

};
#else
// todo if necessary: get block of macro definitions from backup file
#endif
