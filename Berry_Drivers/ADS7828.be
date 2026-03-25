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

var ADS7828_ADDRESS = 0x4b  #- I2C address: 0x48-0x4B depending on A0/A1 pins -#
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

  #- Command byte constants (hex, Berry has no 0b binary literals)
   - CMD_BASE = 0x8C = SD=1 (single-ended), PD1=1 PD0=1 (ref ON, ADC ON)
   - CHANNEL_BITS from Table II of ADS7828 datasheet
  -#
  static CMD_BASE = 0x8C

  static CHANNEL_BITS = [
    0x00,  #- CH0 -#
    0x04,  #- CH1 -#
    0x10,  #- CH2 -#
    0x14,  #- CH3 -#
    0x08,  #- CH4 -#
    0x0C,  #- CH5 -#
    0x18,  #- CH6 -#
    0x1C   #- CH7 -#
  ]

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
      #- Let internal reference settle before first conversion -#
      #- C38 is 100nF on this board so ~42us typical, tasmota.delay is ms -#
      tasmota.delay(5)
    else
      print(string.format("ADS7828: NOT found at 0x%02X - check wiring and A0/A1 pins", self.i2c_addr))
      print("ADS7828: Valid addresses are 0x48, 0x49, 0x4A, 0x4B")
    end
  end

  def read_channel(ch)
    if !self.wire return -1 end

    var cmd = self.CMD_BASE | self.CHANNEL_BITS[ch]

    #- Write command byte to select channel -#
    self.wire._begin_transmission(self.i2c_addr)
    self.wire._write(cmd)
    self.wire._end_transmission()

    #- Read 2 bytes back -#
    self.wire._request_from(self.i2c_addr, 2)
    var hi = self.wire._read()
    var lo = self.wire._read()

    #- Reconstruct 12-bit value: upper nibble of hi byte is padding zeros -#
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

  def every_100ms()
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
