"""Rebuild Brisin's approved environment concepts as editable native pixel SVGs.

Decorations are sampled on a SINGLE square 3px grid, with 28 opaque colours,
then emitted as horizontal vector runs. VFX are hand-built on a logical grid.
No raster images, fonts, source background or card borders are embedded.
"""
from pathlib import Path
from collections import defaultdict
import argparse
import json
import math
import subprocess
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "godot/assets/world_01/environment"
SOURCE = ROOT.parent / "generated_images/exec-54a086db-33d8-4bf6-9fc3-26ebb47c10e4.png"
NS = "http://www.w3.org/2000/svg"
ENTRIES = []
BODIES = {}


def path(colour, d, opacity=1):
    return f'<path fill="{colour}" opacity="{opacity}" d="{d}"/>'


def rect(x, y, w, h, colour, opacity=1):
    return path(colour, f'M{x} {y}h{w}v{h}h-{w}z', opacity)


def emit(key, width, height, body, pivot, **meta):
    BODIES[key] = body
    (OUT / f'{key}.svg').write_text(
        f'<svg xmlns="{NS}" width="{width}" height="{height}" '
        f'viewBox="0 0 {width} {height}" shape-rendering="crispEdges">'
        f'<title>{key}</title>{body}</svg>')
    ENTRIES.append(dict(id=key, file=key+'.svg', canvas=[width, height],
                        pivot=pivot, **meta))


def vectorize(im, lamp=False, dim_lamps=False):
    cells = []
    # Exact uniform spatial sampling. Transparent background remains outside
    # the silhouette. A dark 1px contour is added for coastal game readability.
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = im.getpixel((x, y))
            if a:
                is_lamp = g >= 110 and b >= 110 and b > r*1.65 and g > r*1.2
                if lamp and not is_lamp:
                    continue
                if dim_lamps and is_lamp:
                    r,g,b = (32,49,62)
                cells.append((x, y, (r, g, b)))
    if not cells:
        return ''
    colours = Image.new('RGB', (len(cells), 1))
    colours.putdata([c for x, y, c in cells])
    palette = colours.quantize(colors=28, method=Image.Quantize.MEDIANCUT,
                               dither=Image.Dither.NONE).convert('RGB')
    runs = defaultdict(list)
    for (x, y, _), colour in zip(cells, palette.getdata()):
        runs[(y, '#%02x%02x%02x' % colour)].append(x)
    groups = defaultdict(list)
    for (y, colour), xs in sorted(runs.items()):
        start = last = xs[0]
        for x in xs[1:] + [99999]:
            if x == last+1:
                last = x
                continue
            size = last-start+1
            groups[colour].append(f'M{start+5} {y+5}h{size}v1h-{size}z')
            start = last = x
    return ''.join(path(c, ''.join(ds)) for c, ds in groups.items())


