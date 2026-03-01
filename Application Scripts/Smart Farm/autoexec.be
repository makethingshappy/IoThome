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

#- ========================================
 - SmartFarm Automation - autoexec.be
 - Local autonomous irrigation control
 - ======================================== -#
 
#- =========================================================
 - Author: Arshia Keshvari
 - Role: Independent Developer, Engineer, and Project Author
 - GitHub: @TeslaNeuro
 - MakeThingsHappy.io
 - Last Updated: 2026-03-01
 - ========================================================= -#

#- Load drivers -#
load("TCA9534.be")
load("ADS1115Data.be")

#- ========================================
 - SmartFarm Configuration
 - ======================================== -#

var SOIL_CHANNEL = 0           #- Analog differential channel for soil moisture (D0) -#
var IRRIGATION_RELAY = 1       #- Output channel for irrigation relay -#
var DRY_THRESHOLD_PERCENT = 30 #- Irrigate when below this % -#
var IRRIGATION_DURATION = 20  #- Seconds to run irrigation (300 = 5 minutes) -#

#- Calibration values (adjust based on your sensor in dry/wet soil) -#
var MIN_ANALOG_VALUE = 1.0     #- Voltage when sensor is in DRY soil -#
var MAX_ANALOG_VALUE = 4.5     #- Voltage when sensor is in WET soil -#

import string

class SmartFarm : Driver
  var soil_moisture_percent
  var irrigation_active
  var irrigation_start_time
  var last_trigger_time
  var min_analog
  var max_analog
  var dry_threshold
  var irrigation_duration
  var soil_channel
  var relay_channel
  
  def init(soil_ch, relay_ch, min_val, max_val, threshold, duration)
    self.soil_channel = soil_ch
    self.relay_channel = relay_ch
    self.min_analog = min_val
    self.max_analog = max_val
    self.dry_threshold = threshold
    self.irrigation_duration = duration
    self.soil_moisture_percent = 0
    self.irrigation_active = false
    self.irrigation_start_time = 0
    self.last_trigger_time = 0
    
    print("SmartFarm: Initialized")
    print(string.format("  Soil sensor: D%i", self.soil_channel))
    print(string.format("  Irrigation relay: Channel %i", self.relay_channel))
    print(string.format("  Calibration: %.2fV (dry) to %.2fV (wet)", self.min_analog, self.max_analog))
    print(string.format("  Threshold: %i%%, Duration: %is", self.dry_threshold, self.irrigation_duration))
  end
  
  def scale_to_percent(raw_value)
    #- Scale raw analog value to 0-100% based on calibration -#
    var percent = ((raw_value - self.min_analog) / (self.max_analog - self.min_analog)) * 100.0
    
    #- Clamp to 0-100% -#
    if percent < 0 percent = 0 end
    if percent > 100 percent = 100 end
    
    return percent
  end
  
  def check_irrigation()
    #- Get current soil moisture reading -#
    if !global.ADS1115Data.convert_to_mv
      return
    end
    
    if self.soil_channel >= size(global.ADS1115Data.convert_to_mv)
      print("SmartFarm: Soil channel out of range")
      return
    end
    
    var raw_voltage = global.ADS1115Data.convert_to_mv[self.soil_channel]
    self.soil_moisture_percent = self.scale_to_percent(raw_voltage)
    
    var current_time = tasmota.millis() / 1000  #- Convert to seconds -#
    
    #- Check if irrigation is currently active -#
    if self.irrigation_active
      var elapsed = current_time - self.irrigation_start_time
      
      if elapsed >= self.irrigation_duration
        #- Turn off irrigation after duration expires -#
        global.tca9534.set_output(self.relay_channel, false)
        self.irrigation_active = false
        print(string.format("SmartFarm: Irrigation completed (ran for %is)", elapsed))
      end
      return
    end
    
    #- Check if soil is too dry and needs irrigation -#
    if self.soil_moisture_percent < self.dry_threshold
      #- Prevent rapid re-triggering (minimum 1 hour between cycles) -#
      var time_since_last = current_time - self.last_trigger_time
      
      if time_since_last > 20  #- 3600 = 1 hour cooldown -#
        print(string.format("SmartFarm: Soil moisture LOW (%.1f%%), starting irrigation", self.soil_moisture_percent))
        
        global.tca9534.set_output(self.relay_channel, true)
        self.irrigation_active = true
        self.irrigation_start_time = current_time
        self.last_trigger_time = current_time
      else
        # You can put 3600 if you want 1 hour cooldown, but for testing we can set it to 20 seconds
        var remaining = 20 - time_since_last
        print(string.format("SmartFarm: Soil dry but cooldown active (%i min remaining)", remaining / 60))
      end
    end
  end
  
  def every_second()
    self.check_irrigation()
  end
  
  def web_sensor()
    if self.soil_moisture_percent == nil return nil end
    
    var status = self.irrigation_active ? "ACTIVE" : "IDLE"
    var msg = string.format(
      "{s}Soil Moisture{m}%.1f %%{e}"..
      "{s}Irrigation Status{m}%s{e}",
      self.soil_moisture_percent,
      status
    )
    
    if self.irrigation_active
      var elapsed = (tasmota.millis() / 1000) - self.irrigation_start_time
      var remaining = self.irrigation_duration - elapsed
      msg += string.format("{s}Time Remaining{m}%i s{e}", remaining)
    end
    
    tasmota.web_send_decimal(msg)
  end
  
  def json_append()
    if self.soil_moisture_percent == nil return nil end
    
    var msg = string.format(
      ",\"SmartFarm\":{\"SoilMoisture\":%.1f,\"IrrigationActive\":%s",
      self.soil_moisture_percent,
      self.irrigation_active ? "true" : "false"
    )
    
    if self.irrigation_active
      var elapsed = (tasmota.millis() / 1000) - self.irrigation_start_time
      msg += string.format(",\"TimeRemaining\":%i", self.irrigation_duration - elapsed)
    end
    
    msg += "}"
    tasmota.response_append(msg)
  end
end

#- Initialize SmartFarm automation -#
smartfarm = SmartFarm(
  SOIL_CHANNEL,
  IRRIGATION_RELAY,
  MIN_ANALOG_VALUE,
  MAX_ANALOG_VALUE,
  DRY_THRESHOLD_PERCENT,
  IRRIGATION_DURATION
)

tasmota.add_driver(smartfarm)

print("SmartFarm: autoexec.be loaded successfully")
