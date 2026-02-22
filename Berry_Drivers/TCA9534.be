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

#- ==================================================================
 - Tasmota TCA9534/TCA9534A I2C & GPIO I/O driver written in Berry
 - 8-bit I/O expander & GPIO with explicit input/output configuration
 - GPIO mode mainly uses Tasmota's built-in API features
 - ================================================================== -#

#- =========================================================
 - Author: Arshia Keshvari
 - Role: Independent Developer, Engineer, and Project Author
 - GitHub: @TeslaNeuro
 - MakeThingsHappy.io
 - Last Updated: 2026-02-22
 - ========================================================= -#

#- ===========================================
 - I2C I/O Expander or GPIO User Configuration
 - Change these values to match your board
 - =========================================== -#

var IOEXPANDER_ADDRESS   = 0x3F  #- I2C address: 0x20 to 0x27 or 0x38 to 0x3F depending on A0/A1/A2 pins -#
var IOEXPANDER_PINCONFIG = "00001111"  #- 1=input, 0=output, MSB to LSB (P7 to P0) -#
var HARDWARE_MODE        = "gpio"  #- "i2c" or "gpio" -#

#- TCA9534A I2C Address reference:
 - A2=L A1=L A0=L -> 0x38
 - A2=L A1=L A0=H -> 0x39
 - A2=L A1=H A0=L -> 0x3A
 - A2=L A1=H A0=H -> 0x3B
 - A2=H A1=L A0=L -> 0x3C
 - A2=H A1=L A0=H -> 0x3D
 - A2=H A1=H A0=L -> 0x3E
 - A2=H A1=H A0=H -> 0x3F  (all address pins high)
-#
#- TCA9534 I2C Address reference:
 - A2=L A1=L A0=L -> 0x20
 - A2=L A1=L A0=H -> 0x21
 - A2=L A1=H A0=L -> 0x22
 - A2=L A1=H A0=H -> 0x23
 - A2=H A1=L A0=L -> 0x24
 - A2=H A1=L A0=H -> 0x25
 - A2=H A1=H A0=L -> 0x26
 - A2=H A1=H A0=H -> 0x27  (all address pins high)
-#

# Pin Configuration of the board: 1 -> input channel, 0 -> output channel
# The channels are in this order 0b[P7][P6][P5][P4][P3][P2][P1][P0]
# You can find the pin configuration of the module on the schematic of the IoTExtra board
# IoTExtra Relay2 -> 0b11110000 ATTENTION: check the schematic (P4-P7 i.e. channels 5-8 are unused)
# IoTExtra Input -> 0b11111111
# IoTExtra Octal -> 0b00001111
# IoTExtra Combo -> 0b11000000

import string

