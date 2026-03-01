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

#- ==============================================
 - A simple Alarm System 
 - Berry Application Script for IoTextra Series
 - ============================================== -#

#- =========================================================
 - Author: Arshia Keshvari
 - Role: Independent Developer, Engineer, and Project Author
 - GitHub: @TeslaNeuro
 - MakeThingsHappy.io
 - Last Updated: 2026-02-22
 - ========================================================= -#

import string

#- Load driver files -#
load("TCA9534.be")
load("ADS1115Data.be")

class AlarmSystem
  
  def every_second()
    #- Read analog channel 0 -#
    if global.ADS1115Data.convert_to_mv && size(global.ADS1115Data.convert_to_mv) > 0
      var voltage = global.ADS1115Data.convert_to_mv[0]
      
      print(string.format("Sensor D0: %.2fV", voltage))
      
      #- If below 2V, turn relay channel 1 ON -#
      if voltage < 2.0
        global.tca9534.set_output(1, true)
        print("ALARM: ON")
      else
        global.tca9534.set_output(1, false)
        print("ALARM: OFF")
      end
    end
  end
  
end

var alarmSystem = AlarmSystem()
tasmota.add_driver(alarmSystem)

print("AlarmSystem: Test automation loaded")
