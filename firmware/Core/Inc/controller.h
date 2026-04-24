#ifndef FIRMWARE_CONTROLLER_H
#define FIRMWARE_CONTROLLER_H

#include "stepper_driver.h"
#include "resistive_touch.h"

#define ORIGIN_ANGLE       206.662752199f
#define LEG_COUNT          3

#define BASE_RADIUS        0
#define PLATFORM_RADIUS    0
#define ARM_LENGTH         0
#define ROD_LENGTH         0

// Precalculation
#define ARM_L_SQ           (ARM_LENGTH * ARM_LENGTH)
#define ROD_L_SQ           (ROD_LENGTH * ROD_LENGTH)
#define ARM_L_X2           (2.0f * ARM_LENGTH)
#define PLAT_R_HALF        (PLATFORM_RADIUS * 0.5f)
#define ARM_DIFF_SQ        (ARM_L_SQ - ROD_L_SQ)
#define INV_ARM_L_X2       (1.0f / (2.0f * ARM_LENGTH))

typedef enum {
    LEG_A = 0,
    LEG_B = 1,
    LEG_C = 2,
} Leg;

typedef struct {
    float angle;
    float cos_a;
    float sin_a;
} LegInfo;

static const LegInfo LEGS[3] = {
    {0.000000000f,  1.00000000f,  0.000000000f}, // Leg A: 0 rad
    {2.094395102f, -0.50000000f,  0.866025404f}, // Leg B: 2π/3
    {4.188790205f, -0.50000000f, -0.866025404f}  // Leg C: 4π/3
};

static Stepper* LEG_STEPPER_CONTROLLER[3] = { NULL };

typedef struct {
    float kp, ki, kd;

    float integral;
    float prev_error;
} PID_Controller;

void Controller_Init(void);
void Controller_Update(Touch_CenterOffsetPercentage *offset);
void Controller_Reset(void);

#endif //FIRMWARE_CONTROLLER_H