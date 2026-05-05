#- ===========================================================================
- ⚠️ WORK IN PROGRESS
- This driver is intended for IoTextra Analog V3 and is not yet ready for use.
- ============================================================================ -#

#-
MIT License

Copyright (c) 2026 makethingshappy,
              2026 Arshia Keshvari (@TeslaNeuro)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
-#

#- =========================================================
 - Author: Arshia Keshvari
 - Role: Independent Developer, Engineer, and Project Author
 - GitHub: @TeslaNeuro
 - MakeThingsHappy.io
 - Last Updated: 2026-05-05
 - ========================================================= -#

#- =============================================================
 - ADS7828 12-bit 8-channel I2C ADC I2C Berry Driver for Tasmota
 - Single-ended mode, internal 2.5V reference
 - ============================================================= -#

#- ========================================
 - ADS7828 Configuration
 - Change these values to match your board
 - ======================================== -#

var ADS7828_ADDRESS = 0x4B
var ADS7828_VREF    = 2.5

var SHUNT_RESISTOR = 0.249
var HARDWARE_GAIN  = 0.47523809523809524

#- Per-channel configuration (CH0–CH7) -#
var CHANNEL_RANGES = [
  0x02,  #- CH0: 0-5V -#
  0x22,  #- CH1: 4-20mA -#
  0x82,  #- CH2: ±5V -#
  0x03,  #- CH3: 0-10V -#
  0x02,
  0x02,
  0x02,
  0x02
]

import string
import global

class ADS7828Data : Driver

  var wire
  var i2c_addr
  var vref
  var shunt_resistor
  var hardware_g
  var readings
  var channel_configs

  #- Channel selection bits -#
  static CHANNEL_BITS = [
    0x00, 0x40, 0x10, 0x50,
    0x20, 0x60, 0x30, 0x70
  ]

  #- Command constants -#
  static SD_BIT  = 0x80
  static PD_BITS = 0x0C

  #- Same range system as ADS1115 -#
  static RANGE_CONFIGS = {
    0x01: {'type': 'voltage', 'min': 0.0, 'max': 0.5, 'bipolar': false},
    0x02: {'type': 'voltage', 'min': 0.0, 'max': 5.0, 'bipolar': false},
    0x03: {'type': 'voltage', 'min': 0.0, 'max': 10.0, 'bipolar': false},
    0x81: {'type': 'voltage', 'min': -0.5, 'max': 0.5, 'bipolar': true},
    0x82: {'type': 'voltage', 'min': -5.0, 'max': 5.0, 'bipolar': true},
    0x83: {'type': 'voltage', 'min': -10.0, 'max': 10.0, 'bipolar': true},

    0x21: {'type': 'current', 'min': 0.0, 'max': 20.0, 'bipolar': false},
    0xA1: {'type': 'current', 'min': -20.0, 'max': 20.0, 'bipolar': true},
    0x22: {'type': 'current', 'min': 4.0, 'max': 20.0, 'bipolar': false},
    0x23: {'type': 'current', 'min': 0.0, 'max': 40.0, 'bipolar': false}
  }

  def init(i2c_addr, vref, shunt_resistor, hardware_gain, channel_ranges)
    self.i2c_addr = i2c_addr
    self.vref = vref
    self.shunt_resistor = shunt_resistor
    self.hardware_g = hardware_gain

    self.readings = []
    self.channel_configs = []

    for i:0..7
      self.readings.push(0.0)

      var code = channel_ranges[i]
      if self.RANGE_CONFIGS.contains(code)
        var cfg = self.RANGE_CONFIGS[code]
        self.channel_configs.push(cfg)

        print(string.format("CH%i: %s, range %.1f to %.1f",
          i, cfg['type'], cfg['min'], cfg['max']))
      else
        print(string.format("CH%i: Invalid range code 0x%02X", i, code))
        self.channel_configs.push(nil)
      end
    end

    self.wire = tasmota.wire_scan(self.i2c_addr)

    if self.wire
      print(string.format("ADS7828: found at 0x%02X on bus %i", self.i2c_addr, self.wire.bus))
      tasmota.delay(10)
    else
      print(string.format("ADS7828: NOT found at 0x%02X", self.i2c_addr))
    end
  end

  def build_command(ch)
    return self.SD_BIT | self.CHANNEL_BITS[ch] | self.PD_BITS
  end

  def read_channel(ch)
    if !self.wire return -1 end

    var cmd = self.build_command(ch)

    self.wire._begin_transmission(self.i2c_addr)
    self.wire._write(cmd)
    self.wire._end_transmission()

    tasmota.delay(1)

    self.wire._request_from(self.i2c_addr, 2)
    var hi = self.wire._read()
    var lo = self.wire._read()

    return ((hi & 0x0F) << 8) | lo
  end

  def convert_value(raw, ch)
    var config = self.channel_configs[ch]
    if config == nil return 0.0 end

    #- ADC → voltage → scaled -#
    var v = (raw * self.vref / 4095.0) / self.hardware_g

    if config['type'] == 'voltage'
      if v < config['min']
        v = v == 0.0 ? 0.0 : config['min']
      elif v > config['max']
        v = config['max']
      end
      return v

    elif config['type'] == 'current'
      var ma = v / self.shunt_resistor

      if ma < config['min']
        ma = ma == 0.0 ? 0.0 : config['min']
      elif ma > config['max']
        ma = config['max']
      end

      return ma
    end

    return 0.0
  end

  def read_all()
    if !self.wire return end

    for ch : 0..7
      var raw = self.read_channel(ch)
      if raw >= 0
        self.readings[ch] = self.convert_value(raw, ch)
      end
    end
  end

  def every_100ms()
    self.read_all()
  end

  def web_sensor()
    if !self.wire return nil end

    var msg = ""

    for ch : 0..7
      var cfg = self.channel_configs[ch]
      if cfg != nil
        var unit = cfg['type'] == 'voltage' ? 'V' : 'mA'
        msg += string.format("{s}ADS7828 CH%d %s{m}%.3f %s{e}",
          ch, unit, self.readings[ch], unit)
      end
    end

    tasmota.web_send_decimal(msg)
  end

  def json_append()
    if !self.wire return nil end

    var msg = ",\"ADS7828\":{"
    var first = true

    for ch : 0..7
      var cfg = self.channel_configs[ch]
      if cfg != nil
        if !first msg += "," end
        first = false

        var suffix = cfg['type'] == 'voltage' ? 'V' : 'mA'
        msg += string.format("\"CH%d_%s\":%.3f",
          ch, suffix, self.readings[ch])
      end
    end

    msg += "}"
    tasmota.response_append(msg)
  end

end

global.ads7828 = ADS7828Data(
  ADS7828_ADDRESS,
  ADS7828_VREF,
  SHUNT_RESISTOR,
  HARDWARE_GAIN,
  CHANNEL_RANGES
)

tasmota.add_driver(global.ads7828)
