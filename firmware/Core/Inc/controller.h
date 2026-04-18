#ifndef FIRMWARE_CONTROLLER_H
#define FIRMWARE_CONTROLLER_H

#define BASE_RADIUS        0
#define PLATFORM_RADIUS    0
#define ARM_LENGTH         0
#define ROD_LENGTH         0

// Precalculation for optimization
#define ARM_L_SQ           (ARM_LENGTH * ARM_LENGTH)
#define ROD_L_SQ           (ROD_LENGTH * ROD_LENGTH)
#define ARM_L_X2           (2.0f * ARM_LENGTH)
#define PLAT_R_HALF        (PLATFORM_RADIUS * 0.5f)
#define ARM_DIFF_SQ        (ARM_L_SQ - ROD_L_SQ)
#define INV_ARM_L_X2       (1.0f / (2.0f * ARM_LENGTH))

typedef enum {
    A = 0,
    B = 1,
    C = 2
} Leg;

typedef struct {
    float angle;
    float cos_a;
    float sin_a;
} LegInfo;

static const LegInfo LEGS[3] = {
    {0.0f,       1.0f,  0.0f},       // Leg A
    {2.0943951f, -0.5f, 0.8660254f}, // Leg B
    {4.1887902f, -0.5f, -0.8660254f} // Leg C
};

typedef struct {
    float kp, ki, kd;

    float integral;
    float prev_error;
} PID_Controller;

void Controller_Heartbeat(void);

#endif //FIRMWARE_CONTROLLER_H