#ifndef STEPPER_A_H
#define STEPPER_A_H

#include "main.h"

// PB13 = A_STEP
// PB12 = A_DIR
#define A_STEP_PIN   GPIO_PIN_13
#define A_STEP_PORT  GPIOB
#define A_DIR_PIN    GPIO_PIN_12
#define A_DIR_PORT   GPIOB

void StepperA_Init(void);
void StepperA_SetDirection(uint8_t clockwise);
void StepperA_Move(uint32_t steps, uint32_t delay_us);
void StepperA_Stop(void);

#endif