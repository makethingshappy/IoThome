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
 - Each sampled-mode ISO1211 channel uses:
 -   * fgnd_relay  - FGND switching (TLP188). ALWAYS a Tasmota GPIO/relay
 -                   driven via set_power (template based). FGND is GPIO-only;
 -                   it is NEVER driven through the I2C expander. This is the
 -                   parameter specific to sampled mode (spec section 4.1).
 -   * out_channel - the ISO1211 OUT pin (the DI value). HOW it is read is set
 -                   globally by OUT_SOURCE, mirroring TCA9534.be:
 -                     "i2c"  -> TCA9534/TCA9534A input register.
 -                     "gpio" -> Tasmota template switch (get_switch).
 -
 - To take a reading the driver pulses FGND ON only for the time needed to
 - obtain a stable reading (t_settle), reads OUT, then switches FGND OFF.
 - The whole sequence is non-blocking and channels are scanned one at a time
 - so only a single FGND is ever asserted (low average power).
 - ================================================================== -#

#- =========================================================
 - Author: Arshia Keshvari
 - Role: Independent Developer, Engineer, and Project Author
 - GitHub: @TeslaNeuro
 - MakeThingsHappy.io
 - Last Updated: 2026-06-13
 - ========================================================= -#

import string
import global

#- ===========================================================
 - User Configuration - change these to match your board
 - =========================================================== -#

#- How the ISO1211 OUT pin is read (FGND is ALWAYS gpio - see below):
 -   "i2c"  -> OUT read from a TCA9534/TCA9534A input register.
 -   "gpio" -> OUT read from a Tasmota template switch (get_switch). -#
var OUT_SOURCE = "i2c"

#- TCA9534 / TCA9534A address (used only when OUT_SOURCE == "i2c"). -#
var IOEXPANDER_ADDRESS = 0x27     #- TCA9534 0x20-0x27 / TCA9534A 0x38-0x3F -#

#- t_settle: universal settle time for ALL sampled-mode ranges. Covers the
 - RC settling time of the input circuit and provides a conservative inter-
 - measurement interval that limits average power dissipation. Generous on
 - purpose to tolerate AC mains instability. Decrease only if you understand
 - the thermal implications (IoTextra DI Driver Spec, section 4.2). -#
var ISO1211_T_SETTLE = 25         #- milliseconds -#

#- ---------------------------------------------------------------------
 - Per-channel configuration. Each entry is ONE sampled-mode ISO1211 channel.
 -
 -   name         (string)  Friendly label used in MQTT / web output.
 -   fgnd_relay   (int >=1)  Tasmota relay number (1-based) that drives the
 -                           TLP188 / FGND for this channel, via set_power.
 -                           FGND is GPIO-only and template based. Assign the
 -                           HOST connector pin as a Relay in your template.
 -   out_channel  (int >=1)  The OUT input channel (1-based):
 -                             OUT_SOURCE "i2c"  -> TCA9534 P0..P7 (1..8).
 -                             OUT_SOURCE "gpio" -> Tasmota Switch order.
 -
 - Example below matches IoTextra Quadro (two ISO1211 channels). Adjust to
 - your board schematic / Tasmota template.
 - --------------------------------------------------------------------- -#
var ISO1211_CHANNELS = [
  {"name": "ISO1211_CH1", "fgnd_relay": 1, "out_channel": 1},
  {"name": "ISO1211_CH2", "fgnd_relay": 2, "out_channel": 2}
]

#- ===========================================================
 - Driver implementation
 - =========================================================== -#

