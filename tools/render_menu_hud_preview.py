#!/usr/bin/env python3
"""CPU evidence of imported SVG composition; not a browser/Godot screenshot."""
from pathlib import Path
from PIL import Image, ImageDraw
import io,re,json,subprocess
ROOT=Path(__file__).resolve().parents[1]
ASSETS=ROOT/'godot/assets'
OUT=ROOT/'godot/docs'
OUT.mkdir(exist_ok=True)

def svg(path):
    raw=subprocess.run(['inkscape',str(path),'--export-type=png','--export-filename=-'],check=True,capture_output=True).stdout
    return Image.open(io.BytesIO(raw)).convert('RGBA')

def paste(im,path,pos,scale=1):
    layer=svg(path)
    if scale!=1:layer=layer.resize((round(layer.width*scale),round(layer.height*scale)),Image.Resampling.NEAREST)
    im.alpha_composite(layer,pos)

glyphs={}
for line in (ASSETS/'ui/brisin_pixel.fnt').read_text().splitlines():
    if not line.startswith('char id='):continue
    fields={k:int(v) for k,v in re.findall(r'(\w+)=(-?\d+)',line)}
    glyphs[fields['id']]=fields
atlas=Image.open(ASSETS/'ui/brisin_pixel.png').convert('RGBA')

def text(im,value,pos,bounds,size=24,center=True,color='#fff3cd',optical=True):
    scale=size/12
    width=sum(glyphs[ord(c)]['xadvance'] for c in value)*scale
    optical_shift=round(size/24) if optical else 0
    x=pos[0]+((bounds[0]-width)/2 if center else 0)+optical_shift
    y=pos[1]+(bounds[1]-12*scale)/2-optical_shift
    for c in value:
        g=glyphs[ord(c)]
        a=atlas.crop((g['x'],g['y'],g['x']+g['width'],g['y']+g['height']))
        fill=Image.new('RGBA',a.size,color);fill.putalpha(a.getchannel('A'))
        fill=fill.resize((round(a.width*scale),round(a.height*scale)),Image.Resampling.NEAREST)
        im.alpha_composite(fill,(round(x),round(y)))
        x+=g['xadvance']*scale

hud=Image.new('RGBA',(600,316),'#0b2475')
for row,(title,detail,icon) in enumerate([
 ('RUÍDOZINHO','[SHIFT / X] DASH • [F] SOLTA CHIPS','bolt'),
 ('CONEXÃO RESTABELECIDA','O CAMINHO PARA O PORTAL ESTÁ ABERTO','signal')]):
    base=(40,16+row*100)
    plate=Image.new('RGBA',(520,84))
    paste(plate,ASSETS/'ui/toast_frame.svg',(0,0))
    paste(plate,ASSETS/f'ui/{icon}.svg',(22,26))
    text(plate,title,(60,9),(436,32),24,color='#ffd84d')
    text(plate,detail,(60,41),(436,28),12)
    hud.alpha_composite(plate,base)
plate=Image.new('RGBA',(160,54))
paste(plate,ASSETS/'ui/counter_frame.svg',(0,0))
paste(plate,ASSETS/'ui/diamond.svg',(12,11))
text(plate,'15/25',(44,5),(96,36),24)
hud.alpha_composite(plate,(220,236))
hud.convert('RGB').resize((1200,632),Image.Resampling.NEAREST).save(OUT/'menu_hud_alignment_preview.png')

menu=Image.new('RGBA',(1152,648),'#0b2475')
# Identical shared-coordinate panorama and 2× source platform; no stretched artwork.
for name in ('sky','sea','coast','masts','atmosphere'):
    paste(menu,ASSETS/f'background_svg/{name}.svg',(0,-38))
menu.alpha_composite(Image.new('RGBA',menu.size,(18,6,1,122)))
logo=svg(ASSETS/'ui/logo.svg')
fit=min(432/logo.width,168/logo.height)
logo=logo.resize((round(logo.width*fit),round(logo.height*fit)),Image.Resampling.NEAREST)
menu.alpha_composite(logo,(76+round((432-logo.width)/2),16+round((168-logo.height)/2)))
text(menu,'COSTA DOS VENTOS CONECTADOS',(76,202),(432,36),24)
paste(menu,ASSETS/'world_01/platforms/coastal_0.svg',(666,328),2)
paste(menu,ASSETS/'player/menu_svg/wave_06.svg',(690,184),2)
for label,y in [('COMEÇAR AVENTURA',272),('CONFIGURAÇÕES',352),('CONTROLES',432)]:
    layer=svg(ASSETS/'ui/button.svg').resize((360,60),Image.Resampling.NEAREST)
    menu.alpha_composite(layer,(112,y))
    text(menu,label,(112,y),(360,60),24,optical=False)
text(menu,'RECONECTE O SINAL. ABRA NOVOS MUNDOS.',(76,610),(1000,22),12)
menu.convert('RGB').save(OUT/'menu_platform_preview.png')
print(OUT/'menu_hud_alignment_preview.png')
print(OUT/'menu_platform_preview.png')