def decoration(source, kind, variant, crop, source_pivot):
    original = source.crop(crop).convert('RGB')
    w, h = original.size
    logical = Image.new('RGBA', (math.ceil(w/3), math.ceil(h/3)))
    # Native opaque background is navy; its channel maximum is below 55.
    # Keep the brighter silhouette and interior, never threshold orange alone.
    for y in range(logical.height):
        for x in range(logical.width):
            sx, sy = min(x*3+1, w-1), min(y*3+1, h-1)
            c = original.getpixel((sx, sy))
            if max(c) >= 58 and not (c[0] < 14 and c[1] < 42 and c[2] < 76):
                logical.putpixel((x, y), c+(255,))
    # The tall palm's card includes a tip of the neighbouring palm at its
    # lower-right edge. Remove that separate fragment, preserving this crown.
    if kind == 'palms' and variant == 1:
        for y in range(66, logical.height):
            for x in range(48, logical.width):
                logical.putpixel((x, y), (0, 0, 0, 0))
    # Fill only enclosed tiny holes, preserving intentional holes in arches,
    # cables and tree crowns. No dilation of original silhouette proportions.
    for y in range(1, logical.height-1):
        for x in range(1, logical.width-1):
            if logical.getpixel((x,y))[3] == 0:
                neighbors = [logical.getpixel((x+dx,y+dy))[3] for dx,dy in
                             [(1,0),(-1,0),(0,1),(0,-1)]]
                if sum(bool(v) for v in neighbors) == 4:
                    logical.putpixel((x,y), (16,39,55,255))
    cw, ch = logical.width+10, logical.height+10
    pivot = [round((source_pivot[0]-crop[0])/3)+5,
             round((source_pivot[1]-crop[1])/3)+5]
    key = f'{kind}_{variant}'
    body = vectorize(logical, dim_lamps=(kind=='posts'))
    emit(key, cw, ch, body, pivot, kind=kind, variant=variant,
         source_crop=list(crop), source_uniform_scale=1/3,
         animation=('base_pivot_sway' if kind in ['palms','vegetation'] else
                    'bob_and_foam' if kind == 'water_props' else
                    'online_lamp' if kind == 'posts' else 'static'),
         collision='none')
    if kind == 'posts':
        emit(key+'_lamp', cw, ch, vectorize(logical, lamp=True), pivot,
             kind='posts_lamp', variant=variant, collision='none')


def sparkle(x, y, colour='#fff1b5', size=1):
    return rect(x-2*size,y,5*size,size,colour)+rect(x,y-2*size,size,5*size,colour)


