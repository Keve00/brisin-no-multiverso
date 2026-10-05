"""Create future-world native pixel SVG variants. No integration or Godot import.
Source pixels use ONE uniform 1/4 factor on both axes; last fractional row is padding.
Run from any directory: python tools/build_world_expansion.py.
"""
from pathlib import Path
import json
import math
import subprocess
import xml.etree.ElementTree as ET
from collections import defaultdict
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / 'godot/assets/world_01'
OUT = SRC / 'expansion'
OUT.mkdir(exist_ok=True)
NS = 'http://www.w3.org/2000/svg'


def path(c, d, opacity=None):
    a = f' opacity="{opacity}"' if opacity is not None else ''
    return f'<path fill="{c}"{a} d="{d}"/>'


def rect(x, y, w, h, c):
    return path(c, f'M{x} {y}h{w}v{h}h-{w}z')


def body(name):
    root = ET.parse(SRC / 'svg' / f'{name}.svg').getroot()
    return ''.join(ET.tostring(e, encoding='unicode').replace('ns0:', '').replace(':ns0', '')
                   for e in root if e.tag.endswith('path'))


def svg(name, w, h, data):
    dest = OUT / f'{name}.svg'
    dest.write_text(f'<svg xmlns="{NS}" width="{w}" height="{h}" viewBox="0 0 {w} {h}" shape-rendering="crispEdges"><title>{name}</title>{data}</svg>')
    return dest


def vector_source(filename, pixel_size=4):
    """Square source samples on both axes: no independent-axis fitting or warp."""
    im = Image.open(SRC / filename).convert('RGBA')
    cells = []
    for y in range(math.ceil(im.height / pixel_size)):
        for x in range(math.ceil(im.width / pixel_size)):
            sx = x * pixel_size + pixel_size // 2
            sy = y * pixel_size + pixel_size // 2
            if sx >= im.width or sy >= im.height:
                continue
            c = im.getpixel((sx, sy))
            if c[3] >= 128 and max(c[:3]) - min(c[:3]) >= 15:
                cells.append((x, y, c[:3]))
    colors = Image.new('RGB', (len(cells), 1))
    colors.putdata([c for x, y, c in cells])
    reduced = colors.quantize(colors=24, method=Image.Quantize.MEDIANCUT,
                              dither=Image.Dither.NONE).convert('RGB')
    rows = defaultdict(list)
    for (x, y, _), c in zip(cells, reduced.getdata()):
        rows[(y, '#%02x%02x%02x' % c)].append(x)
    groups = defaultdict(list)
    for (y, c), xs in sorted(rows.items()):
        start = last = xs[0]
        for x in xs[1:] + [100000]:
            if x == last + 1:
                last = x
                continue
            size = last - start + 1
            groups[c].append(f'M{start + 19} {y + 32}h{size}v1h-{size}z')
            start = last = x
    return ''.join(path(c, ''.join(d)) for c, d in groups.items())


island = vector_source('small_island.png')
# Grass clumps and turquoise mineral seams use the source coastal palette.
growth = path('#183946', 'M76 75v-8h-3v-4h-3v-3h5v4h4v7h2V60h3v-5h3v14h-3v6zM124 73v-4h3v-8h3v6h4v-5h3v8h-4v4z')
growth += path('#70a76e', 'M76 69v-5h-3v-3h3v3h3v7zM83 69V60h3v9zM128 69v-5h2v5zM133 69v-3h3v3z')
growth += path('#a9c66c', 'M78 72v-4h2v4zM84 64v-6h2v6zM130 69h3v2h-3z')
crystals = path('#14283f', 'M99 73V61h3v-5h3v-4h4v4h3v6h3v11zM113 73V66h2v-5h4v5h2v7z')
crystals += path('#1e8eaa', 'M102 70V61h3v-5h3v14zM115 70v-4h2v-3h2v7z')
crystals += path('#46d9d5', 'M108 57h2v6h3v7h-5zM117 65h2v5h-2z')
crystals += path('#c1ffee', 'M105 57h2v7h-2zM116 67h1v2h-1z')
crystals += path('#198391', 'M107 97h3v8h-3zM110 105h3v5h-3zM116 109h3v3h-3z')
shine = path('#e2fff0', 'M105 53h2v3h-2zM99 59h2v2h-2zM117 61h2v2h-2zM105 65h2v3h-2zM109 101h2v4h-2z')
svg('island_crystal_base', 160, 176, island + growth + crystals)
svg('island_crystal_signal_on', 160, 176, shine)
svg('island_crystal_signal_off', 160, 176, path('#638c94', 'M105 65h2v3h-2z'))

