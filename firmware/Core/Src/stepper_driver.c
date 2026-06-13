#include "stepper_driver.h"

#include <stdlib.h>
#include "math_extra.h"

void Stepper_Enable(void) {
  HAL_GPIO_WritePin(LEG_ENABLE_GPIO_Port, LEG_ENABLE_Pin, GPIO_PIN_RESET);
}

void Stepper_Disable(void) {
  HAL_GPIO_WritePin(LEG_ENABLE_GPIO_Port, LEG_ENABLE_Pin, GPIO_PIN_SET);
}

Stepper *Stepper_New(GPIO_TypeDef *step_port, uint16_t step_pin, GPIO_TypeDef *dir_port, uint16_t dir_pin) {
  Stepper *stepper = malloc(sizeof(Stepper));
  if (stepper == NULL) return NULL;

  stepper->step_port = step_port;
  stepper->step_pin = step_pin;
  stepper->dir_port = dir_port;
  stepper->dir_pin = dir_pin;

  stepper->current_pos = 0;
  stepper->target_pos = 0;
  stepper->current_velocity = 0.0f;
  stepper->target_velocity = 0.0f;
  stepper->accumulator = 0.0f;

  return stepper;
}

void Stepper_MoveTo(Stepper *stepper, const int32_t target_pos, const float velocity) {
  const float max_velocity = STEPPER_MAX_STEP_RATE / STEPPER_TICK_HZ;
  const float clipped_vel = clampf(velocity, 0.0f, max_velocity);

  stepper->target_pos = target_pos;
  stepper->target_velocity = clipped_vel;
}

void Stepper_Process(Stepper *stepper) {
  if (stepper->current_pos == stepper->target_pos) {
    stepper->current_velocity = 0.0f;
    stepper->target_velocity = 0.0f;
    stepper->accumulator = 0.0f;
    return;
  }

  const float error = stepper->target_velocity - stepper->current_velocity;
  const float abs_err = (error > 0.0f) ? error : -error;

  if (abs_err <= STEPPER_ACCEL_RATE) {
    stepper->current_velocity = stepper->target_velocity;
  } else {
    stepper->current_velocity += (error > 0.0f) ? STEPPER_ACCEL_RATE : -STEPPER_ACCEL_RATE;
  }

  stepper->accumulator += stepper->current_velocity;

  while (stepper->accumulator >= 1.0f && stepper->current_pos != stepper->target_pos) {
    stepper->accumulator -= 1.0f;

    if (stepper->target_pos > stepper->current_pos) {
      stepper->dir_port->BSRR = stepper->dir_pin;
      stepper->current_pos++;
    } else {
      stepper->dir_port->BSRR = (uint32_t)stepper->dir_pin << 16;
      stepper->current_pos--;
    }

    DWT_Delay_us(2u);
    stepper->step_port->BSRR = stepper->step_pin;
    DWT_Delay_us(2u);
    stepper->step_port->BSRR = (uint32_t)stepper->step_pin << 16;
    DWT_Delay_us(2u);
  }
}