def diamond(cx=24, cy=28, width=22, height=30):
    # Stepped faceted diamond. All vertices sit on the integer pixel grid.
    hw, hh = width//2, height//2
    outline = ''
    for dy in range(-hh,hh+1):
        span = max(1,round(hw*(1-abs(dy)/hh)))
        outline += rect(cx-span-1,cy+dy,span*2+3,1,'#42241a')
    body = outline
    for dy in range(-hh+1,hh):
        span = max(1,round(hw*(1-abs(dy)/hh)))
        left = '#fff4ac' if dy < 0 else '#f58a10'
        right = '#ffb000' if dy < 0 else '#df520b'
        body += rect(cx-span,cy+dy,span,1,left)
        body += rect(cx,cy+dy,span+1,1,right)
        # Internal facet ridge narrows towards the tip, giving depth and a
        # recognisable crystal instead of a flat two-colour diamond badge.
        if dy < -1 and span > 2:
            body += rect(cx-span,cy+dy,max(1,span//3),1,'#ffbd26')
            body += rect(cx-2,cy+dy,2,1,'#fff9d3')
        elif dy > 1 and span > 2:
            body += rect(cx-span,cy+dy,max(1,span//3),1,'#ffcd41')
    body += rect(cx-hw+1,cy-1,width-2,2,'#ffd94d')
    body += rect(cx-1,cy+2,2,hh-4,'#ffcf3e')
    return body


def make_vfx():
    for variant, size in enumerate([(20,28),(24,32),(18,26)]):
        w,h=size
        halo = rect(12,22,24,12,'#ff9a00',.045)
        halo += rect(16,15,16,26,'#ff9a00',.035)
        halo += rect(20,10,8,36,'#ffba20',.025)
        sparks = sparkle(7,19,'#ffd74e')+sparkle(38,13,'#fff4ae')
        sparks += rect(7,37,2,2,'#ffbe22')+rect(38,34,2,2,'#ffcd45')
        emit(f'gems_{variant}',48,56,halo+diamond(width=w,height=h)+sparks,
             [24,28],kind='gems',variant=variant,collision='existing_fragment',
             animation='uniform_scale_pulse_6_percent_max')
    # Organic wind trails use discrete logical pixels instead of arrows.
    for variant in range(3):
        points=[]
        for i in range(46):
            if variant == 0:
                x=8+i; y=28+round(5*math.sin(i*.13))
            elif variant == 1:
                x=24+round(5*math.sin(i*.15)); y=9+i
            else:
                angle=i*.13; radius=4+i*.28
                x=32+round(math.cos(angle)*radius); y=32+round(math.sin(angle)*radius)
            points.append((x,y))
        body=''
        for i,(x,y) in enumerate(points):
            body += rect(x,y,2,2,'#a9f8ff',.35+.6*i/len(points))
            if variant != 2:
                body += rect(x+(4 if variant==1 else 0),y+(0 if variant==1 else 6),1,1,'#34cbea',.65)
        for x,y in [(9,15),(53,41),(16,47),(48,20)]:
            body+=rect(x,y,1,1,'#c4ffff')
        # Independent native leaf silhouette: no arrows, chevrons or glyphs.
        body+=path('#1c4c45','M13 16h3v-2h4v3h-2v3h-5z')
        body+=path('#a3c648','M14 16h3v-1h2v2h-2v2h-3z')
        body+=rect(14,18,4,1,'#d0df69')
        emit(f'wind_{variant}',64,64,body,[32,32],kind='wind',variant=variant,
             collision='existing_wind_region',animation='advect_with_region_force')
    # A stable common canvas lets gameplay time these three stages without
    # any bounding-box based scale or centre shifts.
    body=diamond(32,32,20,28)
    for degree in range(0,360,10):
        a=math.radians(degree)
        x=round(32+24*math.cos(a)); y=round(35+8*math.sin(a))
        body+=rect(x,y,2,1,'#ffc54a')
    body+=sparkle(10,13)+sparkle(51,17)+sparkle(32,55,'#ffd54b')
    emit('pickup_0',64,64,body,[32,32],kind='pickup',variant=0,
         collision='none',animation='pickup_ring_0_to_0.12_seconds')
    body=''
    for i in range(7):
        a=i*math.tau/7
        x=round(32+16*math.cos(a)); y=round(32+16*math.sin(a))
        body+=diamond(x,y,6,10)
    for x,y in [(8,21),(52,8),(54,42),(25,54),(31,32)]:
        body+=sparkle(x,y,'#ffd14b')
    emit('pickup_1',64,64,body,[32,32],kind='pickup',variant=1,
         collision='none',animation='pickup_shards_0.12_to_0.28_seconds')
    body=''
    for i in range(12):
        a=i*math.tau/12
        radius=20+(i%3)*3
        x=round(32+radius*math.cos(a)); y=round(32+radius*math.sin(a))
        body+=rect(x,y,2,2,'#ffbd2a')+rect(x,y,1,1,'#fff4a2')
    emit('pickup_2',64,64,body,[32,32],kind='pickup',variant=2,
         collision='none',animation='pickup_sparkles_0.28_to_0.48_seconds')


def contact_sheet():
    families=['palms','vegetation','rocks_sand','ruins','posts','water_props','wind','gems','pickup']
    sheet = Image.new('RGB',(2200,950),'#0b2034')
    draw=ImageDraw.Draw(sheet)
    for group,kind in enumerate(families):
        x0=(group%3)*730; y0=(group//3)*310
        draw.text((x0+12,y0+8),kind.upper(),fill='#ffcf69')
        for variant in range(3):
            key=f'{kind}_{variant}'
            dest=OUT/(key+'.png')
            entry = next(a for a in ENTRIES if a['id']==key)
            subprocess.run(['inkscape',str(OUT/(key+'.svg')),'--export-type=png',
                            '--export-filename='+str(dest),'--export-width='+str(entry['canvas'][0]*3)],
                           check=True,capture_output=True)
            image=Image.open(dest).convert('RGBA')
            # One common 3x factor, never per-cell width/height fitting.
            px=x0+10+variant*235; py=y0+290-image.height
            sheet.paste(image,(px,py),image)
            draw.text((px+20,y0+292),str(variant),fill='#ffcf69')
    sheet.save(OUT/'contact_sheet.png')


def animation_preview():
    # Browser-only SMIL preview. Godot uses environment_svg.gd, not SMIL.
    families=['palms','vegetation','rocks_sand','ruins','posts','water_props','wind','gems','pickup']
    chunks=[rect(0,0,2200,950,'#0b2034')]
    for group,kind in enumerate(families):
        x0=(group%3)*730; y0=(group//3)*310
        chunks.append(f'<text x="{x0+12}" y="{y0+22}" fill="#ffcf69" font-family="monospace" font-size="18">{kind.upper()}</text>')
        for variant in range(3):
            key=f'{kind}_{variant}'
            entry=next(a for a in ENTRIES if a['id']==key)
            width,height=entry['canvas']; px,py=entry['pivot']
            x=x0+10+235*variant; y=y0+290-height*3
            body=BODIES[key]
            anim=''
            if kind in ['palms','vegetation']:
                anim=f'<animateTransform attributeName="transform" type="rotate" values="-1.2 {px} {py};1.2 {px} {py};-1.2 {px} {py}" dur="3.6s" repeatCount="indefinite"/>'
            elif kind=='water_props':
                anim='<animateTransform attributeName="transform" type="translate" values="0 0;0 -2;0 0" dur="2.8s" repeatCount="indefinite"/>'
            elif kind=='posts':
                body+=f'<g>{BODIES[key+"_lamp"]}<animate attributeName="opacity" values=".14;.14;1;.85;1;.14" dur="6s" repeatCount="indefinite"/></g>'
            elif kind=='wind':
                anim='<animateTransform attributeName="transform" type="translate" values="-5 0;5 0;-5 0" dur="2s" repeatCount="indefinite"/>'
            elif kind=='gems':
                # Centre the pulse with fixed pivot rather than scaling about
                # the top-left corner. Identical factor X and Y at all times.
                body=f'<g transform="translate({px} {py})"><g><g transform="translate({-px} {-py})">{body}</g><animateTransform attributeName="transform" type="scale" values="1;1.06;1" dur="2.1s" repeatCount="indefinite"/></g></g>'
            elif kind=='pickup':
                anim='<animate attributeName="opacity" values=".15;1;.15" dur="1.2s" repeatCount="indefinite"/>'
            chunks.append(f'<g transform="translate({x} {y})"><g transform="scale(3)"><g>{body}{anim}</g></g></g>')
    (OUT/'animated_preview.svg').write_text(f'<svg xmlns="{NS}" width="2200" height="950" viewBox="0 0 2200 950" shape-rendering="crispEdges">'+''.join(chunks)+'</svg>')


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--source',type=Path,default=SOURCE)
    parser.add_argument('--render',action='store_true')
    args=parser.parse_args()
    OUT.mkdir(parents=True,exist_ok=True)
    source=Image.open(args.source)
    crops={
      'palms':[((34,150,199,324),(113,317)),((230,79,400,324),(287,317)),((408,123,562,324),(430,317))],
      'vegetation':[((609,192,756,307),(682,301)),((768,178,928,307),(848,301)),((935,180,1082,307),(1008,301))],
      'rocks_sand':[((1121,169,1302,310),(1211,304)),((1305,216,1467,310),(1386,304)),((1471,181,1649,314),(1560,308))],
      'ruins':[((25,414,198,586),(111,577)),((202,421,388,586),(295,577)),((395,418,572,586),(483,577))],
      'posts':[((607,425,759,586),(686,577)),((779,432,956,587),(839,577)),((962,393,1083,588),(1015,578))],
      'water_props':[((1122,431,1299,590),(1198,566)),((1303,444,1468,591),(1386,566)),((1472,476,1655,591),(1563,570))],
    }
    for kind,variants in crops.items():
        for variant,(crop,pivot) in enumerate(variants):
            decoration(source,kind,variant,crop,pivot)
    make_vfx()
    manifest=dict(source=str(args.source.name),native_svg=True,embedded_raster=False,
                  pixel_filter='nearest',placement_format=['kind','variant','base_x','base_y','uniform_scale'],
                  environment_is_decorative=True,assets=ENTRIES)
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False)+'\n')
    animation_preview()
    if args.render:
        contact_sheet()
    print(f'Generated {len(ENTRIES)} native SVG files in {OUT}')


if __name__=='__main__':
    main()
