/*
  teensy_restart.h
  -> Defines a macro that will restart teensy (not trigger upload)
*/

#ifndef TEENSYRESTART_h
#define TEENSYRESTART_h



#define CPU_RESTART_ADDR (uint32_t *)0xE000ED0C
#define CPU_RESTART_VAL 0x5FA0004
#define CPU_RESTART (*CPU_RESTART_ADDR = CPU_RESTART_VAL)


#endif