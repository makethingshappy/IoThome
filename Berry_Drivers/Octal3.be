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
 - Tasmota IoTextra Octal3 driver written in Berry
 -
 - Octal3 is a HYBRID board:
 -   * 4 latching relay outputs driven via TCA9534 over I2C
 -     (2 physical TCA pins per relay = IN1/IN2 H-bridge pair;
 -     all 8 TCA pins are outputs; CONFIG is always 0x00)
 -   * 4 input channels on host MCU GPIO (Tasmota Switches), NOT on the TCA
 -   * optional nSLEEP via a Tasmota template Relay
 -
 - PIN_CONFIG describes the LOGICAL channel map (which of CH1-8 is an
 - input vs output). It does NOT describe TCA9534 pin directions.
 -
 - Which logical channels are latching outputs is given by OCTAL3_CHANNELS;
 - relay pin-pairs are assigned dynamically in ascending channel order.
 -
 - H-bridge safety: never assert IN1 and IN2 together; always return to
 - idle 0x00 after each pulse. (Not the PWM gpio.set_pwm cookbook path.)
 -
 - Template expectation (default map):
 -   I2C SDA/SCL, Switch1..4 for CH5..CH8 inputs, Relay1 for nSLEEP
 - ================================================================== -#

#- =========================================================
 - Author: Arshia Keshvari
 - Role: Independent Developer, Engineer, and Project Author
 - GitHub: @TeslaNeuro
 - MakeThingsHappy.io
 - Last Updated: 2026-07-19
 - ========================================================= -#

#- ===========================================================
 - User Configuration - change these to match your board
 - =========================================================== -#

var IOEXPANDER_ADDRESS = 0x27   #- TCA9534 0x20-0x27 / TCA9534A 0x38-0x3F -#

#- Logical channel map: 0=output, 1=input, MSB=P7..LSB=P0 (string form).
 - Default: CH1-4 latching outputs, CH5-8 host GPIO inputs. -#
var PIN_CONFIG = "00001111"

#- Logical channels that are latching relay outputs (1-based CH1..CH8).
 - Sorted ascending and mapped to physical pairs (IN1,IN2):
 -   pair0=(1,0) pair1=(3,2) pair2=(5,4) pair3=(7,6) -#
var OCTAL3_CHANNELS = [1, 2, 3, 4]

#- 1-based Tasmota Relay number that drives nSLEEP, or nil to skip. -#
var NSLEEP_RELAY = 1

#- Latching coil pulse width (ms). Keep <= 10; Berry must not block long. -#
var PULSE_MS = 5

#- Logical input channel (1-based) -> Tasmota Switch number (1-based).
 - Default matches PIN_CONFIG "00001111" (CH5-8 inputs on Switch1-4).
 - Alternate example (CH1-4 in / CH5-8 out):
 -   PIN_CONFIG = "11110000"
 -   OCTAL3_CHANNELS = [5, 6, 7, 8]
 -   INPUT_SWITCHES = {1:1, 2:2, 3:3, 4:4} -#
var INPUT_SWITCHES = {5:1, 6:2, 7:3, 8:4}

#- TCA9534 / TCA9534A address reference (same as TCA9534.be):
 - TCA9534:  0x20..0x27   TCA9534A: 0x38..0x3F
-#

import string
import global
import gpio

