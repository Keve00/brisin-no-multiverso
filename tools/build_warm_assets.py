#!/usr/bin/env python3
"""Transfer approved warm palettes to native paths without changing silhouettes.

The contrast selection chooses a palette per family. Paths, alpha, canvases and
pivots remain byte-identical after stripping RGB literals. A hash ledger makes
exports idempotent and reapplies the transfer after upstream regeneration.
"""
from pathlib import Path
from collections import defaultdict
import colorsys, hashlib, json, re
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT/'godot/assets'
REF = ROOT/'tools/reference_art/warm'
LEDGER = ASSETS/'warm_palette_manifest.json'
RGB = re.compile(r'#[0-9a-fA-F]{6}\b')
BOXES = {
 'platforms': {'Palmeira':(20,25,554,334),'Cogumelos':(580,85,994,321),'Degraus':(1020,68,1517,316),'Ponte':(40,355,541,519),'Rocha frágil':(570,361,1013,535),'Carga':(1037,365,1508,510),'Rail':(32,590,551,725),'Plataforma ativa':(580,550,1007,744),'Vento':(1032,527,1519,794)},
 'characters': {'Brisin':(95,91,332,346),'Cristal':(391,96,641,345),'Esporo':(757,98,1002,343),'Magnético':(1155,87,1405,343),'Escavador':(239,386,576,628),'Plasma':(617,392,833,627),'Satélite':(1023,379,1290,627),'Corrompido':(110,660,419,926),'Sentinela':(523,670,775,925),'Orbital':(834,687,1112,925),'ETzinho':(1210,657,1494,926)},
 'objects': {'Turbina off':(31,73,169,284),'Turbina on':(171,77,303,284),'Farol off':(338,72,430,284),'Farol on':(434,73,531,284),'Checkpoint off':(557,86,684,284),'Checkpoint on':(689,84,818,284),'Nó off':(858,80,1035,284),'Nó on':(1038,80,1220,284),'Portal off':(1222,83,1388,284),'Portal on':(1379,80,1521,284),'Rail de sinal':(25,376,327,512),'Gemas':(361,384,554,509),'Chip':(622,388,802,484),'Pulso':(828,387,965,510),'Dash':(1004,386,1137,495),'Tiro':(1208,393,1332,486),'Vento':(1366,381,1518,498)}
}
PLATFORMS = dict(zip(['coastal','sand','steps','thin','cracked','raft','wood_bridge','signal','wind_island'],BOXES['platforms']))
CHARACTERS = dict(zip(['cristal','esporo','magnetico','escavador','plasma','satelite','corrompido','sentinela','orbital','etzinho'],list(BOXES['characters'])[1:]))

def sha(s): return hashlib.sha256(s.encode()).hexdigest()
def geometry(s): return sha(RGB.sub('#RGB',s))
def family(path):
 s=path.relative_to(ASSETS).as_posix();name=path.stem
 if 'enemies/cosmic/' in s:
  variant=s.split('/')[2]
  return ('characters',CHARACTERS[variant]) if variant in CHARACTERS else ('objects','Tiro')
 if s.startswith('enemies/'): return 'characters','Corrompido'
 if s.startswith('world_01/platforms/'):
  for key in sorted(PLATFORMS,key=len,reverse=True):
   if name.startswith(key): return 'platforms',PLATFORMS[key]
 if s.startswith('player/'):
  if '/effects/' not in s: return 'characters','Brisin'
  return 'objects', 'Chip' if 'chip' in name else ('Pulso' if 'pulse' in name else 'Dash')
 if 'portal' in s: return 'objects','Portal off' if '_off' in name else 'Portal on'
 for key,label in [('node','Nó'),('turbine','Turbina'),('lighthouse','Farol'),('checkpoint','Checkpoint')]:
  if key in s: return 'objects',label+(' off' if '_off' in name else ' on')
 if 'rail' in s or 'signal' in name: return 'objects','Rail de sinal'
 if 'wind' in name: return 'objects','Vento'
 if 'gem' in name or 'pickup' in name: return 'objects','Gemas'
 if 'palm' in name or 'vegetation' in name: return 'platforms','Palmeira'
 return 'platforms','Rocha frágil'

def palettes():
 stored=REF/'palettes.json'
 if stored.exists():
  return {(group,name):np.array(colors,float) for group,entries in json.loads(stored.read_text()).items() for name,colors in entries.items()}
 selection=json.loads((REF/'selection.json').read_text());out={}
 for group,entries in BOXES.items():
  for name,box in entries.items():
   revised=selection[group][name]['use_revision']
   crop=Image.open(REF/f'{group}-{"revised" if revised else "initial"}.png').convert('RGB').crop(box)
   a=np.asarray(crop).reshape(-1,3).astype(float)
   # Exclude the solid plum approval board. Keep actual copper/cream/plum ink.
   board=np.array(crop)[0,0].astype(float)
   a=a[np.linalg.norm(a-board,axis=1)>24]
   samples=Image.fromarray(a.astype('uint8').reshape(1,-1,3))
   quant=samples.quantize(colors=64,method=Image.Quantize.MEDIANCUT)
   colors=np.array(quant.getpalette()[:192]).reshape(-1,3).astype(float)
   colors=colors[colors.max(axis=1)>12]
   out[group,name]=colors
 serial={group:{name:out[group,name].astype(int).tolist() for name in entries} for group,entries in BOXES.items()}
 stored.write_text(json.dumps(serial,ensure_ascii=False,separators=(',',':'))+'\n')
 return out

def ramp(t,colors):
 p=max(0,min(1,t))*(len(colors)-1);i=min(int(p),len(colors)-2)
 return np.array(colors[i])*(1-(p-i))+np.array(colors[i+1])*(p-i)

