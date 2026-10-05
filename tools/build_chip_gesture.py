#!/usr/bin/env python3
"""SVG throw body/hand from the approved source palette, preserving locomotion feet."""
from pathlib import Path
from PIL import Image, ImageDraw
import json
import xml.etree.ElementTree as ET
import build_brisin_menu_svg as menu
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'godot/assets/player/chip_gesture_svg'
PALETTE=[tuple(bytes.fromhex(c[1:])) for c in menu.PALETTE]
SIZE=(144,128)
# Release then follow-through/return. Coordinates use the same rig as the menu.
POSES=[((54,48),(58,48),(61,50)),((54,48),(61,47),(64,49)),
       ((54,48),(60,48),(63,50)),((54,48),(57,50),(59,52)),
       ((54,48),(55,51),(57,53)),((54,48),(55,52),(56,54))]
def crop_rig(im):
 return im.crop((8,8,80,72)).resize(SIZE,Image.Resampling.NEAREST)
def svg(im):
 groups={}
 for y in range(im.height):
  x=0
  while x<im.width:
   c=im.getpixel((x,y))
   if not c[3]:x+=1;continue
   start=x;x+=1
   while x<im.width and im.getpixel((x,y))==c:x+=1
   color='#%02X%02X%02X'%c[:3]
   groups.setdefault(color,[]).append(f'M{start} {y}h{x-start}v1h-{x-start}z')
 return '<svg xmlns="http://www.w3.org/2000/svg" width="144" height="128" viewBox="0 0 144 128" shape-rendering="crispEdges">'+''.join(f'<path fill="{c}" d="{"".join(p)}"/>' for c,p in groups.items())+'</svg>'
def remove_source_fragments(im):
 # Remove isolated skirt-outline pixels left by lower-body extraction; keep limbs.
 pixels={(x,y) for y in range(128) for x in range(144) if im.getpixel((x,y))[3]}
 components=[]
 while pixels:
  todo=[pixels.pop()];component=set(todo)
  while todo:
   x,y=todo.pop()
   for dx in (-1,0,1):
    for dy in (-1,0,1):
     point=(x+dx,y+dy)
     if point in pixels:pixels.remove(point);component.add(point);todo.append(point)
  components.append(component)
 core=max(components,key=len)
 for component in components:
  if component is core:continue
  assert len(component)<=24, 'Detached leg in source extraction'
  for point in component:im.putpixel(point,(0,0,0,0))
 return im

def main():
 OUT.mkdir(parents=True,exist_ok=True)
 body=menu.BODY.copy();body.alpha_composite(menu.FACE)
 rear=menu.blank();menu.limb(rear,[(36,48),(32,52),(32,54)])
 rear.alpha_composite(body);base=crop_rig(rear)
 meta=json.loads((ROOT/'godot/assets/player/animations.json').read_text())
 refs=[];anim_text=[];preview=[]
 for name,info in meta.items():
  sheet=Image.open(ROOT/f'godot/assets/player/{name}.png').convert('RGBA')
  ids=[]
  for i in range(info['frames']):
   src=sheet.crop((i*144,0,(i+1)*144,128)).resize((72,64),Image.Resampling.NEAREST)
   im=base.copy();legs=Image.new('RGBA',(72,64))
   for y in range(49,64):
    for x in range(72):
     r,g,b,a=src.getpixel((x,y))
     if a<160:continue
     c=min(PALETTE,key=lambda c:sum((u-v)**2 for u,v in zip((r,g,b),c)))
     if c in PALETTE[:5]:continue
     legs.putpixel((x,y),c+(255,))
   d=ImageDraw.Draw(legs)
   for hx in [32,40]:
    candidates=[(x,y) for y in range(49,59) for x in range(18 if hx==32 else 36,36 if hx==32 else 56) if legs.getpixel((x,y))[3]]
    if candidates:
     end=min(candidates,key=lambda p:(p[0]-hx)**2+(p[1]-48)**2)
     d.line([(hx,47),end],fill=menu.INK,width=3)
     d.line([(hx,47),end],fill=menu.BROWN,width=2)
   layer=legs.resize(SIZE,Image.Resampling.NEAREST)
   layer.alpha_composite(base);im=remove_source_fragments(layer)
   # All body textures share canvas, base and source locomotion frame index.
   file=f'body_{name}_{i:02d}.svg';(OUT/file).write_text(svg(im))
   ids.append(f'body_{name}_{i}');refs.append(f'[ext_resource type="Texture2D" path="res://assets/player/chip_gesture_svg/{file}" id="{ids[-1]}"]')
   if i==0:preview.append((name,im))
  frames=',\n'.join('{"duration":1.0,"texture":ExtResource("'+ref+'")}' for ref in ids)
  anim_text.append('{"frames":['+frames+'],"loop":true,"name":&"'+name+'","speed":12.0}')
 (OUT/'body_frames.tres').write_text('[gd_resource type="SpriteFrames" load_steps='+str(len(refs)+1)+' format=3]\n'+'\n'.join(refs)+'\n[resource]\nanimations = ['+',\n'.join(anim_text)+']\n')
 arms=[]
 for i,points in enumerate(POSES):
  arm=menu.blank();menu.limb(arm,list(points),True);arm=crop_rig(arm)
  (OUT/f'hand_{i:02d}.svg').write_text(svg(arm));arms.append(arm)
 # Composite only for QA; actual assets remain modular vectors.
 qa=ROOT/'qa';qa.mkdir(exist_ok=True)
 board=Image.new('RGBA',(144*6,128*3),(36,75,99,255))
 for row,(_,body) in enumerate(preview):
  for i,arm in enumerate(arms):
   cell=body.copy();cell.alpha_composite(arm);board.alpha_composite(cell,(144*i,128*row))
 board.resize((1728,768),Image.Resampling.NEAREST).convert('RGB').save(qa/'chip_gesture_contact_sheet.png')
 ET.register_namespace('', 'http://www.w3.org/2000/svg')
 vector=ET.Element('{http://www.w3.org/2000/svg}svg',{'width':'864','height':'384','viewBox':'0 0 864 384'})
 ET.SubElement(vector,'rect',{'width':'864','height':'384','fill':'#244b63'})
 for row,(anim,frame) in enumerate([('walk',0),('run',7),('jump',3)]):
  for col in range(6):
   group=ET.SubElement(vector,'g',{'transform':f'translate({col*144},{row*128})'})
   for filename in [f'body_{anim}_{frame:02d}.svg',f'hand_{col:02d}.svg']:
    for child in ET.parse(OUT/filename).getroot():group.append(child)
 (qa/'chip_gesture_paths.svg').write_text(ET.tostring(vector,encoding='unicode'))
 (OUT/'manifest.json').write_text(json.dumps({'canvas':SIZE,'source_ground_pivot':[72,120],'visual_origin':[72,120],'duration':0.30,'release_frame':0,'hand_frames':6,'body_frames':{k:v['frames'] for k,v in meta.items()},'source':'walk.png frame0 body, current locomotion frame legs; approved menu palette/rig','technique':'SVG body textures preserve locomotion frame index; separate attached SVG hand follows release and returns; no SMIL or raster embedding','shoulder':[92,80],'release_palm':[106,84]},indent=2))
 print('Generated 64 body + 6 attached hand SVGs')
if __name__=='__main__':main()