class Octal3 : Driver

  var OUTPUT_PORT_REGISTER
  var CONFIG_REGISTER

  var wire              #- nil if expander not found -#
  var i2cAddress
  var pinConfig         #- logical bitmask: bit i = CH(i+1), 1=input 0=output -#
  var pulse_ms
  var nsleep_relay      #- 1-based Relay number, or nil -#
  var pulsing           #- exclusive pulse lock -#

  var octal3_channels   #- list of latching output channel numbers -#
  var relay_pins        #- map channel -> [in1_pin, in2_pin] -#
  var output_states     #- map channel -> bool (software mirror; no I2C readback) -#
  var input_switches    #- map logical CH -> Switch number -#
  var switch_index_map  #- Switch number -> packed index in get_switches() -#

  def init(i2cAddress, pinConfig, octal3_channels, nsleep_relay, pulse_ms, input_switches)
    self.i2cAddress = i2cAddress
    self.pulse_ms = pulse_ms != nil ? pulse_ms : 5
    self.nsleep_relay = nsleep_relay
    self.pulsing = false
    self.input_switches = input_switches != nil ? input_switches : {}

    self.OUTPUT_PORT_REGISTER = 0x01
    self.CONFIG_REGISTER      = 0x03

    #- Parse logical PIN_CONFIG string (MSB P7 .. LSB P0). -#
    if size(pinConfig) != 8
      print("Octal3: PIN_CONFIG must be 8 characters e.g. '00001111'")
      return
    end
    self.pinConfig = 0
    for i:0..7
      if pinConfig[i] == '1'
        self.pinConfig = self.pinConfig | (0x01 << (7 - i))
      end
    end

    #- Sort and store latching output channels; build relay pin-pair map. -#
    self.octal3_channels = self._sorted_copy(octal3_channels)
    self.relay_pins = {}
    self.output_states = {}
    var physical_pairs = [[1, 0], [3, 2], [5, 4], [7, 6]]
    var idx = 0
    for ch : self.octal3_channels
      if idx < size(physical_pairs)
        self.relay_pins[ch] = physical_pairs[idx]
        self.output_states[ch] = false
        idx += 1
      else
        print(string.format("Octal3: channel %i ignored - only 4 physical relay pairs", ch))
      end
    end

    #- Build Switch-number -> packed-index map (handles template holes). -#
    self.switch_index_map = {}
    var packed_idx = 0
    var i = 0
    while i < 32
      if gpio.pin_used(gpio.SWT1, i)
        self.switch_index_map[i + 1] = packed_idx
        packed_idx += 1
      end
      i += 1
    end
    print(string.format("Octal3: %i template switch(es) found", packed_idx))
    for sw_num : self.switch_index_map.keys()
      print(string.format("Octal3:   Switch%i -> packed index %i", sw_num, self.switch_index_map[sw_num]))
    end

    #- Warn if configured input switches are missing from the template. -#
    for ch : self.input_switches.keys()
      var sw = self.input_switches[ch]
      if self.switch_index_map.find(sw) == nil
        print(string.format("Octal3: warning - CH%i Switch%i not in template, reads will be nil", ch, sw))
      end
    end

    #- I2C bring-up: TCA always all-output for Octal3 relay drivers. -#
    self.wire = tasmota.wire_scan(self.i2cAddress)
    if self.wire
      self.wire._begin_transmission(self.i2cAddress)
      self.wire._write(self.CONFIG_REGISTER)
      self.wire._write(0x00)   #- force all-output regardless of PIN_CONFIG -#
      self.wire._end_transmission()

      #- Idle H-bridge outputs. -#
      self.wire._begin_transmission(self.i2cAddress)
      self.wire._write(self.OUTPUT_PORT_REGISTER)
      self.wire._write(0x00)
      self.wire._end_transmission()

      print(string.format("Octal3: TCA9534 at 0x%02X on bus %i configured all-output (relay drivers)",
                           self.i2cAddress, self.wire.bus))
    else
      print(string.format("Octal3: TCA9534 not found at 0x%02X", self.i2cAddress))
    end

    #- Start with drivers asleep. -#
    self._set_nsleep(false)

    print(string.format("Octal3: ready - %i latching out, logical pinConfig=0x%02X, pulse=%ims, nSLEEP relay=%s",
                         size(self.relay_pins), self.pinConfig, self.pulse_ms,
                         self.nsleep_relay != nil ? str(self.nsleep_relay) : "none"))
  end

  #- Ascending copy of a channel list (small N). -#
  def _sorted_copy(channels)
    var sorted = []
    if channels == nil return sorted end
    for ch : channels
      sorted.push(ch)
    end
    var n = size(sorted)
    var a = 0
    while a < n
      var b = 0
      while b < n - 1 - a
        if sorted[b] > sorted[b + 1]
          var tmp = sorted[b]
          sorted[b] = sorted[b + 1]
          sorted[b + 1] = tmp
        end
        b += 1
      end
      a += 1
    end
    return sorted
  end

  #- nSLEEP via template Relay (1-based). true = awake, false = sleep. -#
  def _set_nsleep(awake)
    if self.nsleep_relay == nil return end
    tasmota.set_power(self.nsleep_relay - 1, awake)
  end

  #- Write one byte to the TCA9534 output port register. -#
  def _write_output(val)
    if !self.wire return false end
    self.wire._begin_transmission(self.i2cAddress)
    self.wire._write(self.OUTPUT_PORT_REGISTER)
    self.wire._write(val & 0xFF)
    self.wire._end_transmission()
    return true
  end

  #- Pulse one latching relay. SET: IN1=1 IN2=0; RESET: IN1=0 IN2=1; then idle. -#
  def _pulse_relay(channel, set_state)
    if !self.wire return false end
    var pins = self.relay_pins.find(channel)
    if pins == nil return false end
    if self.pulsing
      print(string.format("Octal3: pulse busy, ignoring CH%i", channel))
      return false
    end

    self.pulsing = true

    var in1 = pins[0]
    var in2 = pins[1]
    var pulse_val = set_state ? (1 << in1) : (1 << in2)

    #- Wake drivers, short settle. -#
    self._set_nsleep(true)
    tasmota.delay(1)

    if !self._write_output(pulse_val)
      self._set_nsleep(false)
      self.pulsing = false
      return false
    end

    tasmota.delay(self.pulse_ms)

    #- Idle both IN1/IN2 low (never leave a bridge leg driven). -#
    self._write_output(0x00)
    tasmota.delay(1)
    self._set_nsleep(false)

    self.pulsing = false
    print(string.format("Octal3: CH%i %s pulsed (%ims)", channel, set_state ? "SET" : "RESET", self.pulse_ms))
    return true
  end

  #- Set latching output. Returns true if software mirror changed, else false/nil. -#
  def set_output(channel, state)
    if channel < 1 || channel > 8 return nil end

    #- Must be logical output in PIN_CONFIG and an Octal3 latching channel. -#
    if (self.pinConfig >> (channel - 1)) & 0x01
      print(string.format("Octal3: channel %i is configured as input, cannot set output", channel))
      return nil
    end
    if self.relay_pins.find(channel) == nil
      print(string.format("Octal3: channel %i is not an Octal3 latching output", channel))
      return nil
    end

    var new_state = state ? true : false
    if !self._pulse_relay(channel, new_state)
      return false
    end

    var changed = self.output_states.find(channel) != new_state
    self.output_states[channel] = new_state
    return changed
  end

  #- Software mirror only (no I2C readback). nil if not an Octal3 output. -#
  def get_output(channel)
    if self.relay_pins.find(channel) == nil return nil end
    return self.output_states.find(channel)
  end

  #- Restore mirror from CH1-CH8 bitmask without pulsing hardware. -#
  def load_states(bitmask)
    if bitmask == nil return end
    for ch : self.octal3_channels
      self.output_states[ch] = (bitmask & (1 << (ch - 1))) != 0
    end
  end

  #- Pack software mirror into a CH1-CH8 bitmask. -#
  def states_bitmask()
    var bitmask = 0
    for ch : self.octal3_channels
      if self.output_states.find(ch)
        bitmask = bitmask | (1 << (ch - 1))
      end
    end
    return bitmask
  end

  #- Length-8 list: input DI (1=signal) or nil for outputs / missing switches. -#
  def read_all_inputs()
    var result = []
    var switches = tasmota.get_switches()

    for i:0..7
      var channel = i + 1
      if (self.pinConfig >> i) & 0x01
        #- Logical input -> host Switch. -#
        var sw_num = self.input_switches.find(channel)
        if sw_num == nil
          result.push(nil)
        else
          var packed_idx = self.switch_index_map.find(sw_num)
          if packed_idx == nil || switches == nil || size(switches) <= packed_idx
            result.push(nil)
          else
            #- get_switches(): true = PRESSED = active (pin LOW). Already
             - logical DI for active-low inputs (same as ISO1211 gpio path). -#
            result.push(switches[packed_idx] ? 1 : 0)
          end
        end
      else
        #- Latching output: no hardware readback. -#
        result.push(nil)
      end
    end

    return result
  end

  def web_sensor()
    var input_states = self.read_all_inputs()
    if input_states == nil return nil end

    var msg = ""
    for i:0..7
      var channel = i + 1
      var pin_name = string.format("CH%d", channel)

      if input_states[i] != nil
        var state_text = input_states[i] == 1 ? "HIGH" : "LOW"
        msg += string.format("{s}%s IN{m}%s{e}", pin_name, state_text)
      elif self.relay_pins.find(channel) != nil
        var on = self.output_states.find(channel)
        msg += string.format("{s}%s OUT{m}%s{e}", pin_name, on ? "ON" : "OFF")
      end
    end

    if size(msg) > 0
      tasmota.web_send_decimal(msg)
    end
  end

  def json_append()
    var input_states = self.read_all_inputs()
    if input_states == nil return nil end

    var msg = ",\"Octal3\":{"
    var first = true

    for i:0..7
      var channel = i + 1

      if input_states[i] != nil
        if !first msg += "," end
        first = false
        msg += string.format("\"CH%d_IN\":%d", channel, input_states[i])
      elif self.relay_pins.find(channel) != nil
        if !first msg += "," end
        first = false
        var on = self.output_states.find(channel)
        msg += string.format("\"CH%d_OUT\":%d", channel, on ? 1 : 0)
      end
    end

    msg += "}"
    tasmota.response_append(msg)
  end
end

global.octal3 = Octal3(IOEXPANDER_ADDRESS, PIN_CONFIG, OCTAL3_CHANNELS,
                       NSLEEP_RELAY, PULSE_MS, INPUT_SWITCHES)
tasmota.add_driver(global.octal3)