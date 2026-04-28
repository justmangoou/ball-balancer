#include "controller.h"

#include <stdint.h>
#include <stdlib.h>
#include "resistive_touch.h"
#include "main.h"
#include "math_extra.h"

static PID_Controller X_CONTROLLER = {25E-4f, 2E-6f, 1E-4f};
static PID_Controller Y_CONTROLLER = {25E-4f, 2E-6f, 1E-4f};
Stepper* LEG_STEPPER_CONTROLLER[3] = { NULL };

extern TIM_HandleTypeDef htim2;
extern TIM_HandleTypeDef htim3;
extern TIM_HandleTypeDef htim4;

static bool is_first_update = true;

volatile float x_out, y_out;

static void prv_move(float nx, float ny);
static float prv_pid_compute(PID_Controller *pid, float setpoint, float measured, float dt);
static void prv_pid_reset(PID_Controller *pid);
static float prv_theta_compute(Leg leg, float hz, float nx, float ny);

void Controller_Init(void) {
  LEG_STEPPER_CONTROLLER[LEG_A] = Stepper_New(LEG_A_STEP_GPIO_Port, LEG_A_STEP_Pin, LEG_A_DIR_GPIO_Port, LEG_A_DIR_Pin);
  LEG_STEPPER_CONTROLLER[LEG_B] = Stepper_New(LEG_B_STEP_GPIO_Port, LEG_B_STEP_Pin, LEG_B_DIR_GPIO_Port, LEG_B_DIR_Pin);
  LEG_STEPPER_CONTROLLER[LEG_C] = Stepper_New(LEG_C_STEP_GPIO_Port, LEG_C_STEP_Pin, LEG_C_DIR_GPIO_Port, LEG_C_DIR_Pin);

  if (LEG_STEPPER_CONTROLLER[LEG_A] == NULL ||
      LEG_STEPPER_CONTROLLER[LEG_B] == NULL ||
      LEG_STEPPER_CONTROLLER[LEG_C] == NULL
  ) {
    Error_Handler();
  }
}

void Controller_Update(Touch_CenterOffsetPercentage *offset) {
  if (is_first_update) {
    X_CONTROLLER.prev_error = 0.0f - offset->x;
    Y_CONTROLLER.prev_error = 0.0f - offset->y;
    is_first_update = false;
  }

  x_out = prv_pid_compute(&X_CONTROLLER, 0, offset->x, HEARTBEAT_DELTA_TIME);
  y_out = prv_pid_compute(&Y_CONTROLLER, 0, offset->y, HEARTBEAT_DELTA_TIME);

  x_out = clampf(x_out, -0.25f, 0.25f);
  y_out = clampf(y_out, -0.25f, 0.25f);

  prv_move(-x_out, -y_out);
}

void Controller_Reset(void) {
  prv_pid_reset(&X_CONTROLLER);
  prv_pid_reset(&Y_CONTROLLER);
  is_first_update = true;

  prv_move(0, 0);
}

static void prv_move(const float nx, const float ny) {
  for (uint8_t i = 0; i < LEG_COUNT; i++) {
    Stepper *s = LEG_STEPPER_CONTROLLER[i];

    const int32_t new_target = lroundf(ORIGIN_ANGLE - prv_theta_compute(i, -4.25f, nx, ny));

    /* VELOCITY CALCULATION (Bresenham/Accumulator)
       We want to reach the new target within 1 Heartbeat (1ms).
       If Muscle Timer is 40kHz, we have 40 ticks per Heartbeat.
       Velocity = Distance / Ticks
    */
    const float dist = (float) abs(new_target - s->current_pos);
    const float velocity = dist / 40.0f; // 40.0f is MUSCLE_FREQ / HEARTBEAT_FREQ

    Stepper_MoveTo(s, new_target, velocity);
  }
}

static float prv_pid_compute(PID_Controller *pid, const float setpoint, const float measured, const float dt) {
  const float error = setpoint - measured;
  const float kp = pid->kp;
  const float ki = pid->ki;
  const float kd = pid->kd;

  pid->integral += (error + pid->prev_error) * 0.5f * dt;
  const float max_i = 0.05f / (ki > 0 ? ki : 1.0f);
  pid->integral = clampf(pid->integral, -max_i, max_i);

  const float raw_derivative = (error - pid->prev_error) / dt;
  pid->filtered_d = (0.1f * raw_derivative) + (0.9f * pid->filtered_d);
  const float output = (kp * error) + (ki * pid->integral) + (kd * pid->filtered_d);

  pid->prev_error = error;

  return output;
}

static void prv_pid_reset(PID_Controller *pid) {
  pid->integral = 0;
  pid->prev_error = 0;
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
static float prv_theta_compute(const Leg leg, const float hz, const float nx, const float ny) {
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

  /* Generic Math for a single leg (aligned to Y-axis)
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

  // Calculate Angle
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
