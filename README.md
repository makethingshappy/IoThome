# 🏡 IoThome

A standalone ecosystem integrating IoTextra, IoTbase and IoTsmart series modules with Tasmota. It enables automation logic for smart home IoT applications, such as smart farming, without requiring external controllers or servers.

---

## ⚡ Key Principle

> **The binary is selected by SoM. The Template is selected by the board.**

- **Flash** the Tasmota binary that matches your **SoM (System-on-Module)** — see the SoM → binary table in [Setup.md](Documentation/Setup.md)
- **Apply** the Tasmota Template that matches your **carrier board** (IoTbase, IoTsmart) — see [`/Tasmota_Templates`](Tasmota_Templates/)

This separation means you can swap the SoM without changing the Template, and vice versa.

---

## 🌱 Make Things Happy Platform Philosophy

Modern prototyping tools make it easy to build a demo but extremely hard to transition that prototype into a stable, maintainable product. Teams often redesign hardware from the ground up after using Raspberry Pi, Arduino, or similar prototyping boards — a costly and time-consuming process that burdens long-term support.

The Make Things Happy platform eliminates this gap by standardizing I/O hardware through the IoTextra module family and providing two clear integration paths:

- **IoTbase** for full-featured, serial-ready solutions using SoMs
- **IoTsmart** for compact wireless MCU nodes

All modules are Open Hardware, well-documented, and usable independently.

To unify these hardware options for smart home users, we created IoThome.

---

## 🔎 What Is IoThome?

IoThome is a software layer that sits on top of Tasmota and the IoTextra hardware family. It provides ready-to-use Berry drivers, Templates, and automation logic so you can go from hardware assembly to a running smart home node without writing firmware from scratch.

| Layer | Role |
|---|---|
| IoTextra modules | Standardized I/O hardware (analog inputs, digital I/O, etc.) |
| Tasmota | Open-source ESP32 firmware handling connectivity, OTA, and much more |
| IoThome Berry Drivers & Application Scripts | Application-level logic running on-device inside Tasmota |
| IoThome Templates | Pre-configured GPIO mappings for each supported carrier board |

No external server, hub, or cloud dependency is required. Every node runs autonomously and locally.

---

## 🛠️ Supported Hardware

### Carrier Boards (Templates are organized by board)

| Board | Form Factor | Compatible SoMs |
|---|---|---|
| **IoTsmart ESP32-S3** | Fixed SoM | ESP32-S3 (integrated) |
| **IoTsmart XIAO** | XIAO slot | XIAO ESP32-S3, XIAO ESP32-C6, XIAO ESP32-C3, and other XIAO-compatible SoMs |
| **IoTbase PICO** | PICO | Waveshare ESP32-S3 PICO and other PICO-compatible SoMs |
| **IoTbase NANO** | Nano | Arduino Nano ESP32, Waveshare ESP32-S3 Nano, and other Nano-compatible SoMs |
| **IoTbase Feather** | Feather | Adafruit Feather ESP32-S3, Adafruit Feather ESP32-C6, and other Feather-compatible SoMs |

> ⚠️ IoTsmart ESP32-S3 requires a Tiny Adaptor Board with Cable for flashing.

<!-- CARRIER_COMPATIBILITY_START -->
# Carrier Board Software Compatibility

