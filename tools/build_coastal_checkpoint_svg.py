from pathlib import Path
from PIL import Image,ImageDraw
import json,shutil
root=Path(__file__).resolve().parents[1]
src=root/'tools/reference_art/approved-checkpoint.png'

out=root/'godot/assets/world_01/checkpoint_coastal';out.mkdir(exist_ok=True)
im=Image.open(src).convert('RGB')
mask=Image.new('1',im.size);d=ImageDraw.Draw(mask)
d.polygon([(537,392),(566,392),(566,454),(591,454),(599,490),(614,491),(614,540),(639,541),(639,617),(618,618),(618,670),(641,673),(645,734),(665,736),(691,734),(696,807),(403,807),(403,773),(451,771),(451,671),(459,650),(450,616),(450,552),(457,490),(475,481),(504,487),(507,455),(537,455)],fill=1)
# Sample the approved pixel grid, then encode colors as actual vector runs.
small=im.crop((400,392,700,812)).resize((75,105),Image.Resampling.BOX).quantize(colors=32).convert('RGB')
core=[];base=[]
for y in range(105):
 for x in range(75):
  sx,sy=400+x*4+2,392+y*4+2
  r,g,b=small.getpixel((x,y))
  if not mask.getpixel((sx,sy)) or (b>85 and b>r*1.2 and b>g*.96):continue
  color='#%02x%02x%02x'%(r,g,b)
  item=(x+3,y+20,color)
  (core if 512<=sx<=581 and 574<=sy<=639 else base).append(item)
def svg(name,cells):
 parts=[]
 for x,y,c in cells:parts.append(f'<path fill="{c}" d="M{x} {y}h1v1h-1z"/>')
 (out/name).write_text('<svg xmlns="http://www.w3.org/2000/svg" width="80" height="128" viewBox="0 0 80 128" shape-rendering="crispEdges">'+''.join(parts)+'</svg>')
svg('base.svg',base);svg('core_off.svg',core)
cyan=['#086c82','#128da2','#16afbf','#29d6df','#5eeaf0','#b4ffff']
svg('core_on.svg',[(x,y,cyan[min(5,max(0,int((int(c[1:3],16)+int(c[3:5],16)+int(c[5:7],16))/3/43)))]) for x,y,c in core])
for frame in range(8):
 cells=[]
 # Two stepped signal ripples rise at 4 fps; body and base remain immobile.
 shift=frame//2
 for row,w in [(16-shift,12),(9-shift,22)]:
  for xx in range(40-w//2,40+w//2):cells.extend([(xx,row,'#43e9ee'),(xx,row+1,'#43e9ee')])
  for side in [-1,1]:
   edge=40+side*(w//2)
   for yy in range(row+2,row+5):cells.extend([(edge,yy,'#43e9ee'),(edge+side,yy,'#43e9ee')])
 svg(f'signal_{frame:02}.svg',cells)
(out/'manifest.json').write_text(json.dumps({'canvas':[80,128],'pivot':[40,125],'scale':1,'source':'tools/reference_art/approved-checkpoint.png','technique':'palette sampled pixel paths, no embedded raster; Godot animates signal frames at 4fps','body_height':105,'signal_frames':8,'reduced_flash':'static signal frame 0 and stable core'},indent=2))
