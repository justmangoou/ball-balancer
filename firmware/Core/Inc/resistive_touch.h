#ifndef FIRMWARE_RESISTIVE_TOUCH_H
#define FIRMWARE_RESISTIVE_TOUCH_H

#include <stdint.h>
#include <stdbool.h>

#define TOUCH_X_MIN          400.0f
#define TOUCH_X_MAX          3750.0f
#define TOUCH_Y_MIN          875.0f
#define TOUCH_Y_MAX          3350.0f

#define X_POS_ADC_CHANNEL    ADC_CHANNEL_1
#define Y_POS_ADC_CHANNEL    ADC_CHANNEL_2
#define X_NEG_ADC_CHANNEL    ADC_CHANNEL_3
#define Y_NEG_ADC_CHANNEL    ADC_CHANNEL_4
#define TOUCH_SAMPLE_COUNT   7

typedef struct {
    uint16_t x, y, z;
} Touch_RawPoint;

typedef struct {
    float x, y;
} Touch_CenterOffsetPercentage;

void Touch_Init(void);
bool Touch_Scan(Touch_RawPoint *point);
uint8_t Touch_CenterOffsetPercent(const Touch_RawPoint *raw_point, Touch_CenterOffsetPercentage *offset_percentage);

#endif //FIRMWARE_RESISTIVE_TOUCH_H