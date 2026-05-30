#include "stepper_driver.h"

#include <stdlib.h>

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
  stepper->velocity = 0.0f;
  stepper->accumulator = 0.0f;

  return stepper;
}

void Stepper_MoveTo(Stepper *stepper, const int32_t target_pos, const float velocity) {
  stepper->target_pos = target_pos;
  float clipped_velocity = velocity;
  if (clipped_velocity < 0.0f) {
    clipped_velocity = 0.0f;
  }

  const float max_velocity = STEPPER_MAX_STEP_RATE / STEPPER_TICK_HZ;
  if (clipped_velocity > max_velocity) {
    clipped_velocity = max_velocity;
  }

  stepper->velocity = clipped_velocity;
}

void Stepper_Process(Stepper *stepper) {
  if (stepper->current_pos == stepper->target_pos) {
    stepper->accumulator = 0;
    return;
  }

  stepper->accumulator += stepper->velocity;

  // Process all complete steps that have accumulated
  while (stepper->accumulator >= 1.0f && stepper->current_pos != stepper->target_pos) {
    stepper->accumulator -= 1.0f;

    // Set Direction
    if (stepper->target_pos > stepper->current_pos) {
      stepper->dir_port->BSRR = stepper->dir_pin;
      stepper->current_pos++;
    } else {
      stepper->dir_port->BSRR = (uint32_t) stepper->dir_pin << 16;
      stepper->current_pos--;
    }

#if STEPPER_DIR_SETUP_US > 0
    DWT_Delay_us(STEPPER_DIR_SETUP_US);
#endif

    // Atomic Step Pulse
    stepper->step_port->BSRR = stepper->step_pin;
#if STEPPER_STEP_PULSE_US > 0
    DWT_Delay_us(STEPPER_STEP_PULSE_US);
#endif
    stepper->step_port->BSRR = (uint32_t) stepper->step_pin << 16;
#if STEPPER_STEP_LOW_US > 0
    DWT_Delay_us(STEPPER_STEP_LOW_US);
#endif
  }
}
