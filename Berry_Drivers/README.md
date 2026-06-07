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

### ISO1211.be (Not Available for use - Under Development)
- Sampled-mode digital input driver for `ISO1211` channels
- Pulses FGND (TLP188) per measurement with `t_settle = 25 ms`, non-blocking
- De-asserts all FGND GPIOs at startup as a safety requirement
- Reads OUT via direct MCU `GPIO` or `TCA9534` I²C expander
- Intended for IoTextra Quadro sampled-mode channels (90V DC, 110V AC, 220V AC)
- Direct-mode channels (12–60V DC) keep using the standard DI driver

---
