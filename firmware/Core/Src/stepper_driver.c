#include <stdlib.h>
#include "stepper_driver.h"

static void prv_set_direction(const Stepper* stepper, int32_t target_pos);
static void prv_prepare_burst(Stepper* stepper, uint32_t steps);

Stepper* Stepper_New(TIM_HandleTypeDef* htim, const uint32_t tim_channel, GPIO_TypeDef* dir_port, const uint16_t dir_pin) {
    Stepper* stepper = malloc(sizeof(Stepper));
    if (stepper == NULL) return NULL;

    // Copy the hardware handles
    stepper->htim = htim;  // This copies the whole HAL structure
    stepper->tim_channel = tim_channel;
    stepper->dir_port = dir_port;
    stepper->dir_pin = dir_pin;

    // Reset position and state
    stepper->current_pos = 0;
    stepper->target_pos = 0;
    stepper->is_moving = false;

    // Default motion parameters
    stepper->current_velocity = 500.0f;
    stepper->max_speed = 2000.0f;
    stepper->acceleration = 10000.0f;

    return stepper;
}

void Stepper_MoveTo(Stepper* stepper, const int32_t target_pos) {
    if (stepper->is_moving || stepper->current_pos == target_pos) return;

    uint32_t steps = abs(target_pos - stepper->current_pos);

    if (steps > STEP_BUFFER_SIZE) {
        steps = STEP_BUFFER_SIZE;
    }

    stepper->target_pos = target_pos;
    prv_set_direction(stepper, target_pos);
    prv_prepare_burst(stepper, steps);

    stepper->is_moving = true;

    // DMA Burst: Start at ARR register, update 2 registers (ARR & CCR)
    // DMA Data Width in CubeMX MUST be 'Word' for 32-bit timers
    HAL_TIM_DMABurst_WriteStart(
        stepper->htim,
        TIM_DMABASE_ARR,
        TIM_DMA_CC2,
        (uint32_t*)stepper->burst_buffer,
        (uint32_t)(steps * 2)
        );

    HAL_TIM_PWM_Start(stepper->htim, stepper->tim_channel);
}

void Stepper_CleanUp(Stepper* stepper) {
    // Use the same trigger (CC2) you used in WriteStart
    HAL_TIM_PWM_Stop(stepper->htim, stepper->tim_channel);
    HAL_TIM_DMABurst_WriteStop(stepper->htim, TIM_DMA_CC2);

    stepper->current_pos = stepper->target_pos;
    stepper->is_moving = false;
}

static void prv_set_direction(const Stepper* stepper, const int32_t target_pos) {
    HAL_GPIO_WritePin(stepper->dir_port, stepper->dir_pin, (stepper->current_pos > target_pos) ? GPIO_PIN_SET : GPIO_PIN_RESET);
}

static void prv_prepare_burst(Stepper* stepper, uint32_t steps) {
    float vel = stepper->current_velocity;

    for (uint32_t i = 0; i < steps; i++) {
        // Calculate ARR as before
        const float dt = 1.0f / vel;
        if (vel < stepper->max_speed) vel += stepper->acceleration * dt;

        const uint16_t arr_val = (uint32_t)(1000000.0f / vel) - 1;

        // Indexing: ARR at even, CCR at odd
        stepper->burst_buffer[i * 2] = arr_val;
        stepper->burst_buffer[i * 2 + 1] = arr_val >> 1; // 50% Duty Cycle
    }
}
