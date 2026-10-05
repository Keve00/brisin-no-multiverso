"""Geometry checks for source sea SVGs, independent of Godot importer."""
from pathlib import Path
from xml.etree import ElementTree as ET
import hashlib

ROOT = Path(__file__).resolve().parents[1] / 'godot/assets/sea_svg'


def geometry(path):
    tree = ET.parse(path).getroot()
    assert tree.get('viewBox') == '0 0 512 224', path
    assert not list(tree.iter('{http://www.w3.org/2000/svg}image')), path
    rectangles = []
    for node in tree:
        assert node.tag.endswith('rect'), (path, node.tag)
        coords = [int(node.get(k)) for k in ['x', 'y', 'width', 'height']]
        assert all(v % 2 == 0 for v in coords), (path, coords)
        x, y, width, height = coords
        assert x >= 0 and y >= 0 and x+width <= 512 and y+height <= 224
        assert node.get('opacity') is None and node.get('fill-opacity') is None
        rectangles.append(coords)
    return rectangles


def main():
    hashes, tops = set(), []
    for frame in range(12):
        path = ROOT / f'surface_{frame:02}.svg'
        rectangles = geometry(path)
        hashes.add(hashlib.sha256(path.read_bytes()).hexdigest())
        columns = [224] * 256
        bottom = [False] * 256
        for x, y, width, height in rectangles:
            for col in range(x//2, (x+width)//2):
                columns[col] = min(columns[col], y)
                if y+height == 224:
                    bottom[col] = True
        assert all(bottom), 'water must cover the complete bottom of every tile'
        assert max(columns) <= 8
        assert abs(columns[0]-columns[-1]) <= 2, 'periodic shoreline seam'
        tops.append(columns)
    assert len(hashes) == 12, 'all animation frames must be distinct'
    for frame, columns in enumerate(tops):
        other = tops[(frame+1) % 12]
        assert max(abs(a-b) for a, b in zip(columns, other)) <= 2, 'surface loop can move at most one grid step per frame'
    for layer in ['reflections', 'swell']:
        geometry(ROOT / f'{layer}.svg')
    print('SEA SVG SOURCE PASS: 12 distinct frames, 2px grid, periodic shoreline, opaque depth, wrapped detail layers')


if __name__ == '__main__':
    main()
