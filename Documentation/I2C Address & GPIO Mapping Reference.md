# I²C Address & GPIO Reference

> **Author:** Arshia Keshvari ([@TeslaNeuro](https://github.com/TeslaNeuro)) · MakeThingsHappy.io  
> **License:** MIT

## ADS1115 — I²C Address Table

The ADS1115 ADDR pin selects one of four addresses:

| ADDR Pin Connection | I²C Address (7-bit) | Hex  |
|---------------------|---------------------|------|
| GND                 | 1001000             | 0x48 |
| VDD                 | 1001001             | 0x49 |
| SDA                 | 1001010             | 0x4A |
| SCL                 | 1001011             | 0x4B |

> NOTE: The `ADS1115Data.be` driver dynamically identifies ADS1115 ADC's from list of known addresses above, so you don't need to manually set the I2C addresses

Make sure the following I2C driver is enabled in tasmota when using `ADS1115` by inputting the following command in Tasmota CMD console:

```
I2cDriver13 1
```

---

## ADS7828 — I²C Address Table (IoTextra Analog 3)

The ADS7828 uses A1/A0 address pins to select one of four addresses:

| A1 | A0 | I²C Address (7-bit) | Hex  |
|:--:|:--:|---------------------|------|
| L  | L  | 1001000             | 0x48 |
| L  | H  | 1001001             | 0x49 |
| H  | L  | 1001010             | 0x4A |
| H  | H  | 1001011             | 0x4B |

> **Note:** In this repo, the `ADS7828.be` Berry driver defaults to `ADS7828_ADDRESS = 0x4B`. If your IoTextra Analog 3 is strapped differently, change the address in the driver (or adjust A0/A1 jumpers on the board).

Make sure to disable the following I2C driver in tasmota when using `ADS7828` by inputting the following command in Tasmota CMD console:

```
I2cDriver13 0
```

---

## TCA9534 — I²C Address Table

The TCA9534 A2/A1/A0 pins select one of eight addresses:

| A2 | A1 | A0 | I²C Address (7-bit) | Hex  |
|----|----|----|---------------------|------|
| 0  | 0  | 0  | 0100000             | 0x20 |
| 0  | 0  | 1  | 0100001             | 0x21 |
| 0  | 1  | 0  | 0100010             | 0x22 |
| 0  | 1  | 1  | 0100011             | 0x23 |
| 1  | 0  | 0  | 0100100             | 0x24 |
| 1  | 0  | 1  | 0100101             | 0x25 |
| 1  | 1  | 0  | 0100110             | 0x26 |
| 1  | 1  | 1  | 0100111             | 0x27 |

Make sure to disable the following I2C driver in tasmota when using `TCA9534` by inputting the following command in Tasmota CMD console:

```
I2cDriver36 0
```

---

## TCA9534A — I²C Address Table

The TCA9534**A** uses a different base address (0x38–0x3F):

| A2 | A1 | A0 | I²C Address (7-bit) | Hex  |
|----|----|----|---------------------|------|
| 0  | 0  | 0  | 0111000             | 0x38 |
| 0  | 0  | 1  | 0111001             | 0x39 |
| 0  | 1  | 0  | 0111010             | 0x3A |
| 0  | 1  | 1  | 0111011             | 0x3B |
| 1  | 0  | 0  | 0111100             | 0x3C |
| 1  | 0  | 1  | 0111101             | 0x3D |
| 1  | 1  | 0  | 0111110             | 0x3E |
| 1  | 1  | 1  | 0111111             | 0x3F |

> **Note:** TCA9534 and TCA9534A are pin-compatible but occupy different address ranges, allowing both to coexist on the same I²C bus.

---

## GPIO Map — Digital I/O Module Parameters

Each digital I/O module is defined by the following parameters:

| Parameter        | Description                                                                 |
|------------------|-----------------------------------------------------------------------------|
| IOEXPANDER_PINCONFIG | 8-bit binary `[P7][P6][P5][P4][P3][P2][P1][P0]` `1=input`, `0=output`, `MSB to LSB (P7 to P0)`|
| HARDWARE_MODE        | `gpio` (direct pin on HOST connector) or `I2C` (via TCA9534/TCA9534A)   |
| IOEXPANDER_ADDRESS   | TCA9534/TCA9534A bus address — applicable only when Interface Type = `I2C`       |
| Channel Number       | Tasmota Channel `1-8`, Pin index `0–7`. Maps to `AP0–AP7` (HOST) or `P0–P7` (TCA9534/TCA9534A)          |

### HOST Connector Pin Map

| Channel No. | HOST Pin |
|:-----------:|:--------:|
| 1           | AP0      |
| 2           | AP1      |
| 3           | AP2      |
| 4           | AP3      |
| 5           | AP4      |
| 6           | AP5      |
| 7           | AP6      |
| 8           | AP7      |

> NOTE: Depending on the IoTextra module you are using the `HOST` pins may be left unconnected or connected as different Input/Output Channels, always refer to the schematic

### TCA9534/TCA9534A Contact Map

| Channel No. | TCA9534 Pin |
|:-----------:|:-----------:|
| 1           | P0          |
| 2           | P1          |
| 3           | P2          |
| 4           | P3          |
| 5           | P4          |
| 6           | P5          |
| 7           | P6          |
| 8           | P7          |

---

## IOEXPANDER_PINCONFIG

Each bit defines each channel starting from LSB CH0 to MSB CH7:

| Bit | 7 (MSB) | 6 | 5 | 4 | 3 | 2 | 1 | 0 (LSB)       |
|-----|---|---|---|---|---|---|---|----------|

Example:

- IoTExtra Relay2 -> `11110000`
- IoTExtra Input ->  `11111111`
- IoTExtra Octal ->  `00001111`
- IoTExtra Combo ->  `xxxxxx00`

> **Note:** Reading is always available for all channel types, including OUTPUT channels (e.g. relays). Always check the schematic for exact pinout for each IoTextra Digital I/O series module.

---

## HARDWARE_MODE

Almost all IoTextra series digital modules support **both** GPIO and I²C access to all channels. The active access method is determined by both the Tasmota configuration / template and changes made through variables within `TCA9534.be` berry driver scripts.

```
HARDWARE_MODE
  ├── 'gpio'  →  Access via AP0–AP7 on HOST connector
  └── 'i2c'   →  Access via P0–P7 on TCA9534/TCA9534A at configured I²C address
```

---

## ISO1211 (Sampled-Mode) — FGND & OUT Mapping

The `ISO1211.be` driver handles **sampled-mode** IoTextra Quadro channels (JM jumper **open**: 90 V DC, 110 V AC, 220 V AC). Direct-mode channels (12–60 V DC, JM closed) are ordinary DI inputs handled by `TCA9534.be`.

> **The ISO1211 is an isolated digital-input receiver, not an I²C device — it has no I²C address of its own.** Each sampled channel uses two separate signals: a **FGND** control output (always GPIO) and an **OUT** read input (I²C *or* GPIO). The I²C address only ever refers to the **TCA9534/TCA9534A expander** used to read OUT.

Each channel in `ISO1211_CHANNELS` maps as follows:

| Driver parameter | Signal | Maps to | Notes |
|---|---|---|---|
| `fgnd_relay` = N | **FGND** (TLP188 control) | Tasmota **Relay N** → a HOST connector pin (`AP0–AP7`) assigned as a `Relay` in your template | **Always GPIO.** Never uses the I²C expander. This is the parameter unique to sampled mode. |
| `out_channel` = N, `OUT_SOURCE = "i2c"` | **OUT** (the DI value) | `P(N-1)` on the TCA9534/TCA9534A at `IOEXPANDER_ADDRESS` (CH1 → P0 … CH8 → P7) | Uses the address tables above (`0x20–0x27` / `0x38–0x3F`). |
| `out_channel` = N, `OUT_SOURCE = "gpio"` | **OUT** (the DI value) | The **Nth defined Tasmota switch** (packed order) | If your template has gaps (e.g. `SWITCH1` + `SWITCH3`), number by position in the defined list, not absolute switch number. |

### Example (IoTextra Quadro, two sampled channels)

```berry
var ISO1211_CHANNELS = [
  {"name": "ISO1211_CH1", "fgnd_relay": 3, "out_channel": 1, "invert": false},
  {"name": "ISO1211_CH2", "fgnd_relay": 4, "out_channel": 2, "invert": false}
]
```

| Logical channel | FGND (`fgnd_relay`) | OUT (`out_channel`, `i2c`) | OUT (`out_channel`, `gpio`) |
|---|---|---|---|
| `ISO1211_CH1` | Relay 3 → HOST pin (template) | TCA9534 `P0` | 1st defined switch |
| `ISO1211_CH2` | Relay 4 → HOST pin (template) | TCA9534 `P1` | 2nd defined switch |

> **I²C driver note:** when `OUT_SOURCE = "i2c"`, the same expander rules apply as for `TCA9534.be` — disable the conflicting built-in driver with `I2cDriver36 0` so the address (e.g. `0x27`) is free for the Berry driver.

> 📖 See [`/Documentation/Berry Drivers.md`](./Berry%20Drivers.md) and [`/Documentation/Setup.md`](./Setup.md) for full configuration, polarity, and safety details.
