# 🍇 Berry Drivers

All drivers are under active development and may change frequently.

---

## Included Drivers

### ADS1115Data.be
- 16-bit ADC driver for `ADS1115`
- Allows customisable voltage and current measurements
- Uses Tasmota's built in APIs / Drivers
- Intended for IoTextra Analog

---

### ADS7828.be
- 8-channel ADC driver for `ADS7828`
- Intended for IoTextra Analog 3

---

### TCA9534.be
- I/O expander driver for `TCA9534 / TCA9534A`
- Customisable Input or Output Channels
- User selectable communication method: `I2C` or `GPIO`
- Intended for IoTextra Digital I/O modules

---

### Octal3.be (<!> Under Development <!>)
- Hybrid driver for IoTextra Octal3
- 4 latching relay outputs via `TCA9534` I2C H-bridge pin-pairs (CONFIG always all-output)
- 4 host MCU GPIO inputs via Tasmota template Switches (not on the TCA)
- Optional nSLEEP via a template Relay; software state mirror (no I2C readback)
- Configurable logical channel map (default CH1–4 out / CH5–8 in)

---

### ISO1211.be
- Sampled-mode digital input driver for `ISO1211` channels
- Pulses FGND (TLP188) per measurement with `t_settle = 25 ms`, non-blocking
- FGND switching is **GPIO only** (Tasmota relay via `set_power`)
- De-asserts all FGND relays at startup as a safety requirement
- OUT reading selectable via `OUT_SOURCE`: `i2c` (TCA9534) or `gpio` (Tasmota switch)
- Intended for IoTextra Quadro sampled-mode channels (90V DC, 110V AC, 220V AC)
- Direct-mode channels (12–60V DC) keep using the standard DI driver

---
