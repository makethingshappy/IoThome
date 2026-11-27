#!/usr/bin/env python3
"""Check NSLEEP_GPIO values (Octal3 / Relay latching drivers) against the platform host-map.yaml files.

Compares Documentation/nsleep_gpio.yaml with
  1. host.AP5 in the host-map.yaml files of IoTsmart / IoTbase (the source of truth),
  2. the NSLEEP_GPIO tables in Documentation/Setup.md and Documentation/Berry Drivers.md,
  3. the comments above `var NSLEEP_GPIO` in Berry_Drivers/Relay.be and Berry_Drivers/Octal3.be,
  4. completeness: every ESP32 board in any host-map.yaml must be listed under `platforms` or `ignore`.

Usage:  check_nsleep_gpio.py            (reads host-map.yaml from GitHub, public repos)
        check_nsleep_gpio.py --local DIR (DIR contains IoTsmart/ and IoTbase/ clones, for testing)
Exit code 1 on any mismatch.
"""
import argparse, json, os, re, sys, urllib.request
import yaml

ORG = 'makethingshappy'
REPOS = ('IoTsmart', 'IoTbase')
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
errors = []


def err(msg):
    errors.append(msg)
    print('ERROR:', msg)


def http(url):
    req = urllib.request.Request(url, headers={'User-Agent': 'check-nsleep-gpio'})
    tok = os.environ.get('GITHUB_TOKEN')
    if tok and 'api.github.com' in url:
        req.add_header('Authorization', f'Bearer {tok}')
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read().decode('utf-8')


def list_host_maps(repo, local):
    if local:
        base = os.path.join(local, repo)
        out = []
        for d, _, fs in os.walk(base):
            if '.git' in d.split(os.sep):
                continue
            if 'host-map.yaml' in fs:
                out.append(os.path.relpath(os.path.join(d, 'host-map.yaml'), base).replace(os.sep, '/'))
        return sorted(out)
    tree = json.loads(http(f'https://api.github.com/repos/{ORG}/{repo}/git/trees/main?recursive=1'))
    return sorted(t['path'] for t in tree['tree'] if t['path'].endswith('/host-map.yaml'))


def load_map(repo, path, local):
    if local:
        with open(os.path.join(local, repo, path), encoding='utf-8') as f:
            return yaml.safe_load(f)
    return yaml.safe_load(http(f'https://raw.githubusercontent.com/{ORG}/{repo}/main/{path}'))


def esp32_boards(doc):
    """Yield (board_key or None, mcu, host) for every ESP32 board in a host-map."""
    if 'boards' in doc:
        for key, b in doc['boards'].items():
            if str(b.get('mcu', '')).upper().startswith('ESP32'):
                yield key, b['mcu'], b.get('host', {})
    elif str(doc.get('mcu', '')).upper().startswith('ESP32'):
        yield None, doc['mcu'], doc.get('host', {})


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--local')
    local = ap.parse_args().local

    with open(os.path.join(ROOT, 'Documentation', 'nsleep_gpio.yaml'), encoding='utf-8') as f:
        cfg = yaml.safe_load(f)
    maps = {}
    def get(repo, path):
        if (repo, path) not in maps:
            maps[(repo, path)] = load_map(repo, path, local)
        return maps[(repo, path)]

    # 1. host-map.yaml vs nsleep_gpio.yaml
    covered = set()
    for p in cfg['platforms']:
        for s in p['sources']:
            key = (s['repo'], s['path'], s.get('board'))
            covered.add(key)
            try:
                doc = get(s['repo'], s['path'])
            except Exception as e:
                err(f"{p['label']}: cannot read {s['repo']}/{s['path']}: {e}")
                continue
            host = None
            for bk, _, h in esp32_boards(doc):
                if bk == s.get('board'):
                    host = h
            if host is None:
                err(f"{p['label']}: board {s.get('board')!r} not found as ESP32 board in {s['repo']}/{s['path']}")
                continue
            ap5 = host.get('AP5')
            if ap5 != p['gpio']:
                err(f"{p['label']}: nsleep_gpio.yaml says GPIO{p['gpio']}, but host.AP5 in {s['repo']}/{s['path']}"
                    f"{' (' + s['board'] + ')' if s.get('board') else ''} is {ap5!r}")
    ignored = {(i['repo'], i['path'], i.get('board')) for i in cfg.get('ignore', [])}

    # 4. completeness: every ESP32 board in every host-map.yaml
    for repo in REPOS:
        for path in list_host_maps(repo, local):
            doc = get(repo, path)
            for bk, mcu, _ in esp32_boards(doc):
                k = (repo, path, bk)
                if k not in covered and k not in ignored:
                    err(f"new ESP32 platform not covered: {repo}/{path}" + (f" board '{bk}'" if bk else '') +
                        f" ({mcu}) - add it to Documentation/nsleep_gpio.yaml (platforms or ignore)")

    # 2. doc tables
    for rel in ('Documentation/Setup.md', 'Documentation/Berry Drivers.md'):
        with open(os.path.join(ROOT, rel), encoding='utf-8') as f:
            text = f.read()
        for p in cfg['platforms']:
            pat = r'^\|\s*' + re.escape(p['label']) + r'\s*\|\s*\*\*' + str(p['gpio']) + r'\*\*'
            if not re.search(pat, text, re.M):
                err(f"{rel}: table row for '{p['label']}' with GPIO {p['gpio']} not found")

    # 3. driver comments
    for rel in ('Berry_Drivers/Relay.be', 'Berry_Drivers/Octal3.be'):
        with open(os.path.join(ROOT, rel), encoding='utf-8') as f:
            text = f.read()
        i = text.find('var NSLEEP_GPIO')
        block = text[max(0, i - 900):i] if i >= 0 else ''
        if i < 0:
            err(f"{rel}: 'var NSLEEP_GPIO' not found")
        for p in cfg['platforms']:
            if f"{p['label']} = {p['gpio']}" not in block:
                err(f"{rel}: comment above NSLEEP_GPIO lacks '{p['label']} = {p['gpio']}'")

    print('\nOK: NSLEEP_GPIO values match host-map.yaml, docs and drivers' if not errors else f'\n{len(errors)} problem(s)')
    sys.exit(1 if errors else 0)


if __name__ == '__main__':
    main()
