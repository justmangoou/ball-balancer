#include "resistive_touch.h"

#include "main.h"
#include "math_extra.h"

#define TARGET_MIN      (-100.0f)
#define TARGET_MAX      100.0f
#define PREPARE_TIME    20

extern ADC_HandleTypeDef hadc1;
static ADC_ChannelConfTypeDef sConfig_read = { 0 };

static void prv_read_x(uint16_t *samples, int n);
static void prv_read_y(uint16_t *samples, int n);
static uint16_t prv_read_z(uint16_t x_raw);

static uint16_t prv_read_single(uint32_t channel);
static void prv_read_samples(uint32_t channel, uint16_t *samples, int n);

static uint16_t prv_get_median(uint16_t arr[], int n);

void Touch_Init(void)
{
    sConfig_read.Rank         = 1;
    sConfig_read.SamplingTime = ADC_SAMPLETIME_480CYCLES;
    sConfig_read.Offset       = 0;
}

bool Touch_Scan(Touch_RawPoint *point)
{
    static uint16_t samples[TOUCH_SAMPLE_COUNT] = { 0 };

    prv_read_x(samples, TOUCH_SAMPLE_COUNT);
    point->x = prv_get_median(samples, TOUCH_SAMPLE_COUNT);

    prv_read_y(samples, TOUCH_SAMPLE_COUNT);
    point->y = prv_get_median(samples, TOUCH_SAMPLE_COUNT);

    point->z = prv_read_z(point->x);

    const bool is_pressure_valid = point->z >= 10 && point->z <= 5000;
    const bool is_x_valid        = point->x < 4050;
    const bool is_y_valid        = point->y < 4050;

    return is_pressure_valid && is_x_valid && is_y_valid;
}

/**
 * @brief Translates raw ADC coordinates into centered percentages (-100 to 100).
 * @return 1 if successful, 0 if null pointers provided.
 */
uint8_t Touch_CenterOffsetPercent(const Touch_RawPoint *raw_point, Touch_CenterOffsetPercentage *offset_percentage)
{
    if (raw_point == NULL || offset_percentage == NULL) return 0;

    offset_percentage->x = map_clampedf(raw_point->x, TOUCH_X_MIN, TOUCH_X_MAX, TARGET_MIN, TARGET_MAX);
    offset_percentage->y = map_clampedf(raw_point->y, TOUCH_Y_MIN, TOUCH_Y_MAX, TARGET_MIN, TARGET_MAX);

    return 1;
}

static void prv_read_x(uint16_t *samples, int n)
{
    GPIO_SetPinMode(TOUCH_X_POS_GPIO_Port, TOUCH_X_POS_Pin, GPIO_MODE_OUTPUT_PP, GPIO_NOPULL);
    HAL_GPIO_WritePin(TOUCH_X_POS_GPIO_Port, TOUCH_X_POS_Pin, GPIO_PIN_SET);
    GPIO_SetPinMode(TOUCH_X_NEG_GPIO_Port, TOUCH_X_NEG_Pin, GPIO_MODE_OUTPUT_PP, GPIO_NOPULL);
    HAL_GPIO_WritePin(TOUCH_X_NEG_GPIO_Port, TOUCH_X_NEG_Pin, GPIO_PIN_RESET);

    GPIO_SetPinMode(TOUCH_Y_POS_GPIO_Port, TOUCH_Y_POS_Pin, GPIO_MODE_ANALOG, GPIO_NOPULL);
    GPIO_SetPinMode(TOUCH_Y_NEG_GPIO_Port, TOUCH_Y_NEG_Pin, GPIO_MODE_ANALOG, GPIO_NOPULL);

    DWT_Delay_us(PREPARE_TIME);

    prv_read_samples(Y_POS_ADC_CHANNEL, samples, n);
}

