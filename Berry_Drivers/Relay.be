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
 - Tasmota IoTextra Relay driver written in Berry
 -
 - IoTextra Relay is a HYBRID board (do NOT use TCA9534.be on this expander):
 -   * RS1-RS4: non-latching SPST relays on HOST AP0-AP3
 -     (Tasmota Relay1-4 via set_power; active-high transistor drive)
 -   * RL1-RL4: latching relays via TCA9534/TCA9534A over I2C
 -     (2 physical TCA pins per relay = IN1/IN2 H-bridge pair;
 -     all 8 TCA pins are outputs; CONFIG is always 0x00)
 -   * nSLEEP for all four DRV8837C drivers on HOST AP5, owned by Berry
 -
 - Channel map (1-based):
 -   CH1-4 = RS1-RS4  (GPIO / Tasmota Power)
 -   CH5-8 = RL1-RL4  (I2C H-bridge pulses)
 -
 - H-bridge safety: never assert IN1 and IN2 together; always return to
 - idle 0x00 after each pulse.
 -
 - Template expectation (IoTsmart ESP32-S3):
 -   AP0-AP3 = Relay1-4, I2C SDA/SCL.
 -   Leave AP5 (nSLEEP) unassigned in the template (User/None) so Berry
 -   owns it; do NOT assign it as a Relay.
 - ================================================================== -#

#- =========================================================
 - Author: Arshia Keshvari
 - Role: Independent Developer, Engineer, and Project Author
 - GitHub: @TeslaNeuro
 - MakeThingsHappy.io
 - Last Updated: 2026-09-13
 - ========================================================= -#

#- ===========================================================
 - User Configuration - change these to match your board
 - =========================================================== -#

#- Default matches IoTextra Relay 3-0x stuffed with TCA9534 and
 - SB1/SB2/SB3 open (A2=A1=A0=1) -> 0x27.
 - TCA9534:  0x20..0x27   TCA9534A: 0x38..0x3F -#
var IOEXPANDER_ADDRESS = 0x27

#- Physical GPIO for nSLEEP (HIGH=awake, LOW=sleep), or nil to skip.
 - Default GPIO5 = HOST AP5 on IoTsmart ESP32-S3.
 - Clear that pin off Relays in the Tasmota template so Berry owns it. -#
var NSLEEP_GPIO = 5

#- Latching coil pulse width (ms). Keep <= 10; Berry must not block long. -#
var PULSE_MS = 5

import string
import global
import gpio

