import json
import string

class ADS1115Data : Driver

  var convert_to_mv

  static var ADS_LIST = [
    "ADS1115-48",
    "ADS1115-49",
    "ADS1115-4A",
    "ADS1115-4B",
    "ADS1115",
  ]

  def ads1115()

    var sensors = json.load(tasmota.read_sensors())
    if sensors == nil return nil end

    var results = []

    var g = 6.144  # ADC Voltage Gain factor for ±6.144 range
    var hardware_g = 0.237619047619048  # Hardware gain factor from circuit design
    var v_p_b = g / 32768  # Volts per bit for ±6.144V range
	
    # Iterate ADS devices in fixed order
    for dev : ADS1115Data.ADS_LIST

      if sensors.contains(dev)

        var ads = sensors[dev]

        # Differential mode = only A0 & A1 exist
        for ch : ["A0","A1"]

          if ads.contains(ch)
            var raw = ads[ch]
            var mv = (raw * v_p_b) / hardware_g
            results.push(mv)
          end

        end

      end
    end

    if results.size() == 0 return nil end

    self.convert_to_mv = results
    return true

  end


  def every_second()
    if !self.ads1115 return nil end
    self.ads1115()
  end


  def web_sensor()

    if !self.convert_to_mv return nil end

    var msg = ""
    var idx = 0

    for val : self.convert_to_mv
      msg += string.format(
        "{s}ADS1115 Diff CH%d{m}%.3f V{e}",
        idx,
        val
      )
      idx += 1
    end

    tasmota.web_send_decimal(msg)

  end


  def json_append()

    if !self.convert_to_mv return nil end

    var msg = ",\"ADS1115Volts\":{"

    var idx = 0
    for val : self.convert_to_mv

      if idx > 0 msg += "," end

      msg += string.format("\"D%d\":%.3f", idx, val)

      idx += 1
    end

    msg += "}"

    tasmota.response_append(msg)

  end

end


ADS1115Data = ADS1115Data()
tasmota.add_driver(ADS1115Data)