relay = path('#14283f', 'M89 74V39h-4v-4h5v-5h4v5h5v4h-4v35zM83 73h18v5H83z')
relay += path('#657f89', 'M90 39h3v34h-3zM85 74h14v2H85z')
relay += path('#afc1ad', 'M90 40h1v27h-1zM87 74h7v1h-7z')
relay += path('#325060', 'M85 35h14v4H85zM81 39h4v3h-4zM99 39h4v3h-4z')
relay += path('#e5a05d', 'M94 47h15v3h7v6h-7v3H94z')
relay += path('#ad554b', 'M94 56h15v3H94z')
relay += path('#f0cb82', 'M95 48h11v2H95z')
svg('island_relay_base', 160, 176, island + growth + relay)
relay_on = path('#5de9d9', 'M90 32h4v5h-4zM91 62h2v3h-2zM85 26h3v2h-3zM81 22h3v4h-3zM96 26h3v2h-3zM100 22h3v4h-3z')
relay_on += path('#d4ffdf', 'M91 33h2v2h-2zM96 51h7v2h-7z')
relay_off = path('#869097', 'M90 32h4v5h-4z') + path('#c09672', 'M96 51h7v2h-7z')
svg('island_relay_signal_on', 160, 176, relay_on)
svg('island_relay_signal_off', 160, 176, relay_off)

# The alternative node keeps its original round 32x32 core at identical scale.
node_base = f'<g transform="translate(16 40)">{body("node_base").replace("#43e9ee", "#40515f")}</g>'
node_base += path('#162c44', 'M32 47h16v41H32zM12 36h4v30h-4v6h-4V32h4zM64 36h4v30h4v6h-8zM16 12h48v4H16z')
node_base += path('#527383', 'M35 50h10v34H35zM12 37h2v23h-2zM66 37h2v23h-2zM18 13h44v1H18z')
node_base += path('#91a6a1', 'M35 52h2v30h-2zM26 89h28v2H26z')
node_base += path('#324558', 'M37 58h6v3h-6zM37 66h6v3h-6zM37 74h6v3h-6z')
# Foundation legs and inset bolts add detail without widening the core itself.
node_base += path('#14283f', 'M17 99h7v7h-7zM56 99h7v7h-7z')
node_base += path('#83a5a6', 'M18 100h4v2h-4zM58 100h4v2h-4z')
svg('connection_node_base', 80, 112, node_base)
for state in ['on', 'off']:
    core = 'node_core' if state == 'on' else 'node_core_off'
    svg('connection_node_core_' + state, 80, 112,
        f'<g transform="translate(24 18)">{body(core)}</g>')
node_signal_on = path('#59e8da', 'M20 24h2v4h-2zM58 24h2v4h-2zM20 40h2v4h-2zM58 40h2v4h-2zM36 8h8v2h-8zM32 94h4v4h-4zM40 94h4v4h-4zM48 94h4v4h-4z')
node_signal_on += path('#c4fff0', 'M38 9h4v1h-4zM41 95h2v1h-2z')
svg('connection_node_signal_on', 80, 112, node_signal_on)
svg('connection_node_signal_off', 80, 112, path('#c687df', 'M20 24h2v4h-2zM58 40h2v4h-2zM40 94h4v4h-4z'))

# PontoBrisa: recognizable pole, broad flag, grounded base and a state symbol.
checkpoint_base = path('#14283f', 'M14 98h48v8H14zM21 94h34v4H21zM26 18h6v77h-6zM24 14h10v6H24z')
checkpoint_base += path('#435d70', 'M17 100h42v3H17zM23 95h30v2H23zM27 21h4v72h-4z')
checkpoint_base += path('#98ada5', 'M27 21h1v72h-1zM23 95h25v1H23z')
checkpoint_base += path('#849da0', 'M26 15h6v3h-6z')
checkpoint_base += path('#203f50', 'M24 102h5v2h-5zM44 102h5v2h-5z')
svg('checkpoint_beacon_base', 80, 112, checkpoint_base)
flag_outline = path('#162c44', 'M31 20h18v3h12v3h10v15H61v3H49v3H31z')
flag_inactive = flag_outline + path('#e69d4a', 'M32 22h16v3h12v3h9v11h-9v3H48v3H32z')
flag_inactive += path('#f4cc85', 'M33 24h13v2H33zM46 26h10v2H46z')
flag_inactive += path('#a35b43', 'M34 39h12v3H34zM48 37h10v3H48z')
flag_inactive += path('#fff3c6', 'M42 29h9v3h-3v7h-3v-7h-3z')
flag_active = flag_outline + path('#34bfbf', 'M32 22h16v3h12v3h9v11h-9v3H48v3H32z')
flag_active += path('#8df8dc', 'M33 24h13v2H33zM46 26h10v2H46z')
flag_active += path('#1c758d', 'M34 39h12v3H34zM48 37h10v3H48z')
# Small check symbol differentiates the saved state beyond its color.
flag_active += path('#e2ffe6', 'M40 32h3v3h3v-6h3v9h-6v-3h-3z')
svg('checkpoint_beacon_flag_off', 80, 112, flag_inactive)
svg('checkpoint_beacon_flag_on', 80, 112, flag_active)
checkpoint_signal = path('#6cf3dc', 'M20 51h3v6h-3zM35 51h3v6h-3zM16 61h3v7h-3zM39 61h3v7h-3zM20 74h3v5h-3zM35 74h3v5h-3zM26 88h6v3h-6z')
svg('checkpoint_beacon_signal_on', 80, 112, checkpoint_signal)
svg('checkpoint_beacon_signal_off', 80, 112, '')

