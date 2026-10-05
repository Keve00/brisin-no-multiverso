"""Animate the approved checkpoint cloth as editable SVG frames.

Only cloth is transported by columns, at integer logical pixels. Source canvas
128x128 and mast attachment (64,64) are identical in every frame/state. The first
3 cloth columns never move, and the mast remains its independent original layer.
Run python tools/build_checkpoint_wave.py; no concept bitmap is required.
"""
from collections import defaultdict
from pathlib import Path
import json
import math
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'godot/assets/world_01/interactive'
COUNT = 12
FPS = 8
ATTACH_X = 64
FIXED_UNTIL = 66
MAX_X = 118


def read_cells(path):
    root = ET.parse(path).getroot()
    cells = {}
    for node in root:
        if node.tag.endswith('title'):
            continue
        assert node.tag.endswith('path'), node.tag
        data = node.attrib['d']
        runs = re.findall(r'M(\d+) (\d+)h(\d+)v1h-\d+z', data)
        assert ''.join(f'M{x} {y}h{w}v1h-{w}z' for x, y, w in runs) == data
        for x, y, width in runs:
            for column in range(int(x), int(x) + int(width)):
                cells[column, int(y)] = node.attrib['fill']
    assert cells and min(x for x, _ in cells) == ATTACH_X
    return cells


def build():
    for state in ['off', 'on']:
        cells = read_cells(OUT / f'checkpoint_flag_{state}.svg')
        for frame in range(COUNT):
            groups = defaultdict(list)
            phase = frame * math.tau / COUNT
            for (x, y), fill in cells.items():
                t = max(0, (x - FIXED_UNTIL) / (MAX_X - FIXED_UNTIL))
                offset = round(5 * t * t * math.sin(phase - t * math.tau * .75))
                animated_y = y + offset
                assert 0 <= animated_y < 128
                groups[fill].append(f'M{x} {animated_y}h1v1h-1z')
            body = ''.join(f'<path fill="{fill}" d="{"".join(paths)}"/>' for fill, paths in groups.items())
            name = f'checkpoint_flag_{state}_wave_{frame:02}'
            (OUT / f'{name}.svg').write_text(
                f'<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128" shape-rendering="crispEdges"><title>BRISIN {name}; fixed attachment 64,64</title>{body}</svg>')
    metadata = {'frames_per_state': COUNT, 'fps': FPS, 'duration_seconds': COUNT / FPS,
                'canvas': [128, 128], 'pivot': [64, 64], 'stationary_columns': [64, FIXED_UNTIL],
                'max_tip_shift_pixels': 5, 'runtime': 'Godot frame selection, continuous Offline and Online'}
    (OUT / 'checkpoint_wave.json').write_text(json.dumps(metadata, indent=2) + '\n')
    print(f'Generated {COUNT * 2} vector cloth frames; fixed mast attachment and 1.5 s loop.')

if __name__ == '__main__':
    build()
