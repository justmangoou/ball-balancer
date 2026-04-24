#include <assert.h>

float clampf(const float x, const float min, const float max)
{
    return __builtin_fminf(__builtin_fmaxf(x, min), max);
}

float map_clampedf(
    const float in,
    const float in_min, const float in_max,
    const float out_min, const float out_max
)
{
    assert(in_min < in_max);
    assert(out_min < out_max);

    const float in_range = in_max - in_min;

    if (in_range == 0.0f)
        return (out_min + out_max) * 0.5f; // Midpoint

    const float t = (in - in_min) / in_range;
    const float out = out_min + t * (out_max - out_min);

    return clampf(out, out_min, out_max);
}