#!/usr/bin/env python3
"""Place small SVG ripples only inside approved sea geometry; no new coastline."""
from pathlib import Path
from PIL import Image
import subprocess,json,tempfile
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'godot/assets/background_svg'
with tempfile.TemporaryDirectory() as folder:
 png=Path(folder)/'sea.png'
 subprocess.run(['inkscape',str(OUT/'sea.svg'),'--export-type=png','--export-filename='+str(png)],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
 alpha=Image.open(png).convert('RGBA').getchannel('A')
 points=[]
 for row,y in enumerate(range(442,710,42)):
  for x in range(40+(row%2)*40,2130,112):
   # Padded sweep encloses every shifted64x12 ripple, so land cannot be washed.
   if alpha.crop((x-40,y-10,x+40,y+10)).getextrema()[0]>=250:points.append([x,y])
(OUT/'ripple.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="64" height="12" viewBox="0 0 64 12" shape-rendering="crispEdges"><path fill="#65D7E6" d="M0 6h12v2H0zM12 4h12v2H12zM26 2h14v2H26zM42 4h10v2H42zM52 6h12v2H52z"/><path fill="#BFF8FF" d="M14 4h8v2h-8zM30 2h6v2h-6zM54 6h6v2h-6z"/><path fill="#127994" d="M12 8h12v2H12zM38 6h12v2H38z"/></svg>')
(OUT/'ripple_positions.json').write_text(json.dumps(points))
print('Sea-only ripple placements:',len(points))
