#!/usr/bin/env python3
"""Trace an approved panorama to real SVG pixel geometry, not an embedded bitmap.
Usage: python trace_background_svg.py approved.png [output_directory]
The 2px source grid, global palette and documented rotor pivots are intentional.
"""
from pathlib import Path
import json, math, sys
from PIL import Image
import numpy as np

src=Path(sys.argv[1]); dest=Path(sys.argv[2]) if len(sys.argv)>2 else Path(__file__).parents[1]/'godot/assets/background_svg'
dest.mkdir(parents=True,exist_ok=True)
original=Image.open(src).convert('RGB')
assert original.size==(2172,724), original.size
GRID=2; W,H=original.size
# Turbine axes measured on the approved artwork, in the original shared canvas.
TURBINES=[{'pivot':[1318,270],'radius':41,'speed':0.26,'phase':0.0},
          {'pivot':[1364,339],'radius':27,'speed':0.32,'phase':0.0},
          {'pivot':[1418,317],'radius':33,'speed':0.23,'phase':0.0}]
raw=np.array(original.resize((W//GRID,H//GRID),Image.Resampling.BOX))
base=raw.copy()
rotors=[]
for entry in TURBINES:
    px,py=np.array(entry['pivot'])/GRID; radius=entry['radius']/GRID
    yy,xx=np.indices(raw.shape[:2]); dx=xx-px;dy=yy-py
    disk=dx*dx+dy*dy<=radius*radius
    # The mast begins directly below the hub and must retain its exact base.
    mast=(abs(dx)<=3)&(dy>=2)
    zone=disk&~mast
    r,g,b=np.moveaxis(raw.astype(float),-1,0)
    # White/lavender blades and cyan hub, including their dark violet outline.
    foreground=((r>34)&(r>g*.65))|((g>145)&(b>150))|((b<90)&(g<65)&(r>12))
    rotor=zone&foreground
    rotors.append(rotor)
    # Reconstruct only the sky under the removed rotor from that exact row's
    # nearby sky colours. No opaque disk or static blade is left underneath.
    for y in np.where(zone.any(axis=1))[0]:
        xs=np.where(zone[y])[0]; x0,x1=xs.min(),xs.max()
        left=raw[y,max(0,x0-3)].astype(float);right=raw[y,min(raw.shape[1]-1,x1+3)].astype(float)
        for x in xs:
            t=(x-x0)/max(1,x1-x0)
            base[y,x]=np.rint(left*(1-t)+right*t).astype('uint8')

# One palette across all layers prevents visible seams and colour drift.
global_palette=Image.fromarray(raw).quantize(colors=192,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
# Reserve pale/violet/cyan turbine colours; their tiny surface must not be
# swallowed by the dominant sea/sky palette during global quantisation.
rotor_pixels=raw[np.logical_or.reduce(rotors)]
reserved=Image.fromarray(rotor_pixels.reshape((1,len(rotor_pixels),3))).quantize(colors=64,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
global_palette.putpalette(global_palette.getpalette()[:192*3]+reserved.getpalette()[:64*3])
small=Image.fromarray(base).quantize(palette=global_palette,dither=Image.Dither.NONE)
palette=small.getpalette(); indexes=np.array(small)
rgb=np.array(small.convert('RGB'));r,g,b=np.moveaxis(rgb.astype(float),-1,0)
yy,xx=np.indices(indexes.shape)
# Shared canvas and complementary masks preserve every approved pixel.
sea=(yy*GRID>=478)&(g>b*.61)&(g>r*1.24)&(b>g*.85)
land=((yy*GRID>=478)&~sea)|((yy*GRID<478)&((r>b*.88)&(r>40)|(g>b*1.2)&(g>40)))
sky=~(sea|land)
# Separate fixed mast silhouettes in their own layer, with the original shared
# pixel coordinates. Do not independently centre or stretch their bounding boxes.
masts=np.zeros_like(sky)
for px,py in [e['pivot'] for e in TURBINES]:
    shaft=(abs(xx*GRID-px)<=10)&(yy*GRID>=py+4)&(yy*GRID<=py+112)
    silhouette=((r>34)&(r>g*.65))|((g>145)&(b>150))|((b<90)&(g<65)&(r>12))
    masts|=shaft&silhouette
sea &= ~masts;land &= ~masts;sky &= ~masts

def runs(indexes,mask):
    """Merge horizontal runs vertically; each output is a vector rectangle."""
    active={}; rectangles={}
    for y in range(indexes.shape[0]+1):
        row=[]
        if y<indexes.shape[0]:
            x=0
            while x<indexes.shape[1]:
                if not mask[y,x]: x+=1;continue
                colour=int(indexes[y,x]); end=x+1
                while end<indexes.shape[1] and mask[y,end] and int(indexes[y,end])==colour:end+=1
                row.append((colour,x,end-x));x=end
        present=set(row)
        for key,(start,last) in list(active.items()):
            if key not in present:
                colour,x,width=key
                rectangles.setdefault(colour,[]).append((x*GRID,start*GRID,width*GRID,(last-start+1)*GRID))
                del active[key]
        for key in row:
            start=active.get(key,(y,y))[0];active[key]=(start,y)
    return rectangles

def trace(filename,idx,mask,pal,viewbox=(0,0,W,H),shift=(0,0),extra=''):
    sx,sy=shift;v=' '.join(map(str,viewbox))
    out=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{viewbox[2]}" height="{viewbox[3]}" viewBox="{v}" shape-rendering="crispEdges">',
         '<title>Brisin — panorama aprovado, geometria vetorial em grade de 2px</title>',extra]
    count=0
    for colour,rects in runs(idx,mask).items():
        rr,gg,bb=pal[colour*3:colour*3+3];commands=[]
        for x,y,w,h in rects:
            commands.append(f'M{x+sx} {y+sy}h{w}v{h}h{-w}z');count+=1
        out.append(f'<path fill="#{rr:02x}{gg:02x}{bb:02x}" d="{"".join(commands)}"/>')
    out.append('</svg>');(dest/filename).write_text('\n'.join(out))
    return count
counts={}
for name,mask in [('sky',sky),('coast',land),('sea',sea),('masts',masts)]:counts[name]=trace(name+'.svg',indexes,mask,palette)
# Reflections stay on their own approved cells; animation modulates light gently.
glints=sea&(g>205)&(b>210)&(r>100)
counts['sea_glints']=trace('sea_glints.svg',indexes,glints,palette)
# Fixed masts already belong to the traced panorama. Each rotor uses its own
# square local canvas; its pivot is the centre, with padding for rotation.
rawq=Image.fromarray(raw).quantize(palette=small,dither=Image.Dither.NONE)
rawindex=np.array(rawq)
for i,(entry,mask) in enumerate(zip(TURBINES,rotors)):
    px,py=entry['pivot']; margin=entry['radius']+5
    entry['canvas']=margin*2;entry['local_pivot']=[margin,margin]
    counts['rotor_'+str(i)]=trace('rotor_'+str(i)+'.svg',rawindex,mask,palette,(0,0,margin*2,margin*2),(margin-px,margin-py))
# Local beacon geometry is an additive halo only; the original lamp is preserved.
(dest/'beacon_glow.svg').write_text('''<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64" shape-rendering="crispEdges"><title>Halo suave dos faróis</title><path fill="#24b8ee" opacity=".09" d="M20 4h24v8h12v40H8V12h12z"/><path fill="#48eaff" opacity=".13" d="M20 12h24v8h8v24H12V20h8z"/><path fill="#adffff" opacity=".22" d="M24 20h16v24H24z"/></svg>''')
metadata={'source_dimensions':[W,H],'grid':GRID,'palette_colours':256,'rotors':TURBINES,'beacons':[[949,397],[1255,315],[1610,396]],'rectangle_counts':counts,'composition':'single panorama; no mirrored repeats; SVG paths only'}
(dest/'manifest.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2)+'\n')
# Standalone SVG preview uses SVG symbols/uses referencing actual vector files.
parts=[]
for name in ['sky','sea','coast','masts']:
    content=(dest/(name+'.svg')).read_text(); inner=content[content.index('>')+1:content.rindex('</svg>')];parts.append(inner)
for i,e in enumerate(TURBINES):
    c=e['canvas'];px,py=e['pivot']; content=(dest/f'rotor_{i}.svg').read_text();inner=content[content.index('>')+1:content.rindex('</svg>')]
    parts.append(f'<g transform="translate({px-c/2} {py-c/2})">{inner}</g>')
(dest.parents[2]/'docs/background_svg_preview.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" shape-rendering="crispEdges">'+''.join(parts)+'</svg>')
print(json.dumps(metadata,indent=2));print('SVG total bytes',sum(f.stat().st_size for f in dest.glob('*.svg')))
