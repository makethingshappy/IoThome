#!/usr/bin/env python3
"""
Check an ESPHome GPIO config against the two host-map.yaml files it is built from
(module + carrier), and print the channel table for the devices.esphome.io page.

Usage:
  esphome_check.py MODULE_HOST_MAP CARRIER_HOST_MAP CONFIG.yaml [--table]

Checks (exit code 1 on any ERROR):
  - every module channel with a HOST line exists in the config under the same name
  - GPIO number == carrier host map (AP line -> GPIO)
  - inverted == (active: low)
  - entity kind: DI -> binary_sensor, outputs -> switch
  - I2C SDA/SCL == carrier host map
  - no extra GPIO entities in the config
  - module/carrier revision in host-map matches the version in the config file name
    (iotextra-<module>-v3-02-...-v2-01-...)
--table prints the Markdown table (two halves side by side) built from the host maps.
"""
import re
import sys

import yaml

OUTPUT_TYPES = {"npn", "mosfet", "ssr", "relay_spst", "relay_spdt", "relay"}
INPUT_TYPES = {"DI"}


class Loader(yaml.SafeLoader):
    pass


Loader.add_multi_constructor("!", lambda loader, suffix, node: None)


def load(path):
    with open(path, encoding="utf-8") as f:
        return yaml.load(f, Loader=Loader)


def gpio_num(value):
    m = re.fullmatch(r"(?:GPIO)?(\d+)", str(value))
    return int(m.group(1)) if m else None


def main(argv):
    table = "--table" in argv
    args = [a for a in argv if a != "--table"]
    if len(args) != 3:
        print(__doc__)
        return 2
    mod_path, car_path, cfg_path = args
    mod, car, cfg = load(mod_path), load(car_path), load(cfg_path)
    errors, notes = [], []

    host = {k: int(v) for k, v in car["host"].items() if re.fullmatch(r"AP\d", k)}
    channels = mod["channels"]

    # revision vs file name
    fn = cfg_path.replace("\\", "/").split("/")[-1]
    vers = re.findall(r"-v(\d+-\d+)", fn)
    if len(vers) == 2:
        for label, ver, rev in (("module", vers[0], str(mod["revision"])),
                                ("carrier", vers[1], str(car["revision"]))):
            if ver.replace("-", ".") != rev:
                errors.append(f"{label} revision: file name says {ver}, host-map says {rev}")
    else:
        errors.append(f"file name has no two -vX-XX versions: {fn}")

    # config entities
    entities = {}
    for kind in ("binary_sensor", "switch"):
        for item in cfg.get(kind) or []:
            if item.get("platform") != "gpio":
                continue
            pin = item["pin"]
            if isinstance(pin, dict):
                num, inv = gpio_num(pin.get("number")), bool(pin.get("inverted", False))
            else:
                num, inv = gpio_num(pin), False
            entities[item["name"]] = (kind, num, inv)

    checked = set()
    for name, ch in channels.items():
        ap, typ = ch.get("ap"), ch.get("type")
        if ap is None or (typ not in OUTPUT_TYPES and typ not in INPUT_TYPES):
            notes.append(f"skipped {name} (type {typ})")
            continue
        want_kind = "binary_sensor" if typ in INPUT_TYPES else "switch"
        want_gpio = host[ap]
        want_inv = ch.get("active") == "low"
        if name not in entities:
            errors.append(f"{name}: missing in config")
            continue
        kind, num, inv = entities[name]
        checked.add(name)
        if kind != want_kind:
            errors.append(f"{name}: is {kind}, host-map type {typ} needs {want_kind}")
        if num != want_gpio:
            errors.append(f"{name}: GPIO{num} in config, host-map says {ap} = GPIO{want_gpio}")
        if inv != want_inv:
            errors.append(f"{name}: inverted={inv} in config, host-map active={ch.get('active')}")
    for name in entities:
        if name not in checked:
            errors.append(f"{name}: in config but not a channel of the module host-map")

    # I2C
    i2c = cfg.get("i2c")
    if isinstance(i2c, list):
        i2c = i2c[0]
    if i2c:
        for key, hk in (("sda", "SDA"), ("scl", "SCL")):
            if gpio_num(i2c.get(key)) != int(car["host"]["I2C"][hk]):
                errors.append(f"i2c {key}: GPIO{gpio_num(i2c.get(key))} in config, "
                              f"host-map says GPIO{car['host']['I2C'][hk]}")
    else:
        notes.append("no i2c block in config")

    print(f"module : {mod['product']} {mod['revision']}  ({mod_path})")
    print(f"carrier: {car['product']} {car['revision']}  ({car_path})")
    print(f"config : {fn}")
    for n in notes:
        print("note :", n)
    for e in errors:
        print("ERROR:", e)
    print("RESULT:", "FAILED" if errors else f"OK ({len(checked)} channels checked)")

    if table:
        rows = [(n, c["ap"], host[c["ap"]]) for n, c in channels.items()
                if c.get("ap") and (c.get("type") in OUTPUT_TYPES or c.get("type") in INPUT_TYPES)]
        print()
        if len(rows) > 4:
            half = (len(rows) + 1) // 2
            print("| Channel | HOST line | GPIO | Channel | HOST line | GPIO |")
            print("|---|---|---|---|---|---|")
            for i in range(half):
                l = rows[i]
                r = rows[i + half] if i + half < len(rows) else None
                left = f"| {l[0]} | {l[1]} | GPIO{l[2]} |"
                right = f" {r[0]} | {r[1]} | GPIO{r[2]} |" if r else " | | |"
                print(left + right)
        else:
            print("| Channel | HOST line | GPIO |")
            print("|---|---|---|")
            for n, ap, g in rows:
                print(f"| {n} | {ap} | GPIO{g} |")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
