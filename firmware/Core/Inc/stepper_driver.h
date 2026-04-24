#ifndef STEPPER_DRIVER_H
#define STEPPER_DRIVER_H

#include "main.h"

#define ANGLE_TO_STEP    (3200 / 360)
#define STEP_BUFFER_SIZE 16

typedef struct {
    TIM_HandleTypeDef* htim;
    uint32_t           tim_channel;

    GPIO_TypeDef*      dir_port;
    uint16_t           dir_pin;

    int32_t            current_pos;
    int32_t            target_pos;
    bool               is_moving;

    float              current_velocity;
    float              max_speed;
    float              acceleration;

    uint16_t           burst_buffer[STEP_BUFFER_SIZE * 2] __attribute__((aligned(2)));
    uint16_t           steps_to_move;
} Stepper;

Stepper* Stepper_New(TIM_HandleTypeDef* htim, uint32_t tim_channel, GPIO_TypeDef* dir_port, uint16_t dir_pin);
void Stepper_MoveTo(Stepper* stepper, int32_t target_pos);
void Stepper_CleanUp(Stepper* stepper);

#endif