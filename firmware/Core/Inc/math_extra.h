#ifndef FIRMWARE_MATH_EXTRA_H
#define FIRMWARE_MATH_EXTRA_H

#define RAD_TO_DEG (180.0f / (float)M_PI)
#define DEG_TO_RAD ((float)M_PI / 180.0f)

float clampf(float in, float min, float max);
float map_clampedf(float in, float in_min, float in_max, float out_min, float out_max);

#endif //FIRMWARE_MATH_EXTRA_H