class IoTextraRelay : Driver

  var OUTPUT_PORT_REGISTER
  var CONFIG_REGISTER

  var wire              #- nil if expander not found -#
  var i2cAddress
  var pulse_ms
  var nsleep_gpio       #- physical GPIO number, or nil -#
  var pulsing           #- exclusive pulse lock -#

  var relay_pins        #- map RL index 1-4 -> [in1_pin, in2_pin] -#
  var latching_states   #- map RL index 1-4 -> bool (software mirror) -#

  def init(i2cAddress, nsleep_gpio, pulse_ms)
    self.i2cAddress = i2cAddress
    self.pulse_ms = pulse_ms != nil ? pulse_ms : 5
    self.nsleep_gpio = nsleep_gpio
    self.pulsing = false

    self.OUTPUT_PORT_REGISTER = 0x01
    self.CONFIG_REGISTER      = 0x03

    #- RL1..RL4 -> TCA pairs (IN1, IN2): (P1,P0) (P3,P2) (P5,P4) (P7,P6) -#
    var physical_pairs = [[1, 0], [3, 2], [5, 4], [7, 6]]
    self.relay_pins = {}
    self.latching_states = {}
    var rl = 1
    while rl <= 4
      self.relay_pins[rl] = physical_pairs[rl - 1]
      self.latching_states[rl] = false
      rl += 1
    end

    #- I2C bring-up: TCA always all-output for latching H-bridge drivers. -#
    self.wire = tasmota.wire_scan(self.i2cAddress)
    if self.wire
      self.wire._begin_transmission(self.i2cAddress)
      self.wire._write(self.CONFIG_REGISTER)
      self.wire._write(0x00)
      self.wire._end_transmission()

      self.wire._begin_transmission(self.i2cAddress)
      self.wire._write(self.OUTPUT_PORT_REGISTER)
      self.wire._write(0x00)
      self.wire._end_transmission()

      print(string.format("Relay: TCA9534 at 0x%02X on bus %i configured all-output (latching drivers)",
                           self.i2cAddress, self.wire.bus))
    else
      print(string.format("Relay: TCA9534 not found at 0x%02X (SPST GPIO relays still available)", self.i2cAddress))
    end

    #- nSLEEP: claim physical GPIO as output, start asleep (LOW). -#
    if self.nsleep_gpio != nil
      gpio.pin_mode(self.nsleep_gpio, gpio.OUTPUT)
      self._set_nsleep(false)
      print(string.format("Relay: nSLEEP on GPIO%i (direct gpio, start asleep)", self.nsleep_gpio))
    end

    print(string.format("Relay: ready - RS1-4 SPST (Tasmota Power), RL1-4 latching, pulse=%ims, nSLEEP GPIO=%s",
                         self.pulse_ms,
                         self.nsleep_gpio != nil ? str(self.nsleep_gpio) : "none"))
  end

  #- nSLEEP via direct gpio. true = awake (HIGH), false = sleep (LOW). -#
  def _set_nsleep(awake)
    if self.nsleep_gpio == nil return end
    gpio.digital_write(self.nsleep_gpio, awake ? gpio.HIGH : gpio.LOW)
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
  def _pulse_latching(rl, set_state)
    if !self.wire return false end
    var pins = self.relay_pins.find(rl)
    if pins == nil return false end
    if self.pulsing
      print(string.format("Relay: pulse busy, ignoring RL%i", rl))
      return false
    end

    self.pulsing = true

    var in1 = pins[0]
    var in2 = pins[1]
    var pulse_val = set_state ? (1 << in1) : (1 << in2)

    self._set_nsleep(true)
    tasmota.delay(1)

    if !self._write_output(pulse_val)
      self._set_nsleep(false)
      self.pulsing = false
      return false
    end

    tasmota.delay(self.pulse_ms)

    self._write_output(0x00)
    tasmota.delay(1)
    self._set_nsleep(false)

    self.pulsing = false
    print(string.format("Relay: RL%i %s pulsed (%ims)", rl, set_state ? "SET" : "RESET", self.pulse_ms))
    return true
  end

  def _get_spst(rs)
    var powers = tasmota.get_power()
    if powers == nil || size(powers) < rs return nil end
    return powers[rs - 1] ? true : false
  end

  #- Set output. CH1-4 = RS1-4 (SPST), CH5-8 = RL1-4 (latching).
   - Returns true if applied (latching: if software mirror changed), else false/nil. -#
  def set_output(channel, state)
    if channel < 1 || channel > 8 return nil end
    var new_state = state ? true : false

    if channel <= 4
      tasmota.set_power(channel - 1, new_state)
      print(string.format("Relay: RS%i set to %s", channel, new_state ? "ON" : "OFF"))
      return true
    end

    var rl = channel - 4
    if !self._pulse_latching(rl, new_state)
      return false
    end

    var changed = self.latching_states.find(rl) != new_state
    self.latching_states[rl] = new_state
    return changed
  end

  def set_spst(rs, state)
    if rs < 1 || rs > 4 return nil end
    return self.set_output(rs, state)
  end

  def set_latching(rl, state)
    if rl < 1 || rl > 4 return nil end
    return self.set_output(rl + 4, state)
  end

  #- SPST from Tasmota Power; latching from software mirror (no I2C readback). -#
  def get_output(channel)
    if channel < 1 || channel > 8 return nil end
    if channel <= 4
      return self._get_spst(channel)
    end
    return self.latching_states.find(channel - 4)
  end

  #- Restore latching mirror from RL1-RL4 bitmask without pulsing hardware. -#
  def load_states(bitmask)
    if bitmask == nil return end
    var rl = 1
    while rl <= 4
      self.latching_states[rl] = (bitmask & (1 << (rl - 1))) != 0
      rl += 1
    end
  end

  #- Pack latching software mirror into an RL1-RL4 bitmask. -#
  def states_bitmask()
    var bitmask = 0
    var rl = 1
    while rl <= 4
      if self.latching_states.find(rl)
        bitmask = bitmask | (1 << (rl - 1))
      end
      rl += 1
    end
    return bitmask
  end

  def web_sensor()
    var msg = ""
    var on = nil
    var i = 1
    while i <= 4
      on = self._get_spst(i)
      if on != nil
        msg += string.format("{s}RS%d{m}%s{e}", i, on ? "ON" : "OFF")
      end
      i += 1
    end

    i = 1
    while i <= 4
      on = self.latching_states.find(i)
      msg += string.format("{s}RL%d{m}%s{e}", i, on ? "ON" : "OFF")
      i += 1
    end

    if size(msg) > 0
      tasmota.web_send_decimal(msg)
    end
  end

  def json_append()
    var msg = ",\"Relay\":{"
    var first = true
    var on = nil
    var i = 1
    while i <= 4
      on = self._get_spst(i)
      if on != nil
        if !first msg += "," end
        first = false
        msg += string.format("\"RS%d\":%d", i, on ? 1 : 0)
      end
      i += 1
    end

    i = 1
    while i <= 4
      if !first msg += "," end
      first = false
      on = self.latching_states.find(i)
      msg += string.format("\"RL%d\":%d", i, on ? 1 : 0)
      i += 1
    end

    msg += "}"
    tasmota.response_append(msg)
  end
end

global.relay = IoTextraRelay(IOEXPANDER_ADDRESS, NSLEEP_GPIO, PULSE_MS)
tasmota.add_driver(global.relay)
