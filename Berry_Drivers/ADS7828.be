#- ========================================
 - ADS7828 Analog I2C Driver for Tasmota
 - 12-bit, 8-channel, single-ended mode
 - Internal 2.5V reference
 - ======================================== -#

var ADS7828_ADDR = 0x48  #- Change to match A0/A1 wiring: 0x48-0x4B -#
var ADS7828_VREF = 2.5   #- Internal reference voltage -#

class ADS7828Data : Driver

  var i2c_addr
  var vref
  var readings      #- list of 8 float voltage readings -#

  #- Channel select bits from Table II in datasheet -#
  #- SD=1 (single-ended), PD1=1 PD0=1 (ref ON, ADC ON) -#
  static CMD_BASE = 0x8C   #- was 0b10001100: SD=1, PD1=1, PD0=1 -#
  
  static CHANNEL_BITS = [
    0x00,  #- CH0: was 0b00000000 -#
    0x04,  #- CH1: was 0b00000100 -#
    0x10,  #- CH2: was 0b00010000 -#
    0x14,  #- CH3: was 0b00010100 -#
    0x08,  #- CH4: was 0b00001000 -#
    0x0C,  #- CH5: was 0b00001100 -#
    0x18,  #- CH6: was 0b00011000 -#
    0x1C   #- CH7: was 0b00011100 -#
  ]

  def init(addr, vref)
    self.i2c_addr = addr
    self.vref = vref
    self.readings = []
    for i : 0..7
      self.readings.push(0.0)
    end

    if tasmota.i2c_enabled(self.i2c_addr)
      print(string.format("ADS7828: found at 0x%02X", self.i2c_addr))
    else
      print(string.format("ADS7828: NOT found at 0x%02X - check wiring and A0/A1", self.i2c_addr))
    end
  end

  def read_channel(ch)
    var cmd = self.CMD_BASE | self.CHANNEL_BITS[ch]

    #- Write command byte -#
    wire.write(self.i2c_addr, cmd, -1, 1)

    #- Read 2 bytes back -#
    var hi = wire.read(self.i2c_addr, -1, 1)
    var lo = wire.read(self.i2c_addr, -1, 1)

    #- Reconstruct 12-bit result -#
    var raw = ((hi & 0x0F) << 8) | lo
    return raw
  end

  def raw_to_voltage(raw)
    return raw * self.vref / 4096.0
  end

  def read_all()
    var ok = true
    for ch : 0..7
      var raw = self.read_channel(ch)
      if raw >= 0
        self.readings[ch] = self.raw_to_voltage(raw)
      else
        ok = false
      end
    end
    return ok
  end

  def every_100ms()
    self.read_all()
  end

  def web_sensor()
    if !self.readings return nil end

    var msg = ""
    for ch : 0..7
      msg += string.format("{s}ADS7828 CH%d{m}%.4f V{e}", ch, self.readings[ch])
    end
    tasmota.web_send_decimal(msg)
  end

  def json_append()
    if !self.readings return nil end

    var msg = ",\"ADS7828\":{"
    for ch : 0..7
      if ch > 0 msg += "," end
      msg += string.format("\"CH%d\":%.4f", ch, self.readings[ch])
    end
    msg += "}"
    tasmota.response_append(msg)
  end

end

ADS7828Data = ADS7828Data(ADS7828_ADDR, ADS7828_VREF)
tasmota.add_driver(ADS7828Data)
