#ifndef FIRMWARE_MATH_EXTRA_H
#define FIRMWARE_MATH_EXTRA_H

#include "math.h"

#define RAD_TO_DEG (180.0f / (float)M_PI)
#define DEG_TO_RAD ((float)M_PI / 180.0f)

float clampf(float x, float min, float max);

#endif //FIRMWARE_MATH_EXTRA_H