def recolor(hexcolor,group,name,palette,emission=False):
 c=np.array([int(hexcolor[i:i+2],16) for i in [1,3,5]],float)
 h,s,v=colorsys.rgb_to_hsv(*(c/255));lum=float(c@[.2126,.7152,.0722])/255
 # Preserve existing orange body, gold SIM contacts and dark facial ink.
 cold=.17<h<.98 and s>.16
 if not cold:
  if s<.15 and v>.72: target=ramp(lum,[(235,212,185),(255,247,222)])
  elif s<.18 and v>.25: target=ramp(lum,[(62,43,47),(187,142,117),(255,240,210)])
  else:return hexcolor.lower()
 elif name=='Plataforma ativa' and .45<h<.86 and lum<.74:
  # Solid plum/copper metal separates the hovering platform from orange sky.
  # High-value energy and contact highlights stay cream; alpha is unchanged.
  target=ramp(lum/.74,[(35,20,39),(49,29,43),(74,43,53),(103,60,61),(142,89,73)])
 elif lum<.18 and not emission:
  target=ramp(lum/.18,[(29,17,34),(58,31,45)])
 elif name=='ETzinho' and .19<h<.48:
  target=ramp(lum,[(79,40,46),(137,74,65),(206,128,99),(255,207,167),(255,239,206)])
 elif h>.86:
  target=ramp(lum,[(51,24,46),(104,43,58),(176,65,70),(237,111,102),(255,184,157),(255,240,211)])
 elif .45<h<.65 or emission:
  target=ramp(lum,[(141,60,39),(208,107,42),(255,169,62),(255,218,132),(255,250,216)])
 elif .17<h<.45:
  target=ramp(lum,[(57,33,43),(104,52,44),(178,88,46),(237,154,68),(255,222,154)])
 else:
  target=ramp(lum,[(32,18,37),(65,35,51),(110,57,65),(164,83,75),(225,152,111),(255,232,183)])
 # Transfer actual approved swatches while avoiding a jump to the board color.
 dist=np.sum((palette-target)**2*np.array([.4,.45,.15]),axis=1)
 closest=palette[np.argmin(dist)]
 if np.min(dist)<850:target=closest
 return '#'+''.join(f'{int(round(x)):02x}' for x in target)

def locomotion():
 from build_cosmic_assets import write
 meta=json.loads((ASSETS/'player/animations.json').read_text());folder=ASSETS/'player/locomotion_svg'
 paths=[];animations=[]
 for name in ['run','walk','jump']:
  info=meta[name];atlas=Image.open(ASSETS/f'player/{name}.png').convert('RGBA');frames=[]
  for i in range(info['frames']):
   path=folder/f'{name}/{i:02}.svg'
   if not path.exists():
    # RGB quantization keeps the exact original alpha silhouette and frame grid.
    frame=atlas.crop((i*144,0,(i+1)*144,128));alpha=frame.getchannel('A')
    frame=frame.convert('RGB').quantize(colors=48,dither=Image.Dither.NONE).convert('RGBA');frame.putalpha(alpha)
    write(path,frame,[72,120])
   paths.append(path);frames.append(len(paths))
  animations.append((name,info['fps'],frames))
 lines=[f'[gd_resource type="SpriteFrames" load_steps={len(paths)+1} format=3]','']
 for i,path in enumerate(paths,1):lines.append(f'[ext_resource type="Texture2D" path="res://{path.relative_to(ROOT/"godot")}" id="{i}"]')
 lines+=['','[resource]','animations = [']
 for name,fps,frames in animations:
  lines.append('{"frames": ['+','.join('{"duration": 1.0, "texture": ExtResource("'+str(i)+'")}' for i in frames)+f'], "loop": true, "name": &"{name}", "speed": {float(fps)}'+ '},')
 lines.append(']');(folder/'spriteframes.tres').write_text('\n'.join(lines)+'\n')
 (folder/'manifest.json').write_text(json.dumps({'canvas':[144,128],'pivot':[72,120],'fps':12,'frames':64,'alpha':'original atlas, unchanged','backend':'native SVG paths / Godot SpriteFrames'},indent=2)+'\n')

def main():
 locomotion();swatches=palettes();previous=json.loads(LEDGER.read_text()) if LEDGER.exists() else {'files':{}}
 records={};changed=0
 for path in sorted(ASSETS.rglob('*.svg')):
  rel=path.relative_to(ASSETS).as_posix()
  if rel.startswith(('background_svg/','ui/')):continue
  text=path.read_text();old=previous['files'].get(rel,{})
  if sha(text)==old.get('output_sha256'):
   records[rel]=old;continue
  group,name=family(path);palette=swatches[group,name]
  emissive=any(x in path.stem for x in ['halo','glow','beam','spark','lamp_on','packet','shot','signal','arcs','tunnel'])
  mapping=old.get('colors',{})
  for color in set(RGB.findall(text)):
   if color not in mapping:mapping[color]=recolor(color,group,name,palette,emissive)
  result=RGB.sub(lambda m:mapping[m[0]],text)
  assert geometry(text)==geometry(result),rel
  if result!=text:path.write_text(result);changed+=1
  records[rel]={'group':group,'family':name,'geometry_sha256':geometry(text),'source_sha256':sha(text),'output_sha256':sha(result),'colors':mapping}
 LEDGER.write_text(json.dumps({'theme':'warm orange approval / contrast selection','geometry':'RGB-only substitution; alpha, path commands and viewBox preserved','files':records},ensure_ascii=False,separators=(',',':'))+'\n')
 print(f'Warm SVG transfer: {changed} updated / {len(records)} checked; geometry preserved.')

if __name__=='__main__':main()
