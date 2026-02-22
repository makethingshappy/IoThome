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
 - ADS1115 Analog I2C Driver written in Berry for Tasmota
 - Supports voltage and current floating point measurements
 - Channels can be configured with different ranges and types
 - ========================================================== -#

 #- =========================================================
 - Author: Arshia Keshvari
 - Role: Independent Developer, Engineer, and Project Author
 - GitHub: @TeslaNeuro
 - MakeThingsHappy.io
 - Last Updated: 2026-02-22
 - ========================================================= -#

 #- ========================================
 - ADS1115 Analog Input Configuration
 - Change these values to match your board
 - ======================================== -#

var SHUNT_RESISTOR = 0.249  #- 0.249 or 0.120 depending on board -#
var HARDWARE_GAIN = 0.23761904761904762  #- Hardware voltage divider gain -#
#- Hardware gain options:
 - One 49.9kΩ resistor (jumpers cut): 0.47523809523809524
 - Two 49.9kΩ resistors in parallel (default): 0.23761904761904762
 - Old IoTextra modules: 0.2
-#

#- Measurement range for each differential channel (D0, D1, D2...) -#
#- P=Polarity, C=Current, RR=Range -#
#- Voltage ranges: 0x01=0-0.5V, 0x02=0-5V, 0x03=0-10V, 0x81=±0.5V, 0x82=±5V, 0x83=±10V -#
#- Current ranges: 0x21=0-20mA, 0xA1=±20mA, 0x22=4-20mA, 0x23=0-40mA -#
var CHANNEL_RANGES = [
  0x02,  #- D0: 0-5V -#
  0x22,  #- D1: 4-20mA -#
  0x82,  #- D2: ±5V -#
  0x03  #- D3: 0-10V -#
]

import json
import string

