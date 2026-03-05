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
| Direction        | `INPUT` or `OUTPUT`                                                         |
| Interface Type   | `HOST` (direct pin on HOST connector) or `I2C` (via TCA9534)              |
| I²C Address      | TCA9534 bus address — applicable only when Interface Type = `I2C`          |
| Channel Number   | Pin index `0–7`. Maps to `AP0–AP7` (HOST) or `P0–P7` (TCA9534)           |
| Possible Actions | Bitmask byte defining allowed operations (see table below)                 |

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

The **Possible Actions** field is a single byte. Each bit defines whether a specific operation is permitted on the channel:

| Bit | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0        |
|-----|---|---|---|---|---|---|---|----------|
| Action | — | — | — | — | — | — | — | Write    |

| Bit 0 Value | Meaning        |
|:-----------:|----------------|
| `1`         | Write enabled  |
| `0`         | No write       |

> **Note:** Reading is always available for all channel types, including OUTPUT channels (e.g. relays). The firmware stores the last known state of each channel, enabling readback of output states. Bits 1–7 are reserved for future use.

---

## Multi-Channel Node Rules

- A node supports **up to 8 channels**.
- Channels within a single node may be a **mix** of INPUT and OUTPUT directions.
- Channels within a single node may be a **mix** of HOST and I²C interface types.
- Operations on one channel **must not affect** the state of any other channel.
- The firmware must **maintain and use state** for all HOST and TCA9534 channels to ensure safe read-modify-write operations on shared I²C registers.

---

## Channel Access Method

Almost all IoTextra series digital modules support **both** HOST and I²C access to the same physical channel. The active access method is determined per-channel by the **Interface Type** parameter.

```
Channel
  ├── Interface Type: HOST  →  Access via AP0–AP7 on HOST connector
  └── Interface Type: I2C   →  Access via P0–P7 on TCA9534 at configured I²C address
```
