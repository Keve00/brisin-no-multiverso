#!/usr/bin/env python3
"""Restore the matching web WASM when a source-only checkout omits build binaries."""
from pathlib import Path
import argparse
import hashlib
import json
import tempfile
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_URL = 'https://brisinho-costa-web.armandocorreiadeoliv.chatgpt.site'

def restore_runtime(base_url=DEFAULT_URL):
    manifest = json.loads((ROOT / 'wasm-parts.json').read_text())
    target = ROOT / 'dist'
    def matches(folder):
        digest = hashlib.sha256()
        for part in manifest['parts']:
            file = folder / part['name']
            if not file.exists() or file.stat().st_size != part['size']:
                return False
            with file.open('rb') as source:
                while chunk := source.read(1024 * 1024):
                    digest.update(chunk)
        return digest.hexdigest() == manifest['sha256']
    if matches(target):
        print('Compatible web runtime already present.')
        return
    target.mkdir(exist_ok=True)
    # Validate the entire download before replacing any live runtime parts.
    with tempfile.TemporaryDirectory(prefix='brisin-runtime-', dir=target) as temporary:
        temporary = Path(temporary)
        for part in manifest['parts']:
            name = part['name']
            if Path(name).name != name:
                raise ValueError('Runtime manifest contains an invalid filename')
            print(f'Downloading {name} ({part["size"]} bytes)...')
            with urllib.request.urlopen(base_url.rstrip('/') + '/' + name, timeout=60) as source:
                with (temporary / name).open('wb') as output:
                    remaining = part['size']
                    while chunk := source.read(min(1024 * 1024, remaining + 1)):
                        remaining -= len(chunk)
                        if remaining < 0:
                            raise ValueError(f'Runtime part {name} exceeds its expected size')
                        output.write(chunk)
                    if remaining:
                        raise ValueError(f'Incomplete runtime part {name}')
        if not matches(temporary):
            raise ValueError('Downloaded WASM does not match the committed SHA256')
        for part in manifest['parts']:
            (temporary / part['name']).replace(target / part['name'])
    print('Web runtime restored and SHA256 verified.')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--runtime-url', default=DEFAULT_URL, help='Mirror of the exact committed runtime')
    restore_runtime(parser.parse_args().runtime_url)
