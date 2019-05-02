/*
  devicemanager.h - Library for managing the operation modular nodes on an
  embedded computing device Created by Mark Bucklin, Jan 21, 2018.
*/

#ifndef DEVICEMANAGER_h
#define DEVICEMANAGER_h

#include <Arduino.h>
#define BOARD_IDENTIFY_WARNING
// If warnings still don't display, ensure "File->Preferences->compiler
// warnings" is set to "Default". Even doing this, some boards still won't
// display the warning in the compile window but the constant will still be
// created.

// Include the library
#include <Board_Identify.h>

bool printBoardID() {
  // Open the serial
  if (Serial.availableForWrite()) {
    // Print the board information to the serial using the defined terms
    Serial.print(F("Board Make: "));
    Serial.println(BoardIdentify::make);
    Serial.print(F("Board Model: "));
    Serial.println(BoardIdentify::model);
    Serial.print(F("Board MCU: "));
    Serial.println(BoardIdentify::mcu);
    // Board Indentify uses the namespace BoardIdentify to prevent varibale
    // name conflicts
    return true;
  } else {
    return false;
  }
}

#endif DEVICEMANAGER_h