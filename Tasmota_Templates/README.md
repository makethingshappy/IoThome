# Tasmota Templates

Tasmota configuration templates for IoTextra mezzanine modules across all IoTsmart & IoTbase platforms.

## Template Coverage Matrix

<!-- IOTEXTRA_TASMOTA_COMPATIBILITY_START -->
# IoTextra Tasmota Compatibility
| IoTextra Module | IoTsmart ESP32-S3 | IoTsmart XIAO + XIAO ESP32-S3 | IoTbase PICO + Waveshare ESP32-S3-Pico | IoTbase NANO + Waveshare ESP32-S3-NANO | IoTbase Feather + Adafruit ESP32-C6 Feather |
|---|:---:|:---:|:---:|:---:|:---:|
| Input | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTsmart_ESP32-S3.md#iotextra-input) | 🔶 | 🔶 | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTbase_Nano.md#iotextra-input) | 🔶 |
| Relay | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 |
| Relay2 | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTsmart_ESP32-S3.md#iotextra-relay2) | 🔶 | 🔶 | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTbase_Nano.md#iotextra-relay2) | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTbase_Feather.md#iotextra-relay2) |
| SSR Small | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTsmart_ESP32-S3.md#iotextra-ssr-small) | 🔶 | 🔶 | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTbase_Nano.md#iotextra-ssr-small) | 🔶 |
| MOSFET2 | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTsmart_ESP32-S3.md#iotextra-mosfet2) | 🔶 | 🔶 | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTbase_Nano.md#iotextra-mosfet2) | 🔶 |
| Quadro | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTsmart_ESP32-S3.md#iotextra-quadro) | 🔲 | 🔲 | 🔲 | 🔲 |
| Octal | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTsmart_ESP32-S3.md#iotextra-octal) | 🔶 | 🔶 | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTbase_Nano.md#iotextra-octal) | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTbase_Feather.md#iotextra-octal) |
| Octal2 | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTsmart_ESP32-S3.md#iotextra-octal2) | 🔶 | 🔶 | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTbase_Nano.md#iotextra-octal2) | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTbase_Feather.md#iotextra-octal2) |
| Octal3 | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTsmart_ESP32-S3.md#iotextra-octal3) | 🔲 | 🔲 | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTbase_Nano.md#iotextra-octal3) | 🔲 |
| Analog | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTsmart_ESP32-S3.md#iotextra-analog) | 🔶 | 🔶 | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTbase_Nano.md#iotextra-analog) | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTbase_Feather.md#iotextra-analog) |
| Analog2 | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 |
| Analog3 | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTsmart_ESP32-S3.md#iotextra-analog3) | 🔶 | 🔶 | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTbase_Nano.md#iotextra-analog3) | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTbase_Feather.md#iotextra-analog3) |
| Combo | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTsmart_ESP32-S3.md#iotextra-combo) | 🔶 | 🔶 | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTbase_Nano.md#iotextra-combo) | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTbase_Feather.md#iotextra-combo) |
| Combo2 | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 |

**Legend:**
- [![Template](https://img.shields.io/badge/Template-green)]() — available, click to open
- 🔶 — Coming Soon
- 🔲 — Planned

<!-- IOTEXTRA_TASMOTA_COMPATIBILITY_END -->

## Platforms

| Platform | Templates |
|----------|-----------|
| IoTsmart ESP32-S3 | [IoTsmart_ESP32-S3.md](./IoTsmart_ESP32-S3.md) |
| IoTbase PICO | [IoTbase_PICO.md](./IoTbase_PICO.md) |
| IoTbase Nano | [IoTbase_Nano.md](./IoTbase_Nano.md) |
| IoTbase Feather | [IoTbase_Feather.md](./IoTbase_Feather.md) |

## How to Apply a Template

See the [IoThome Setup Guide](https://github.com/makethingshappy/IoThome/blob/main/Documentation/Setup.md) for instructions.
