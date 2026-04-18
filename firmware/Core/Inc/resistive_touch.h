#ifndef FIRMWARE_RESISTIVE_TOUCH_H
#define FIRMWARE_RESISTIVE_TOUCH_H

#include "stdint.h"

#define X_Y_ADC_INSTANCE	 ADC1
#define X_POS_ADC_CHANNEL    ADC_CHANNEL_1
#define Y_POS_ADC_CHANNEL    ADC_CHANNEL_2
#define X_NEG_ADC_CHANNEL    ADC_CHANNEL_3
#define TOUCH_SAMPLE_COUNT   7

typedef struct {
    uint16_t x, y;
} ResistiveTouch_RawPoint;

void ResistiveTouch_Init(void);
int ResistiveTouch_Scan(ResistiveTouch_RawPoint *point);

#endif //FIRMWARE_RESISTIVE_TOUCH_H