| Carrier Board | IoTflow (Node-RED) | IoThome (Tasmota) |
|---|:---:|:---:|
| IoTbase PICO + Waveshare ESP32-S3-Pico | 🔶 Coming Soon | 🔶 Coming Soon |
| IoTbase PICO + Waveshare ESP32-C6-Pico | 🔶 Coming Soon | 🔶 Coming Soon |
| IoTbase PICO + RP2040 | [![Open](https://img.shields.io/badge/Open-green)](https://github.com/makethingshappy/IoTflow/blob/main/Documentation/SETUP.md) | — |
| IoTbase PICO + RP2350 | [![Open](https://img.shields.io/badge/Open-green)](https://github.com/makethingshappy/IoTflow/blob/main/Documentation/SETUP.md) | — |
| IoTbase NANO + Waveshare ESP32-S3-NANO | [![Open](https://img.shields.io/badge/Open-green)](https://github.com/makethingshappy/IoTflow/blob/main/Documentation/SETUP.md) | [![Open](https://img.shields.io/badge/Open-green)](https://github.com/makethingshappy/IoThome/blob/main/Documentation/Setup.md) |
| IoTbase Feather + Adafruit ESP32-C6 Feather | 🔶 Coming Soon | 🔶 Coming Soon |
| IoTbase Feather + FeatherS3[D] ESP32-S3 | 🔲 Planned | 🔲 Planned |
| IoTsmart RP2040 | [![Open](https://img.shields.io/badge/Open-green)](https://github.com/makethingshappy/IoTflow/blob/main/Documentation/SETUP.md) | — |
| IoTsmart RP2350A | [![Open](https://img.shields.io/badge/Open-green)](https://github.com/makethingshappy/IoTflow/blob/main/Documentation/SETUP.md) | — |
| IoTsmart ESP32-S3 | [![Open](https://img.shields.io/badge/Open-green)](https://github.com/makethingshappy/IoTflow/blob/main/Documentation/SETUP.md) | [![Open](https://img.shields.io/badge/Open-green)](https://github.com/makethingshappy/IoThome/blob/main/Documentation/Setup.md) |
| IoTsmart XIAO + XIAO RP2350 | 🔶 Coming Soon | — |
| IoTsmart XIAO + XIAO ESP32-S3 | 🔶 Coming Soon | 🔶 Coming Soon |
| IoTsmart XIAO + XIAO ESP32-C5 | 🔲 Planned | 🔲 Planned |
| IoTsmart XIAO + XIAO ESP32-C6 | 🔲 Planned | 🔲 Planned |

**Legend:**
- [![Open](https://img.shields.io/badge/Open-green)]() — available, click to open
- — — not applicable
- 🔶 — Coming Soon
- 🔲 — Planned

<!-- CARRIER_COMPATIBILITY_END -->

### Supported IoTextra Modules

**Digital I/O**
- IoTextra Input
- IoTextra Relay2
- IoTextra SSR Small
- IoTextra MOSFET2
- IoTextra Octal
- IoTextra Octal2

**Analog / Combo**
- IoTextra Analog
- IoTextra Analog 3
- IoTextra Combo

### Template Coverage

<!-- IOTEXTRA_TASMOTA_COMPATIBILITY_START -->
# IoTextra Tasmota Compatibility
| IoTextra Module | IoTsmart ESP32-S3 | IoTsmart XIAO + XIAO ESP32-S3 | IoTbase PICO + Waveshare ESP32-S3-Pico | IoTbase NANO + Waveshare ESP32-S3-NANO | IoTbase Feather + Adafruit ESP32-C6 Feather |
|---|:---:|:---:|:---:|:---:|:---:|
| Input | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTsmart_ESP32-S3.md#iotextra-input) | 🔶 | 🔶 | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTbase_Nano.md#iotextra-input) | 🔶 |
| Relay2 | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTsmart_ESP32-S3.md#iotextra-relay2) | 🔶 | 🔶 | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTbase_Nano.md#iotextra-relay2) | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTbase_Feather.md#iotextra-relay2) |
| SSR Small | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTsmart_ESP32-S3.md#iotextra-ssr-small) | 🔶 | 🔶 | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTbase_Nano.md#iotextra-ssr-small) | 🔶 |
| MOSFET2 | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTsmart_ESP32-S3.md#iotextra-mosfet2) | 🔶 | 🔶 | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTbase_Nano.md#iotextra-mosfet2) | 🔶 |
| Quadro | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTsmart_ESP32-S3.md#iotextra-quadro) | 🔲 | 🔲 | 🔲 | 🔲 |
| Octal | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTsmart_ESP32-S3.md#iotextra-octal) | 🔶 | 🔶 | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTbase_Nano.md#iotextra-octal) | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTbase_Feather.md#iotextra-octal) |
| Octal2 | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTsmart_ESP32-S3.md#iotextra-octal2) | 🔶 | 🔶 | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTbase_Nano.md#iotextra-octal2) | [![Template](https://img.shields.io/badge/Template-green)](https://github.com/makethingshappy/IoThome/blob/main/Tasmota_Templates/IoTbase_Feather.md#iotextra-octal2) |
| Octal3 | 🔲 | 🔲 | 🔲 | 🔲 | 🔲 |
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

Full template files: [`/Tasmota_Templates`](Tasmota_Templates/)

---

## 🚀 Home Automation Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│  1. HARDWARE                                                    │
│     Carrier board + SoM + IoTextra I/O module(s)                │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│  2. FLASH                                                       │
│     Flash Tasmota factory binary from official Tasmota releases │
│     Binary is selected by SoM — see SoM table in Setup.md       │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│  3. CONFIGURE                                                   │
│     Apply IoTextra GPIO Template from /Tasmota_Templates        │
│     Template is selected by carrier board                       │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│  4. DEPLOY DRIVERS                                              │
│     Upload Berry drivers from /Berry_Drivers via File System    │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│  5. AUTOMATE                                                    │
│     Upload application scripts from /Application_Scripts        │
│     Add berry driver load() calls to autoexec.be                │
│     Node runs autonomously — no external server required        │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📥 Installation & Quick Start

See full setup instructions in:

📄 [Setup.md](Documentation/Setup.md)

---

## 📹 Demo Videos

▶️ [IoThome Smart Farm Demo](https://youtu.be/eNpTaUodwE4)

---

## 📁 Repository Structure

```
IoThome/
│
├── Application_Scripts/     # Ready-to-use Berry automation scripts
│                            # Drop-in logic for common use cases
│
├── Berry_Drivers/           # Low-level Berry drivers for IoTextra hardware
│   ├── ADS1115Data.be       # ADS1115 analog ADC driver (voltage & current)
│   ├── TCA9534.be           # TCA9534/TCA9534A digital I/O expander driver
│   └── ADS7828.be           # ADS7828 analog ADC driver (IoTextra Analog 3)
│
├── Documentation/           # Setup guides and parameter references
│
├── Media/                   # Images and video links
│
├── Tasmota_Templates/       # GPIO Templates organized by carrier board
│   ├── IoTsmart_ESP32-S3/
│   ├── IoTsmart_XIAO/
│   ├── IoTbase_PICO/
│   ├── IoTbase_NANO/
│   └── IoTbase_Feather/
│
├── LICENSE
└── README.md
```

> Tasmota binary files are **not** stored in this repository.
> Download them from the [official Tasmota releases](https://github.com/arendst/Tasmota/releases) using the SoM → binary table in [Setup.md](Documentation/Setup.md).

---

## 📜 Licensing

All IoThome code, documentation, and media are licensed under the MIT License — see [LICENSE](LICENSE).

Hardware licenses do not apply; this is a software-only repository.
