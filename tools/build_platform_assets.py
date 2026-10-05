"""Vectorize the 18 approved platform concepts as editable pixel SVG layers.

Every source pixel is sampled at the same 1/2 scale in X and Y. Only exterior
navy is flood removed; silhouettes, purple shadows and enclosed dark details
remain. No raster image is embedded. Ground modules deliberately tile/crop.
Run: /usr/bin/python3 tools/build_platform_assets.py [concept.png]
"""
from pathlib import Path
from collections import defaultdict, deque
import json
import sys
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'godot/assets/world_01/platforms'
SOURCE = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / 'generated_images/exec-d24d424c-04f7-41cb-9a46-cc76cb199712.png'
# Bounds and contact Y are in the approved concept image, before uniform /2.
SPECS = {
 'coastal': [(32,118,302,357,217),(337,118,529,357,217)],
 'sand': [(590,121,867,358,220),(892,165,1092,360,220)],
 'steps': [(1130,122,1403,359,178),(1450,143,1653,358,187)],
 'thin': [(32,443,305,584,491),(343,438,527,584,492)],
 'cracked': [(600,435,827,597,479),(875,438,1073,597,481)],
 'raft': [(1137,461,1417,565,482),(1424,452,1652,565,482)],
 'wood_bridge': [(23,682,358,858,744),(369,684,545,858,744)],
 'signal': [(613,684,827,855,696),(863,685,1066,824,696)],
 'wind_island': [(1135,665,1401,857,715),(1420,665,1658,856,715)],
}

def exterior_mask(im):
 w,h=im.size; px=im.load(); seen=set(); todo=deque()
 def bg(x,y):
  r,g,b=px[x,y]; return r<42 and g<63 and b<91
 for x in range(w):
  for y in (0,h-1):
   if bg(x,y): seen.add((x,y)); todo.append((x,y))
 for y in range(h):
  for x in (0,w-1):
   if bg(x,y) and (x,y) not in seen: seen.add((x,y)); todo.append((x,y))
 while todo:
  x,y=todo.popleft()
  for nx,ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
   if 0<=nx<w and 0<=ny<h and (nx,ny) not in seen and bg(nx,ny):
    seen.add((nx,ny)); todo.append((nx,ny))
 # Navy holes between vines/effects must be transparent as well.
 return seen | {(x,y) for y in range(h) for x in range(w) if bg(x,y)}

def write_svg(path, im, title):
 rows=defaultdict(list)
 for y in range(im.height):
  x=0
  while x<im.width:
   c=im.getpixel((x,y)); start=x; x+=1
   while x<im.width and im.getpixel((x,y))==c: x+=1
   if c[3]: rows['#%02x%02x%02x'%c[:3]].append(f'M{start} {y}h{x-start}v1h-{x-start}z')
 body=''.join(f'<path fill="{c}" d="{"".join(ds)}"/>' for c,ds in rows.items())
 path.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{im.width}" height="{im.height}" viewBox="0 0 {im.width} {im.height}" shape-rendering="crispEdges"><title>{title}</title>{body}</svg>')

