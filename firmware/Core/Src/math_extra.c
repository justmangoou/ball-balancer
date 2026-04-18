#include "math_extra.h"

float clampf(const float x, const float min, const float max) {
    return fminf(fmaxf(x, min), max);
}