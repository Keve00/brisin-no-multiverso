#!/usr/bin/env python3
"""Vector-only mobile UI, matched to the approved 05/10 mockups."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'godot/assets/ui/mobile';OUT.mkdir(exist_ok=True)
def step(x,y,w,h,c=24,s=4):
 pts=[(x+c,y),(x+w-c,y)]
 for i in range(c//s):pts.extend([(x+w-c+(i+1)*s,y+i*s),(x+w-c+(i+1)*s,y+(i+1)*s)])
 pts.append((x+w,y+h-c))
 for i in range(c//s):pts.extend([(x+w-i*s,y+h-c+(i+1)*s),(x+w-(i+1)*s,y+h-c+(i+1)*s)])
 pts.append((x+c,y+h))
 for i in range(c//s):pts.extend([(x+c-(i+1)*s,y+h-i*s),(x+c-(i+1)*s,y+h-(i+1)*s)])
 pts.append((x,y+c))
 for i in range(c//s):pts.extend([(x+i*s,y+c-(i+1)*s),(x+(i+1)*s,y+c-(i+1)*s)])
 return 'M'+'L'.join(f'{a},{b}' for a,b in pts)+'Z'
def path(d,color):return f'<path fill="{color}" d="{d}"/>'
def svg(name,w,h,body):
 (OUT/(name+'.svg')).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}" shape-rendering="crispEdges">{body}</svg>\n')
def frame(name,w,h,primary=False,pressed=False,corner=24):
 body=path(step(0,6,w,h-6,corner),'#100A04')
 body+=path(step(0,0,w,h-8,corner),'#100A04')
 body+=path(step(4,4,w-8,h-16,corner-4),'#FFB000')
 body+=path(step(8,8,w-16,h-24,corner-8),'#FFD84D')
 body+=path(step(12,12,w-24,h-32,corner-12),'#FF7A00' if primary else '#3B220C')
 body+=path(step(16,16,w-32,h-40,max(4,corner-16)),'#A84100' if pressed and primary else '#241508' if pressed else '#FF7A00' if primary else '#2D190A')
 # Warm edge light and a short hard shadow, no blurred/glass treatment.
 body+=f'<path fill="#FFF3CD" d="M{corner} 8H{w-corner}V12H{corner}Z"/>'
 svg(name,w,h,body)
for primary in [False,True]:
 for pressed in [False,True]:
  suffix=('_primary' if primary else '')+('_pressed' if pressed else '')
  frame('action'+suffix,128,128,primary,pressed)
  frame('menu'+suffix,560,100,primary,pressed,16)
for pressed in [False,True]:frame('direction'+('_pressed' if pressed else ''),160,128,False,pressed)
icons={
 'left':'M12 28H20V20H28V12H36V4H44V24H60V40H44V60H36V52H28V44H20V36H12Z',
 'right':'M52 28H44V20H36V12H28V4H20V24H4V40H20V60H28V52H36V44H44V36H52Z',
 'jump':'M28 4H36V12H44V20H52V28H60V36H44V60H20V36H4V28H12V20H20V12H28Z',
 'dash':'M36 4H56L36 28H56L20 60H12L28 36H8Z',
 'pause':'M16 8H28V56H16ZM40 8H52V56H40Z',
 'pulse':'M4 20H8V12H12V8H16V16H12V24H8V40H12V48H16V56H12V52H8V44H4ZM20 20H24V16H28V24H24V40H28V48H24V44H20ZM36 16H40V20H44V44H40V48H36V40H40V24H36ZM48 8H52V12H56V20H60V44H56V52H52V56H48V48H52V40H56V24H52V16H48ZM28 28H36V36H28Z',
 'chip':'M20 4H40V8H48V12H52V56H48V60H16V56H12V12H16V8H20Z'
}
for name,d in icons.items():
 body=f'<g transform="translate(2 2)">{path(d,"#100A04")}</g>'+path(d,'#FFD84D')
 if name=='chip':
  body+=path('M20 12H28V24H20ZM32 12H36V24H32ZM40 16H44V24H40ZM20 28H44V40H20ZM20 44H28V52H20ZM32 44H44V52H32Z','#7A3000')
 svg('icon_'+name,64,64,body)
print('Mobile SVG frames and icons generated; no embedded raster.')
# A heavier weight of the existing original pixel glyphs: identical metrics,
# doubled grid and one-pixel stroke extension. No substitute system font.
from PIL import Image
import re
source=ROOT/'godot/assets/ui'
original=Image.open(source/'brisin_pixel.png').convert('RGBA')
atlas=Image.new('RGBA',(256,original.height*2))
records=[]
for line in (source/'brisin_pixel.fnt').read_text().splitlines():
 if not line.startswith('char id='):continue
 g={k:int(v) for k,v in re.findall(r'(\w+)=(-?\d+)',line)}
 x,y=g['x']*2,g['y']*2
 for py in range(g['height']):
  for px in range(g['width']):
   visible=bool(original.getpixel((g['x']+px,g['y']+py))[3])
   if g['id']==48 and 3<=py<=9:
    visible=['01110','10001','10001','10001','10001','10001','01110'][py-3][px]=='1'
   if visible:
    for dy in range(3):
     for dx in range(3):
      if y+py*2+dy<atlas.height:atlas.putpixel((x+px*2+dx,y+py*2+dy),(255,255,255,255))
 records.append(f"char id={g['id']} x={x} y={y} width=11 height=24 xoffset=0 yoffset=0 xadvance=12 page=0 chnl=15")
atlas.save(OUT/'brisin_mobile_bold.png')
(OUT/'brisin_mobile_bold.fnt').write_text('\n'.join(['info face="Brisin Mobile Bold" size=24 bold=1 italic=0 unicode=1 smooth=0 aa=0',f'common lineHeight=24 base=20 scaleW=256 scaleH={atlas.height} pages=1 packed=0','page id=0 file="brisin_mobile_bold.png"',f'chars count={len(records)}']+records)+'\n')
