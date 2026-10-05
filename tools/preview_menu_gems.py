#!/usr/bin/env python3
"""Preview local bounded HUD patch without touching the Site checkout."""
from pathlib import Path
import io,subprocess,math,importlib.util
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/menu_qa'
OUT.mkdir(parents=True,exist_ok=True)
spec=importlib.util.spec_from_file_location('menu_preview',ROOT/'tools/render_menu_hud_preview.py')
# Reuse definitions without executing the original module's output-producing code.
code=(ROOT/'tools/render_menu_hud_preview.py').read_text().split('hud=Image.new')[0]
ns={'__file__':str(ROOT/'tools/render_menu_hud_preview.py')}
exec(code,ns)
svg=ns['svg'];paste=ns['paste'];text=ns['text'];A=ROOT/'godot/assets'

def base():
 im=Image.new('RGBA',(1152,648),'#0b2475')
 for name in ('sky','sea','coast','masts','atmosphere'):paste(im,A/f'background_svg/{name}.svg',(0,-38))
 im.alpha_composite(Image.new('RGBA',im.size,(18,6,1,122)))
 logo=svg(A/'ui/logo.svg');fit=min(432/logo.width,168/logo.height)
 logo=logo.resize((round(logo.width*fit),round(logo.height*fit)),Image.Resampling.NEAREST)
 im.alpha_composite(logo,(76+round((432-logo.width)/2),16+round((168-logo.height)/2)))
 text(im,'COSTA DOS VENTOS CONECTADOS',(76,198),(432,36),24)
 paste(im,A/'world_01/platforms/coastal_0.svg',(666,328),2)
 for label,y in [('COMEÇAR AVENTURA',268),('CONFIGURAÇÕES',348),('CONTROLES',428)]:
  layer=svg(A/'ui/button.svg').resize((360,60),Image.Resampling.NEAREST);im.alpha_composite(layer,(112,y))
  text(im,label,(112,y),(360,60),24,optical=False)
 text(im,'RECONECTE O SINAL. ABRA NOVOS MUNDOS.',(76,610),(1000,22),12)
 return im

def gem(im,t,i):
 angle=t*.42+math.tau*i/5-math.pi/2
 x=round(866+186*math.cos(angle));y=round(346+174*math.sin(angle))
 scale=[1.05,1.65,1.25,1.85,1.4][i]*(1+.05*math.sin(t*1.6+i))
 glow=svg(A/'world_01/svg/gem_glow.svg')
 glow.putalpha(glow.getchannel('A').point(lambda a:round(a*(.25+.05*math.sin(t*1.6+i)))))
 body=svg(A/'world_01/svg/gem_orange.svg')
 for layer in (glow,body):
  layer=layer.resize((round(layer.width*scale),round(layer.height*scale)),Image.Resampling.NEAREST)
  im.alpha_composite(layer,(round(x-layer.width/2),round(y-layer.height/2)))

samples=[]
for t in (0,1,2):
 im=base()
 for i in range(5):
  a=t*.42+math.tau*i/5-math.pi/2
  if math.sin(a)<0:gem(im,t,i)
 paste(im,A/'player/menu_svg/wave_06.svg',(690,184),2)
 for i in range(5):
  a=t*.42+math.tau*i/5-math.pi/2
  if math.sin(a)>=0:gem(im,t,i)
 im.convert('RGB').save(OUT/f'menu_gems_{t:02d}.png');samples.append(im)
sheet=Image.new('RGB',(1152,648*3),'#241508')
for i,im in enumerate(samples):sheet.paste(im,(0,648*i))
sheet.save(OUT/'menu_gems_contact_sheet.png')
# Continuous whole-cycle geometry audit using drawn gem content, not its halo padding.
checks=0
for reduced in (False,True):
 speed=.26 if reduced else .42
 for k in range(721):
  t=math.tau/speed*k/720
  for i in range(5):
   a=t*speed+math.tau*i/5-math.pi/2
   x=round(866+186*math.cos(a));y=round(346+174*math.sin(a))
   scale=[1.05,1.65,1.25,1.85,1.4][i]*(1+(.015 if reduced else .05)*math.sin(t*1.6+i))
   # Existing body's ink bbox x10..38,y10..46 centered in its 48x56 canvas.
   l=x-14*scale;r=x+14*scale;top=y-18*scale;bottom=y+18*scale
   assert not (l<970 and r>798 and top<434 and bottom>282),'face overlap'
   assert l>600 and r<1128 and top>110 and bottom<575,'safe menu ornament region'
   checks+=2
print(f'{checks} sampled whole-orbit face/safe-area checks passed; previews in {OUT}')
