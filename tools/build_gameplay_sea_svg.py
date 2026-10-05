"""Reproducible native SVG sea; 2px grid and mathematically periodic tiles.

No bitmap embedding, texture stretching, transparency fades or physics edits.
Run from anywhere: python tools/build_gameplay_sea_svg.py.
"""
from pathlib import Path
from math import sin, tau
import json

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'godot/assets/sea_svg'
WIDTH, HEIGHT, GRID, FRAMES = 512, 224, 2, 12


def rect(x, y, w, h, color):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{color}"/>'


def wrapped_rect(x, y, w, h, color):
    x %= WIDTH
    edge = min(w, WIDTH-x)
    return rect(x, y, edge, h, color) + (rect(0, y, w-edge, h, color) if edge < w else '')


def save(name, body):
    (OUT / f'{name}.svg').write_text(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{HEIGHT}" '
        f'viewBox="0 0 {WIDTH} {HEIGHT}" shape-rendering="crispEdges">'
        + ''.join(body) + '</svg>\n')


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    # Opaque stepped depth, with a top shore of soft blue and darker deep water.
    depths = [(0, 26, '#17678B'), (26, 54, '#155F83'), (54, 88, '#125779'),
              (88, 124, '#104E70'), (124, 162, '#0D4464'), (162, 194, '#0B3D5C'),
              (194, HEIGHT, '#093653')]
    for frame in range(FRAMES):
        phase = tau * frame / FRAMES
        body = []
        for x in range(0, WIDTH, GRID):
            top = 4 + GRID * round(1.5*sin(tau*x/WIDTH + phase)
                                  + 0.5*sin(4*tau*x/WIDTH - phase))
            top = max(0, top)
            for start, end, color in depths:
                y = max(start, top)
                if y < end:
                    body.append(rect(x, y, GRID, end-y, color))
            # Sparse foam follows the same fixed waterline; never a flat stroke.
            if (x//GRID) % 40 < 26:
                body.append(rect(x, top, GRID, 2, '#A6DEDC'))
            if (x//GRID) % 64 < 24:
                body.append(rect(x, top+4, GRID, 2, '#4CAAB8'))
        save(f'surface_{frame:02}', body)
    reflections = []
    # Long broken glints, not a blinking sheet. Widths/positions stay on the grid.
    for row, y in enumerate([20, 36, 54, 78, 106, 140, 174, 202]):
        for n in range(4):
            x = (n*134 + row*42 + (row%3)*18) % WIDTH
            width = [38, 22, 54, 14][(n+row)%4]
            color = ['#3E91A9', '#317F9B', '#286E8F'][min(2, row//3)]
            reflections.append(wrapped_rect(x, y, width, 2, color))
            if row < 3 and n%2 == 0:
                reflections.append(wrapped_rect(x+8, y-2, 14, 2, '#6EB8C5'))
    save('reflections', reflections)
    swell = []
    for row, y in enumerate([14, 66, 118, 170]):
        for n in range(3):
            x = n*170 + row*54
            color = '#32849F' if row < 2 else '#206080'
            swell += [wrapped_rect(x, y+4, 18, 2, color),
                      wrapped_rect(x+18, y+2, 24, 2, color),
                      wrapped_rect(x+42, y, 38, 2, color),
                      wrapped_rect(x+80, y+2, 22, 2, color),
                      wrapped_rect(x+102, y+4, 12, 2, color)]
    save('swell', swell)
    (OUT / 'manifest.json').write_text(json.dumps({
        'tile_size': [WIDTH, HEIGHT], 'grid': GRID, 'frame_count': FRAMES,
        'fps': 6, 'water_y': 810, 'bottom_y': 810+HEIGHT,
        'scale': 1, 'z_index': -3,
        'layers': ['surface', 'reflections', 'swell'],
        'reflection_period_seconds': 32, 'swell_period_seconds': 64
    }, indent=2)+'\n')


if __name__ == '__main__':
    main()