entries = [
    ('island_crystal', 160, 176, [80, 77], 'Ilha de cristais', ['island_crystal_base'], ['island_crystal_signal_off'], ['island_crystal_signal_on']),
    ('island_relay', 160, 176, [80, 77], 'Ilha de retransmissão', ['island_relay_base'], ['island_relay_signal_off'], ['island_relay_signal_on']),
    ('connection_node', 80, 112, [40, 104], 'Nó estabilizado', ['connection_node_base'], ['connection_node_core_off', 'connection_node_signal_off'], ['connection_node_core_on', 'connection_node_signal_on']),
    ('checkpoint_beacon', 80, 112, [29, 106], 'PontoBrisa', ['checkpoint_beacon_base'], ['checkpoint_beacon_flag_off', 'checkpoint_beacon_signal_off'], ['checkpoint_beacon_flag_on', 'checkpoint_beacon_signal_on']),
]
manifest = {'status': 'prepared_not_integrated', 'pixel_filter': 'nearest', 'source_uniform_scale': 0.25,
            'source': 'small_island.png 488x514; same mapping factor X and Y, transparent final half-row; near-neutral opaque checker residue excluded before palette reduction', 'assets': []}
for key, w, h, pivot, title, common, off, on in entries:
    manifest['assets'].append({'id': key, 'canvas': [w, h], 'pivot': pivot, 'common': common, 'offline': off, 'online': on,
                              'recommended_scale': 2, 'animations': {'signal': 'opacity steps at 6 fps; no XY stretch', 'flags': 'integer +/-1 px vertical movement, 1.2 second loop'}})
    for state, layers in [('off', off), ('on', on)]:
        parts = ''.join(''.join(ET.tostring(e, encoding='unicode').replace('ns0:', '').replace(':ns0', '')
                               for e in ET.parse(OUT / f'{n}.svg').getroot() if not e.tag.endswith('title'))
                        for n in common + layers)
        svg(key + '_assembled_' + state, w, h, parts)
(OUT / 'manifest.json').write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + '\n')

# Contact sheet preserves all native units: same 3x scale for every asset.
def assemble_asset(layers, animated=False):
    chunks = []
    for name in layers:
        root = ET.parse(OUT / f'{name}.svg').getroot()
        content = ''.join(ET.tostring(e, encoding='unicode').replace('ns0:', '').replace(':ns0', '') for e in root if not e.tag.endswith('title'))
        if animated and ('signal_on' in name or 'core_on' in name):
            content += '<animate attributeName="opacity" values="1;.65;.85;1" calcMode="discrete" dur="1.2s" repeatCount="indefinite"/>'
        if animated and 'flag_on' in name:
            content += '<animateTransform attributeName="transform" type="translate" values="0 0;0 -1;0 0;0 1;0 0" calcMode="discrete" dur="1.2s" repeatCount="indefinite"/>'
        chunks.append('<g>' + content + '</g>')
    return ''.join(chunks)

sheet = ['<rect width="1400" height="1096" fill="#101e30"/>']
sheet += ['<text x="28" y="38" font-family="DejaVu Sans" font-size="24" fill="#fff3cd">BRISIN · EXPANSÃO COSTEIRA — ASSETS PREPARADOS</text>',
          '<text x="28" y="67" font-family="DejaVu Sans" font-size="16" fill="#b4c9cd">OFFLINE / ONLINE • Camadas vetoriais • Escala uniforme 3× • Não integrado à fase</text>']
