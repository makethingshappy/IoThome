#- ==================================================================
 - <!> ISO1211.be Driver Currently In Development (Not Ready for use)
 - ================================================================== -#

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
 - Tasmota ISO1211 sampled-mode Digital Input driver written in Berry
 - For IoTextra Quadro (and compatible) ISO1211 channels.
 -
 - SCOPE: sampled-mode channels only (90V DC, 110V AC, 220V AC), where the
 -        JM jumper is OPEN and FGND is switched by a HOST connector pin
 -        through a TLP188 optocoupler.
 -        Direct-mode channels (12-60V DC, JM closed) are ordinary DI
 -        channels - use the standard DI driver (TCA9534.be) for those.
 -
 - I/O ACCESS mirrors TCA9534.be exactly - it is the proven IoThome DI
 - access layer, so this driver does NOT reinvent it:
 -   * "i2c"  mode -> TCA9534/TCA9534A I/O expander registers.
 -   * "gpio" mode -> Tasmota template assignments (set_power / get_switch).
 -
 - Each sampled-mode ISO1211 channel uses two I/O channels on that layer:
 -   * fgnd_channel - an OUTPUT  controlling the TLP188 (FGND switching).
 -   * out_channel  - an INPUT   reading the ISO1211 OUT pin (the DI value).
 -
 - To take a reading the driver pulses FGND ON only for the time needed to
 - obtain a stable reading (t_settle), reads OUT, then switches FGND OFF.
 - The whole sequence is non-blocking and channels are scanned one at a
 - time so only a single FGND is ever asserted (low average power).
 - ================================================================== -#

#- =========================================================
 - Author: Arshia Keshvari
 - Role: Independent Developer, Engineer, and Project Author
 - GitHub: @TeslaNeuro
 - MakeThingsHappy.io
 - Last Updated: 2026-06-08
 - ========================================================= -#

import string
import global

#- ===========================================================
 - User Configuration - change these to match your board
 - =========================================================== -#

var IOEXPANDER_ADDRESS = 0x27     #- TCA9534 0x20-0x27 / TCA9534A 0x38-0x3F (i2c mode only) -#
var HARDWARE_MODE      = "i2c"    #- "i2c" (via TCA9534) or "gpio" (Tasmota template) -#

#- t_settle: universal settle time for ALL sampled-mode ranges. Covers the
 - RC settling time of the input circuit and provides a conservative inter-
 - measurement interval that limits average power dissipation. Generous on
 - purpose to tolerate AC mains instability. Decrease only if you understand
 - the thermal implications (IoTextra DI Driver Spec, section 4.2). -#
var ISO1211_T_SETTLE = 25         #- milliseconds -#

#- ---------------------------------------------------------------------
 - Per-channel configuration. Each entry is ONE sampled-mode ISO1211
 - channel, defined by two I/O channels on the TCA9534 / Tasmota template:
 -
 -   name          (string)  Friendly label used in MQTT / web output.
 -   fgnd_channel   (int 1-8) OUTPUT channel controlling the TLP188 (FGND).
 -                            This is the parameter specific to sampled mode.
 -   out_channel    (int 1-8) INPUT channel reading the ISO1211 OUT pin.
 -
 - Channel numbers are 1-8 and map exactly like TCA9534.be:
 -   i2c  -> P0..P7 on the expander.
 -   gpio -> Relay order (outputs) / Switch order (inputs) in the template.
 -
 - Example below matches IoTextra Quadro (two ISO1211 channels). Adjust the
 - channel numbers to your board schematic / Tasmota template.
 - --------------------------------------------------------------------- -#
var ISO1211_CHANNELS = [
  {"name": "ISO1211_CH1", "fgnd_channel": 5, "out_channel": 1},
  {"name": "ISO1211_CH2", "fgnd_channel": 6, "out_channel": 2}
]

#- ===========================================================
 - Driver implementation
 - =========================================================== -#

