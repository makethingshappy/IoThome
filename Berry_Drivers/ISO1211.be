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
 - SCOPE: sampled-mode channels only (90V DC, 110V AC, 220V AC), where
 -        the JM jumper is OPEN and FGND is switched by a HOST connector
 -        pin through a TLP188 optocoupler.
 -        Direct-mode channels (12-60V DC, JM closed) are ordinary DI
 -        channels and are NOT handled here - use the standard DI driver
 -        (e.g. TCA9534.be) for those.
 -
 - The driver pulses FGND ON only for the time needed to obtain a stable
 - reading (t_settle), reads the ISO1211 OUT pin, then switches FGND OFF
 - again. The whole sequence is non-blocking. Channels are scanned one at
 - a time (round-robin) so only a single FGND is ever asserted, keeping
 - average power dissipation low.
 - ================================================================== -#

#- =========================================================
 - Author: Arshia Keshvari
 - Role: Independent Developer, Engineer, and Project Author
 - GitHub: @TeslaNeuro
 - MakeThingsHappy.io
 - Last Updated: 2026-06-07
 - ========================================================= -#

import string
import global

#- ===========================================================
 - User configuration - edit to match your board / wiring
 - =========================================================== -#

#- t_settle: universal settle time for ALL sampled-mode ranges.
 - Covers the RC settling time of the input circuit and provides a
 - conservative inter-measurement interval that limits average power
 - dissipation. Generous on purpose to tolerate AC mains instability.
 - Increase for noisier installations; decrease only if you understand
 - the thermal implications (see IoTextra DI Driver Spec, section 4.2). -#
var ISO1211_T_SETTLE = 25      #- milliseconds -#

#- How often a full scan round of all channels is started (milliseconds).
 - Must be comfortably larger than (number_of_channels * t_settle). -#
var ISO1211_SCAN_PERIOD = 1000

#- FGND polarity. true  -> drive GPIO HIGH to turn TLP188 ON (assert FGND)
 -                false -> drive GPIO LOW  to turn TLP188 ON (assert FGND)
 - "De-asserted" (TLP188 OFF / safe) is always the opposite level. -#
var ISO1211_FGND_ACTIVE_HIGH = true

#- ---------------------------------------------------------------------
 - Per-channel configuration.
 -
 - Each entry is a sampled-mode ISO1211 channel. Compared with a standard
 - DI channel, the ONLY mandatory extra parameter is "fgnd_gpio".
 -
 -   name        (string)  Friendly label used in MQTT / web output.
 -   fgnd_gpio   (int)     HOST connector ESP GPIO controlling TLP188
 -                         (FGND switching). REQUIRED - JM jumper is open,
 -                         so FGND is controlled exclusively by this GPIO.
 -   out_source  (string)  How the ISO1211 OUT pin is read:
 -                           "gpio" -> direct MCU pin   (needs out_gpio)
 -                           "i2c"  -> TCA9534 expander  (needs i2c_addr + i2c_bit)
 -   out_gpio    (int)     ESP GPIO wired to ISO1211 OUT   (out_source == "gpio")
 -   i2c_addr    (int)     TCA9534/TCA9534A address        (out_source == "i2c")
 -   i2c_bit     (int)     P-bit (0..7) on the expander    (out_source == "i2c")
 -   invert_out  (bool)    OPTIONAL. Inverts the raw OUT reading to obtain
 -                         the logical DI value. Defaults: gpio -> false,
 -                         i2c (TCA9534 active-low) -> true.
 - --------------------------------------------------------------------- -#
var ISO1211_CHANNELS = [
  {
    "name":       "ISO1211_CH1",
    "fgnd_gpio":  25,          #- TLP188 control pin for channel 1 -#
    "out_source": "gpio",
    "out_gpio":   26           #- ISO1211 OUT read on this MCU pin -#
  },
  {
    "name":       "ISO1211_CH2",
    "fgnd_gpio":  27,          #- TLP188 control pin for channel 2 -#
    "out_source": "i2c",
    "i2c_addr":   0x27,        #- TCA9534/TCA9534A address -#
    "i2c_bit":    1            #- expander P-bit carrying this channel's OUT -#
  }
]

#- ===========================================================
 - Driver implementation
 - =========================================================== -#

