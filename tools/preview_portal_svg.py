"""Render Godot-sampled portal sprite transforms with the real source SVGs.
Input is the JSON emitted by the runtime sampler; this is asset compositing,
not a browser or Godot framebuffer capture. The sampler never exports gameplay.
"""
import json, sys, xml.etree.ElementTree as ET
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
samples = json.loads(Path(sys.argv[1]).read_text())
output = Path(sys.argv[2]); output.parent.mkdir(parents=True, exist_ok=True)
parts = ['<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="960" viewBox="0 0 1600 960" shape-rendering="crispEdges"><rect width="1600" height="960" fill="#122638"/>']
for index, sample in enumerate(samples):
    x, y = (index % 5) * 320 + 160, (index // 5) * 320 + 150
    parts.append(f'<g transform="translate({x} {y})"><rect x="-152" y="-122" width="304" height="270" fill="#243E50"/><path d="M-152 104H152V124H-152Z" fill="#0D2539"/>')
    for layer in sorted(sample['layers'], key=lambda layer: layer['z']):
        path = ROOT / 'godot' / layer['path'].removeprefix('res://')
        if path.suffix != '.svg': continue
        svg = ET.parse(path).getroot()
        a,b,c,d,e,f = layer['matrix']; rx,ry,w,h=layer['rect']
        red,green,blue = layer['rgb']
        for element in svg.iter():
            fill = element.attrib.get('fill', '')
            if fill.startswith('#') and len(fill) == 7:
                components = [int(fill[i:i+2], 16) for i in [1,3,5]]
                element.set('fill', '#' + ''.join(f'{round(component * channel):02x}' for component, channel in zip(components,[red,green,blue])))
        body = ''.join(ET.tostring(child, encoding='unicode') for child in svg)
        vb = svg.attrib.get('viewBox',f'0 0 {w} {h}')
        parts.append(f'<g transform="matrix({a} {b} {c} {d} {e} {f})" opacity="{layer["alpha"]}"><svg x="{rx}" y="{ry}" width="{w}" height="{h}" viewBox="{vb}">{body}</svg></g>')
    parts.append(f'<text x="0" y="145" text-anchor="middle" fill="#FFF3CD" font-family="sans-serif" font-size="16">{sample["label"]}</text></g>')
parts.append('</svg>'); output.write_text(''.join(parts))
print(output)
