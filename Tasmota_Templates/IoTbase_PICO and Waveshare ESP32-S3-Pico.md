# Tasmota Templates — IoTbase PICO + Waveshare ESP32-S3-Pico
Tasmota templates for IoTextra mezzanine modules used with the **IoTbase PICO** platform and **Waveshare ESP32-S3-Pico** module.

## Available Templates

| IoTextra Module | Status         |
|-----------------|----------------|
| Input           | ✅ Available   |
| Relay2          | ✅ Available   |
| SSR Small       | ✅ Available   |
| MOSFET2         | ✅ Available   |
| Octal           | ✅ Available   |
| Octal2          | ✅ Available   |
| Analog          | 🔶 Coming Soon |
| Analog2         | 🔲 Planned     |
| Analog3         | 🔶 Coming Soon |
| Combo           | 🔶 Coming Soon |
| Combo2          | 🔲 Planned     |

## Firmware

- Flash firmware: `tasmota32s3-4MB-factory.bin`

## Templates

### IoTextra Input
```json
{"NAME":"IoTextra Input","GPIO":[0,166,167,0,608,640,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,160,161,162,163,164,165,0,0,0,0,0,0,0],"FLAG":0,"BASE":1}
```

### IoTextra Relay2
```json
{"NAME":"IoTextra Relay2","GPIO":[0,0,0,0,608,640,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,256,257,0,0,0,0,0,0,0,0,0,0,0],"FLAG":0,"BASE":1}
```

### IoTextra SSR Small
```json
{"NAME":"IoTextra SSR Small","GPIO":[0,0,0,0,608,640,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,256,257,258,259,260,261,0,0,0,0,0,0,0],"FLAG":0,"BASE":1}
```

### IoTextra MOSFET2
```json
{"NAME":"IoTextra MOSFET2","GPIO":[0,0,0,0,608,640,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,256,257,258,259,260,261,0,0,0,0,0,0,0],"FLAG":0,"BASE":1}
```

### IoTextra Octal
```json
{"NAME":"IoTextra Octal","GPIO":[0,162,163,0,608,640,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,256,257,258,259,160,161,0,0,0,0,0,0,0],"FLAG":0,"BASE":1}
```

### IoTextra Octal2
```json
{"NAME":"IoTextra Octal2","GPIO":[0,162,163,0,608,640,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,256,257,258,259,160,161,0,0,0,0,0,0,0],"FLAG":0,"BASE":1}
```