def main():
 OUT.mkdir(parents=True,exist_ok=True); source=Image.open(SOURCE).convert('RGB'); meta={}; sheet=Image.new('RGBA',(600,9*200),(14,24,40,255)); pen=ImageDraw.Draw(sheet)
 for row,(kind,specs) in enumerate(SPECS.items()):
  meta[kind]=[]
  for variation,(l,t,r,b,contact) in enumerate(specs):
   crop=source.crop((l,t,r,b)); removed=exterior_mask(crop)
   small=crop.resize(((r-l+1)//2,(b-t+1)//2),Image.Resampling.NEAREST)
   palette=small.quantize(colors=48,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE).convert('RGB')
   layer=Image.new('RGBA',small.size)
   for y in range(small.height):
    for x in range(small.width):
     sx=min(crop.width-1,x*2+1); sy=min(crop.height-1,y*2+1)
     if (sx,sy) not in removed: layer.putpixel((x,y),(*palette.getpixel((x,y)),255))
   # Disconnected subpixel antialias specks/frame remnants are not assets.
   visited=set()
   for y in range(layer.height):
    for x in range(layer.width):
     if (x,y) in visited or not layer.getpixel((x,y))[3]: continue
     part={(x,y)}; queue=deque([(x,y)]); visited.add((x,y))
     while queue:
      ax,ay=queue.popleft()
      for nx,ny in ((ax-1,ay),(ax+1,ay),(ax,ay-1),(ax,ay+1)):
       if 0<=nx<layer.width and 0<=ny<layer.height and (nx,ny) not in visited and layer.getpixel((nx,ny))[3]:
        visited.add((nx,ny)); part.add((nx,ny)); queue.append((nx,ny))
     at_frame_corner=any(py>layer.height-10 and (px<8 or px>layer.width-8) for px,py in part)
     if len(part)<7 or (len(part)<30 and at_frame_corner):
      for px,py in part: layer.putpixel((px,py),(0,0,0,0))
   full=Image.new('RGBA',(200,176)); contact_local=(contact-t)//2; dx=(200-layer.width)//2; dy=64-contact_local
   full.alpha_composite(layer,(dx,dy)); stem=f'{kind}_{variation}'
   write_svg(OUT/f'{stem}.svg',full,f'{kind} variation {variation}; pivot 100,64')
   # Fixed shared canvas for decoration: keep its source offset and pivot.
   deco=full.copy(); deco.paste((0,0,0,0),(0,64,200,176)); write_svg(OUT/f'{stem}_deco.svg',deco,stem+' decoration')
   ground=layer.crop((0,contact_local,layer.width,layer.height))
   if kind == 'wind_island':
    fx=Image.new('RGBA',full.size)
    for y in range(ground.height):
     for x in range(ground.width):
      color=ground.getpixel((x,y)); cr,cg,cb,alpha=color
      if y>12 and alpha and cg>cr and cb>cr*0.55:
       fx.putpixel((dx+x,64+y),color); ground.putpixel((x,y),(0,0,0,0))
    write_svg(OUT/f'{stem}_wind.svg',fx,stem+' animated wind layer')
   # Empty padding at the walking surface must not become repeated floor gaps.
   # Crop the ground horizontally by its continuous top, never scale X/Y apart.
   crop_left,crop_right=0,ground.width
   if kind!='steps':
    xs=[x for x in range(ground.width) if any(ground.getpixel((x,y))[3] for y in range(min(5,ground.height)))]
    if xs:
     crop_left,crop_right=min(xs),max(xs)+1
     ground=ground.crop((crop_left,0,crop_right,ground.height))
     # Decorative breaks in the concept cannot leave an invisible walkable gap.
     present=[x for x in range(ground.width) if any(ground.getpixel((x,y))[3] for y in range(min(8,ground.height)))]
     for x in range(ground.width):
      if x not in present:
       neighbor=min(present,key=lambda col:abs(col-x))
       for y in range(min(12,ground.height)):ground.putpixel((x,y),ground.getpixel((neighbor,y)))
   write_svg(OUT/f'{stem}_ground.svg',ground,stem+' modular ground; surface padding cropped')
   meta[kind].append({'canvas':[200,176],'pivot':[100,64],'ground_size':list(ground.size),'cap':min(24,ground.width//3),'surface_crop_x':[crop_left,crop_right],'source_crop':[l,t,r,b],'source_contact_y':contact,'uniform_source_scale':0.5})
   sheet.alpha_composite(full.resize((300,264),Image.Resampling.NEAREST),(variation*300,row*200-25))
   pen.text((variation*300+8,row*200+180),f'{kind} / {variation}',fill=(255,190,80))
 (OUT/'manifest.json').write_text(json.dumps(meta,indent=2))
 # QA file stays in scratch, outside reusable game assets.
 qa=ROOT.parent/'platforms-preview.png'; sheet.convert('RGB').save(qa)
 print(f'56 real SVGs generated; preview {qa}')

if __name__=='__main__': main()