class ISO1211 : Driver

  # TCA9534 registers (same as TCA9534.be)
  var INPUT_PORT_REGISTER
  var OUTPUT_PORT_REGISTER
  var CONFIG_REGISTER

  var wire              #- if wire == nil then the i2c module is not initialized -#
  var i2cAddress
  var hardware_mode
  var pinConfig         #- 1 = input (out_channel), 0 = output (fgnd_channel) -#
  var output_pin_state  #- tracks output pins on the firmware (active-low) -#

  var channels          #- validated list of sampled-mode channel state maps -#
  var busy              #- true while a non-blocking scan round is running -#

  def init(i2cAddress, hardware_mode, channels)
    self.i2cAddress = i2cAddress
    self.hardware_mode = hardware_mode
    self.output_pin_state = 0xFF  #- all outputs off initially (active-low) -#
    self.busy = false

    self.INPUT_PORT_REGISTER  = 0x00
    self.OUTPUT_PORT_REGISTER = 0x01
    self.CONFIG_REGISTER      = 0x03

    #- Validate channels and build the pin-direction bitmask:
     - out_channel -> input (1), fgnd_channel -> output (0). -#
    self.channels = []
    self.pinConfig = 0
    for cfg : channels
      var ch = self._validate(cfg)
      if ch != nil
        self.channels.push(ch)
        self.pinConfig = self.pinConfig | (0x01 << (ch["out_channel"] - 1))  #- mark OUT as input -#
      end
    end

    #- Bring up the chosen I/O backend (identical approach to TCA9534.be). -#
    if self.hardware_mode == "i2c"
      self.wire = tasmota.wire_scan(self.i2cAddress)
      if self.wire
        self.wire._begin_transmission(self.i2cAddress)
        self.wire._write(self.CONFIG_REGISTER)
        self.wire._write(self.pinConfig)
        self.wire._end_transmission()
        print(string.format("ISO1211: I/O Expander detected at 0x%02X on bus %i", self.i2cAddress, self.wire.bus))
        print(string.format("ISO1211: pin directions bitmask 0x%02X (1=OUT input, 0=FGND output)", self.pinConfig))
      else
        print(string.format("ISO1211: I/O Expander not found at address 0x%02X", self.i2cAddress))
      end
    elif self.hardware_mode == "gpio"
      print("ISO1211: Initializing in GPIO mode (Tasmota template assignments)")
    else
      print("ISO1211: invalid hardware mode, must be 'i2c' or 'gpio'")
    end

    #- ----------------------------------------------------------------
     - CRITICAL SAFETY REQUIREMENT (spec section 4.3):
     - As the first action after the I/O backend is ready, de-assert every
     - FGND output (TLP188 OFF). HOST connector pins are undefined at power-
     - on; a floating fgnd could power the ISO1211 at full field voltage
     - (up to 220V AC) before any measurement, causing overheating.
     - ---------------------------------------------------------------- -#
    for ch : self.channels
      self.set_output(ch["fgnd_channel"], false)
    end
    print(string.format("ISO1211: %i sampled-mode channel(s) ready, all FGND de-asserted, t_settle=%ims",
                         size(self.channels), ISO1211_T_SETTLE))
  end

  #- Validate one raw config entry. Returns a channel state map or nil
   - (with a descriptive error printed) on invalid configuration. -#
  def _validate(cfg)
    var name = cfg.find("name", "ISO1211")

    var fgnd = cfg.find("fgnd_channel")
    if fgnd == nil || type(fgnd) != "int" || fgnd < 1 || fgnd > 8
      print(string.format("ISO1211: [%s] rejected - 'fgnd_channel' must be an integer 1..8", name))
      return nil
    end

    var out = cfg.find("out_channel")
    if out == nil || type(out) != "int" || out < 1 || out > 8
      print(string.format("ISO1211: [%s] rejected - 'out_channel' must be an integer 1..8", name))
      return nil
    end

    if fgnd == out
      print(string.format("ISO1211: [%s] rejected - 'fgnd_channel' and 'out_channel' must differ", name))
      return nil
    end

    return {
      "name":         name,
      "fgnd_channel": fgnd,
      "out_channel":  out,
      "value":        nil,    #- last confirmed DI value (0/1), nil = unknown -#
      "error":        false   #- per-channel error flag -#
    }
  end

  #- ----------------------------------------------------------------
   - Output (FGND) control - mirrors TCA9534.be set_output(). Active-low,
   - so state true ("assert"/TLP188 ON) clears the bit, state false
   - ("de-assert"/TLP188 OFF) sets it. Polarity can be flipped in the
   - Tasmota template (REL_INV) or in hardware if your board differs.
   - ---------------------------------------------------------------- -#
  def set_output(channel, output_state)
    if channel < 1 || channel > 8 return nil end

    #- reject pins configured as input (1 in pinConfig) -#
    if (self.pinConfig >> (channel - 1)) & 0x01
      print(string.format("ISO1211: channel %i is an input, cannot drive FGND", channel))
      return nil
    end

    if self.hardware_mode == "i2c"
      if !self.wire return nil end
      if self.output_pin_state == nil return nil end

      var pin_index = channel - 1
      if output_state
        self.output_pin_state = self.output_pin_state & ~(1 << pin_index)
      else
        self.output_pin_state = self.output_pin_state | (1 << pin_index)
      end

      self.wire._begin_transmission(self.i2cAddress)
      self.wire._write(self.OUTPUT_PORT_REGISTER)
      self.wire._write(self.output_pin_state)
      self.wire._end_transmission()

    elif self.hardware_mode == "gpio"
      #- Count how many output channels exist BEFORE this channel -> relay index -#
      var relay_idx = 0
      for i:0..(channel - 2)
        if ((self.pinConfig >> i) & 0x01) == 0  #- is output -#
          relay_idx = relay_idx + 1
        end
      end
      tasmota.set_power(relay_idx, output_state)
    end

    return output_state
  end

  #- Read a single INPUT (OUT) channel. Mirrors TCA9534.be read_all_inputs()
   - logic (active-low invert in i2c, Tasmota switch in gpio). Returns 0/1,
   - or nil on error. -#
  def read_input(channel)
    if channel < 1 || channel > 8 return nil end

    if self.hardware_mode == "i2c"
      if !self.wire return nil end
      var r = self.wire.read(self.i2cAddress, self.INPUT_PORT_REGISTER, 1)
      if r == nil return nil end
      var state = (r >> (channel - 1)) & 0x01
      #- active-low hardware: 0 = signal present, so invert (same as TCA9534) -#
      return state ^ 0x01

    elif self.hardware_mode == "gpio"
      var switches = tasmota.get_switch()
      var i = channel - 1
      if switches && size(switches) > i
        return switches[i] ? 1 : 0
      end
      return nil
    end

    return nil
  end

  #- ----------------------------------------------------------------
   - Non-blocking round-robin scan (spec sections 4.4 / 5).
   - every_second() starts a round; each channel is sampled with a single
   - FGND pulse. The t_settle wait uses tasmota.set_timer (asynchronous, no
   - blocking sleep), and channels chain one after another so only one FGND
   - is asserted at any moment.
   - ---------------------------------------------------------------- -#
  def every_second()
    if self.busy return end
    if size(self.channels) == 0 return end
    self.busy = true
    self._sample_channel(0)
  end

  #- Assert FGND for one channel, then schedule the read after t_settle. -#
  def _sample_channel(idx)
    if idx >= size(self.channels)
      self.busy = false
      self._publish()
      return
    end

    var ch = self.channels[idx]

    #- Assert FGND (TLP188 ON) for this channel only. -#
    self.set_output(ch["fgnd_channel"], true)

    #- Wait t_settle WITHOUT blocking, then read + de-assert + advance. -#
    tasmota.set_timer(ISO1211_T_SETTLE, def () self._finish_channel(idx) end)
  end

  #- Read OUT, de-assert FGND, store the DI value, then move on. -#
  def _finish_channel(idx)
    var ch = self.channels[idx]
    var di = self.read_input(ch["out_channel"])

    #- De-assert FGND immediately after the read (TLP188 OFF). -#
    self.set_output(ch["fgnd_channel"], false)

    if di == nil
      ch["error"] = true
    else
      ch["error"] = false
      ch["value"] = di
    end

    self._sample_channel(idx + 1)
  end

  #- ----------------------------------------------------------------
   - Publish DI values to MQTT using Tasmota's standard topic structure.
   - Pushed to the RESULT topic (stat/<topic>/RESULT) at the end of each
   - scan round; also exposed through json_append (tele/.../SENSOR) and the
   - web UI.
   - ---------------------------------------------------------------- -#
  def _publish()
    if size(self.channels) == 0 return end
    tasmota.publish_result("{\"ISO1211\":" + self._values_json() + "}", "RESULT")
  end

  #- Build the JSON object body shared by RESULT, SENSOR and web output. -#
  def _values_json()
    var msg = "{"
    var first = true
    for ch : self.channels
      if !first msg += "," end
      first = false
      var v = ch["error"] ? "null" : (ch["value"] == nil ? "null" : str(ch["value"]))
      msg += string.format("\"%s\":{\"DI\":%s,\"error\":%s}",
                           ch["name"], v, ch["error"] ? "true" : "false")
    end
    msg += "}"
    return msg
  end

  #- Add ISO1211 data to Tasmota's periodic SENSOR telemetry. -#
  def json_append()
    if size(self.channels) == 0 return end
    tasmota.response_append(",\"ISO1211\":" + self._values_json())
  end

  #- Web UI: one row per channel. -#
  def web_sensor()
    if size(self.channels) == 0 return end
    var msg = ""
    for ch : self.channels
      var txt
      if ch["error"]
        txt = "ERROR"
      elif ch["value"] == nil
        txt = "---"
      else
        txt = ch["value"] == 1 ? "HIGH" : "LOW"
      end
      msg += string.format("{s}%s DI{m}%s{e}", ch["name"], txt)
    end
    tasmota.web_send_decimal(msg)
  end

  #- Public helper: trigger a single non-blocking measurement of ONE channel
   - on demand (e.g. from the console: iso1211.measure(1)). 1-based index
   - into ISO1211_CHANNELS. Only the requested channel is pulsed. -#
  def measure(channel)
    if channel < 1 || channel > size(self.channels) return nil end
    if self.busy return nil end

    var idx = channel - 1
    var ch = self.channels[idx]
    self.busy = true
    self.set_output(ch["fgnd_channel"], true)

    tasmota.set_timer(ISO1211_T_SETTLE, def ()
      var di = self.read_input(ch["out_channel"])
      self.set_output(ch["fgnd_channel"], false)
      if di == nil
        ch["error"] = true
      else
        ch["error"] = false
        ch["value"] = di
      end
      self.busy = false
      self._publish()
    end)
  end
end

global.iso1211 = ISO1211(IOEXPANDER_ADDRESS, HARDWARE_MODE, ISO1211_CHANNELS)
tasmota.add_driver(global.iso1211)