class ADS1115Data : Driver
  var convert_to_mv
  var shunt_resistor
  var hardware_g
  var channel_configs
  
  static ADS_LIST = [
    "ADS1115-48",
    "ADS1115-49",
    "ADS1115-4A",
    "ADS1115-4B",
    "ADS1115",
  ]
  
  # ADS1115 gain settings and their corresponding full-scale ranges
  static ADS_GAINS = {
    0: 6.144,   # ±6.144V, 2/3x gain
    1: 4.096,   # ±4.096V, 1x gain
    2: 2.048,   # ±2.048V, 2x gain
    3: 1.024,   # ±1.024V, 4x gain
    4: 0.512,   # ±0.512V, 8x gain
    5: 0.256    # ±0.256V, 16x gain
  }
  
  # Measurement range lookup table
  # Format: 0bPCRR where P=Polarity(bit7), C=Current(bit5), RR=Range(bits0-1)
  static RANGE_CONFIGS = {
    # Voltage ranges (bit 5 = 0)
    0x01: {'type': 'voltage', 'min': 0.0, 'max': 0.5, 'bipolar': false, 'ads_gain': 4},
    0x02: {'type': 'voltage', 'min': 0.0, 'max': 5.0, 'bipolar': false, 'ads_gain': 1},
    0x03: {'type': 'voltage', 'min': 0.0, 'max': 10.0, 'bipolar': false, 'ads_gain': 0},
    0x81: {'type': 'voltage', 'min': -0.5, 'max': 0.5, 'bipolar': true, 'ads_gain': 4},
    0x82: {'type': 'voltage', 'min': -5.0, 'max': 5.0, 'bipolar': true, 'ads_gain': 1},
    0x83: {'type': 'voltage', 'min': -10.0, 'max': 10.0, 'bipolar': true, 'ads_gain': 0},
    # Current ranges (bit 5 = 1)
    0x21: {'type': 'current', 'min': 0.0, 'max': 20.0, 'bipolar': false, 'ads_gain': 1},
    0xA1: {'type': 'current', 'min': -20.0, 'max': 20.0, 'bipolar': true, 'ads_gain': 1},
    0x22: {'type': 'current', 'min': 4.0, 'max': 20.0, 'bipolar': false, 'ads_gain': 1},
    0x23: {'type': 'current', 'min': 0.0, 'max': 40.0, 'bipolar': false, 'ads_gain': 0}
  }

  def init(shunt_resistor, hardware_gain, channel_ranges)
    self.shunt_resistor = shunt_resistor
    self.hardware_g = hardware_gain
    self.convert_to_mv = []
    self.channel_configs = []
    
    #- Build channel config from range codes -#
    for i:0..(size(channel_ranges)-1)
      var range_code = channel_ranges[i]
      if self.RANGE_CONFIGS.contains(range_code)
        var config = self.RANGE_CONFIGS[range_code]
        self.channel_configs.push(config)
        print(string.format("D%i: %s, range %.1f to %.1f, ADS gain %i", 
          i, config['type'], config['min'], config['max'], config['ads_gain']))
      else
        print(string.format("D%i: Invalid range code 0x%02X", i, range_code))
        self.channel_configs.push(nil)
      end
    end
  end

  def ads1115()
    var sensors = json.load(tasmota.read_sensors())
    if sensors == nil return nil end
    
    var results = []
    var channel_idx = 0
    
    # Iterate ADS devices in fixed order
    for dev : self.ADS_LIST
      if sensors.contains(dev)
        var ads = sensors[dev]
        
        # Differential mode = only A0 & A1 exist
        for ch : ["A0", "A1"]
          if ads.contains(ch)
            if channel_idx >= size(self.channel_configs)
              print(string.format("Warning: More channels detected than configured (D%i)", channel_idx))
              break
            end
            
            var config = self.channel_configs[channel_idx]
            if config == nil
              results.push(0.0)
              channel_idx += 1
              continue
            end
            
            var raw = ads[ch]
            var ads_gain_code = config['ads_gain']
            var g = self.ADS_GAINS[ads_gain_code]
            var v_p_b = g / 32768  # Volts per bit
            
            if config['type'] == 'voltage'
              #- Voltage measurement -#
              var mv = (raw * v_p_b) / self.hardware_g
              results.push(mv)
              
            elif config['type'] == 'current'
              #- Current measurement -#
              var mv = (raw * v_p_b) / self.hardware_g
              var ma = mv / self.shunt_resistor
              results.push(ma)
            end
            
            channel_idx += 1
          end
        end
      end
    end
    
    if size(results) == 0 return nil end
    
    self.convert_to_mv = results
    return true
  end

  def every_100ms()
    self.ads1115()
  end

  def web_sensor()
    if !self.convert_to_mv return nil end
    
    var msg = ""
    var idx = 0
    
    for val : self.convert_to_mv
      if idx >= size(self.channel_configs) break end
      
      var config = self.channel_configs[idx]
      if config != nil
        var unit = config['type'] == 'voltage' ? 'V' : 'mA'
        msg += string.format("{s}ADS1115 D%d %s{m}%.3f %s{e}", idx, unit, val, unit)
      end
      
      idx += 1
    end
    
    tasmota.web_send_decimal(msg)
  end

  def json_append()
    if !self.convert_to_mv return nil end
    
    var msg = ",\"ADS1115\":{"
    var idx = 0
    var first = true
    
    for val : self.convert_to_mv
      if idx >= size(self.channel_configs) break end
      
      var config = self.channel_configs[idx]
      if config != nil
        if !first msg += "," end
        first = false
        
        var suffix = config['type'] == 'voltage' ? 'V' : 'mA'
        msg += string.format("\"D%d_%s\":%.3f", idx, suffix, val)
      end
      
      idx += 1
    end
    
    msg += "}"
    tasmota.response_append(msg)
  end
end

ADS1115Data = ADS1115Data(SHUNT_RESISTOR, HARDWARE_GAIN, CHANNEL_RANGES)
tasmota.add_driver(ADS1115Data)