class ISO1211 : Driver

  static var INPUT_PORT_REGISTER = 0x00   #- TCA9534 input port register -#

  var channels        #- list of validated channel state maps -#
  var busy            #- true while a scan round is in progress -#
  var scan_index      #- index of the channel currently being sampled -#
  var gpio_ok         #- true if the gpio module is available -#

  def init()
    import gpio

    #- ----------------------------------------------------------------
     - CRITICAL SAFETY REQUIREMENT (spec section 4.3):
     - The ABSOLUTE FIRST action is to de-assert every fgnd_gpio so the
     - TLP188s are OFF. HOST connector pins are undefined at power-on; if
     - left floating the ISO1211 may be powered at full field voltage
     - (up to 220V AC) before any measurement, causing overheating.
     - This is done from the RAW config, before any other initialisation.
     - ---------------------------------------------------------------- -#
    self.gpio_ok = (gpio != nil)
    if self.gpio_ok
      for cfg : ISO1211_CHANNELS
        var pin = cfg.find("fgnd_gpio")
        if pin != nil
          try
            gpio.pin_mode(pin, gpio.OUTPUT)
            gpio.digital_write(pin, self._fgnd_off_level())
          except .. as e, m
            print(string.format("ISO1211: failed to de-assert FGND gpio %s (%s: %s)", str(pin), str(e), str(m)))
          end
        end
      end
      print("ISO1211: all FGND GPIOs de-asserted (TLP188 OFF) at startup")
    else
      print("ISO1211: gpio module unavailable - cannot drive FGND, driver disabled")
    end

    #- Now it is safe to build and validate per-channel state. -#
    self.channels = []
    self.busy = false
    self.scan_index = 0

    for cfg : ISO1211_CHANNELS
      var ch = self._validate(cfg)
      if ch != nil
        self.channels.push(ch)
      end
    end

    print(string.format("ISO1211: %i sampled-mode channel(s) configured, t_settle=%ims",
                         size(self.channels), ISO1211_T_SETTLE))
  end

  #- Level that switches a TLP188 OFF (FGND disconnected / safe). -#
  def _fgnd_off_level()
    return ISO1211_FGND_ACTIVE_HIGH ? 0 : 1
  end

  #- Level that switches a TLP188 ON (FGND connected / measuring). -#
  def _fgnd_on_level()
    return ISO1211_FGND_ACTIVE_HIGH ? 1 : 0
  end

  #- Validate one raw config entry. Returns a channel state map on success,
   - or nil (with a descriptive error printed) on invalid configuration. -#
  def _validate(cfg)
    import gpio

    var name = cfg.find("name", "ISO1211")

    #- fgnd_gpio is mandatory for every sampled-mode channel. -#
    var fgnd = cfg.find("fgnd_gpio")
    if fgnd == nil || type(fgnd) != "int" || fgnd < 0
      print(string.format("ISO1211: [%s] rejected - missing or invalid 'fgnd_gpio'", name))
      return nil
    end

    var src = cfg.find("out_source")
    if src != "gpio" && src != "i2c"
      print(string.format("ISO1211: [%s] rejected - 'out_source' must be 'gpio' or 'i2c'", name))
      return nil
    end

    var ch = {
      "name":      name,
      "fgnd_gpio": fgnd,
      "source":    src,
      "value":     nil,        #- last confirmed DI value (0/1), nil = unknown -#
      "error":     false,      #- per-channel error flag -#
      "invert":    cfg.find("invert_out", src == "i2c")
    }

    if src == "gpio"
      var op = cfg.find("out_gpio")
      if op == nil || type(op) != "int" || op < 0
        print(string.format("ISO1211: [%s] rejected - 'out_gpio' required for gpio out_source", name))
        return nil
      end
      ch["out_gpio"] = op
      if self.gpio_ok
        try
          gpio.pin_mode(op, gpio.INPUT)
        except .. as e, m
          print(string.format("ISO1211: [%s] could not set OUT gpio %i as input (%s)", name, op, str(m)))
        end
      end

    else  #- i2c -#
      var addr = cfg.find("i2c_addr")
      var bit  = cfg.find("i2c_bit")
      if addr == nil || type(addr) != "int"
        print(string.format("ISO1211: [%s] rejected - 'i2c_addr' required for i2c out_source", name))
        return nil
      end
      if bit == nil || type(bit) != "int" || bit < 0 || bit > 7
        print(string.format("ISO1211: [%s] rejected - 'i2c_bit' must be 0..7 for i2c out_source", name))
        return nil
      end
      ch["i2c_addr"] = addr
      ch["i2c_bit"]  = bit
      #- Locate the I2C bus carrying this expander once, up front. -#
      ch["wire"] = tasmota.wire_scan(addr)
      if ch["wire"]
        print(string.format("ISO1211: [%s] OUT via TCA9534 0x%02X bit P%i on bus %i",
                             name, addr, bit, ch["wire"].bus))
      else
        ch["error"] = true
        print(string.format("ISO1211: [%s] TCA9534 not found at 0x%02X - channel marked error", name, addr))
      end
    end

    return ch
  end

  #- ----------------------------------------------------------------
   - Non-blocking round-robin scan.
   - Tasmota ticks every_second() -> we start one round. Each channel is
   - sampled with a single FGND pulse; the t_settle wait uses set_timer
   - (asynchronous, no blocking sleep). When a channel finishes it chains
   - to the next, so exactly one FGND is asserted at any moment.
   - ---------------------------------------------------------------- -#
  def every_second()
    if !self.gpio_ok return end
    if self.busy return end                 #- previous round still running -#
    if size(self.channels) == 0 return end

    self.busy = true
    self.scan_index = 0
    self._sample_channel(0)
  end

  #- Assert FGND for one channel, then schedule the read after t_settle. -#
  def _sample_channel(idx)
    import gpio

    if idx >= size(self.channels)
      #- Round complete. -#
      self.busy = false
      self._publish()
      return
    end

    var ch = self.channels[idx]

    #- Skip channels flagged with a configuration / hardware error, but
     - keep advancing the round so healthy channels still get sampled. -#
    if ch["error"] && ch["source"] == "i2c" && ch["wire"] == nil
      self._sample_channel(idx + 1)
      return
    end

    #- Assert FGND (TLP188 ON) for this channel only. -#
    try
      gpio.digital_write(ch["fgnd_gpio"], self._fgnd_on_level())
    except .. as e, m
      ch["error"] = true
      print(string.format("ISO1211: [%s] FGND assert failed (%s)", ch["name"], str(m)))
      self._sample_channel(idx + 1)
      return
    end

    #- Wait t_settle WITHOUT blocking, then read + de-assert + advance. -#
    tasmota.set_timer(ISO1211_T_SETTLE, def () self._finish_channel(idx) end)
  end

  #- Read OUT, de-assert FGND, store the DI value, then move on. -#
  def _finish_channel(idx)
    import gpio

    var ch = self.channels[idx]
    var raw = self._read_out(ch)

    #- De-assert FGND immediately after the read (TLP188 OFF). -#
    try
      gpio.digital_write(ch["fgnd_gpio"], self._fgnd_off_level())
    except .. as e, m
      ch["error"] = true
      print(string.format("ISO1211: [%s] FGND de-assert failed (%s)", ch["name"], str(m)))
    end

    if raw == nil
      ch["error"] = true
    else
      ch["error"] = false
      var di = ch["invert"] ? (raw ^ 0x01) : raw
      ch["value"] = di
    end

    #- Chain to the next channel (still non-blocking). -#
    self._sample_channel(idx + 1)
  end

  #- Read the raw ISO1211 OUT level for a channel. Returns 0/1 or nil on error. -#
  def _read_out(ch)
    import gpio

    if ch["source"] == "gpio"
      try
        return gpio.digital_read(ch["out_gpio"]) ? 1 : 0
      except .. as e, m
        print(string.format("ISO1211: [%s] OUT gpio read failed (%s)", ch["name"], str(m)))
        return nil
      end
    else  #- i2c via TCA9534 -#
      var wire = ch["wire"]
      if wire == nil return nil end
      var r = wire.read(ch["i2c_addr"], self.INPUT_PORT_REGISTER, 1)
      if r == nil return nil end
      return (r >> ch["i2c_bit"]) & 0x01
    end
  end

  #- ----------------------------------------------------------------
   - Publish DI values to MQTT using Tasmota's standard topic structure.
   - Pushed to the RESULT topic (stat/<topic>/RESULT) at the end of each
   - scan round; also exposed through json_append (tele/.../SENSOR) and
   - the web UI.
   - ---------------------------------------------------------------- -#
  def _publish()
    if size(self.channels) == 0 return end
    var payload = "{\"ISO1211\":" + self._values_json() + "}"
    tasmota.publish_result(payload, "RESULT")
  end

  #- Build the JSON object body shared by RESULT, SENSOR and tele output. -#
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
   - on demand (e.g. from the console: iso1211.measure(1)). 1-based channel
   - number. Does not run a full round - only the requested channel is pulsed. -#
  def measure(channel)
    import gpio
    if !self.gpio_ok return nil end
    if channel < 1 || channel > size(self.channels) return nil end
    if self.busy return nil end

    var idx = channel - 1
    var ch = self.channels[idx]
    if ch["source"] == "i2c" && ch["wire"] == nil return nil end

    self.busy = true
    try
      gpio.digital_write(ch["fgnd_gpio"], self._fgnd_on_level())
    except .. as e, m
      ch["error"] = true
      self.busy = false
      print(string.format("ISO1211: [%s] FGND assert failed (%s)", ch["name"], str(m)))
      return nil
    end

    tasmota.set_timer(ISO1211_T_SETTLE, def ()
      var raw = self._read_out(ch)
      try
        gpio.digital_write(ch["fgnd_gpio"], self._fgnd_off_level())
      except .. as e, m
        ch["error"] = true
      end
      if raw == nil
        ch["error"] = true
      else
        ch["error"] = false
        ch["value"] = ch["invert"] ? (raw ^ 0x01) : raw
      end
      self.busy = false
      self._publish()
    end)
  end
end

global.iso1211 = ISO1211()
tasmota.add_driver(global.iso1211)
