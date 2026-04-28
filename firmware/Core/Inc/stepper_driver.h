#ifndef STEPPER_DRIVER_H
#define STEPPER_DRIVER_H

#include "main.h"

#define ANGLE_TO_STEP    (3200 / 360)
#define STEP_BUFFER_SIZE 16

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

Stepper* Stepper_New(GPIO_TypeDef* step_port, uint16_t step_pin, GPIO_TypeDef* dir_port, uint16_t dir_pin);
void Stepper_MoveTo(Stepper* stepper, int32_t target_pos, float velocity);
void Stepper_Process(Stepper* stepper);

#endif