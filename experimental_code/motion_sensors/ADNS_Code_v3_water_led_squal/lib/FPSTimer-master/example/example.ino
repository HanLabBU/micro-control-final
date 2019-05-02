#include "FPSTimer.h"

FPSTimer timer(60.f); // set to 60fps

void setup()
{
    Serial.begin(115200);

    timer.setFrameRate(30.f);
    timer.setCurrentFrame(0);
    timer.start();
}

void loop()
{
    if (timer.needsUpdate()) // check if now should be next frame
    {
        Serial.print("current frame   : ");
        Serial.println(timer.getCurrentFrame());
        Serial.print("frame rate      : ");
        Serial.println(timer.getFrameRate());
        Serial.print("frame time [us] : ");
        Serial.println(timer.getCurrentFrameTimeUs());
        Serial.print("frame time [s]  : ");
        Serial.println(timer.getCurrentFrameTimeF());
        Serial.println();

        timer.setUpdated(); // wait for next frame time
    }

    if (timer.getCurrentFrame() > 1000)
    {   // re-start from 30 frame
        timer.start();
        timer.setCurrentFrame(30);
    }
}