for i, (key, w, h, pivot, title, common, off, on) in enumerate(entries):
    col = i % 2
    row = i // 2
    x, y = 28 + col * 690, 94 + row * 550
    sheet.append(f'<rect x="{x}" y="{y}" width="660" height="526" fill="#172b3e"/>')
    sheet.append(f'<text x="{x+16}" y="{y+29}" font-family="DejaVu Sans" font-size="20" fill="#fff3cd">{title}</text>')
    for j, (label, layers) in enumerate([('OFFLINE', off), ('ONLINE', on)]):
        sx = x + 18 + j * 324
        sy = y + 52
        # Islands need 320 px of width; two states side-by-side are too wide.
        # Each state is a 2x copy with identical scale, shown side-by-side.
        scale = 2 if w == 160 else 3
        sheet.append(f'<text x="{sx}" y="{sy+18}" font-family="DejaVu Sans" font-size="14" fill="#b4c9cd">{label} · {scale:g}×</text>')
        sheet.append(f'<g transform="translate({sx} {sy+34}) scale({scale})">{assemble_asset(common+layers)}</g>')
    sheet.append(f'<text x="{x+16}" y="{y+503}" font-family="DejaVu Sans" font-size="14" fill="#9bb4bb">Canvas {w}×{h} · pivô {pivot[0]},{pivot[1]}</text>')
svg('contact_sheet', 1400, 1196, ''.join(sheet).replace('height="1096"','height="1196"').replace('Escala uniforme 3×','Escala uniforme por objeto'))
animated = ['<rect width="1400" height="760" fill="#101e30"/>', '<text x="28" y="40" font-family="DejaVu Sans" font-size="24" fill="#fff3cd">BRISIN · PRÉVIA ANIMADA — ONLINE</text>', '<text x="28" y="68" font-family="DejaVu Sans" font-size="16" fill="#b4c9cd">Sinais e bandeiras em camadas; base e proporções fixas. Pacote ainda não integrado.</text>']
for i, (key, w, h, pivot, title, common, off, on) in enumerate(entries):
    x = 24 + i * 346
    animated.append(f'<text x="{x}" y="122" font-family="DejaVu Sans" font-size="18" fill="#fff3cd">{title}</text>')
    scale = 2 if w == 160 else 3
    ox = x + (328 - w*scale)/2
    oy = 500 - pivot[1]*scale
    animated.append(f'<g transform="translate({ox:g} {oy:g}) scale({scale})">{assemble_asset(common+on, True)}</g>')
animated.append('<text x="28" y="718" font-family="DejaVu Sans" font-size="16" fill="#b4c9cd">Movimento discreto de 1 px nas bandeiras; sinais por opacidade, sem distorção.</text>')
svg('animated_preview', 1400, 760, ''.join(animated))
for key, w, h, pivot, title, common, off, on in entries:
    for state in ['off','on']:
        filename = OUT / f'{key}_assembled_{state}.svg'
        subprocess.run(['inkscape', str(filename), '--export-type=png', '--export-filename='+str(filename.with_suffix('.png'))], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
subprocess.run(['inkscape', str(OUT/'contact_sheet.svg'), '--export-type=png', '--export-filename='+str(OUT/'contact_sheet.png')], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
# QA reference comparison is raster-only documentation, never embedded in SVG assets.
comparison = Image.new('RGB', (720, 400), '#172b3e')
draw = ImageDraw.Draw(comparison)
font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 16)
draw.text((20, 20), 'Fonte original · 1/2 uniforme', fill='#fff3cd', font=font)
draw.text((370, 20), 'Vetor + cristais · 2x lógico', fill='#fff3cd', font=font)
reference = Image.open(SRC/'small_island.png').convert('RGBA').resize((244,257), Image.Resampling.NEAREST)
variant = Image.open(OUT/'island_crystal_assembled_on.png').convert('RGBA').crop((19,32,141,161)).resize((244,258), Image.Resampling.NEAREST)
comparison.paste(reference, (26,70), reference)
comparison.paste(variant, (380,70), variant)
draw.text((20,360), 'Mesma geometria; redução de paleta e limpeza de resíduos neutros.', fill='#b4c9cd', font=font)
comparison.save(OUT/'source_comparison.png')

# Every layer must be pure vector, square grid, same canvas per family.
for key, w, h, pivot, title, common, off, on in entries:
    for name in common + off + on:
        tree = ET.parse(OUT/f'{name}.svg').getroot()
        assert tree.attrib['viewBox'] == f'0 0 {w} {h}'
        assert not any(e.tag.endswith(('image', 'filter', 'mask')) for e in tree.iter())
print('Prepared 4 variant families, 16 native layers, state assemblies, manifest and previews:', OUT)
