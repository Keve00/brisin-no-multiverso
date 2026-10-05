"""Reconstruct editable pixel SVG layers from the existing art; no raster embedding."""
from pathlib import Path
from PIL import Image
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'godot/assets/world_01'
OUT=ROOT/'godot/assets/world_01/svg'
OUT.mkdir(exist_ok=True)

def sample(name,w,h):
    a=np.array(Image.open(SRC/(name+'.png')).convert('RGBA'))
    cells=[]
    for y in range(h):
        for x in range(w):
            cx=int((x+.5)*a.shape[1]/w);cy=int((y+.5)*a.shape[0]/h)
            p=np.median(a[max(0,cy-1):cy+2,max(0,cx-1):cx+2],axis=(0,1)).astype(int)
            if p[3]>=128:cells.append((x,y,tuple(p[:3])))
    s=Image.new('RGB',(len(cells),1));s.putdata([p for x,y,p in cells])
    q=s.quantize(colors=24,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE).convert('RGB')
    return [(x,y,'#%02x%02x%02x'%c) for (x,y,p),c in zip(cells,q.getdata())]

def shapes(cells):
    rows={}
    for x,y,c in cells:rows.setdefault((y,c),set()).add(x)
    paths={}
    for (y,c),xs in sorted(rows.items()):
        xs=sorted(xs);start=last=xs[0]
        for x in xs[1:]+[9999]:
            if x==last+1:last=x;continue
            w=last-start+1;paths.setdefault(c,[]).append(f'M{start} {y}h{w}v1h-{w}z')
            start=last=x
    return ''.join(f'<path fill="{c}" d="{"".join(p)}"/>' for c,p in paths.items())

def write(name,w,h,body):
    (OUT/(name+'.svg')).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}" shape-rendering="crispEdges"><title>{name}</title>{body}</svg>')

for state in ['on','off']:
    cells=sample('turbine_'+state,64,106)
    base=[];rotor=[]
    for x,y,c in cells:
        in_tower=y>=57 or (y>=45 and abs(x-32)<=9)
        if in_tower or (y>=38 and abs(x-32)<=6):base.append((x,y,c))
        if not in_tower:rotor.append((x+32,y+26,c))
    write('turbine_base_'+state,64,106,shapes(base))
    write('turbine_rotor_'+state,128,128,shapes(rotor))

cells=sample('portal',100,84);frame=[];core=[]
for x,y,c in cells:
    if (x-49)**2+(y-43)**2<=21.5**2:core.append((x-49+32,y-43+32,c))
    else:frame.append((x,y,c))
write('portal_frame',100,84,shapes(frame))
write('portal_core',64,64,shapes(core))
write('lighthouse_base',64,126,shapes(sample('lighthouse_on',64,126)))
write('lighthouse_beam',192,48,'''
<path fill="#69eee3" opacity=".10" d="M0 20h24v-4h24v-4h24v-4h24v-4h48V0h48v48h-48v-4H96v-4H72v-4H48v-4H24v-4H0z"/>
<path fill="#fff3a1" opacity=".16" d="M0 22h48v-4h48v-4h48v-4h48v28h-48v-4H96v-4H48v-4H0z"/>
<path fill="#fff9cb" opacity=".24" d="M0 22h80v-2h112v8H80v-2H0z"/>''')
write('lighthouse_lamp',16,16,'<path fill="#40dadd" d="M4 0h8v4h4v8h-4v4H4v-4H0V4h4z"/><path fill="#ffefa0" d="M4 4h8v8H4z"/><path fill="#fffce6" d="M6 6h4v4H6z"/>')
write('rail_packet',16,8,'<path fill="#39ced8" d="M0 2h8V0h4v2h4v4h-4v2H8V6H0z"/><path fill="#c2ffff" d="M4 3h7V2h2v4h-2V5H4z"/>')
write('node_base',48,64,'<path fill="#192d45" d="M4 44h40v20H4z"/><path fill="#425b70" d="M8 44h32v4H8z"/><path fill="#69808a" d="M12 48h24v4H12z"/><path fill="#173844" d="M12 54h24v6H12z"/><path fill="#43e9ee" d="M16 54h4v4h-4zm8 0h4v4h-4zm8 0h4v4h-4z"/>')
write('node_core',32,32,'<path fill="#152b43" d="M8 0h16v4h4v4h4v16h-4v4h-4v4H8v-4H4v-4H0V8h4V4h4z"/><path fill="#43e9ee" d="M10 4h12v4h4v4h2v8h-2v4h-4v4H10v-4H6v-4H4v-8h2V8h4z"/><path fill="#183d51" d="M12 10h8v4h4v6h-4v4h-8v-4H8v-6h4z"/><path fill="#b9ffff" d="M14 12h4v8h-4z"/>')
write('node_halo',48,48,'<path fill="#46e6e9" d="M16 0h16v4H16zM4 8h4v8H4zM0 16h4v16H0zM8 36h8v4H8zM16 44h16v4H16zM40 32h4v8h-4zM44 16h4v16h-4zM32 4h8v4h-8z"/>')
(OUT/'node_core_off.svg').write_text((OUT/'node_core.svg').read_text().replace('#43e9ee','#ba67d1').replace('#b9ffff','#edb9ff'))
print('Created',len(list(OUT.glob('*.svg'))),'editable SVG layers')
