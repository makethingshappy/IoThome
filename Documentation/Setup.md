# ⚡ IoThome Setup Guide

> **Author:** Arshia Keshvari ([@TeslaNeuro](https://github.com/TeslaNeuro)) · MakeThingsHappy.io  
> **License:** MIT

This guide walks you through setting up an IoThome node from scratch, from flashing Tasmota onto your ESP32 to having your Berry drivers running and publishing sensor data.

**Assumed knowledge:** You have worked with ESP32 boards before and are comfortable with basic hardware setup, but Tasmota is new to you.

**Time to complete:** ~20–30 minutes

---

## Table of Contents

1. [What You Need](#1-what-you-need)
2. [Flash Tasmota](#2-flash-tasmota)
3. [Connect to Your Network](#3-connect-to-your-network)
4. [Apply Your IoTextra Tasmota Template](#4-apply-your-iotextra-tasmota-template)
5. [Enable I²C](#5-enable-i2c)
6. [Upload Berry Drivers](#6-upload-berry-drivers)
7. [Configure Your Drivers](#7-configure-your-drivers)
8. [Create autoexec.be](#8-create-autoexecbe)
9. [Verify Everything Is Working](#9-verify-everything-is-working)
10. [Next Steps](#10-next-steps)

---

## 1. What You Need

### Hardware

- ESP32-based board (ESP32, ESP32-S3, or compatible)
- IoTextra module(s) wired to your ESP32
- USB cable (data-capable, not charge-only)

### Software & Files — download before starting

| File | Where to get it |
|---|---|
| Tasmota factory binary for your SoM | See SoM → binary table in [Flash Tasmota](#2-flash-tasmota) below |
| GPIO template for your IoTextra module | [`/Tasmota_Templates`](../Tasmota_Templates) in this repo |
| Berry driver(s) for your hardware | [`/Berry_Drivers`](../Berry_Drivers) in this repo |
| A modern web browser (Chrome or Edge recommended) | — |

---

## 2. Flash Tasmota

Tasmota is flashed using the browser-based web installer — no drivers or command-line tools required, but can also be used optionally.

### SoM → Factory Binary Table

Find your SoM in the table below and download the corresponding factory binary from the [official Tasmota releases](https://github.com/arendst/Tasmota/releases).

> ⚠️ Always verify file names against the latest release before flashing — names may change between versions.

#### ESP32-S3

| SoM | Factory binary |
|---|---|
| Adafruit Feather ESP32-S3 4MB + 2MB PSRAM, SparkFun Thing Plus ESP32-S3 | `tasmota32s3-4MB-2MB-psram-factory.bin` |
| Waveshare ESP32-S3-Tiny, XIAO ESP32-S3, XIAO ESP32-S3 Sense, Adafruit QT Py ESP32-S3, Adafruit Feather ESP32-S3 8MB, Arduino Nano ESP32 | `tasmota32s3-8MB-factory.bin` |
| Waveshare ESP32-S3-Pico | `tasmota32s3-16MB-2MB-psram-factory.bin` |
| Waveshare ESP32-S3-Nano, FeatherS3 by Unexpected Maker | `tasmota32s3-16MB-8MB-psram-factory.bin` |

#### ESP32-C3

| SoM | Factory binary |
|---|---|
| XIAO ESP32-C3 | `tasmota32c3-4MB-factory.bin` |

#### ESP32-C5

| SoM | Factory binary |
|---|---|
| XIAO ESP32-C5 | `tasmota32c5-4MB-factory.bin` |

#### ESP32-C6

| SoM | Factory binary |
|---|---|
| XIAO ESP32-C6, Adafruit Feather ESP32-C6, Waveshare ESP32-C6 Pico | `tasmota32c6-4MB-factory.bin` |
| SparkFun Thing Plus ESP32-C6 | `tasmota32c6-16MB-factory.bin` |

---

### When Do You Need to Re-flash with a Factory Binary?

Re-flash with a factory binary (not OTA) in these cases:

- **Switching SoM** — different SoM may require a different binary or partition scheme
- **Corrupted firmware** — device does not boot or is unresponsive
- **Returning from ESPHome or Arduino** — these use different partition schemes incompatible with Tasmota OTA
- **Changing partition scheme** — required when switching between flash size variants

---

### Flashing Steps

**1.** Plug your ESP32 into your computer via USB.

**2.** Open [https://tasmota.github.io/docs/Getting-Started/](https://tasmota.github.io/docs/Getting-Started/) or [https://tasmota.github.io/install/](https://tasmota.github.io/install/) in Chrome or Edge.

> ⚠️ Firefox and Safari do not support the Web Serial API. Use Chrome or Edge.

**3.** Click **Connect** and select your ESP32's COM port from the popup list. (See Below Example)

<p align="center">
  
<img width="450" height="450" alt="image" src="https://github.com/user-attachments/assets/386dbbb3-5f0e-4247-b521-2ee77427f15d" />

</p>

<p align="center">

<img width="350" height="450" alt="image" src="https://github.com/user-attachments/assets/d3791d65-61c1-4691-a7f9-cfefde37ca92" />

</p>

**4.** Find your SoM in the table above, download the corresponding factory binary from [Tasmota releases](https://github.com/arendst/Tasmota/releases), and select it in the installer.

**5.** Check **Erase device** if this is a fresh install or the board has been previously flashed with different firmware.

**6.** Click **Install** and wait for the process to complete (~30–60 seconds). The board will restart automatically.

> 💡 If your COM port does not appear in the list, try a different USB cable or port. Some cables are charge-only and carry no data.

---

## 3. Connect to Your Network

After flashing, Tasmota boots into access point mode so you can give it your Wi-Fi credentials.

**1.** On your phone or laptop, scan for Wi-Fi networks. You will see one named `tasmota-XXXXXX`. You can also use the Web UI from Tasmotas website to connect your device to Wi-Fi.

**2.** Connect to it, no password is required.

**3.** A captive portal should open automatically. If it does not, navigate to Tasmota Web UI in your browser and check if you can change Wi-Fi network and credentials.

**4.** Enter your Wi-Fi SSID and password, then click **Save**.

**5.** The device will disconnect from the hotspot and join your network. Reconnect your computer to your normal Wi-Fi.

**6.** Find the device's IP address, you can check your router's DHCP client list, or use a network scanner. The device also announces itself via mDNS as `tasmota-XXXXXX.local` or a Fixed IP Address like `192.168.1.77`. If in doubt, please refer to `Tasmota Getting Started` page.

**7.** Open `http://<device-ip>` in your browser. You should see the Tasmota web UI.

---

## 4. Apply Your IoTextra Tasmota Template

Tasmota needs to know which GPIO pins are connected to what. IoThome provides pre-built templates for each IoTextra module.

**1.** Open the Tasmota web UI and go to **Configuration → Configure Other**.

**2.** Open the template JSON file for your module from [`/Tasmota_Templates`](../Tasmota_Templates) in a text editor and copy the entire contents.

**3.** Paste it into the **Template** field in the Tasmota UI.

**4.** Check the **Activate** checkbox directly below the template field.

**5.** Click **Save**. Tasmota will restart and apply the new GPIO assignments.

> 📖 If your exact module is not listed in `/Tasmota_Templates`, check the schematic for your IoTextra board to identify the GPIO pin assignments and create a template manually using the [Tasmota Template documentation](https://tasmota.github.io/docs/Templates/).

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

---

## 5. Enable I2C

IoTextra modules communicate over I²C. Verify Tasmota has I²C enabled after applying your template.

**1.** In the Tasmota web UI go to **Configuration → Configure Module**.

**2.** Confirm that your SDA and SCL pins are assigned. These should already be set correctly if you applied a template from this repo, but double-check against your board's schematic.

**3.** Go to **Consoles → Console** and type:

```
I2CScan
```

**4.** Press Enter. Tasmota will scan the I²C bus and print the addresses of any detected devices, for example:

```
I2C device found at address 0x48
I2C device found at address 0x27
```

If you see your module's expected address(es) listed here, I²C is working correctly. If nothing appears, check your wiring and confirm SDA/SCL pin assignments.

> 📖 See [`/Documentation/Berry Drivers.md`](./Berry%20Drivers.md) for the I²C address reference tables for ADS1115 and TCA9534/TCA9534A.

### ⚠️ Disable Conflicting Tasmota I²C Drivers

Tasmota includes built-in drivers for many I²C devices. Some of these share addresses with the TCA9534 and TCA9534A — most notably the HMI display driver, which also uses address `0x27`. If a conflicting built-in driver claims your device first, the TCA9534 Berry driver will not be able to communicate with it correctly.

**Disable the conflicting driver before proceeding.** Run the following in the Tasmota console:

```
I2cDriver36 0
```

This disables Tasmota's built-in HMI driver (I²C driver index 36), freeing address `0x27` and the surrounding range for exclusive use by the TCA9534 Berry driver.

To confirm the conflict is resolved, re-run `I2CScan` — the address should still appear, but it will no longer be claimed by a built-in driver. The Berry driver will take ownership on next boot.

> 📖 If you encounter other conflicting drivers, try to disable them using Tasmota's built-in console commands, learn more in [Tasmota's I²C Devices Official Guide](https://tasmota.github.io/docs/I2CDEVICES/)

---

## 6. Upload Berry Drivers

Berry drivers are `.be` files that run directly on the ESP32 inside Tasmota. Upload only the drivers that match your hardware.

**1.** In the Tasmota web UI go to **Consoles → Manage File System**.

**2.** Click **Choose File** and select the relevant `.be` file(s) from [`/Berry_Drivers`](../Berry_Drivers):

| Module | Driver file |
|---|---|
| IoTextra Analog Input (ADS1115) | `ADS1115Data.be` |
| IoTextra Analog 3 (ADS7828) | `ADS7828.be` |
| IoTextra Relay / Digital I/O (TCA9534 or TCA9534A) | `TCA9534.be` |
| IoTextra Quadro — ISO1211 **sampled-mode** channels (90 V DC / 110 V AC / 220 V AC) | `ISO1211.be` |

**3.** Click **Upload** for each file. You will see it appear in the file list once uploaded successfully.

> ⚠️ Do not restart yet, configure the drivers first (next step).

---

## 7. Configure Your Drivers

Each driver has a short configuration block at the top of the file. You need to edit these values to match your specific hardware before running the drivers.

The easiest way to edit them is directly in the Tasmota file manager or via a text editor on your PC:

**1.** In **Consoles → Manage File System**, click the edit icon (✏️) next to the driver file.

**2.** Adjust the variables at the top of the file. The key settings for each driver are:

### ADS1115 (`ADS1115Data.be`)

```berry
var SHUNT_RESISTOR = 0.249       # Match to your board: 0.249 or 0.120
var HARDWARE_GAIN  = 0.23761904761904762  # Match to your resistor config
var CHANNEL_RANGES = [0x02, 0x22, 0x82, 0x03]  # One range code per channel
```

| What to check | Where to find the answer |
|---|---|
| Shunt resistor value | Printed on or in the schematic for your IoTextra analog board |
| Hardware gain | See the gain table in [`/Documentation/Berry Drivers.md`](./Berry%20Drivers.md) |
| Channel range codes | See the range code table in [`/Documentation/Berry Drivers.md`](./Berry%20Drivers.md) |

**Configure ADS1115 boot behaviour in Tasmota:**

Tasmota's built-in ADS1115 sensor must be set to differential mode (`D`) on boot so it matches what the Berry driver expects. Do this with a Tasmota Rule.

Run the following two commands in the Tasmota console:

```
Rule1 on system#boot do sensor12 d0 endon
Rule1 1
```

The first command creates a rule that sets the ADS1115 to differential mode channel 0 every time the device boots. The second command enables the rule.

> ⚠️ **Why `system#boot` and not `system#init`?**  
> `system#boot` fires after the full Tasmota stack is ready — I²C, sensors, and drivers are all initialised. `system#init` fires earlier in the boot sequence before I²C is fully available, which can cause the command to silently fail. Use `system#boot` unless you have a specific reason not to.

**Sensor12 mode and gain reference:**

`sensor12` takes a two-character argument combining **mode** (`m`) and **gain** (`g`):

| Part | Option | Meaning |
|---|:---:|---|
| **Mode** | `S` | Single-ended — channels 0–3 read AIN0 to AIN3 independently |
| **Mode** | `D` | Differential — channel 0 = AIN0−AIN1, channel 1 = AIN2−AIN3 |
| **Gain** | `0` | ±6.144 V full range |
| **Gain** | `1` | ±4.096 V full range |
| **Gain** | `2` | ±2.048 V full range |
| **Gain** | `3` | ±1.024 V full range |
| **Gain** | `4` | ±0.512 V full range |
| **Gain** | `5` | ±0.256 V full range |

The IoThome ADS1115 Berry driver uses **differential mode** (`D`). The gain is handled per-channel inside the driver via `CHANNEL_RANGES` — the `sensor12` gain argument is overridden by the Berry driver at runtime.

**Examples:**

```
Sensor12 D0    # Differential mode, 6.144V range (used by IoThome driver)
Sensor12 S2    # Single-ended mode, 2.048V range
Sensor12 D1    # Differential mode, 4.096V range
```

### ADS7828 (`ADS7828.be`)

```berry
var ADS7828_ADDRESS = 0x4B  # Valid: 0x48–0x4B (A1/A0 strapping)
var ADS7828_VREF    = 2.5   # Internal reference (default)

var SHUNT_RESISTOR = 0.249
var HARDWARE_GAIN  = 0.47523809523809524

# One range code per channel (CH0–CH7)
var CHANNEL_RANGES = [0x02, 0x22, 0x82, 0x03, 0x02, 0x02, 0x02, 0x02]
```

| What to check | Where to find the answer |
|---|---|
| I²C address (`ADS7828_ADDRESS`) | Check A0/A1 strapping vs the address table in [`/Documentation/I2C Address & GPIO Mapping Reference.md`](./I2C%20Address%20%26%20GPIO%20Mapping%20Reference.md) |
| Hardware gain / shunt resistor | Check the schematic / BOM for your IoTextra Analog 3 board |
| Channel range codes | See the range code tables in [`/Documentation/Berry Drivers.md`](./Berry%20Drivers.md) |

### TCA9534 (`TCA9534.be`)

```berry
var IOEXPANDER_ADDRESS   = 0x27        # I²C address from your A0/A1/A2 wiring
var IOEXPANDER_PINCONFIG = "xxxxxx00"  # 8 chars, MSB→LSB: 1=input, 0=output
var HARDWARE_MODE        = "i2c"       # "i2c" or "gpio"
```

| What to check | Where to find the answer |
|---|---|
| I²C address | Check A0/A1/A2 pin wiring on your board against the address table in [`/Documentation/Berry Drivers.md`](./Berry%20Drivers.md) |
| Pin config string | Check the schematic for your IoTextra module — common presets are listed in the driver documentation |
| Hardware mode | Use `"i2c"` unless your channels are directly wired to ESP32 GPIO pins |

### ISO1211 (`ISO1211.be`)

> ⚠️ This driver is **only** for IoTextra Quadro channels in **sampled mode** (JM jumper **open**: 90 V DC, 110 V AC, 220 V AC). Direct-mode channels (12–60 V DC, JM closed) are ordinary DI inputs — use `TCA9534.be` for those.

```berry
var OUT_SOURCE         = "i2c"    # how OUT is read: "i2c" (TCA9534) or "gpio" (Tasmota switch)
var IOEXPANDER_ADDRESS = 0x27     # TCA9534 0x20-0x27 / TCA9534A 0x38-0x3F (only when OUT_SOURCE = i2c)
var OUT_INVERT         = false    # optional EXTRA flip of the DI value (default = standard IoTextra convention)
var ISO1211_T_SETTLE   = 25       # FGND settle time per reading, ms (effective ~50 ms, see note below)

var ISO1211_CHANNELS = [
  {"name": "ISO1211_CH1", "fgnd_relay": 3, "out_channel": 1, "invert": false},
  {"name": "ISO1211_CH2", "fgnd_relay": 4, "out_channel": 2, "invert": false}
]
```

| What to check | Where to find the answer |
|---|---|
| `OUT_SOURCE` | `"i2c"` reads OUT from a TCA9534/TCA9534A input register; `"gpio"` reads it from a Tasmota template switch. FGND is **always** GPIO regardless of this. |
| `fgnd_relay` (per channel) | The Tasmota **relay** number driving that channel's TLP188 / FGND. Assign the HOST connector pin as a `Relay` in your template, then put its relay number here. **This is the parameter unique to sampled mode.** |
| `out_channel` (per channel) | Where OUT is read: `i2c` → TCA9534 `P0..P7` (1..8); `gpio` → position in the packed template-switch list. |
| `OUT_INVERT` / per-channel `invert` | Leave `false` — the driver already applies the standard active-low convention. Only flip if a channel reads reversed on your wiring. |
| `ISO1211_T_SETTLE` | Universal `25 ms` for all sampled ranges. Decrease only if you understand the thermal trade-offs. |

> ⚠️ **Safety / thermal:** This driver pulses FGND **on** only briefly (~50 ms) to take each reading, then **off**, and scans channels one at a time so only one channel is ever energized. This is mandatory in sampled mode — at up to 220 V AC, leaving FGND on continuously would overheat the ISO1211. Do **not** change the scan to fire faster than once per second, and keep the startup FGND de-assertion intact. See [`/Documentation/Berry Drivers.md`](./Berry%20Drivers.md) for full details.

> 💡 **Timing note:** `tasmota.set_timer` has ~50 ms resolution, so a `t_settle` of 25 ms rounds up to a real ~50 ms pulse. That is harmless — a longer settle only makes the reading more reliable while keeping the duty cycle tiny.

**3.** Save the file after editing.

---

## 8. Create autoexec.be

Tasmota runs `autoexec.be` automatically on every boot. You need to create this file to tell Tasmota which drivers to load or application code to run.

**1.** In **Consoles → Manage File System**, check whether `autoexec.be` already exists.

- If it does — click the edit icon and add your `load()` lines to it.
- If it does not — click **Create** (or upload a new file named `autoexec.be`).

**2.** Add a `load()` line for each driver you uploaded:

```berry
# Load only the drivers that match your hardware
load('ADS1115Data.be')
load('ADS7828.be')
load('TCA9534.be')
load('ISO1211.be')   # IoTextra Quadro, sampled-mode ISO1211 channels only
```

**3.** Save the file.

**4.** Restart Tasmota by going to **Consoles → Console** and typing:

```
Restart 1
```

---

## 9. Verify Everything Is Working

After restart, confirm each part of the stack is running correctly.

### Check the console log

Go to **Consoles → Console**. On boot you should see output from your drivers, for example:

```
D0: voltage, range 0.0 to 5.0, ADS gain 1
D1: current, range 4.0 to 20.0, ADS gain 1
I2C: I/O Expander detected at 0x27 on bus 1
I/O Expander: Configuring pins with bitmask 0xFC
```

If you see `not found at address` errors, recheck your I²C address configuration and wiring.

### Check the web UI sensor display

The Tasmota home page should now show live readings from your modules:

```
ADS1115 D0 V     3.214 V
ADS1115 D1 mA   12.450 mA
P0 (CH1) OUT     OFF
P1 (CH2) IN      HIGH
```

Example Web UI display for `Smart Farm` application script running on `IoTextra Combo`:

<p align="center">
  <img width="300" height="450" alt="image" src="https://github.com/user-attachments/assets/0c43140b-9626-4759-ad6d-132b0e4b211f" />
</p>

### Check telemetry JSON

In the console, type:

```
Status 8
```

This prints the current sensor JSON payload. You should see your driver data nested inside, for example:

```json
{"StatusSNS":{"Time":"2026-03-01T12:00:00","ADS1115":{"D0_V":3.214,"D1_mA":12.450},"TCA9534":{"P0_OUT":0,"P1_IN":1}}}
```

This is the same payload that gets published to MQTT if you have a broker configured.

### Check ISO1211 (sampled-mode) channels

On boot the driver prints a readiness line confirming all FGND relays were de-asserted:

```
ISO1211: 2 sampled-mode channel(s) ready, all FGND de-asserted, t_settle=25ms
```

Once per second it pulses each channel's FGND, reads OUT, and publishes a `RESULT` like:

```json
{"ISO1211":{"ISO1211_CH1":{"DI":0,"error":false},"ISO1211_CH2":{"DI":0,"error":false}}}
```

- `DI` is the logical input: `0` = no signal, `1` = signal present. With nothing connected, `DI:0` is correct.
- `error:false` means the OUT read succeeded (it flags a read/comms failure, **not** a field fault).
- You will also see the FGND relays toggle (e.g. `POWER3 ON/OFF`, `POWER4 ON/OFF`) — that is the normal pulse-and-read sequence, not a glitch.

---

## 10. Next Steps

Your IoThome node is now running. Here is what to explore next:

| Goal | Where to look |
|---|---|
| Understand all driver configuration options | [`/Documentation/Berry Drivers.md`](./Berry%20Drivers.md) |
| Add automation logic with a ready made `autoexec.be` application script (e.g. control relays based on sensor readings) | [`/Application_Scripts`](../Application_Scripts) |
| Connect to Home Assistant or Node-RED | Configure MQTT under **Configuration → Configure MQTT** in Tasmota |
| Add more IoTextra modules | Repeat steps 4–8 for each additional module |
| Troubleshoot I²C detection issues | Re-run `I2CScan` in the console and verify wiring against the address tables in [`/Documentation`](.) |
