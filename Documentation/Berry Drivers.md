# ADS1115 & TCA9534 Berry Drivers for Tasmota

> **Author:** Arshia Keshvari ([@TeslaNeuro](https://github.com/TeslaNeuro)) · MakeThingsHappy.io  
> **License:** MIT

Berry drivers for the ADS1115 analog ADC and TCA9534/TCA9534A digital I/O expander, designed for use with IoTextra series modules running Tasmota.

---

## Table of Contents

- [ADS1115 Analog Driver](#ads1115-analog-driver)
  - [What It Does](#what-it-does)
  - [Configuration](#ads1115-configuration)
  - [Channel Range Codes](#channel-range-codes)
  - [Hardware Gain](#hardware-gain)
  - [Output Format](#ads1115-output-format)
- [TCA9534 Digital I/O Driver](#tca9534-digital-io-driver)
  - [What It Does](#what-it-does-1)
  - [Configuration](#tca9534-configuration)
  - [Pin Configuration String](#pin-configuration-string)
  - [Hardware Mode](#hardware-mode)
  - [Controlling Outputs](#controlling-outputs)
  - [Reading Inputs](#reading-inputs)
  - [Output Format](#tca9534-output-format)
- [I²C Address Reference](#ic-address-reference)
- [Installation](#installation)

---

## ADS1115 Analog Driver

### What It Does

Reads differential analog measurements from an ADS1115 ADC over I²C and exposes them to Tasmota's web UI, telemetry JSON, and console. Supports voltage (V) and current (mA) measurements across four configurable differential channels (D0–D3).

Each channel maps to a differential pair on the ADS1115:

| Driver Channel | ADS1115 Pins |
|:--------------:|:------------:|
| D0             | A0 (CH0–CH1) |
| D1             | A1 (CH2–CH3) |
| D2             | A0 (next device) |
| D3             | A1 (next device) |

---

### ADS1115 Configuration

At the top of `ads1115.be`, three variables control all user-facing behaviour:

```berry
var SHUNT_RESISTOR = 0.249
var HARDWARE_GAIN  = 0.23761904761904762
var CHANNEL_RANGES = [0x02, 0x22, 0x82, 0x03]
```

| Variable | What It Controls | When to Change |
|---|---|---|
| `SHUNT_RESISTOR` | Resistance (Ω) of the current-sense shunt on your board | Change to `0.120` or `0.249` if your board has a 120Ω or 249Ω shunt resistor |
| `HARDWARE_GAIN` | Voltage divider ratio on the analog input circuit | Match to your board's resistor configuration (see below) |
| `CHANNEL_RANGES` | Measurement type and range per channel | Set one range code per channel you are using |

---

### Hardware Gain

The `HARDWARE_GAIN` value depends on how the resistor divider is assembled on your IoTextra board:

| Board Configuration | `HARDWARE_GAIN` Value |
|---|---|
| Two 49.9 kΩ resistors in parallel *(default)* | `0.23761904761904762` |
| One 49.9 kΩ resistor (jumpers cut) | `0.47523809523809524` |
| Old IoTextra modules | `0.2` |

If you are using a custom board, calculate your gain as the voltage divider ratio of your input resistor network.

---

### Channel Range Codes

`CHANNEL_RANGES` is an array of four values — one per differential channel. Set each entry to the range code that matches your signal type and expected range.

#### Voltage Ranges

| Code | Range | Notes |
|:----:|-------|-------|
| `0x01` | 0 – 0.5 V | Unipolar, low range |
| `0x02` | 0 – 5 V | Unipolar *(common for 0–5 V sensors)* |
| `0x03` | 0 – 10 V | Unipolar *(common for 0–10 V sensors)* |
| `0x81` | ±0.5 V | Bipolar, low range |
| `0x82` | ±5 V | Bipolar |
| `0x83` | ±10 V | Bipolar |

#### Current Ranges

| Code | Range | Notes |
|:----:|-------|-------|
| `0x21` | 0 – 20 mA | Standard unipolar current loop |
| `0x22` | 4 – 20 mA | Industrial current loop *(most common)* |
| `0x23` | 0 – 40 mA | Extended unipolar |
| `0xA1` | ±20 mA | Bipolar current |

**Example — setting four channels:**

```berry
var CHANNEL_RANGES = [
  0x02,  # D0: 0–5 V voltage
  0x22,  # D1: 4–20 mA current loop
  0x82,  # D2: ±5 V bipolar voltage
  0x03   # D3: 0–10 V voltage
]
```

> Channels are clamped to their configured min/max. A zero raw reading returns `0.0` regardless of the configured minimum.

---

### ADS1115 Output Format

**Web UI:**
```
ADS1115 D0 V    3.214 V
ADS1115 D1 mA  12.450 mA
```

**Telemetry JSON (`tele/tasmota/SENSOR`):**
```json
"ADS1115": {
  "D0_V":  3.214,
  "D1_mA": 12.450,
  "D2_V": -1.832,
  "D3_V":  9.100
}
```

---

## TCA9534 Digital I/O Driver

### What It Does

Drives a TCA9534 or TCA9534A 8-bit I/O expander over I²C, or uses Tasmota's native GPIO system as an alternative backend. Each of the 8 pins (P0–P7) can be independently configured as input or output. The driver handles active-low hardware logic transparently — you work with logical `ON`/`OFF` and `HIGH`/`LOW` states.

---

### TCA9534 Configuration

At the top of `tca9534.be`, three variables control all user-facing behaviour:

```berry
var IOEXPANDER_ADDRESS   = 0x27
var IOEXPANDER_PINCONFIG = "xxxxxx00"
var HARDWARE_MODE        = "i2c"
```

| Variable | What It Controls | Valid Values |
|---|---|---|
| `IOEXPANDER_ADDRESS` | I²C address of the TCA9534/TCA9534A chip | `0x20`–`0x27` (TCA9534) or `0x38`–`0x3F` (TCA9534A) |
| `IOEXPANDER_PINCONFIG` | Which pins are inputs and which are outputs | 8-character string (see below) |
| `HARDWARE_MODE` | Whether to use I²C or Tasmota's GPIO system | `"i2c"` or `"gpio"` |

---

### Pin Configuration String

`IOEXPANDER_PINCONFIG` is an 8-character string running **MSB to LSB** (P7 → P0, left to right):

| Character | Meaning |
|:---------:|---------|
| `1` | Pin is an **input** |
| `0` | Pin is an **output** |
| `x` | Pin treated as **output** (same as `0`, used for clarity on unused pins) |

**Examples for common IoTextra boards:**

| Board | `IOEXPANDER_PINCONFIG` | Notes |
|---|:---:|---|
| IoTextra Relay2 | `"11110000"` | P4–P7 inputs, P0–P3 outputs (check schematic — P4–P7 may be unused) |
| IoTextra Input | `"11111111"` | All 8 pins as inputs |
| IoTextra Octal | `"00001111"` | P0–P3 outputs, P4–P7 inputs |
| IoTextra Combo | `"xxxxxx00"` | P0–P1 outputs, P2–P7 unused/output |

**Bit order visualised:**

```
String index:  [0] [1] [2] [3] [4] [5] [6] [7]
Pin:            P7  P6  P5  P4  P3  P2  P1  P0
```

---

### Hardware Mode

#### `"i2c"` mode *(default)*

The driver communicates directly with the TCA9534 chip over I²C. Use this when your I/O expander is wired to the I²C bus.

- Set `IOEXPANDER_ADDRESS` to match your chip's A0/A1/A2 wiring (see [I²C Address Reference](#ic-address-reference)).
- Tasmota must have I²C enabled and the bus pins configured in the template.

#### `"gpio"` mode

The driver routes through Tasmota's native GPIO and switch subsystem instead of the I²C chip. Use this when your channels are wired directly to ESP32/ESP8266 GPIO pins defined in your Tasmota template.

- `IOEXPANDER_ADDRESS` is ignored in this mode.
- Output channels map to Tasmota `Relay` assignments in order.
- Input channels map to Tasmota `Switch` assignments in order.
- No physical TCA9534 chip is required.

---

### Controlling Outputs

Call `set_output(channel, state)` on the global `tca9534` object from Berry scripts, rules, or the Tasmota console:

```berry
# Turn channel 1 ON
tca9534.set_output(1, true)

# Turn channel 3 OFF
tca9534.set_output(3, false)
```

| Parameter | Type | Description |
|---|---|---|
| `channel` | Integer `1–8` | Physical pin number (P0 = channel 1, P7 = channel 8) |
| `state` | Boolean | `true` = ON, `false` = OFF |

> Attempting to call `set_output()` on a pin configured as an input will be rejected and a warning printed to the console. Output state is stored in firmware so it can be read back at any time.

**Linking an input to an output (example inside `every_100ms`):**

```berry
def every_100ms()
  var input_states = self.read_all_inputs()
  if input_states != nil
    # If input P1 (channel 2) is active, turn on output P0 (channel 1)
    if input_states[1] == 1
      self.set_output(1, true)
    else
      self.set_output(1, false)
    end
  end
end
```

Uncomment and adapt the example block already present in `every_100ms()` in the script.

---

### Reading Inputs

Call `read_all_inputs()` to get a snapshot of all pin states:

```berry
var states = tca9534.read_all_inputs()
# states[0] = P0 state, states[7] = P7 state
# Returns 1 (HIGH/active), 0 (LOW/inactive), or nil (pin is an output)
```

Active-low hardware inversion is handled automatically — a physically pulled-low input returns `1` (active/HIGH).

---

### TCA9534 Output Format

**Web UI:**
```
P0 (CH1) OUT    ON
P1 (CH2) OUT    OFF
P2 (CH3) IN     HIGH
P3 (CH4) IN     LOW
```

**Telemetry JSON (`tele/tasmota/SENSOR`):**
```json
"TCA9534": {
  "P0_OUT": 1,
  "P1_OUT": 0,
  "P2_IN":  1,
  "P3_IN":  0
}
```

---

## I²C Address Reference

### TCA9534 (0x20 – 0x27)

| A2 | A1 | A0 | Address |
|:--:|:--:|:--:|:-------:|
| L  | L  | L  | `0x20`  |
| L  | L  | H  | `0x21`  |
| L  | H  | L  | `0x22`  |
| L  | H  | H  | `0x23`  |
| H  | L  | L  | `0x24`  |
| H  | L  | H  | `0x25`  |
| H  | H  | L  | `0x26`  |
| H  | H  | H  | `0x27`  |

### TCA9534A (0x38 – 0x3F)

| A2 | A1 | A0 | Address |
|:--:|:--:|:--:|:-------:|
| L  | L  | L  | `0x38`  |
| L  | L  | H  | `0x39`  |
| L  | H  | L  | `0x3A`  |
| L  | H  | H  | `0x3B`  |
| H  | L  | L  | `0x3C`  |
| H  | L  | H  | `0x3D`  |
| H  | H  | L  | `0x3E`  |
| H  | H  | H  | `0x3F`  |

TCA9534 and TCA9534A are pin-compatible and can coexist on the same I²C bus because their address ranges do not overlap.

### ADS1115 (0x48 – 0x4B)

| ADDR Pin | Address |
|:--------:|:-------:|
| GND      | `0x48`  |
| VDD      | `0x49`  |
| SDA      | `0x4A`  |
| SCL      | `0x4B`  |

---

## Installation

1. Copy `ads1115.be` and/or `tca9534.be` to your Tasmota file system via **Consoles → Manage File System**.
2. Edit the configuration variables at the top of each file to match your hardware.
3. Add an `autoexec.be` (or append to an existing one) to load the drivers on boot:

```berry
load('ads1115.be')
load('tca9534.be')
```

4. Restart Tasmota. The drivers register themselves automatically and begin publishing sensor data.

> **Tasmota requirement:** I²C must be enabled in firmware and bus pins (SDA/SCL) must be assigned in your GPIO template before the I²C drivers will detect their chips.
