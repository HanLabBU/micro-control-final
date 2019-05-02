/*
  teensy_stl.h
  -> Configures includes and to allow STL access from teensyduino
*/

#ifndef TEENSYSTL_h
#define TEENSYSTL_h

#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
// #include <time.h>

// Vector
// namespace std {
//   void __throw_bad_alloc()
//   {
//     Serial.println("Unable to allocate memory");
//   }

//   void __throw_length_error( char const*e )
//   {
//     Serial.print("Length Error :");
//     Serial.println(e);
//   }
// }
#include <bitset>
#include <chrono>
#include <queue>
#include <vector>

// small versions of standard libraries from ARM
// LIBS=-lsupc++_s -lm -lc_s -lstdc++_s

//  std::string
// --> need to add -lstdc++ to library line in boards.txt file
// teensy31.build.flags.libs=-larm_cortexM4l_math -lm -lstdc++
// which will mean above functions won't need to be defined
// (__throw_bad_alloc...) then must add the following extern "C"{
//   int _getpid(){ return -1;}
//   int _kill(int pid, int sig){ return -1; }
// }
// #include <string>

#endif