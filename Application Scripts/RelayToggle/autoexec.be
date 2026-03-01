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
 - TCA9534 Relay Toggle - autoexec.be
 - Strict-mode compatible
 - ======================================== -#

#- =========================================================
 - Author: Arshia Keshvari
 - Role: Independent Developer, Engineer, and Project Author
 - GitHub: @TeslaNeuro
 - MakeThingsHappy.io
 - Last Updated: 2026-02-22
 - ========================================================= -#

#- Load driver -#
load("TCA9534.be")

class TCA9534Toggle

  var state
  
  def init()
    self.state = false
  end
  
  def every_second()
    #- Toggle state -#
    self.state = !self.state
    
    #- Set TCA9534 channel 1 -#
    global.tca9534.set_output(1, self.state)
    
    if self.state
      print("TCA9534 CH1: ON")
    else
      print("TCA9534 CH1: OFF")
    end
  end
  
end

var toggle = TCA9534Toggle()
tasmota.add_driver(toggle)

print("TCA9534 Toggle: Loaded")
