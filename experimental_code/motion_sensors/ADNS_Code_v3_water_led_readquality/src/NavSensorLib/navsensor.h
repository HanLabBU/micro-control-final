/*
  navsensor.h
  -> Common include for NavigationSensor-type devices
*/

#ifndef NAVSENSOR_h
#define NAVSENSOR_h

#include <Arduino.h>
#include <stdint.h>

#define COMMAND(NAME) \
  { #NAME, NAME##_command }
// struct command commands[] =
// {
//   COMMAND (quit),
//   COMMAND (help),
//   …
// };

// =============================================================================
// Data-Sample Template Structures
// =============================================================================
template <typename T>
struct vec2_cartesian {
  T x;
  T y;
};

template <typename T1, typename T2 = T1>
struct vec2_polar {
  T1 r;
  T2 w;
};

template <typename T>
struct data_sample {
  time_t time;
  T data;
};

// =============================================================================
// Structured Data Sample types with values in SI-Units
// =============================================================================

typedef struct {
  float x;
  float y;
  float t;  // todo: 64-bit {sec,nsec}
} position_t;

typedef struct {
  float dx;
  float dy;
  float dt;  // todo change to duration_t
  uint8_t motion;
} displacement_t;

typedef vec2_cartesian<float> velocity_cartesian_t;
typedef vec2_polar<float, float> velocity_polar_t;
typedef velocity_cartesian_t velocity_t;
typedef data_sample<vec2_cartesian<float>> displacement_sample_t;
typedef data_sample<vec2_cartesian<float>> velocity_sample_t;

typedef struct {
  int32_t count;
  time_t timestamp;
  position_t position;
  displacement_t displacement;
} sample_t;

// =============================================================================
// Unit Enumerations
// =============================================================================
#define DEFAULT_DISTANCE_UNIT Unit::Distance::MILLIMETER
#define DEFAULT_TIME_UNIT Unit::Time::MILLISECOND

// enables streaming-type printing
template <class T>
inline Print &operator<<(Print &obj, T arg) {
  obj.print(arg);
  return obj;
}

// todo teensy interrupt pin
// uno,nano,mini: 2, 3
// mega: 2, 3, 21, 20, 19, 18
// teensy:

// // typedef unit_specification_t;
namespace Unit {
enum class Distance {
  NANOMETER,
  MICROMETER,
  MILLIMETER,
  CENTIMETER,
  METER,
  KILOMETER,
  THOU,
  INCH,
  FOOT,
  YARD,
  MILE
};
inline float perInch(const Distance unit) {
  switch (unit) {
    case Distance::NANOMETER:
      return 25400000.0;
    case Distance::MICROMETER:
      return 25400.0;
    case Distance::MILLIMETER:
      return 25.4;
    case Distance::CENTIMETER:
      return 2.54;
    case Distance::METER:
      return .0254;
    case Distance::KILOMETER:
      return .0000254;
    case Distance::THOU:
      return 1000.0;
    case Distance::INCH:
      return 1.000;
    case Distance::FOOT:
      return .0833333;
    case Distance::YARD:
      return .0277778;
    case Distance::MILE:
      return 1.5783E-5;
    default:
      return 1.0;
  }
};
// todo unitPerCentimeter() or unitPerMillimeter
enum class Time { NANOSECOND, MICROSECOND, MILLISECOND, SECOND, MINUTE, HOUR };
inline float perSecond(const Time unit)  // todo remove const output?
{
  switch (unit) {
    case Time::NANOSECOND:
      return 1000000000.0;
    case Time::MICROSECOND:
      return 1000000.0;
    case Time::MILLISECOND:
      return 1000.0;
    case Time::SECOND:
      return 1.0;
    case Time::MINUTE:
      return 0.0166667;
    case Time::HOUR:
      return 0.00027777833333;
    default:
      return 1000000.0;
  }
};
inline float perMicrosecond(const Time unit) {
  switch (unit) {
    case Time::NANOSECOND:
      return 1000.0;
    case Time::MICROSECOND:
      return 1.0;
    case Time::MILLISECOND:
      return 0.001;
    case Time::SECOND:
      return 0.000001;
    case Time::MINUTE:
      return 0.00000001666666667;
    case Time::HOUR:
      return 0.00000000027777833333;
    default:
      return 1.0;
  }
}
inline const String getAbbreviation(const Distance unit) {
  switch (unit) {
    case Distance::NANOMETER:
      return "nm";
    case Distance::MICROMETER:
      return "um";
    case Distance::MILLIMETER:
      return "mm";
    case Distance::CENTIMETER:
      return "cm";
    case Distance::METER:
      return "m";
    case Distance::KILOMETER:
      return "km";
    case Distance::THOU:
      return "th";
    case Distance::INCH:
      return "in";
    case Distance::FOOT:
      return "ft";
    case Distance::YARD:
      return "yd";
    case Distance::MILE:
      return "mi";
    default:
      return "";
  }
}
inline const String getAbbreviation(const Time unit) {
  switch (unit) {
    case Time::NANOSECOND:
      return "ns";
    case Time::MICROSECOND:
      return "us";
    case Time::MILLISECOND:
      return "ms";
    case Time::SECOND:
      return "sec";
    case Time::MINUTE:
      return "min";
    case Time::HOUR:
      return "hr";
    default:
      return "";
  }
}
}  // namespace Unit
typedef struct {
  Unit::Distance distance;
  Unit::Time time;
} unit_specification_t;
static constexpr unit_specification_t DEFAULT_UNIT = {DEFAULT_DISTANCE_UNIT,
                                                      DEFAULT_TIME_UNIT};

#endif

// ADAFRUIT_SENSOR UNIFIED
// bool getEvent(sensors_event_t *event)
// void getSensor(sensor_t *sensor)
// enable
// disable
// void displaySensorDetails(void)
// void configureSensor(void)

// // #if defined(ARDUINO_ARCH_ESP8266) | defined(ARDUINO_ESP8266_ESP01)
// // #elif defined(__AVR__)
// // #elif defined(__AVR_ATmega32U4__) || defined(__AVR_ATmega1280__) ||
// defined(__AVR_ATmega2560__) || defined(__AVR_ATtiny24__) ||
// defined(__AVR_ATtiny44__) || defined(__AVR_ATtiny84__) ||
// defined(__AVR_ATtiny25__) || defined(__AVR_ATtiny45__) ||
// defined(__AVR_ATtiny85__) || defined(__AVR_AT90USB646__) ||
// defined(__AVR_AT90USB1286__) || defined(__AVR_ATmega1280__) ||
// defined(__AVR_ATmega328_) || defined(__AVR_ATmega128__)
// // #elif defined(ESP8266) || defined(ESP32)
// // #elif defined(ARDUINO_ESP8266_NODEMCU) ||
// defined(ARDUINO_ESP8266_WEMOS_D1MINI)
// // #elif defined(CORE_TEENSY)
// // #elif defined(__arm__) && defined(TEENSYDUINO)
// // #if defined(__MK20DX128__) || defined(__MK20DX256__) ||
// defined(__MKL26Z64__) || defined(__MK66FX1M0__)
// // // Teensy 3.1 -> __MK20DX256__
// // // Teensy 3.0  3.1 (PIC32's might have some day) 3.1LC 3.2 3.5
// // //todo add teensy support // #include <TeensyDelay.h>
// // #endif
// // #endif
