# IoThome Berry Drivers for Tasmota

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
- [ADS7828 Analog Driver (IoTextra Analog 3)](#ads7828-analog-driver-iotextra-analog-3)
  - [What It Does](#what-it-does-1)
  - [Configuration](#ads7828-configuration)
  - [Channel Range Codes](#channel-range-codes-1)
  - [Output Format](#ads7828-output-format)
- [TCA9534 Digital I/O Driver](#tca9534-digital-io-driver)
  - [What It Does](#what-it-does-2)
  - [Configuration](#tca9534-configuration)
  - [Pin Configuration String](#pin-configuration-string)
  - [Hardware Mode](#hardware-mode)
  - [Controlling Outputs](#controlling-outputs)
  - [Reading Inputs](#reading-inputs)
  - [Output Format](#tca9534-output-format)
- [ISO1211 Sampled-Mode Digital Input Driver](#iso1211-sampled-mode-digital-input-driver)
  - [What It Does](#what-it-does-3)
  - [Direct vs Sampled Mode](#direct-vs-sampled-mode)
  - [Configuration](#iso1211-configuration)
  - [Per-Channel Parameters](#per-channel-parameters)
  - [Scan Sequence & Timing](#scan-sequence--timing)
  - [Startup Safety](#startup-safety)
  - [Output Format](#iso1211-output-format)
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

## ADS7828 Analog Driver (IoTextra Analog 3)

Driver for **IoTextra Analog 3** based on the `ADS7828` 8-channel I²C ADC.

### What It Does

Reads **8 single-ended** analog channels (CH0–CH7) from an **ADS7828 12-bit ADC** over I²C and exposes them to Tasmota’s web UI and telemetry JSON.

- Uses the ADS7828 **internal 2.5 V reference** by default (`ADS7828_VREF = 2.5`)
- Publishes per-channel values as either **volts (V)** or **milliamps (mA)** depending on `CHANNEL_RANGES`

> **I²C address:** `0x48`–`0x4B` depending on A0/A1 strapping. The driver defaults to `0x4B` (see `ADS7828_ADDRESS`).

---

### ADS7828 Configuration

At the top of `ADS7828.be`, these variables control all user-facing behaviour:

```berry
var ADS7828_ADDRESS = 0x4B
var ADS7828_VREF    = 2.5

var SHUNT_RESISTOR = 0.249
var HARDWARE_GAIN  = 0.47523809523809524

var CHANNEL_RANGES = [0x02, 0x22, 0x82, 0x03, 0x02, 0x02, 0x02, 0x02]
```

| Variable | What It Controls | Notes |
|---|---|---|
| `ADS7828_ADDRESS` | I²C address of the ADS7828 | Valid: `0x48`, `0x49`, `0x4A`, `0x4B` |
| `ADS7828_VREF` | Reference voltage used for conversion | Driver assumes internal reference (default `2.5`) |
| `SHUNT_RESISTOR` | Shunt resistor (Ω) for current measurements | Used when a channel is configured as `current` |
| `HARDWARE_GAIN` | Analog front-end gain/attenuation factor | Board-specific scaling applied to all channels |
| `CHANNEL_RANGES` | Range code per channel (8 entries for CH0–CH7) | Controls whether each channel is V or mA, and clamp range |

---

### Channel Range Codes

`CHANNEL_RANGES` uses the same range code scheme as the ADS1115 driver, but applied per **single-ended** channel (CH0–CH7):

#### Voltage Ranges

| Code | Range | Notes |
|:----:|-------|-------|
| `0x01` | 0 – 0.5 V | Unipolar, low range |
| `0x02` | 0 – 5 V | Unipolar *(common for 0–5 V sensors)* |
| `0x03` | 0 – 10 V | Unipolar *(common for 0–10 V sensors)* |
| `0x81` | ±0.5 V | Bipolar |
| `0x82` | ±5 V | Bipolar |
| `0x83` | ±10 V | Bipolar |

#### Current Ranges

| Code | Range | Notes |
|:----:|-------|-------|
| `0x21` | 0 – 20 mA | Unipolar current |
| `0x22` | 4 – 20 mA | *(most common)* |
| `0x23` | 0 – 40 mA | Extended range |
| `0xA1` | ±20 mA | Bipolar current |

---

### ADS7828 Output Format

**Web UI:**
```
ADS7828 CH0 V    3.214 V
ADS7828 CH1 mA  12.450 mA
```

**Telemetry JSON (`tele/tasmota/SENSOR`):**
```json
"ADS7828": {
  "CH0_V":  3.214,
  "CH1_mA": 12.450,
  "CH2_V": -1.832,
  "CH3_V":  9.100
}
```

> The driver only emits keys for channels whose range codes are valid (i.e. present in its `RANGE_CONFIGS` table).

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
- Output channels map to Tasmota `Relay_i` assignments in order.
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

## ISO1211 Sampled-Mode Digital Input Driver

> Driver file: `Berry_Drivers/ISO1211.be` · Target: **IoTextra Quadro** ISO1211 channels.

### What It Does

Implements the **sampled-mode** scan sequence for ISO1211 digital input channels. On the IoTextra Quadro, each ISO1211 channel can be wired for high input voltages (90V DC, 110V AC, 220V AC) with the `JM` jumper **open**. In this mode the chip's field-side ground (`FGND`) is not hardwired — it is switched by a HOST connector pin through a `TLP188` optocoupler.

To take a reading the driver:

1. Asserts the channel's FGND output (TLP188 ON), connecting FGND.
2. Waits `t_settle = 25 ms` for the input circuit to settle (non-blocking).
3. Reads the ISO1211 `OUT` pin to obtain the digital input (DI) value.
4. De-asserts the FGND output (TLP188 OFF) so the channel idles and dissipates no power.

Channels are scanned **one at a time** (round-robin), so only a single FGND is ever asserted, which keeps average power dissipation low and is friendly to AC-mains inputs.

Each sampled-mode ISO1211 channel uses two things:

- **FGND switching — GPIO only.** The TLP188/FGND is *always* driven by a Tasmota relay (`set_power`), i.e. a HOST connector pin assigned as a `Relay` in your template. FGND is **never** routed through the I²C expander. This is the parameter unique to sampled mode.
- **OUT reading.** *How* the OUT pin is read is set globally by `OUT_SOURCE`, mirroring `TCA9534.be`: `"i2c"` reads a TCA9534/TCA9534A input register, `"gpio"` reads a Tasmota template switch (`get_switch`).

---

### Direct vs Sampled Mode

| Mode | Voltage range | `JM` jumper | FGND | Driver |
|---|---|:---:|---|---|
| **Direct** | 12–60V DC | Closed | Hardwired to ground | Existing DI driver (e.g. `TCA9534.be`) — *no change* |
| **Sampled** | 90V DC, 110V AC, 220V AC | Open | Switched by a GPIO relay (TLP188) | **`ISO1211.be`** (this driver) |

The mode is determined purely by the physical `JM` jumper. You do **not** configure it in software — selecting an ISO1211 sampled-mode channel here implies the jumper is open. Direct-mode channels must **not** be added to this driver.

---

### ISO1211 Configuration

The top of `ISO1211.be` sets how OUT is read (FGND is always GPIO), the expander address, the settle time, and a channel list:

```berry
var OUT_SOURCE         = "i2c"    # how OUT is read: "i2c" (TCA9534) or "gpio" (Tasmota switch)
var IOEXPANDER_ADDRESS = 0x27     # TCA9534 0x20-0x27 / TCA9534A 0x38-0x3F (only when OUT_SOURCE = i2c)
var OUT_INVERT         = false    # optional EXTRA flip of the final DI; default false = standard IoTextra/TCA9534 convention
var ISO1211_T_SETTLE   = 25       # settle time per measurement (ms)
```

| Variable | What It Controls | Notes |
|---|---|---|
| `OUT_SOURCE` | **How the OUT pin is read** (FGND is unaffected — always GPIO) | `"i2c"` = TCA9534 input register; `"gpio"` = Tasmota template switch (`get_switch`). Mirrors `TCA9534.be`. |
| `IOEXPANDER_ADDRESS` | I²C address of the TCA9534/TCA9534A | Only used when `OUT_SOURCE == "i2c"`. `0x20`–`0x27` or `0x38`–`0x3F`. |
| `OUT_INVERT` | **Optional extra DI inversion** | The driver already applies the standard IoTextra convention per source (i2c: active-low like `TCA9534.be`; gpio: `get_switch()` logical state, `true` = `PRESSED` → `DI 1`). `OUT_INVERT` is an *extra* flip on top, only for boards wired opposite. `false` (default) = standard convention; `true` = flip. Override per channel with an `invert` key. |
| `ISO1211_T_SETTLE` | Settle time between asserting FGND and reading OUT | `25 ms` is the universal value for all sampled ranges. Decrease only if you understand the thermal trade-offs. |

Channels are defined in the `ISO1211_CHANNELS` list — each entry pairs a GPIO **FGND relay** with an **OUT channel** (and may optionally override polarity):

```berry
var ISO1211_CHANNELS = [
  {"name": "ISO1211_CH1", "fgnd_relay": 3, "out_channel": 1, "invert": false},
  {"name": "ISO1211_CH2", "fgnd_relay": 4, "out_channel": 2, "invert": false}  # set "invert": true only if this channel reads reversed
]
```

---

### Per-Channel Parameters

| Parameter | Required | Type | Description |
|---|:---:|---|---|
| `name` | optional | string | Friendly label used in MQTT / web output. |
| `fgnd_relay` | **yes** | int `≥ 1` | Tasmota **relay** number (1-based) that drives the TLP188 / FGND for this channel via `set_power`. **GPIO only** — assign the HOST connector pin as a `Relay` in your template. This is the parameter unique to sampled mode. |
| `out_channel` | **yes** | int `≥ 1` | The channel that reads the ISO1211 `OUT` pin (the DI value). Meaning depends on `OUT_SOURCE` (see below). |
| `invert` | optional | bool | Optional **extra** inversion of the final DI for this channel. Defaults to `OUT_INVERT` (`false`). Leave at the default unless this channel reads reversed. |

How the channel numbers map:

- **FGND (`fgnd_relay`)** → always a Tasmota relay: `fgnd_relay = 1` → `Relay1` / `Power1`, etc. FGND never uses the I²C expander.
- **OUT with `OUT_SOURCE = "i2c"`** → `P0`–`P7` on the expander (`out_channel` 1 = P0 … 8 = P7). The expander is read-only here, so the driver configures all its pins as inputs.
- **OUT with `OUT_SOURCE = "gpio"`** → read via `tasmota.get_switch()` (returns `true` = `PRESSED`, the logical state). Like `TCA9534.be`, this is **not inverted** by the driver, so `true` (PRESSED) → `DI 1` (HIGH). `out_channel` is the **position in the packed switch list** (1 = first *defined* switch). If your template has holes (e.g. `SWITCH1` + `SWITCH3`), the list skips the gap, so number by position, not absolute switch number. To flip polarity here, invert the switch in the Tasmota template (`Switch_n_i` / `SwitchMode`) rather than using `OUT_INVERT`.

> **Validation:** A channel with a missing/invalid `fgnd_relay` (`< 1`) or `out_channel` (`< 1`, or `> 8` in i2c mode) is **rejected** with a descriptive console message and skipped. In `"i2c"` mode, if the expander is not found at `IOEXPANDER_ADDRESS` a single warning is printed and OUT reads return errors per channel.

---

### Scan Sequence & Timing

The whole sequence is **non-blocking** — the `t_settle` wait uses `tasmota.set_timer()`, never a blocking delay. The driver's `every_second()` hook starts a round; each channel chains to the next only after its own FGND pulse completes:

```
assert FGND relay ──▶ wait t_settle (set_timer) ──▶ read OUT ──▶ de-assert FGND relay ──▶ next channel
```

> **Timing resolution:** `tasmota.set_timer` fires on the next ~50 ms tick, so a `t_settle` below 50 ms rounds **up** — the actual FGND-on time is ~50 ms (you'll see ~46–49 ms pulses in the console). This is harmless: a longer settle only improves reading reliability, and the duty cycle stays tiny (~50 ms on per ~1 s scan). Hitting exactly 25 ms would require blocking, which the spec forbids (*"no blocking sleep in the main execution context"*), so `set_timer` is the correct tool.

You can also trigger a single on-demand measurement from the Berry console:

```berry
iso1211.measure(1)   # pulse + read channel 1 only (1-based)
```

---

### Startup Safety

> **Critical:** At power-on the HOST connector pins are undefined. If an FGND control were left floating, a TLP188 could conduct and power the ISO1211 at full field voltage (up to 220V AC) before any measurement — causing immediate overheating.

To prevent this, the first **hardware** action in `init()` — before the OUT/I²C backend is even brought up — is to de-assert **every** `fgnd_relay` (TLP188 OFF) via `set_power(relay, false)`. (Channel-list validation runs first, but it performs no hardware I/O.) Because FGND is GPIO-only, this happens regardless of `OUT_SOURCE`.

> **Polarity:** `set_power(relay, true)` asserts FGND (TLP188 ON). If your board's TLP188 drive is inverted, flip it in the Tasmota template (`Relay_i_INV`) or in hardware — don't change the driver.

---

### ISO1211 Output Format

**Web UI:**
```
ISO1211_CH1 DI    HIGH
ISO1211_CH2 DI    LOW
```

**MQTT (`stat/<topic>/RESULT`, published each scan round) and telemetry (`tele/<topic>/SENSOR`):**
```json
"ISO1211": {
  "ISO1211_CH1": { "DI": 1, "error": false },
  "ISO1211_CH2": { "DI": 0, "error": false }
}
```

A channel reports `"DI": null` when its value is not yet known or a read failed. `"error"` is a **read-validity** flag, not a field/wiring fault: it is `true` only when the OUT read itself could not complete — e.g. the TCA9534 was not found / an I²C read NACKed (i2c mode), or `out_channel` points past the number of defined switches (gpio mode). `"error": false` means the read succeeded, so a `DI` of `0` with nothing connected is a valid, trusted reading.

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

Make sure to disable the following I2C driver in tasmota when using TCA9534 by inputting the following command in Tasmota CMD console:

```
I2cDriver36 0
```

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

1. Copy `ADS1115Data.be`, `TCA9534.be`, and/or `ISO1211.be` to your Tasmota file system via **Consoles → Manage File System**.
2. Edit the configuration variables at the top of each file to match your hardware.
3. Add an `autoexec.be` (or append to an existing one) to load the drivers on boot:

```berry
load('ADS1115Data.be')
load('TCA9534.be')
load('ISO1211.be')   # only for IoTextra Quadro sampled-mode ISO1211 channels
```

4. Restart Tasmota. The drivers register themselves automatically and begin publishing sensor data.

> **Tasmota requirement:** I²C must be enabled in firmware and bus pins (SDA/SCL or GPIO) must be assigned in your tasmota template before the I²C drivers will detect their chips.
