#include "stepper_a.h"

// Simple microsecond delay using DWT cycle counter
static void delay_us(uint32_t us) {
    uint32_t start = DWT->CYCCNT;
    uint32_t ticks = us * (HAL_RCC_GetHCLKFreq() / 1000000);
    while ((DWT->CYCCNT - start) < ticks);
}

void StepperA_Init(void) {
    // Enable DWT for microsecond delay
    CoreDebug->DEMCR |= CoreDebug_DEMCR_TRCENA_Msk;
    DWT->CYCCNT = 0;
    DWT->CTRL  |= DWT_CTRL_CYCCNTENA_Msk;

    // GPIO already initialized in MX_GPIO_Init()
    // Just make sure DIR starts LOW
    HAL_GPIO_WritePin(A_DIR_PORT, A_DIR_PIN, GPIO_PIN_RESET);
    HAL_GPIO_WritePin(A_STEP_PORT, A_STEP_PIN, GPIO_PIN_RESET);
}

void StepperA_SetDirection(uint8_t clockwise) {
    HAL_GPIO_WritePin(A_DIR_PORT, A_DIR_PIN,
                      clockwise ? GPIO_PIN_SET : GPIO_PIN_RESET);
    delay_us(10); // small settle time after DIR change
}

void StepperA_Move(uint32_t steps, uint32_t delay_us_val) {
    for (uint32_t i = 0; i < steps; i++) {
        HAL_GPIO_WritePin(A_STEP_PORT, A_STEP_PIN, GPIO_PIN_SET);
        delay_us(delay_us_val);
        HAL_GPIO_WritePin(A_STEP_PORT, A_STEP_PIN, GPIO_PIN_RESET);
        delay_us(delay_us_val);
    }
}

void StepperA_Stop(void) {
    HAL_GPIO_WritePin(A_STEP_PORT, A_STEP_PIN, GPIO_PIN_RESET);
}