class TCA9534 : Driver

  # TCA9534 registers
  var INPUT_PORT_REGISTER
  var OUTPUT_PORT_REGISTER
  var CONFIG_REGISTER

  var wire              #- if wire == nil then the module is not initialized -#
  var output_pin_state
  var i2cAddress
  var pinConfig
  var hardware_mode

  def init(i2cAddress, pinConfig, hardware_mode)
    self.i2cAddress = i2cAddress
    self.hardware_mode = hardware_mode
    self.output_pin_state = 0xFF # All relays off initially -> this is to track state of the outputs on the firmware

    self.INPUT_PORT_REGISTER  = 0x00
    self.OUTPUT_PORT_REGISTER = 0x01
    self.CONFIG_REGISTER      = 0x03
    
    
    #- convert pinConfig string "11110000" to bitmask -#
    if size(pinConfig) != 8
      print("TCA9534: pinConfig must be 8 characters e.g. '11110000'")
      return
    end
    self.pinConfig = 0
    for i:0..7
      if pinConfig[i] == '1'
        self.pinConfig = self.pinConfig | (0x01 << (7 - i))
      end
    end

    if self.hardware_mode == "i2c"
      self.wire = tasmota.wire_scan(self.i2cAddress)

      if self.wire
        #- write pin config to the config register over i2c-#
        self.wire._begin_transmission(self.i2cAddress)
        self.wire._write(self.CONFIG_REGISTER)
        self.wire._write(self.pinConfig)
        self.wire._end_transmission()
        print(string.format("I2C: I/O Expander detected at 0x%02X on bus %i", self.i2cAddress, self.wire.bus))
        print(string.format("I/O Expander: Configuring pins with bitmask 0x%02X", self.pinConfig))
      else
        print(string.format("I2C: I/O Expander not found at address 0x%02X", self.i2cAddress))
      end
    elif self.hardware_mode == "gpio"
      print("I/O Expander: Initializing in GPIO mode")
      print(string.format("I/O Expander: Using Tasmota template GPIO assignments"))
    else
      print("Invalid hardware mode, must be 'i2c' or 'gpio'")
    end
  end

  def set_output(channel, output_state)
    #- validate channel range -#
    if channel < 1 || channel > 8 return nil end

    #- check this pin is configured as output (0 in pinConfig) -#
    if (self.pinConfig >> (channel - 1)) & 0x01
      print(string.format("I/O Expander: channel %i is configured as input, cannot set output", channel))
      return nil
    end

    if self.hardware_mode == "i2c"
      if !self.wire return nil end
      if self.output_pin_state == nil return nil end

      var pin_index = channel - 1

      #- active-low: state true = bit 0, state false = bit 1 -#
      if output_state
        self.output_pin_state = self.output_pin_state & ~(1 << pin_index)
      else
        self.output_pin_state = self.output_pin_state | (1 << pin_index)
      end

      self.wire._begin_transmission(self.i2cAddress)
      self.wire._write(self.OUTPUT_PORT_REGISTER)
      self.wire._write(self.output_pin_state)
      self.wire._end_transmission()

      print(string.format("I2C: channel %i set to %s, output register=0x%02X", channel, output_state ? "ON" : "OFF", self.output_pin_state))

    elif self.hardware_mode == "gpio"
      #- Count how many output channels exist BEFORE this channel -#
      var relay_idx = 0
      for i:0..(channel - 2)
        if ((self.pinConfig >> i) & 0x01) == 0  #- is output -#
          relay_idx = relay_idx + 1
        end
      end
      tasmota.set_power(relay_idx, output_state)
      print(string.format("GPIO: channel %i (relay %i) set to %s", channel, relay_idx, output_state ? "ON" : "OFF"))
    end

    return output_state
  end

  def read_all_inputs()
    var result = []

    if self.hardware_mode == "i2c"
      if !self.wire return nil end #- exit if not initialized -#

      var r = self.wire.read(self.i2cAddress, self.INPUT_PORT_REGISTER, 1)
      if r == nil return nil end

      # pinConfig: 1 = input, 0 = output
      for i:0..7
        if (self.pinConfig >> i) & 0x01

          #- input pin: read and invert state -#
          var state = (r >> i) & 0x01
          
          # Reverse logic: active-low hardware means 0 = signal present, 1 = no signal, so we invert it
          result.push(state ^ 0x01)
        else
          # Output pin → None
          result.push(nil)
        end
      end

    elif self.hardware_mode == "gpio"
      var switches = tasmota.get_switch()
      
      for i:0..7
        if (self.pinConfig >> i) & 0x01
          #- Input pin - read from Tasmota switch -#
          if switches && size(switches) > i
            result.push(switches[i] ? 1 : 0)
          else
            result.push(0)
          end
        else
          result.push(nil)
        end
      end
    end

    return result
  end

  #-- Debugging method to read all inputs and publish on tasmota every 100ms -#
  # def every_100ms()
  #   if !self.wire == nil return end  #- exit if wire not initialized -#
  #   var input_states = self.read_all_inputs()
  #   if input_states != nil
  #     var msg = "{\"TCA9534\":{"
  #     for i:0..7
  #       if input_states[i] != nil
  #         msg = msg + string.format("\"P%i\":%i", i, input_states[i])
  #         if i < 7
  #           msg = msg + ", "
  #         end
  #       end
  #     end
  #     msg = msg + "}}"
  #     tasmota.publish_result(msg, 'RESULT')
  #   end
  # end
  
  # Read all inputs and publish changes on input state changes on console monitor every 100ms
  # You can also set outputs based on input states in this method as an example of how to use the read_all_inputs() method
  def every_second()
    # if !self.wire return end  #- exit if wire not initialized -#
    # self.read_all_inputs()

    var input_states = self.read_all_inputs()
    
    if input_states != nil
      print(string.format("I/O Channels: %s", str(input_states)))
      #- Setting output example: if input P1 is active, turn on output P4 -#
      if input_states[1] == 1
        self.set_output(5, true)
      else
        self.set_output(5, false)
      end
    end
  end

  # def web_sensor()
  #   if !self.wire return nil end #- exit if not initialized -#
  #   var msg = string.format("

  #   tasmota.web_send_decimal(msg)
  # end

  # def json_append()
  #   if !self.wire return nil end #- exit if not initialized -#

  #   tasmota.response_append(msg)
  
  # end
end

tca9534 = TCA9534(IOEXPANDER_ADDRESS, IOEXPANDER_PINCONFIG, HARDWARE_MODE)
tasmota.add_driver(tca9534)
