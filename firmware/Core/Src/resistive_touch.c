#include "resistive_touch.h"

/* Private macro -------------------------------------------------------------*/

extern ADC_HandleTypeDef hadc1;
static ADC_ChannelConfTypeDef sConfig_read = { 0 };

/* Private function prototypes -----------------------------------------------*/
static uint32_t prv_adc_read_raw(uint32_t channel, uint16_t *samples, int n);
static void prv_set_gpio_mode(GPIO_TypeDef* port, uint16_t pin, uint32_t mode, uint32_t pull);
static uint16_t prv_get_median(uint16_t arr[], int n);

void ResistiveTouch_Init(void) {
    sConfig_read.Rank         = 1;
    sConfig_read.SamplingTime = ADC_SAMPLETIME_480CYCLES;
    sConfig_read.Offset       = 0;
}

int ResistiveTouch_Scan(ResistiveTouch_RawPoint *point) {
    uint16_t samples_x[TOUCH_SAMPLE_COUNT] = { 0 };
    uint16_t samples_y[TOUCH_SAMPLE_COUNT] = { 0 };

    // --- READ X AXIS ---
    // Power X-axis: XP (PA1) High, XN (PA3) Low. Read from YP (PA2)
    prv_set_gpio_mode(TOUCH_X_POS_GPIO_Port, TOUCH_X_POS_Pin, GPIO_MODE_OUTPUT_PP, GPIO_PULLUP);
    prv_set_gpio_mode(TOUCH_X_NEG_GPIO_Port, TOUCH_X_NEG_Pin, GPIO_MODE_OUTPUT_PP, GPIO_PULLDOWN);
    prv_set_gpio_mode(TOUCH_Y_POS_GPIO_Port, TOUCH_Y_POS_Pin, GPIO_MODE_ANALOG, GPIO_NOPULL);

    HAL_GPIO_WritePin(TOUCH_X_POS_GPIO_Port, TOUCH_X_POS_Pin, GPIO_PIN_SET);
    HAL_GPIO_WritePin(TOUCH_X_NEG_GPIO_Port, TOUCH_X_NEG_Pin, GPIO_PIN_RESET);

    DWT_Delay_us(50);

    prv_adc_read_raw(X_POS_ADC_CHANNEL, samples_x, TOUCH_SAMPLE_COUNT);

    // --- READ Y AXIS ---
    // Power Y-axis: YP (PA2) High, YN (PA4) Low. Read from XP (PA1)
    prv_set_gpio_mode(TOUCH_Y_POS_GPIO_Port, TOUCH_Y_POS_Pin, GPIO_MODE_OUTPUT_PP, GPIO_PULLUP);
    prv_set_gpio_mode(TOUCH_Y_NEG_GPIO_Port, TOUCH_Y_NEG_Pin, GPIO_MODE_OUTPUT_PP, GPIO_PULLDOWN);
    prv_set_gpio_mode(TOUCH_X_POS_GPIO_Port, TOUCH_X_POS_Pin, GPIO_MODE_ANALOG, GPIO_NOPULL);

    HAL_GPIO_WritePin(TOUCH_Y_POS_GPIO_Port, TOUCH_Y_POS_Pin, GPIO_PIN_SET);
    HAL_GPIO_WritePin(TOUCH_Y_NEG_GPIO_Port, TOUCH_Y_NEG_Pin, GPIO_PIN_RESET);

    DWT_Delay_us(50);

    prv_adc_read_raw(Y_POS_ADC_CHANNEL, samples_y, TOUCH_SAMPLE_COUNT);

    point->x = prv_get_median(samples_x, TOUCH_SAMPLE_COUNT);
    point->y = prv_get_median(samples_y, TOUCH_SAMPLE_COUNT);

    // Simple touch detection (assuming 12-bit ADC, 0 is no touch/grounded)
    return (point->x > 36 && point->y > 36) ? 1 : 0;
}

static uint32_t prv_adc_read_raw(uint32_t channel, uint16_t *samples, int n) {
    sConfig_read.Channel = channel;
    sConfig_read.Rank = 1; // Always use Rank 1 for single polling
    HAL_ADC_ConfigChannel(&hadc1, &sConfig_read);

    for (int i = 0; i < n; i++) {
        HAL_ADC_Start(&hadc1);

        if (HAL_ADC_PollForConversion(&hadc1, 10) == HAL_OK) {
            samples[i] = HAL_ADC_GetValue(&hadc1);
        }
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

/**
 * @brief Compute the median using insertion sort (in-place)
 *
 * Sorts the input array using insertion sort and returns the median value.
 * This function modifies the input array.
 *
 * @param arr Pointer to the array of uint32_t elements
 * @param n   Number of elements in the array (recommended: n < 16, preferably odd)
 *
 * @return    Median value of the array
 *            - If n is odd: middle element
 *            - If n is even: upper median (element at index n/2)
 *
 * @note
 * - Time complexity: O(n^2), suitable for small n
 * - Operates in-place (input array will be reordered)
 * - Intended for embedded use (e.g., small median filters)
 */
static uint16_t prv_get_median(uint16_t arr[], int n) {
    if (n <= 0) return 0;

    for (int32_t i = 1; i < n; i++) {
        const uint16_t key = arr[i];
        int32_t j = i - 1;

        while (j >= 0 && arr[j] > key) {
            arr[j + 1] = arr[j];
            j = j - 1;
        }
        arr[j + 1] = key;
    }
    return arr[n / 2];
}
