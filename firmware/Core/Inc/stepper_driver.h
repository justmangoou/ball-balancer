#ifndef STEPPER_DRIVER_H
#define STEPPER_DRIVER_H

#include "main.h"

#define ANGLE_TO_STEP    (3200.0f / 360.0f)
#define STEP_BUFFER_SIZE 16
#define STEPPER_TICK_HZ  40000.0f // Must match TIM9 update frequency.
#define STEPPER_MAX_STEP_RATE 20000.0f
#define STEPPER_DIR_SETUP_US  2u
#define STEPPER_STEP_PULSE_US 2u
#define STEPPER_STEP_LOW_US   2u

typedef struct {
    GPIO_TypeDef*      step_port;
    uint16_t           step_pin;
    GPIO_TypeDef*      dir_port;
    uint16_t           dir_pin;

    int32_t            current_pos;
    int32_t            target_pos;

    volatile float     velocity;
    float              accumulator;
} Stepper;

void Stepper_Enable(void);
void Stepper_Disable(void);
Stepper* Stepper_New(GPIO_TypeDef* step_port, uint16_t step_pin, GPIO_TypeDef* dir_port, uint16_t dir_pin);
void Stepper_MoveTo(Stepper* stepper, int32_t target_pos, float velocity);
void Stepper_Process(Stepper* stepper);

#endif