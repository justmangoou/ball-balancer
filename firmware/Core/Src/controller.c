#include "controller.h"

#include <stdint.h>
#include <stdbool.h>
#include "resistive_touch.h"
#include "main.h"
#include "math_extra.h"

/* Private variables ---------------------------------------------------------*/
static PID_Controller X_CONTROLLER = { 0, 0, 0 };
static PID_Controller Y_CONTROLLER = { 0, 0, 0 };

extern TIM_HandleTypeDef htim2;
extern TIM_HandleTypeDef htim3;
extern TIM_HandleTypeDef htim4;

/* Private function prototypes -----------------------------------------------*/
static float prv_pid_compute(PID_Controller *pid, float setpoint, float measured, float dt);
static float prv_theta_compute(Leg leg, float hz, float nx, float ny);

void Controller_Init(void)
{
    LEG_STEPPER_CONTROLLER[LEG_A] = Stepper_New(&htim2, LEG_A_TIM_CHANNEL, LEG_A_DIR_GPIO_Port, LEG_A_DIR_Pin);
    LEG_STEPPER_CONTROLLER[LEG_B] = Stepper_New(&htim3, LEG_B_TIM_CHANNEL, LEG_B_DIR_GPIO_Port, LEG_B_DIR_Pin);
    LEG_STEPPER_CONTROLLER[LEG_C] = Stepper_New(&htim4, LEG_C_TIM_CHANNEL, LEG_C_DIR_GPIO_Port, LEG_C_DIR_Pin);

    if (LEG_STEPPER_CONTROLLER[LEG_A] == NULL ||
        LEG_STEPPER_CONTROLLER[LEG_B] == NULL ||
        LEG_STEPPER_CONTROLLER[LEG_C] == NULL
    ) {
        Error_Handler();
    }
}

void Controller_Update(Touch_CenterOffsetPercentage *offset)
{
    float x_out = 0, y_out = 0;

    x_out = prv_pid_compute(&X_CONTROLLER, 0, offset->x, HEARTBEAT_DELTA_TIME);
    y_out = prv_pid_compute(&Y_CONTROLLER, 0, offset->y, HEARTBEAT_DELTA_TIME);

    x_out = clampf(x_out, -0.25f, 0.25f);
    y_out = clampf(y_out, -0.25f, 0.25f);

    for (uint8_t i = 0; i < LEG_COUNT; i++) {
        const int32_t pos = lroundf(ORIGIN_ANGLE - prv_theta_compute(i, -4.25f, -x_out, -y_out));

        Stepper_MoveTo(LEG_STEPPER_CONTROLLER[i], pos);
    }
}

void Controller_Reset(void) {

}

float prv_pid_compute(PID_Controller *pid, const float setpoint, const float measured, const float dt)
{
    const float error = setpoint - measured;
    const float kp = pid->kp;
    const float ki = pid->ki;
    const float kd = pid->kd;

    pid->integral += (error + pid->prev_error) * 0.5f * dt;

    const float derivative = (error - pid->prev_error) / dt;
    const float output = (kp * error) + (ki * pid->integral) + (kd * derivative);

    pid->prev_error = error;

    return output;
}

/**
 * @brief Computes the inverse kinematics for a single leg of a 3-motor platform.
 * * Calculates the required motor angle (theta) to achieve a specific platform
 * height and tilt. This uses a 2D-projection method by rotating the platform
 * coordinate system to align with the specific leg's axis.
 *
 * @param leg    The leg index (A, B, or C) corresponding to the motor.
 * @param hz     The target center height of the platform in mm.
 * @param nx     The X-component of the platform's normal vector gradient.
 * @param ny     The Y-component of the platform's normal vector gradient.
 * * @return float The calculated motor arm angle in degrees.
 * * @note Assumes a 3-RSS (Revolute-Spherical-Spherical) geometry.
 * @note Optimized for STM32 FPU: Uses lookup tables and minimizes divisions.
 * @warning Returns 0.0f or clamped values if the requested position is
 * physically unreachable (kinematic singularity).
 */
static float prv_theta_compute(const Leg leg, const float hz, const float nx, const float ny)
{
    // Normalize vector
    const float nmag = sqrtf(nx * nx + ny * ny + 1.0f);
    const float n_x = nx / nmag;
    const float n_y = ny / nmag;
    const float n_z = 1.0f / nmag;

    const LegInfo *info = &LEGS[leg];

    // Standard 2D rotation for the tilt vector
    const float rx = n_x * info->cos_a - n_y * info->sin_a;
    const float ry = n_x * info->sin_a + n_y * info->cos_a;
    const float rx2 = rx * rx;
    const float ry2 = ry * ry;

    /* 3. Generic Math for a single leg (aligned to Y-axis)
       This is the generalized version of your Case A logic.
       We use the rotated coordinates (rx, ry) to represent the platform tilt
       relative to the leg's local frame.
    */
    const float nz_p1 = n_z + 1.0f;
    const float inv_nz_p1 = 1.0f / nz_p1;
    const float denom_inv = 1.0f / (nz_p1 - rx2);

    const float term1 = (rx2 + 3.0f * n_z * n_z + 3.0f * n_z) * denom_inv;
    const float term2 = (rx2 * rx2 - 3.0f * rx2 * ry2) * (inv_nz_p1 * inv_nz_p1 * denom_inv);

    const float joint_y = BASE_RADIUS + PLAT_R_HALF * (1.0f - term1 + term2);
    const float joint_z = hz + PLATFORM_RADIUS * ry;

    // 4. Calculate Angle
    const float mag_sq = (joint_y * joint_y) + (joint_z * joint_z);
    const float mag = sqrtf(mag_sq);

    // Make sure mag is not 0 so inv_mag is divisible
    if (mag < 0.0001f) return 0.0f;

    const float inv_mag = 1.0f / mag;

    float ratio_acos2 = (mag_sq + ARM_DIFF_SQ) * inv_mag * INV_ARM_L_X2;
    float ratio_acos1 = joint_y * inv_mag;

    ratio_acos1 = clampf(ratio_acos1, -1.0f, 1.0f);
    ratio_acos2 = clampf(ratio_acos2, -1.0f, 1.0f);

    return (acosf(ratio_acos1) + acosf(ratio_acos2)) * RAD_TO_DEG;
}
