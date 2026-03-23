## 🏡 IoThome 

A standalone ecosystem integrating IoTextra, IoTbase and IoTsmart series modules with **Tasmota**. It enables automation logic for smart home IoT applications, such as smart farming, without requiring external controllers or servers.

## 🌱 Make Things Happy Platform Philosophy
Modern prototyping tools make it easy to build a demo but extremely hard to transition that prototype into a stable, maintainable product. Teams often redesign hardware from the ground up after using Raspberry Pi, Arduino, or similar prototyping boards, a costly and time-consuming process that burdens long-term support.

The **Make Things Happy** platform eliminates this gap by standardizing I/O hardware through the IoTextra module family and providing two clear integration paths:

**IoTbase** for full-featured, serial-ready solutions using SoMs, and **IoTsmart** for compact wireless MCU nodes. All modules are Open Hardware, well-documented, and usable independently.

To unify these hardware options for smart home users, we created **IoThome**.

## 🔎 What Is IoThome?

IoThome is a software layer that sits on top of Tasmota and the IoTextra hardware family. It provides ready-to-use Berry drivers, templates, and automation logic so you can go from hardware assembly to a running smart home node without writing firmware from scratch.

| Layer | Role |
|---|---|
| **IoTextra modules** | Standardized I/O hardware (analog inputs, digital I/O, etc.) |
| **Tasmota** | Open-source ESP32 firmware handling connectivity, OTA, and much more |
| **IoThome Berry Drivers & Application Scripts** | Application-level logic running on-device inside Tasmota |
| **IoThome templates** | Pre-configured GPIO mappings for each supported module |

No external server, hub, or cloud dependency is required. Every node runs autonomously and locally.

## 🛠️ Supported Hardware

### Microcontrollers and System On Modules (SoM)
* [**IoTbase PICO**](https://makethingshappy.io/products/iotbase-pico) - Compatible with Waveshare ESP32-S3 PICO and any ESP32 PICO based device
* [**IoTbase NANO**](https://makethingshappy.io/products/iotbase-nano) - Arduino Nano ESP32 or ESP32-S3 or Waveshare ESP32-S3 Nano
* [**IoTsmart ESP32-S3**](https://makethingshappy.io/products/iotsmart-esp32-s3) - Tiny Adaptor Board with Cable is required for flashing
* [**IoTsmart XIAO**](https://makethingshappy.io/products/iotsmart-xiao) - Compatible with ESP32 based devices / Tiny Adaptor Board with Cable is required for flashing

*IoTsmart modules are System-on-Module (SOM) microcontroller boards that provide the primary compute and control functionality for the system.
Each module integrates a complete MCU environment, and different form factors (soldered SoM, slot-based modules such as the IoTsmart XIAO, etc.) are treated as implementation variations rather than separate device classes.*

### Supported IoTextra Board Categories

#### Digital I/O Boards
* [**IoTextra Input**](https://makethingshappy.io/products/iotextra-input)
* [**IoTextra Octal2**](https://makethingshappy.io/products/iotextra-octal2)
* [**IoTextra Relay2**](https://makethingshappy.io/products/iotextra-relay2)
* [**IoTextra SSR Small**](https://makethingshappy.io/products/iotextra-ssr-small)
* Custom digital mezzanines

#### Analog or Combo I/O Boards
* [**IoTextra Analog**](https://makethingshappy.io/products/iotextra-analog)
* [**IoTextra Analog 2**](https://makethingshappy.io/products/iotextra-analog)
* [**IoTextra Analog 3**](https://makethingshappy.io/products/iotextra-analog3)
* [**IoTextra Combo**](https://makethingshappy.io/products/iotextra-combo)
* Custom analog mezzanines

## 🚀 Home Automation Workflow

A typical IoThome node follows this flow from hardware to running automation:

```
┌─────────────────────────────────────────────────────────────────┐
│  1. HARDWARE                                                    │
│     ESP32 based module + IoTextra I/O board(s) wired together   │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│  2. FLASH                                                       │
│     Flash pre-built Tasmota binary from /Tasmota_Binaries       │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│  3. CONFIGURE                                                   │
│     Apply IoTextra GPIO template from /Tasmota_Templates        │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│  4. DEPLOY DRIVERS                                              │
│     Upload Berry drivers from /Berry_Drivers via File System    │
│                                                                 │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────--┐
│  5. AUTOMATE                                                      │
│     Write or upload application scripts from /Application_Scripts │
│     Add berry driver load() calls to your `autoexec.be`           │
│     Node runs autonomously — no external server required          │
└─────────────────────────────────────────────────────────────────--┘
```

## 📥 Installation & Quick Start

See full setup instructions in:

📄 **[`Setup.md`](./Documentation/Setup.md)**

## 📹 Demo Videos

- [▶️ IoThome Smart Farm Demo](https://www.dropbox.com/scl/fi/xlf9rtpuqjcjmh14j3t56/Smart-Farm-Demo-IoTextra-Combo-IoThome.mp4?rlkey=2maaingyoptgajm5k6btwlqop&st=5jdrwy80&dl=0)

## 📁 Repository Structure

```
IoThome/
│
├── Application_Scripts/     # Ready-to-use Berry automation scripts
│                            # Drop-in logic for common use cases
│
├── Berry_Drivers/           # Low-level Berry drivers for IoTextra hardware
│   ├── ADS1115Data.be       # ADS1115 analog ADC driver (voltage & current)
│   └── TCA9534.be           # TCA9534/TCA9534A digital I/O expander driver
│
├── Documentation/           # Configuration / setup guides and parameter references
│
│
├── Media/                   # Images and Video links
│
├── Tasmota_Binaries/        # Pre-built Tasmota firmware for supported boards
│
├── Tasmota_Templates/       # GPIO templates for IoTextra module variants
│
├── LICENSE                  # MIT License
└── README.md
```

## 📜 Licensing

All IoThome code, documentation, and media are licensed under:

📄 **[`LICENSE`](./LICENSE)**

Hardware licenses do not apply, this is a software-only repository.
