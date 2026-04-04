#ifndef FIRMWARE_RESISTIVE_TOUCH_H
#define FIRMWARE_RESISTIVE_TOUCH_H

#include "stm32f4xx_hal.h"
#include "stm32f4xx.h"
#include "stdlib.h"

#define X_Y_ADC_INSTANCE	ADC1
#define X_POS_ADC_CHANNEL   ADC_CHANNEL_2
#define Y_POS_ADC_CHANNEL   ADC_CHANNEL_1

void ResistiveTouch_Init(void);
int ResistiveTouch_Read(float *x, float *y);

#endif //FIRMWARE_RESISTIVE_TOUCH_H