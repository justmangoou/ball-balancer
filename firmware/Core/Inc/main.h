/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.h
  * @brief          : Header for main.c file.
  *                   This file contains the common defines of the application.
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2026 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */

/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __MAIN_H
#define __MAIN_H

#ifdef __cplusplus
extern "C" {
#endif

/* Includes ------------------------------------------------------------------*/
#include "stm32f4xx_hal.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include "stdbool.h"
/* USER CODE END Includes */

/* Exported types ------------------------------------------------------------*/
/* USER CODE BEGIN ET */

/* USER CODE END ET */

/* Exported constants --------------------------------------------------------*/
/* USER CODE BEGIN EC */

/* USER CODE END EC */

/* Exported macro ------------------------------------------------------------*/
/* USER CODE BEGIN EM */

/* USER CODE END EM */

void HAL_TIM_MspPostInit(TIM_HandleTypeDef *htim);

/* Exported functions prototypes ---------------------------------------------*/
void Error_Handler(void);

/* USER CODE BEGIN EFP */
void DWT_Delay_us(uint32_t microseconds);
/* USER CODE END EFP */

/* Private defines -----------------------------------------------------------*/
#define LED_Pin GPIO_PIN_13
#define LED_GPIO_Port GPIOC
#define TOUCH_X_POS_Pin GPIO_PIN_1
#define TOUCH_X_POS_GPIO_Port GPIOA
#define TOUCH_Y_POS_Pin GPIO_PIN_2
#define TOUCH_Y_POS_GPIO_Port GPIOA
#define TOUCH_X_NEG_Pin GPIO_PIN_3
#define TOUCH_X_NEG_GPIO_Port GPIOA
#define TOUCH_Y_NEG_Pin GPIO_PIN_4
#define TOUCH_Y_NEG_GPIO_Port GPIOA
#define LEG_ENABLE_Pin GPIO_PIN_12
#define LEG_ENABLE_GPIO_Port GPIOA
#define LEG_A_DIR_Pin GPIO_PIN_15
#define LEG_A_DIR_GPIO_Port GPIOA
#define LEG_A_STEP_Pin GPIO_PIN_3
#define LEG_A_STEP_GPIO_Port GPIOB
#define LEG_B_DIR_Pin GPIO_PIN_4
#define LEG_B_DIR_GPIO_Port GPIOB
#define LEG_B_STEP_Pin GPIO_PIN_5
#define LEG_B_STEP_GPIO_Port GPIOB
#define LEG_C_DIR_Pin GPIO_PIN_6
#define LEG_C_DIR_GPIO_Port GPIOB
#define LEG_C_STEP_Pin GPIO_PIN_7
#define LEG_C_STEP_GPIO_Port GPIOB

/* USER CODE BEGIN Private defines */
#define LEG_A_TIM      TIM2
#define LEG_B_TIM      TIM3
#define LEG_C_TIM      TIM4
#define HEARTBEAT_TIM  TIM5
/* USER CODE END Private defines */

#ifdef __cplusplus
}
#endif

#endif /* __MAIN_H */
