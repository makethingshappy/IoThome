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
 - Last Updated: 2026-03-25
 - ========================================================= -#

#- ========================================================
 - ADS7828 12-bit 8-channel I2C ADC Driver for Tasmota
 - Single-ended mode, internal 2.5V reference
 - ======================================================== -#

#- ========================================
 - ADS7828 Configuration
 - Change these values to match your board
 - ======================================== -#

var ADS7828_ADDRESS = 0x4B  #- I2C address: 0x48-0x4B depending on A0/A1 pins -#
var ADS7828_VREF    = 2.5   #- Internal reference voltage -#

#- ADS7828 Address reference:
 - A1=L A0=L -> 0x48
 - A1=L A0=H -> 0x49
 - A1=H A0=L -> 0x4A
 - A1=H A0=H -> 0x4B
-#

import string
import global

class ADS7828 : Driver

  var wire
  var i2c_addr
  var vref
  var readings

  #- Command byte constants
   - SD=1 (single-ended) = 0x80
   - PD1=1 PD0=1 (internal ref ON, ADC ON) = 0x0C
   - Channel bits from Table II of ADS7828 datasheet (bits 6-4)
  -#
  static CMD_BASE = 0x8C  #- SD=1, PD1=1, PD0=1, CH0 -#

  static CHANNEL_BITS = [
    0x00,  #- CH0: C2=0 C1=0 C0=0 -#
    0x40,  #- CH1: C2=1 C1=0 C0=0 -#
    0x10,  #- CH2: C2=0 C1=0 C0=1 -#
    0x50,  #- CH3: C2=1 C1=0 C0=1 -#
    0x20,  #- CH4: C2=0 C1=1 C0=0 -#
    0x60,  #- CH5: C2=1 C1=1 C0=0 -#
    0x30,  #- CH6: C2=0 C1=1 C0=1 -#
    0x70   #- CH7: C2=1 C1=1 C0=1 -#
  ]

  static SD_BIT  = 0x80
  static PD_BITS = 0x0C

  def init(i2c_addr, vref)
    self.i2c_addr = i2c_addr
    self.vref = vref
    self.readings = []

    for i : 0..7
      self.readings.push(0.0)
    end

    self.wire = tasmota.wire_scan(self.i2c_addr)

    if self.wire
      print(string.format("ADS7828: found at 0x%02X on bus %i", self.i2c_addr, self.wire.bus))
      tasmota.delay(10)  #- let internal reference settle -#
    else
      print(string.format("ADS7828: NOT found at 0x%02X - check wiring and A0/A1 pins", self.i2c_addr))
      print("ADS7828: valid addresses are 0x48, 0x49, 0x4A, 0x4B")
    end
  end

  def build_command(ch)
    return self.SD_BIT | self.CHANNEL_BITS[ch] | self.PD_BITS
  end

  def read_channel(ch)
    if !self.wire return -1 end

    var cmd = self.build_command(ch)

    #- Write command byte to select channel and trigger conversion -#
    self.wire._begin_transmission(self.i2c_addr)
    self.wire._write(cmd)
    self.wire._end_transmission()

    #- Wait for conversion — datasheet says 6us, tasmota.delay is ms so 1ms is safe -#
    tasmota.delay(1)

    #- Read 2 bytes back -#
    self.wire._request_from(self.i2c_addr, 2)
    var hi = self.wire._read()
    var lo = self.wire._read()

    #- Reconstruct 12-bit value -#
    var raw = ((hi & 0x0F) << 8) | lo
    return raw
  end

  def raw_to_voltage(raw)
    return raw * self.vref / 4096.0
  end

  def read_all()
    if !self.wire return end

    for ch : 0..7
      var raw = self.read_channel(ch)
      if raw >= 0
        self.readings[ch] = self.raw_to_voltage(raw)
      end
    end
  end

  def every_second()
    #- Use every_second instead of every_100ms — 8 channels × 1ms delay = 8ms per scan -#
    self.read_all()
  end

  def web_sensor()
    if !self.wire return nil end

    var msg = ""
    for ch : 0..7
      msg += string.format("{s}ADS7828 CH%d{m}%.4f V{e}", ch, self.readings[ch])
    end
    tasmota.web_send_decimal(msg)
  end

  def json_append()
    if !self.wire return nil end

    var msg = ",\"ADS7828\":{"
    for ch : 0..7
      if ch > 0 msg += "," end
      msg += string.format("\"CH%d\":%.4f", ch, self.readings[ch])
    end
    msg += "}"
    tasmota.response_append(msg)
  end

end

global.ads7828 = ADS7828(ADS7828_ADDRESS, ADS7828_VREF)
tasmota.add_driver(global.ads7828)
