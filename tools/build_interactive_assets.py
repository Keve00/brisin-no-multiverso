"""Rebuild approved BRISIN interaction board as editable pixel vector layers.

No embedded image is used. Source coordinates are isolated per object, backgrounds
are discarded, pixels are quantized, and equal-color horizontal runs become paths.
The source board is optional argv[1]; every emitted layer has a documented pivot.
"""
from pathlib import Path
import sys, json, math
from PIL import Image, ImageDraw
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'godot/assets/world_01/interactive'
SOURCE=Path(sys.argv[1]) if len(sys.argv)>1 else ROOT.parent/'generated_images/exec-d1fdcf1c-274d-4457-9a1a-2f8668f6d398.png'
OUT.mkdir(parents=True,exist_ok=True)
source=Image.open(SOURCE).convert('RGB')
manifest={}

def write(name,w,h,cells=None,body='',pivot=None):
 if cells is not None:
  groups={}
  for y in range(h):
   x=0
   while x<w:
    c=cells[y,x]
    if c[3]<128:x+=1;continue
    rgb=tuple(c[:3]);end=x+1
    while end<w and cells[y,end,3]>=128 and tuple(cells[y,end,:3])==rgb:end+=1
    groups.setdefault(rgb,[]).append(f'M{x} {y}h{end-x}v1h-{end-x}z');x=end
  body=''.join(f'<path fill="#{r:02x}{g:02x}{b:02x}" d="{"".join(paths)}"/>' for (r,g,b),paths in groups.items())
 (OUT/(name+'.svg')).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}" shape-rendering="crispEdges"><title>BRISIN {name}</title>{body}</svg>')
 manifest[name]={'canvas':[w,h],'pivot':pivot or [w/2,h/2]}

