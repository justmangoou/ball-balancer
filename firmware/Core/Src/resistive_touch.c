#include "resistive_touch.h"
#include "main.h"

extern ADC_HandleTypeDef hadc1;
extern ADC_ChannelConfTypeDef sConfig_read;

static uint32_t prv_adc_read_raw(uint32_t channel);
static void prv_set_gpio_mode(GPIO_TypeDef* port, uint16_t pin, uint32_t mode, uint32_t pull);
static uint32_t prv_get_median(uint32_t arr[], int n);

void ResistiveTouch_Init(void) {
    sConfig_read.Rank         = 1;
    sConfig_read.SamplingTime = ADC_SAMPLETIME_480CYCLES;
    sConfig_read.Offset       = 0;
}

int ResistiveTouch_Read(float *x, float *y) {
    uint32_t samples_x[7]; // Reduced to 7 for faster processing
    uint32_t samples_y[7];

    // --- READ X AXIS ---
    // Power X-axis: XP (PA1) High, XN (PA3) Low. Read from YP (PA2)
    prv_set_gpio_mode(TOUCH_X_POS_GPIO_Port, TOUCH_X_POS_Pin, GPIO_MODE_OUTPUT_PP, GPIO_PULLUP);
    prv_set_gpio_mode(TOUCH_X_NEG_GPIO_Port, TOUCH_X_NEG_Pin, GPIO_MODE_OUTPUT_PP, GPIO_PULLDOWN);
    prv_set_gpio_mode(TOUCH_Y_POS_GPIO_Port, TOUCH_Y_POS_Pin, GPIO_MODE_ANALOG, GPIO_NOPULL);

    HAL_GPIO_WritePin(TOUCH_X_POS_GPIO_Port, TOUCH_X_POS_Pin, GPIO_PIN_SET);
    HAL_GPIO_WritePin(TOUCH_X_NEG_GPIO_Port, TOUCH_X_NEG_Pin, GPIO_PIN_RESET);

    for (int i = 0; i < 7; i++) {
        samples_x[i] = prv_adc_read_raw(ADC_CHANNEL_2); // Sensed on PA2
    }

    // --- READ Y AXIS ---
    // Power Y-axis: YP (PA2) High, YN (PA4) Low. Read from XP (PA1)
    prv_set_gpio_mode(TOUCH_Y_POS_GPIO_Port, TOUCH_Y_POS_Pin, GPIO_MODE_OUTPUT_PP, GPIO_PULLUP);
    prv_set_gpio_mode(TOUCH_Y_NEG_GPIO_Port, TOUCH_Y_NEG_Pin, GPIO_MODE_OUTPUT_PP, GPIO_PULLDOWN);
    prv_set_gpio_mode(TOUCH_X_POS_GPIO_Port, TOUCH_X_POS_Pin, GPIO_MODE_ANALOG, GPIO_NOPULL);

    HAL_GPIO_WritePin(TOUCH_Y_POS_GPIO_Port, TOUCH_Y_POS_Pin, GPIO_PIN_SET);
    HAL_GPIO_WritePin(TOUCH_Y_NEG_GPIO_Port, TOUCH_Y_NEG_Pin, GPIO_PIN_RESET);

    for (int i = 0; i < 7; i++) {
        samples_y[i] = prv_adc_read_raw(ADC_CHANNEL_1); // Sensed on PA1
    }

    *x = (float)prv_get_median(samples_x, 7);
    *y = (float)prv_get_median(samples_y, 7);

    // Simple touch detection (assuming 12-bit ADC, 0 is no touch/grounded)
    return (*x > 50 && *y > 50) ? 1 : 0;
}

static uint32_t prv_adc_read_raw(uint32_t channel) {
    sConfig_read.Channel = channel;
    sConfig_read.Rank = 1; // Always use Rank 1 for single polling
    HAL_ADC_ConfigChannel(&hadc1, &sConfig_read);

    HAL_ADC_Start(&hadc1);

    if (HAL_ADC_PollForConversion(&hadc1, 10) == HAL_OK) {
        return HAL_ADC_GetValue(&hadc1);
    }

    return 0;
}

static void prv_set_gpio_mode(GPIO_TypeDef* port, const uint16_t pin, const uint32_t mode, const uint32_t pull) {
    GPIO_InitTypeDef GPIO_InitStruct = {0};
    GPIO_InitStruct.Pin = pin;
    GPIO_InitStruct.Mode = mode;
    GPIO_InitStruct.Pull = pull;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
    HAL_GPIO_Init(port, &GPIO_InitStruct);
}

static uint32_t prv_get_median(uint32_t arr[], const int n) {
    for (int32_t i = 1; i < n; i++) {
        const uint32_t key = arr[i];
        int32_t j = i - 1;

        while (j >= 0 && arr[j] > key) {
            arr[j + 1] = arr[j];
            j = j - 1;
        }
        arr[j + 1] = key;
    }
    return arr[n / 2];
}