class ISO1211 : Driver

  # TCA9534 registers (same as TCA9534.be) - used only for OUT_SOURCE "i2c"
  var INPUT_PORT_REGISTER
  var CONFIG_REGISTER

  var wire              #- if wire == nil then the i2c expander is not initialized -#
  var i2cAddress
  var out_source

  var channels          #- validated list of sampled-mode channel state maps -#
  var busy              #- true while a non-blocking scan round is running -#

  def init(out_source, i2cAddress, channels)
    self.out_source = out_source
    self.i2cAddress = i2cAddress
    self.busy = false

    self.INPUT_PORT_REGISTER = 0x00
    self.CONFIG_REGISTER     = 0x03

    #- Validate the channel list. -#
    self.channels = []
    for cfg : channels
      var ch = self._validate(cfg)
      if ch != nil
        self.channels.push(ch)
      end
    end

    #- Bring up the OUT reading backend (FGND never uses the expander). -#
    if self.out_source == "i2c"
      self.wire = tasmota.wire_scan(self.i2cAddress)
      if self.wire
        #- This expander is read-only here (OUT inputs), so configure all
         - pins as inputs (TCA9534: 1 = input). -#
        self.wire._begin_transmission(self.i2cAddress)
        self.wire._write(self.CONFIG_REGISTER)
        self.wire._write(0xFF)
        self.wire._end_transmission()
        print(string.format("ISO1211: OUT via TCA9534 0x%02X on bus %i (all pins input)", self.i2cAddress, self.wire.bus))
      else
        print(string.format("ISO1211: TCA9534 not found at 0x%02X - OUT reads will error", self.i2cAddress))
      end
    elif self.out_source == "gpio"
      print("ISO1211: OUT via Tasmota template switches (get_switch)")
    else
      print("ISO1211: invalid OUT_SOURCE, must be 'i2c' or 'gpio'")
    end

    #- ----------------------------------------------------------------
     - CRITICAL SAFETY REQUIREMENT (spec section 4.3):
     - As the first action, de-assert every FGND relay (TLP188 OFF). HOST
     - connector pins are undefined at power-on; a floating fgnd could power
     - the ISO1211 at full field voltage (up to 220V AC) before any
     - measurement, causing overheating. FGND is GPIO-only, so this is a
     - set_power(relay, false) on each channel.
     - ---------------------------------------------------------------- -#
    for ch : self.channels
      self.set_fgnd(ch, false)
    end
    print(string.format("ISO1211: %i sampled-mode channel(s) ready, all FGND de-asserted, t_settle=%ims",
                         size(self.channels), ISO1211_T_SETTLE))
  end

  #- Validate one raw config entry. Returns a channel state map or nil
   - (with a descriptive error printed) on invalid configuration. -#
  def _validate(cfg)
    var name = cfg.find("name", "ISO1211")

    var fgnd = cfg.find("fgnd_relay")
    if fgnd == nil || type(fgnd) != "int" || fgnd < 1
      print(string.format("ISO1211: [%s] rejected - 'fgnd_relay' must be an integer >= 1", name))
      return nil
    end

    var out = cfg.find("out_channel")
    if out == nil || type(out) != "int" || out < 1
      print(string.format("ISO1211: [%s] rejected - 'out_channel' must be an integer >= 1", name))
      return nil
    end
    if self.out_source == "i2c" && out > 8
      print(string.format("ISO1211: [%s] rejected - 'out_channel' must be 1..8 for i2c (P0..P7)", name))
      return nil
    end

    return {
      "name":        name,
      "fgnd_relay":  fgnd,
      "out_channel": out,
      "value":       nil,    #- last confirmed DI value (0/1), nil = unknown -#
      "error":       false   #- per-channel error flag -#
    }
  end

  #- ----------------------------------------------------------------
   - FGND control - GPIO ONLY, via Tasmota set_power (template based).
   - state true  = assert   (TLP188 ON,  FGND connected, measuring)
   - state false = de-assert (TLP188 OFF, FGND disconnected, safe/idle)
   - Tasmota relays are 0-based, so relay N maps to set_power(N-1). Polarity
   - can be flipped in the template (Relay_i_INV) or in hardware if needed.
   - ---------------------------------------------------------------- -#
  def set_fgnd(ch, state)
    tasmota.set_power(ch["fgnd_relay"] - 1, state)
  end

  #- Read a channel's ISO1211 OUT pin. Returns 0/1, or nil on error.
   - Mirrors TCA9534.be read logic: active-low invert over i2c, Tasmota
   - switch in gpio mode. -#
  def read_out(ch)
    var channel = ch["out_channel"]

    if self.out_source == "i2c"
      if !self.wire return nil end
      var r = self.wire.read(self.i2cAddress, self.INPUT_PORT_REGISTER, 1)
      if r == nil return nil end
      var state = (r >> (channel - 1)) & 0x01
      #- active-low hardware: 0 = signal present, so invert (same as TCA9534) -#
      return state ^ 0x01

    elif self.out_source == "gpio"
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
    self.set_fgnd(ch, true)

    #- Wait t_settle WITHOUT blocking, then read + de-assert + advance. -#
    tasmota.set_timer(ISO1211_T_SETTLE, def () self._finish_channel(idx) end)
  end

  #- Read OUT, de-assert FGND, store the DI value, then move on. -#
  def _finish_channel(idx)
    var ch = self.channels[idx]
    var di = self.read_out(ch)

    #- De-assert FGND immediately after the read (TLP188 OFF). -#
    self.set_fgnd(ch, false)

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

    var ch = self.channels[channel - 1]
    self.busy = true
    self.set_fgnd(ch, true)

    tasmota.set_timer(ISO1211_T_SETTLE, def ()
      var di = self.read_out(ch)
      self.set_fgnd(ch, false)
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

global.iso1211 = ISO1211(OUT_SOURCE, IOEXPANDER_ADDRESS, ISO1211_CHANNELS)
tasmota.add_driver(global.iso1211)