static void prv_read_y(uint16_t *samples, int n)
{
    GPIO_SetPinMode(TOUCH_Y_POS_GPIO_Port, TOUCH_Y_POS_Pin, GPIO_MODE_OUTPUT_PP, GPIO_NOPULL);
    HAL_GPIO_WritePin(TOUCH_Y_POS_GPIO_Port, TOUCH_Y_POS_Pin, GPIO_PIN_SET);
    GPIO_SetPinMode(TOUCH_Y_NEG_GPIO_Port, TOUCH_Y_NEG_Pin, GPIO_MODE_OUTPUT_PP, GPIO_NOPULL);
    HAL_GPIO_WritePin(TOUCH_Y_NEG_GPIO_Port, TOUCH_Y_NEG_Pin, GPIO_PIN_RESET);

    GPIO_SetPinMode(TOUCH_X_POS_GPIO_Port, TOUCH_X_POS_Pin, GPIO_MODE_ANALOG, GPIO_NOPULL);
    GPIO_SetPinMode(TOUCH_X_NEG_GPIO_Port, TOUCH_X_NEG_Pin, GPIO_MODE_ANALOG, GPIO_NOPULL);

    DWT_Delay_us(PREPARE_TIME);

    prv_read_samples(X_POS_ADC_CHANNEL, samples, n);
}

static uint16_t prv_read_z(uint16_t x_raw)
{
    GPIO_SetPinMode(TOUCH_X_NEG_GPIO_Port, TOUCH_X_NEG_Pin, GPIO_MODE_OUTPUT_PP, GPIO_NOPULL);
    HAL_GPIO_WritePin(TOUCH_X_NEG_GPIO_Port, TOUCH_X_NEG_Pin, GPIO_PIN_RESET);
    GPIO_SetPinMode(TOUCH_Y_POS_GPIO_Port, TOUCH_Y_POS_Pin, GPIO_MODE_OUTPUT_PP, GPIO_NOPULL);
    HAL_GPIO_WritePin(TOUCH_Y_POS_GPIO_Port, TOUCH_Y_POS_Pin, GPIO_PIN_SET);

    GPIO_SetPinMode(TOUCH_X_POS_GPIO_Port, TOUCH_X_POS_Pin, GPIO_MODE_ANALOG, GPIO_NOPULL);
    GPIO_SetPinMode(TOUCH_Y_NEG_GPIO_Port, TOUCH_Y_NEG_Pin, GPIO_MODE_ANALOG, GPIO_NOPULL);

    DWT_Delay_us(PREPARE_TIME);

    const uint16_t z1 = prv_read_single(X_POS_ADC_CHANNEL);
    const uint16_t z2 = prv_read_single(Y_NEG_ADC_CHANNEL);

    if (z1 == 0) return 0;

    /* * The Compensated Formula:
     * R_touch = (X_plate_resistance) * (x_raw / 4096) * ((z2 / z1) - 1)
     * * Since we don't care about the actual Ohms, we just need a consistent metric.
     * We use (uint32_t) to prevent overflow during the multiplication.
     */
    const uint32_t pressure = (uint32_t)x_raw * (z2 - z1) / z1;

    return pressure;
}

static void prv_setup_read(uint32_t channel)
{
    sConfig_read.Channel = channel;

    HAL_ADC_Stop(&hadc1);

    if (HAL_ADC_ConfigChannel(&hadc1, &sConfig_read) != HAL_OK) {
        Error_Handler();
    }

    DWT_Delay_us(10);
}

static uint16_t prv_read_single(const uint32_t channel)
{
    prv_setup_read(channel);

    HAL_ADC_Start(&hadc1);
    const uint16_t result = ADC_Read_Polling(DEFAULT_ADC_POLLING_TIMEOUT);
    HAL_ADC_Stop(&hadc1);

    return result;
}

static void prv_read_samples(const uint32_t channel, uint16_t *samples, const int n)
{
    prv_setup_read(channel);

    for (int i = 0; i < n; i++) {
        HAL_ADC_Start(&hadc1);
        samples[i] = ADC_Read_Polling(DEFAULT_ADC_POLLING_TIMEOUT);
    }
    HAL_ADC_Stop(&hadc1);
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
static uint16_t prv_get_median(uint16_t arr[], int n)
{
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
