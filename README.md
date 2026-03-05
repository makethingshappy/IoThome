## 🏡 IoThome 

A standalone ecosystem integrating the IoTextra series modules with **Tasmota** on ESP32 based microcontrollers. It enables automation logic for smart home IoT applications, such as smart farming, without requiring external controllers or servers.

---

## 🌱 Make Things Happy Platform Philosophy
Modern prototyping tools make it easy to build a demo but extremely hard to transition that prototype into a stable, maintainable industrial product. Teams often redesign hardware from the ground up after using Raspberry Pi, Arduino, or similar prototyping boards, a costly and time-consuming process that burdens long-term support.

The **Make Things Happy** platform eliminates this gap by standardizing I/O hardware through the IoTextra module family and providing two clear integration paths:

**IoTbase** for full-featured, serial-ready solutions using SoMs, and **IoTsmart** for compact wireless MCU nodes. All modules are Open Hardware, well-documented, and usable independently.

To unify these hardware options for smart home users, we created **IoThome**.

---

## 🔎 What Is IoThome?

IoThome is a software layer that sits on top of Tasmota and the IoTextra hardware family. It provides ready-to-use Berry drivers, templates, and automation logic so you can go from hardware assembly to a running smart home node without writing firmware from scratch.

| Layer | Role |
|---|---|
| **IoTextra modules** | Standardized I/O hardware (analog inputs, digital I/O, etc.) |
| **Tasmota** | Open-source ESP32 firmware handling connectivity, OTA, and much more |
| **IoThome Berry Drivers & Application Scripts** | Application-level logic running on-device inside Tasmota |
| **IoThome templates** | Pre-configured GPIO mappings for each supported module |

No external server, hub, or cloud dependency is required. Every node runs autonomously and locally.

---

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
---

## 📥 Installation & Quick Start

See full setup instructions in:

📄 **[`SETUP.md`](./Documentation/SETUP.md)**

---

## 📁 Repository Structure

```
IoThome/
│
├── Application_Scripts/     # Ready-to-use Berry automation scripts
│                            # Drop-in logic for common use cases
│
├── Berry_Drivers/           # Low-level Berry drivers for IoTextra hardware
│   ├── ads1115.be           # ADS1115 analog ADC driver (voltage & current)
│   └── tca9534.be           # TCA9534/TCA9534A digital I/O expander driver
│
├── Documentation/           # Configuration / setup guides and parameter references
│
│
├── Media/                   # Images and diagrams used in documentation
│
├── Tasmota_Binaries/        # Pre-built Tasmota firmware for supported boards
│
├── Tasmota_Templates/       # GPIO templates for IoTextra module variants
│
├── LICENSE                  # MIT License
└── README.md
```

---

## 🔄 Planned Updates

---

## 📜 Licensing

All IoThome code, documentation, and media are licensed under:

📄 **[`LICENSE`](./LICENSE)**

Hardware licenses do not apply, this is a software-only repository.
