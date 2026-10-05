"""Render the shipped vector frames into a compact animation proof."""
from pathlib import Path
import json,re,xml.etree.ElementTree as ET
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]
def raster(path):
    im=Image.new('RGBA',(128,128));draw=ImageDraw.Draw(im)
    for node in ET.parse(path).getroot():
        color=node.attrib['fill'];opacity=round(float(node.attrib.get('opacity','1'))*255)
        rgb=tuple(int(color[i:i+2],16) for i in [1,3,5])+(opacity,)
        for x,y,w in re.findall(r'M(\d+) (\d+)h(\d+)v1h-\d+z',node.attrib['d']):
            x,y,w=int(x),int(y),int(w);draw.rectangle((x,y,x+w-1,y),fill=rgb)
    return im
def main():
    data=json.loads((ROOT/'godot/data/world_01.json').read_text());names=data['enemy_variants'];frames=[];durations=[]
    states=[('idle',8,125,'REPOUSO'),('patrol',8,83,'CAMINHADA'),('alert',6,100,'ALERTA'),('hit',6,83,'DANO'),('defeated',12,83,'DERROTA')]
    for state,count,delay,label in states:
        for index in range(count):
            frame=Image.new('RGBA',(850,440),'#15122c');draw=ImageDraw.Draw(frame);draw.text((16,12),label,fill='#fff3cd')
            for i,name in enumerate(names):
                asset=ROOT/f'godot/assets/enemies/cosmic/{name}/frames/{state}/{index:02}.svg'
                sprite=raster(asset).resize((166,166),Image.Resampling.NEAREST)
                x=(i%5)*170;y=(i//5)*195+26;frame.alpha_composite(sprite,(x,y))
                draw.text((x+16,y+172),name.upper(),fill='#fff3cd')
            frames.append(frame.convert('RGB'));durations.append(delay)
    out=ROOT/'godot/docs/cosmic_animations.gif'
    frames[0].save(out,save_all=True,append_images=frames[1:],duration=durations,loop=0,optimize=False,disposal=2)
    print(out)
if __name__=='__main__':main()
