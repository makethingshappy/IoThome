# I²C Address & GPIO Reference

## ADS1115 — I²C Address Table

The ADS1115 ADDR pin selects one of four addresses:

| ADDR Pin Connection | I²C Address (7-bit) | Hex  |
|---------------------|---------------------|------|
| GND                 | 1001000             | 0x48 |
| VDD                 | 1001001             | 0x49 |
| SDA                 | 1001010             | 0x4A |
| SCL                 | 1001011             | 0x4B |

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

Make sure to disable the following I2C driver in tasmota when using TCA9534 using the following command in Tasmota console:

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

## GPIO Map — Digital Channel Parameters

Each digital channel is defined by the following parameters:

| Parameter        | Description                                                                 |
|------------------|-----------------------------------------------------------------------------|
| IOEXPANDER_PINCONFIG | 8-bit binary `[P7][P6][P5][P4][P3][P2][P1][P0]` `1=input`, `0=output`, `MSB to LSB (P7 to P0)`|
| HARDWARE_MODE        | `gpio` (direct pin on HOST connector) or `I2C` (via TCA9534/TCA9534A)   |
| IOEXPANDER_ADDRESS   | TCA9534 bus address — applicable only when Interface Type = `I2C`       |
| Channel Number       | Pin index `0–7`. Maps to `AP0–AP7` (HOST) or `P0–P7` (TCA9534)          |

### HOST Connector Pin Map

| Channel No. | HOST Pin |
|:-----------:|:--------:|
| 0           | AP0      |
| 1           | AP1      |
| 2           | AP2      |
| 3           | AP3      |
| 4           | AP4      |
| 5           | AP5      |
| 6           | AP6      |
| 7           | AP7      |

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

## Possible Actions Bitmask

The **Possible Actions** field is a single byte. Each bit defines each channel starting from LSB CH0 to MSB CH7:

| Bit | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0        |
|-----|---|---|---|---|---|---|---|----------|


> **Note:** Reading is always available for all channel types, including OUTPUT channels (e.g. relays).

---

## Channel Access Method

Almost all IoTextra series digital modules support **both** HOST and I²C access to the same physical channel. The active access method is determined per-channel by Tasmota configuration and changes made through variables within TCA9534.be berry driver script.

```
HARDWARE_MODE
  ├── 'gpio'  →  Access via AP0–AP7 on HOST connector
  └── 'i2c'   →  Access via P0–P7 on TCA9534/TCA9534A at configured I²C address
```
