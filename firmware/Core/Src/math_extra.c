#include "math_extra.h"

float clampf(const float x, const float min, const float max) {
    return __builtin_fminf(__builtin_fmaxf(x, min), max);
}