def sample(box):
 x,y,w,h=box
 a=np.array(source.crop((x,y,x+w,y+h)).resize((w//2,h//2),Image.Resampling.BOX))
 # Navy paper has no place in a standalone prop. Keep warm masonry/green flora.
 background=(a[:,:,0]<36)&(a[:,:,1]<57)&(a[:,:,2]<86)&(a[:,:,2]>a[:,:,1]*1.16)
 q=Image.fromarray(a).quantize(colors=40,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE).convert('RGB')
 rgba=np.zeros((h//2,w//2,4),dtype=np.uint8);rgba[:,:,:3]=np.array(q);rgba[:,:,3]=np.where(background,0,255)
 return rgba

def masked(a,polygons):
 m=Image.new('L',(a.shape[1],a.shape[0]));d=ImageDraw.Draw(m)
 for polygon in polygons:d.polygon(polygon,fill=255)
 out=a.copy();out[:,:,3]=np.minimum(out[:,:,3],np.array(m));return out

def cutout(a,mask):
 out=a.copy();out[:,:,3]=np.where(mask[:,:,3]>0,0,out[:,:,3]);return out

def centered_layer(a,cx,cy,size):
 # Retain coordinate system by placing the known source pivot at canvas center.
 out=np.zeros((size,size,4),dtype=np.uint8)
 for y in range(a.shape[0]):
  for x in range(a.shape[1]):
   nx=round(x-cx+size/2);ny=round(y-cy+size/2)
   if 0<=nx<size and 0<=ny<size:out[ny,nx]=a[y,x]
 return out

for state,x in [('off',36),('on',282)]:
 a=sample((x,100,256,320))
 # Individual blade polygons remove wind streaks and keep the mast independent.
 poly=[[(55,6),(70,6),(72,42),(67,50),(58,47)],[(62,48),(53,62),(18,82),(15,74),(49,54)],[(68,49),(80,48),(111,65),(108,79),(76,65)],[(53,47),(74,47),(77,61),(66,69),(54,63)]]
 blade=masked(a,poly)
 tower=masked(a,[[(55,65),(74,65),(74,131),(55,131)],[(0,128),(127,128),(127,158),(0,158)]])
 write('turbine_base_'+state,128,160,tower,pivot=[64,156])
 write('turbine_rotor_'+state,128,128,centered_layer(blade,64,55,128),pivot=[64,64])

for state,x in [('off',596),('on',828)]:
 a=sample((x,110,232,312))
 bulb=masked(a,[[(57,34),(70,34),(70,46),(57,46)]])
 write('lighthouse_base_'+state,116,156,cutout(a,bulb),pivot=[63,153])
 write('lighthouse_lamp_'+state,20,20,centered_layer(bulb,64,40,20),pivot=[10,10])

for state,x in [('off',1148),('on',1400)]:
 a=sample((x,144,256,280))
 flag=masked(a,[[(60,14),(88,14),(112,26),(117,35),(105,36),(100,50),(78,52),(60,43)]])
 lamp=masked(a,[[(35,60),(45,60),(45,76),(35,76)]])
 body=cutout(cutout(a,flag),lamp)
 # Remove the surrounding effect streaks and particles by restricting the silhouette.
 body=masked(body,[[(46,3),(65,3),(65,78),(106,101),(124,133),(0,136),(0,121),(25,91),(31,52),(47,52)]])
 write('checkpoint_base_'+state,128,140,body,pivot=[54,134])
 write('checkpoint_flag_'+state,128,128,centered_layer(flag,60,18,128),pivot=[64,64])
 write('checkpoint_lamp_'+state,24,24,centered_layer(lamp,40,68,24),pivot=[12,12])

for state,x in [('off',36),('on',282)]:
 a=sample((x,550,240,260));cy=52;cx=63
 yy,xx=np.indices(a.shape[:2]);in_core=(xx-cx)**2+(yy-cy)**2<=23**2
 core=a.copy();core[:,:,3]=np.where(in_core,core[:,:,3],0)
 frame=a.copy();frame[:,:,3]=np.where(in_core,0,frame[:,:,3])
 frame=masked(frame,[[(9,23),(29,8),(85,6),(107,26),(106,99),(120,125),(1,128),(9,106)]])
 write('node_frame_'+state,120,130,frame,pivot=[63,127])
 write('node_core'+('' if state=='on' else '_off'),64,64,centered_layer(core,cx,cy,64),pivot=[32,32])

for state,x in [('off',574),('on',832)]:
 a=sample((x,532,256,280));cx=62;cy=69
 yy,xx=np.indices(a.shape[:2]);inside=(xx-cx)**2+(yy-cy)**2<35**2
 core=a.copy();core[:,:,3]=np.where(inside,core[:,:,3],0)
 # Empty Offline opening intentionally becomes a calm, faint vortex, never a disk of paper.
 frame=a.copy();frame[:,:,3]=np.where(inside,0,frame[:,:,3])
 frame=masked(frame,[[(6,9),(92,3),(121,23),(128,127),(125,138),(1,138),(1,34)]])
 write('portal_frame_'+state,128,140,frame,pivot=[62,136])
 if state=='off':
  write('portal_core_off',80,80,body='<path fill="#3a3154" opacity=".5" d="M28 15h22v3h9v5h7v9h3v17h-3v-16h-4v-8h-7v-4H28v4H18v9h-3V24h5v-6h8zM14 45h3v10h8v5h25v-4h10v-9h3v12h-8v5H24v-5H14z"/><path fill="#62507a" opacity=".7" d="M28 29h20v3h6v6h3v10h-3v6H35v-3h-6v-7h4v5h17V38h-4v-5H28z"/>',pivot=[40,40])
 else:write('portal_core',80,80,centered_layer(core,cx,cy,80),pivot=[40,40])

for state,y in [('off',558),('on',706)]:
 # Endcaps and short cable modules repeat at their original size.
 post=sample((1160,y,84,104));write('rail_post_'+state,42,52,post,pivot=[30,24])
 segment=sample((1308,y+24,48,36));write('rail_segment_'+state,24,18,segment,pivot=[0,9])
write('rail_packet',12,12,body='<path fill="#0a647d" d="M3 0h6v3h3v6H9v3H3V9H0V3h3z"/><path fill="#35e5ef" d="M3 2h6v1h1v6H9v1H3V9H2V3h1z"/><path fill="#d8ffed" d="M4 4h4v4H4z"/>')
write('node_halo',80,80,body='<path fill="#49e7e5" d="M25 2h8v2h-8zM48 4h8v2h-8zM66 14h4v6h-4zM76 35h2v10h-2zM63 65h6v3h-6zM36 76h8v2h-8zM9 61h3v7H9zM2 28h2v9H2z"/>')
write('lighthouse_beam',192,48,body='<path fill="#ffd869" opacity=".07" d="M0 21h24v-3h24v-3h24v-3h24V9h24V6h24V3h24V0h24v48h-24v-3h-24v-3h-24v-3H96v-3H72v-3H48v-3H24v-3H0z"/><path fill="#fff3ba" opacity=".16" d="M0 22h48v-2h48v-2h48v-2h48v16h-48v-2H96v-2H48v-2H0z"/>',pivot=[0,24])
(OUT/'manifest.json').write_text(json.dumps({'source':SOURCE.name,'grid':'1 logical px = 2 source px','assets':manifest},indent=2)+'\n')
print(f'Generated {len(manifest)} editable SVG layers for six interaction families.')
