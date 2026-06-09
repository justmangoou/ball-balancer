# Ball Balancer

## Acknowledgements & Credits

This project is heavily inspired by and built upon the open-source work of **Aaed Musa** ([Ball Balancer on Instructables](https://www.instructables.com/Ball-Balancer/)). 

Python scripts to log data and graph visualizer are generated using Claude Sonnet 4.6.

## Development
### Pre-requisites
- Python 3.10 or higher (with `matplotlib`, `numpy` and `pyserial` libraries)
- STM32CubeMX
- STM32CubeCLT
- OpenOCD
- Clion (preferred)
- ST-Link V2

*It's also possible to use STM32CubeIDE, but CLion is recommended for better coding and debugging experience.*

### Firmware
All firmware code is located in the `firmware` directory. The project is configured for STM32F411CEU6 "Blackpill" microcontroller.

## Scipts
To log data to terminal only:
```bash
python loggger.py
```

To log data to terminal, draw graph ``x_err``, ``y_err``, ``x_out``, ``y_out`` and save to csv file:
```bash
python live_debugger.py
```

To see the graph of the logged data from csv file:
```bash
python log_viewer.py --file logs/xxxx-xx-xx_xx-xx-xx.csv
```

## PID Tuning Tracker
| Times | Time | Kp | Ki | Kd | 
| :---: | :---: | :---: | :---: | :---: |
| **1** | [2026-06-09_14-49-30](logs/2026-06-09_14-49-30.csv) | `6E-4f` | `6E-5f` | `10E-6f` |
| **2** | [2026-06-09_16-08-42](logs/2026-06-09_16-08-42.csv) | `1.3E-3f` | `7E-5f` | `2.3E-5f` |
| **3** | [2026-06-09_16-36-50](logs/2026-06-09_16-36-50.csv) | `1.1E-3f` | `5E-5f` | `2.3E-5f` |
| **4** | [2026-06-09_16-38-50](logs/2026-06-09_16-38-50.csv) | `1.1E-3f` | `5E-5f` (x) / `7E-5f` (y) | `2.3E-5f` |
| **5** | [2026-06-09_16-54-01](logs/2026-06-09_16-54-01.csv) | `1.1E-3f` | `5.5E-5f` (x) / `7.5E-5f` (y) | `2.3E-5f` |
| **6** | [2026-06-09_16-58-05](logs/2026-06-09_16-58-05.csv) | `1.1E-3f` | `6E-5f` (x) / `7.5E-5f` (y) | `2.3E-5f` |

### BOM
| ID | Name  | Quantity | Description |
| --- | --- | --- | --- |
| STM32F411CEU6 | STM32 BlackPill | 1 | Microcontroller |
|  | Resistive Touch Panel | 1 | 4 Pins  |
| 17HS4401S | Stepper 42x42mm | 3 | 1.5 - 2A |
| TMC2208 | Stepper Driver | 3 |  |
| LM2596 | Voltage Regulator | 1 | 4 - 35 VDC Input, 1 - 35 VDC Ouput (3A)  |
|  | Capacitor | 3 | 35V - 220uF |
|  | 24V power supply  | 1 | 24V - 5A |
|  | Terminal Connector | 1 | 15A - 12 Ports |
|  | FPC/FFC to DIP Adapter Board | 1 | 4 Pins |
|  | DC Jack | 1 |  |
|  | USB to TTL | 1 | |
|  | Male and female header pin | many |  |
