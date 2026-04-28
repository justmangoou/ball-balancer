#include "stepper_driver.h"

#include <stdlib.h>

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
  stepper->velocity = velocity > 1.0f ? 1.0f : velocity;
}

void Stepper_Process(Stepper *stepper) {
  if (stepper->current_pos == stepper->target_pos) {
    stepper->accumulator = 0;
    return;
  }

  stepper->accumulator += stepper->velocity;

  // 2. Is the bucket full? (Did we reach 1.0 steps?)
  if (stepper->accumulator >= 1.0f) {
    stepper->accumulator -= 1.0f; // Empty 1 step from the bucket

    // 3. Set Direction
    if (stepper->target_pos > stepper->current_pos) {
      stepper->dir_port->BSRR = stepper->dir_pin;
      stepper->current_pos++;
    } else {
      stepper->dir_port->BSRR = (uint32_t) stepper->dir_pin << 16;
      stepper->current_pos--;
    }

    // 4. Atomic Step Pulse
    stepper->step_port->BSRR = stepper->step_pin;
    for (volatile int d = 0; d < 20; d++);
    stepper->step_port->BSRR = (uint32_t) stepper->step_pin << 16;
  }
}
