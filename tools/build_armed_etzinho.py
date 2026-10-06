"""Trace the approved armed alien into real SVG paths with a shoulder rig.

The body and arm share a 128px canvas and foot anchor; Godot owns animation.
"""
from pathlib import Path
from collections import defaultdict
import json, math
import numpy as np
from PIL import Image, ImageDraw
from cosmic_enemy_motion import pose

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'godot/assets/enemies/cosmic/etzinho'

def svg(path, im):
    path.parent.mkdir(parents=True, exist_ok=True)
    a=np.array(im);groups=defaultdict(list)
    for y in range(im.height):
        x=0
        while x<im.width:
            c=tuple(a[y,x]);start=x;x+=1
            while x<im.width and tuple(a[y,x])==c:x+=1
            if c[3]:groups[c].append(f'M{start} {y}h{x-start}v1h-{x-start}z')
    paths=''.join(f'<path fill="#{r:02x}{g:02x}{b:02x}" d="{"".join(runs)}"/>' for (r,g,b,alpha),runs in groups.items())
    path.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128" shape-rendering="crispEdges">{paths}</svg>\n')

def main():
    source=Image.open(ROOT/'tools/reference_art/cosmic/etzinho-armed-approved.png').convert('RGBA')
    source.putalpha(source.getchannel('A').point(lambda v:255 if v>=128 else 0))
    box=source.getbbox();raw=source.crop(box)
    factor=100/raw.height
    raw=raw.resize((round(raw.width*factor),100),Image.Resampling.NEAREST)
    alpha=raw.getchannel('A')
    # Quantize visible artwork only, so invisible black cannot contaminate ink.
    pixels=np.array(raw);opaque=pixels[:,:,3]>0
    palette=Image.fromarray(pixels[:,:,:3][opaque].reshape(1,-1,3)).quantize(colors=24,dither=Image.Dither.NONE)
    colors=palette.getpalette()
    for index,color in enumerate([(255,176,0),(255,122,0),(255,216,77),(34,207,255),(0,172,232),(255,243,205)],24):
        colors[index*3:index*3+3]=color
    palette.putpalette(colors)
    raw=raw.convert('RGB').quantize(palette=palette,dither=Image.Dither.NONE).convert('RGBA');raw.putalpha(alpha)
    base=Image.new('RGBA',(128,128))
    # The body/feet center is x625 in the approved source, not the gun bbox.
    x0=64-round((625-box[0])*factor)
    base.alpha_composite(raw,(x0,12))
    a=np.array(base);y,x=np.indices(a.shape[:2])
    # Shoulder-connected foreground arm, hand and pistol, excluding face/legs.
    arm_mask=((x>=74)&(y>=78)&(y<=89))|((x>=87)&(y>=65)&(y<=89))
    arm=a.copy();arm[~arm_mask]=0
    body=a.copy();body[arm_mask]=0
    # Keep a two-pixel overlap at the shoulder through all rig rotations.
    body[(x>=74)&(x<=76)&(y>=78)&(y<=83)]=a[(x>=74)&(x<=76)&(y>=78)&(y<=83)]
    svg(OUT/'armed_arm.svg',Image.fromarray(arm))
    specs={'idle':(8,8,True),'patrol':(8,12,True),'alert':(6,10,False),'aim':(8,8,True),'shoot':(5,20,False),'hit':(6,12,False),'defeated':(12,12,False)}
    ext=[];animations=[];index=0;previews=[]
    for state,(count,fps,loop) in specs.items():
        for i in range(count):
            # Damage and defeat include the attached gun, avoiding a floating
            # weapon when its separate articulated layer is hidden.
            src=base if state in ('hit','defeated') else Image.fromarray(body)
            if state=='aim':im=pose(src,'etzinho','idle',i,count)
            elif state=='shoot':
                im=pose(src,'etzinho','hit',i,6)
            else:im=pose(src,'etzinho',state,i,count)
            svg(OUT/'frames'/state/f'{i:02}.svg',im)
            index+=1
            ext.append(f'[ext_resource type="Texture2D" path="res://assets/enemies/cosmic/etzinho/frames/{state}/{i:02}.svg" id="{index}"]')
            if i==0:previews.append((state,im))
        frames=', '.join('{"duration":1.0,"texture":ExtResource("'+str(n)+'")}' for n in range(index-count+1,index+1))
        animations.append('{"frames":['+frames+'],"loop":'+str(loop).lower()+',"name":&"'+state+'","speed":'+str(float(fps))+'}')
    (OUT/'spriteframes.tres').write_text(f'[gd_resource type="SpriteFrames" load_steps={index+1} format=3]\n\n'+'\n\n'.join(ext)+'\n\n[resource]\nanimations = ['+',\n'.join(animations)+']\n')
    flash=Image.new('RGBA',(128,128));draw=ImageDraw.Draw(flash)
    draw.polygon([(67,58),(71,61),(79,60),(75,65),(81,69),(72,68),(69,73),(67,67),(60,68),(63,63),(60,59)],fill='#22cfff')
    draw.rectangle((65,61,71,66),fill='#fff3cd')
    svg(OUT/'muzzle_flash.svg',flash)
    (OUT/'animations.json').write_text(json.dumps({'variant':'etzinho','canvas':[128,128],'ground_pivot':[64,112],'sprite_offset':[0,-48],'scale':1,'visual_height':100,'shoulder':[74,80],'muzzle':[114,73],'states':specs,'source':'etzinho-armed-approved.png','animation_backend':'Godot AnimatedSprite2D + articulated shoulder and muzzle flash; no SMIL','motion':'Breathing/blink, alternating legs, shoulder aim, finite recoil, pulse damage and disintegration'},indent=2))
    qa=ROOT/'godot/docs/cosmic_qa';qa.mkdir(parents=True,exist_ok=True)
    base.resize((512,512),Image.Resampling.NEAREST).save(qa/'armed_etzinho_reference.png')
    sheet=Image.new('RGBA',(128*len(previews),150),'#3b284b')
    for n,(state,im) in enumerate(previews):
        if state not in ('hit','defeated'):im=Image.alpha_composite(im,Image.fromarray(arm))
        sheet.alpha_composite(im,(128*n,0));ImageDraw.Draw(sheet).text((128*n+10,130),state,fill='white')
    sheet.resize((sheet.width*2,300),Image.Resampling.NEAREST).save(qa/'armed_etzinho_states.png')

if __name__=='__main__':main()
