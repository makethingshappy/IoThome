# Tasmota Templates — IoTbase PICO + Waveshare ESP32-S3-Pico
Tasmota templates for IoTextra mezzanine modules used with the **IoTbase PICO** platform and **Waveshare ESP32-S3-Pico** module.

## Signal Mapping (v2)

| IoTbase Signal | IoTbase Function     | ESP32-S3 GPIO | Tasmota Use    |
|----------------|----------------------|---------------|----------------|
| TX0            | UART0 TX             | GPIO11        | Serial TX      |
| RX0            | UART0 RX             | GPIO12        | Serial RX      |
| SCK            | SPI Clock            | GPIO13        | SPI CLK        |
| MOSI           | SPI Data Out         | GPIO14        | SPI MOSI       |
| MISO           | SPI Data In          | GPIO15        | SPI MISO       |
| CS             | SPI CS (HOST / M1)   | GPIO16        | SPI CS0        |
| SDA1           | I2C1 SDA / Watchdog  | GPIO17        | I2C2 SDA       |
| SCL1           | I2C1 SCL             | GPIO18        | I2C2 SCL       |
| TX1            | UART1 TX (RS-485)    | GPIO33        | TXD1           |
| RX1            | UART1 RX (RS-485)    | GPIO34        | RXD1           |
| AP0            | Application IO 0     | GPIO35        | REL1 / SWT1    |
| AP1            | Application IO 1     | GPIO36        | REL2 / SWT2    |
| AP2            | Application IO 2     | GPIO37        | REL3 / SWT3    |
| AP3            | Application IO 3     | GPIO38        | REL4 / SWT4    |
| AP4            | Application IO 4     | GPIO39        | REL5 / SWT5    |
| AP5            | Application IO 5     | GPIO40        | REL6 / SWT6    |
| CS1            | SPI CS1 (M2)         | GPIO41        | SPI CS1        |
| RST            | Reset output         | GPIO42        | Reset          |
| AP6            | Application IO 6     | GPIO1         | REL7 / SWT7    |
| AP7            | Application IO 7     | GPIO2         | REL8 / SWT8    |
| SDA            | I2C0 SDA (main)      | GPIO4         | I2C SDA        |
| SCL            | I2C0 SCL (main)      | GPIO5         | I2C SCL        |
| PWM            | PWM / Backlight      | GPIO6         | PWM            |
| INT            | INT                  | GPIO7         | KEY1 / IRQ     |
| AN             | AN                   | GPIO9         | ADC1           |
| CS2            | CS2                  | GPIO10        | SPI CS2        |

## Available Templates

| IoTextra Module | Status         |
|-----------------|----------------|
| Input           | ✅ Available   |
| Relay2          | ✅ Available   |
| SSR Small       | ✅ Available   |
| MOSFET2         | ✅ Available   |
| Octal           | ✅ Available   |
| Octal2          | ✅ Available   |
| Analog          | 🔶 Coming Soon |
| Analog2         | 🔲 Planned     |
| Analog3         | 🔶 Coming Soon |
| Combo           | 🔶 Coming Soon |
| Combo2          | 🔲 Planned     |

## Firmware

- Flash firmware: `tasmota32s3-4MB-factory.bin`

## Templates

### IoTextra Input
```json
{"NAME":"IoTextra Input","GPIO":[0,166,167,0,608,640,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,160,161,162,163,164,165,0,0,0,0,0,0,0],"FLAG":0,"BASE":1}
```

### IoTextra Relay2
```json
{"NAME":"IoTextra Relay2","GPIO":[0,0,0,0,608,640,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,256,257,0,0,0,0,0,0,0,0,0,0,0],"FLAG":0,"BASE":1}
```

### IoTextra SSR Small
```json
{"NAME":"IoTextra SSR Small","GPIO":[0,0,0,0,608,640,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,256,257,258,259,260,261,0,0,0,0,0,0,0],"FLAG":0,"BASE":1}
```

### IoTextra MOSFET2
```json
{"NAME":"IoTextra MOSFET2","GPIO":[0,0,0,0,608,640,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,256,257,258,259,260,261,0,0,0,0,0,0,0],"FLAG":0,"BASE":1}
```

### IoTextra Octal
```json
{"NAME":"IoTextra Octal","GPIO":[0,162,163,0,608,640,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,256,257,258,259,160,161,0,0,0,0,0,0,0],"FLAG":0,"BASE":1}
```

### IoTextra Octal2
```json
{"NAME":"IoTextra Octal2","GPIO":[0,162,163,0,608,640,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,256,257,258,259,160,161,0,0,0,0,0,0,0],"FLAG":0,"BASE":1}
```
