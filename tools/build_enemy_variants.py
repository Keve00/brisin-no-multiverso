#!/usr/bin/env python3
"""Rebuild hand-authored Ruídozinho family. Uniform logical pixels; genuine SVG paths."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json, math, xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'godot/assets/enemies/ruiduzinho_v2'
SIZE=64
PIVOT=(32,54)
PALETTE={
 'ink':'#211633','deep':'#3C2059','shade':'#682F9F','violet':'#813FBF',
 'surface':'#9555DF','light':'#AB64F1','gleam':'#C997FF','eye':'#C600DC',
 'hot':'#EC73FF','cyan':'#51D3DF','icy':'#B6F3EF','metal':'#55476D','metal_light':'#867699'}
VARIANTS={'classic':('Ruídozinho clássico','Corpo refinado e antena curva; identidade violeta/magenta preservada.'),
 'scout':('Ruídozinho batedor','Antena de sinal bifurcada, núcleo ciano e receptor lateral.'),
 'shield':('Ruídozinho blindado','Armadura violeta compacta integrada ao corpo; escudo lateral em placas.')}
SPECS={'idle':(8,8,True),'patrol':(8,12,True),'alert':(6,10,False),'hit':(6,12,False),'defeated':(12,12,False)}

def layer(): return Image.new('RGBA',(SIZE,SIZE))
def drawbase(variant,eye=0,hurt=False,antenna_shift=0,alert=False):
    """Each coordinate belongs to the same fixed grid, never a pose-dependent fit."""
    body=layer();d=ImageDraw.Draw(body)
    def poly(points,c):d.polygon(points,fill=PALETTE[c])
    def rect(box,c):d.rectangle(box,fill=PALETTE[c])
    poly([(25,21),(37,21),(37,23),(42,23),(42,26),(46,26),(46,30),(48,30),(48,42),(46,42),(46,47),(42,47),(42,50),(22,50),(22,48),(18,48),(18,44),(16,44),(16,31),(18,31),(18,27),(21,27),(21,24),(25,24)],'ink')
    poly([(25,23),(37,23),(37,25),(42,25),(42,28),(44,28),(44,31),(46,31),(46,41),(44,41),(44,46),(40,46),(40,48),(23,48),(23,46),(20,46),(20,42),(18,42),(18,31),(20,31),(20,28),(23,28),(23,25),(25,25)],'shade')
    poly([(26,24),(36,24),(36,26),(40,26),(40,28),(42,28),(42,32),(44,32),(44,39),(40,39),(40,43),(25,43),(25,41),(21,41),(21,31),(23,31),(23,28),(26,28)],'surface')
    poly([(26,25),(35,25),(35,27),(30,27),(30,29),(25,29),(25,31),(22,31),(22,34),(20,34),(20,31),(23,31),(23,28),(26,28)],'light')
    rect((26,25,29,25),'gleam');rect((23,28,24,29),'gleam')
    poly([(37,28),(41,28),(41,32),(44,32),(44,39),(40,39),(40,43),(37,43),(37,41),(39,41),(39,35),(37,35)],'violet')
    poly([(23,44),(28,44),(28,46),(37,46),(37,44),(40,44),(40,46),(37,46),(37,48),(25,48),(25,46),(23,46)],'deep')
    rect((19,37,20,39),'violet');rect((42,42,43,43),'light');rect((38,46,39,46),'light')
    # Eye sockets, hostile brows and the original short zigzag mouth.
    for x in (24+eye,35+eye):
        rect((x-1,30,x+5,36),'ink')
        rect((x,31,x+3,34),'eye')
        rect((x,31,x+1,31),'hot')
        if hurt:
            rect((x,31,x+3,34),'deep');rect((x,32,x+3,32),'eye')
    rect((23+eye,29,26+eye,29),'ink');rect((38+eye,29,41+eye,29),'ink')
    if variant=='scout' and not hurt:
        rect((36+eye,32,37+eye,33),'cyan')
    poly([(25,39),(28,39),(28,40),(31,40),(31,39),(35,39),(35,40),(38,40),(38,42),(34,42),(34,43),(30,43),(30,42),(27,42),(27,41),(25,41)],'ink')
    rect((29,40,30,40),'light');rect((35,40,36,40),'light')
    if hurt:rect((29,40,35,41),'ink')
    # Shield is integrated compact armour, not a scaled copy of the body.
    if variant=='shield':
        poly([(41,28),(47,28),(47,31),(50,31),(50,44),(47,44),(47,49),(43,49),(43,46),(40,46),(40,41),(38,41),(38,34),(41,34)],'ink')
        poly([(42,30),(46,30),(46,33),(48,33),(48,42),(46,42),(46,47),(44,47),(44,44),(42,44),(42,39),(40,39),(40,35),(42,35)],'metal')
        poly([(42,30),(46,30),(46,33),(48,33),(48,34),(44,34),(44,32),(42,32)],'metal_light')
        rect((42,36,46,36),'light');rect((43,37,45,41),'shade');rect((44,38,44,40),'eye')
        rect((46,44,46,45),'metal_light');rect((19,29,21,34),'metal');rect((20,29,21,29),'metal_light')
    if variant=='scout':
        rect((45,31,49,38),'ink');rect((46,32,48,36),'deep');rect((47,33,48,34),'cyan')
    ant=layer();a=ImageDraw.Draw(ant)
    def ar(box,c):a.rectangle(tuple(v+(antenna_shift if i%2==0 else 0) for i,v in enumerate(box)),fill=PALETTE[c])
    if variant=='scout':
        for b,c in [((28,17,30,22),'ink'),((29,17,29,21),'surface'),((26,14,32,18),'ink'),((27,15,31,17),'shade'),((24,11,27,15),'ink'),((25,11,26,14),'cyan'),((31,9,34,15),'ink'),((32,10,33,14),'cyan'),((23,9,28,11),'ink'),((24,9,27,10),'icy'),((30,7,35,9),'ink'),((31,7,34,8),'icy')]:ar(b,c)
    else:
        for b,c in [((27,17,30,23),'ink'),((28,18,29,22),'surface'),((24,14,29,17),'ink'),((25,15,28,16),'light'),((21,11,25,14),'ink'),((22,12,24,13),'surface'),((20,8,23,11),'ink'),((21,9,22,10),'light'),((18,7,23,8),'ink'),((19,7,22,7),'eye')]:ar(b,c)
        if variant=='shield':ar((26,20,31,22),'metal');ar((27,20,30,20),'metal_light')
    return body,ant

def paste_shift(target,im,dx=0,dy=0):target.alpha_composite(im,(dx,dy))
def feet(left=0,right=0,left_lift=0,right_lift=0):
    im=layer();d=ImageDraw.Draw(im)
    for x,step,lift in [(23,left,left_lift),(35,right,right_lift)]:
        d.rectangle((x+step,49-lift,x+6+step,52-lift),fill=PALETTE['ink'])
        d.rectangle((x-1+step,52-lift,x+6+step,53-lift),fill=PALETTE['ink'])
        d.rectangle((x+1+step,50-lift,x+4+step,51-lift),fill=PALETTE['shade'])
        d.rectangle((x+step,52-lift,x+4+step,52-lift),fill=PALETTE['light'])
    return im

def fragments(base,phase):
    im=layer();source=base.load();d=ImageDraw.Draw(im)
    # Dissolve fixed blocks along integer trajectories. Three rubble frames linger.
    if phase>=8:
        for x,y,w,c in [(22,52,5,'deep'),(32,51,5,'shade'),(41,52,3,'metal'),(28,50,2,'eye')]:
            d.rectangle((x,y,x+w-1,min(y+1,53)),fill=PALETTE[c])
        return im
    for cy in range(SIZE//2):
        for cx in range(SIZE//2):
            seed=(cx*11+cy*17)%29
            if seed/29 < phase/9:continue
            dx=round((cx*2-32)*phase/17)
            dy=-round(phase*0.6)+max(0,round((phase-3)*0.9))
            for yy in range(cy*2,cy*2+2):
                for xx in range(cx*2,cx*2+2):
                    pix=source[xx,yy]
                    nx,ny=xx+dx,yy+dy
                    if pix[3]:
                        assert 0<=nx<64 and 0<=ny<64,(nx,ny)
                        d.point((nx,ny),fill=pix)
    return im

def frame(variant,state,index):
    bob=0;dx=0;eye=0;ashift=0;hurt=False;alert=False
    if state=='idle':bob=-1 if index in (2,3,4) else 0;ashift=-1 if index in (3,4) else 0
    elif state=='patrol':bob=-1 if index in (1,2,5,6) else 0;ashift=1 if index in (2,3) else -1 if index in (6,7) else 0
    elif state=='alert':bob=-1 if index>=2 else 0;eye=1 if index>=2 else 0;ashift=1 if index>=2 else 0;alert=index>=2
    elif state=='hit':dx=[0,-2,-1,0,0,0][index];hurt=index<4
    elif state=='defeated':hurt=True
    body,ant=drawbase(variant,eye,hurt,ashift,alert)
    im=layer()
    if state=='patrol':
        step=[0,1,1,0,-1,-1,-1,0][index]
        paste_shift(im,feet(step,-step,int(index in (1,2)),int(index in (5,6))))
    else:paste_shift(im,feet())
    paste_shift(im,body,dx,bob);paste_shift(im,ant,dx,bob)
    d=ImageDraw.Draw(im)
    if state in ('idle','patrol') and index%4 in (1,2):
        for x,y in [(13,35),(51,42)]:d.rectangle((x,y,x+1,y+1),fill=PALETTE['eye'])
    if alert:
        col=PALETTE['cyan'] if variant=='scout' else PALETTE['hot']
        for b in [(38,12,39,14),(41,15,43,16),(44,19,45,21)]:d.rectangle(b,fill=col)
        if index in (2,3):d.rectangle((39,7,40,9),fill=col)
    if state=='hit' and index in (1,2):
        for b in [(10,28,12,28),(11,27,11,29),(50,25,52,25),(51,24,51,26)]:d.rectangle(b,fill=PALETTE['hot'])
    if state=='defeated' and index>=2:im=fragments(im,index-2)
    return im

def paths(im):
    bycolor={}
    for y in range(SIZE):
        x=0
        while x<SIZE:
            color=im.getpixel((x,y))
            if color[3]==0:x+=1;continue
            end=x+1
            while end<SIZE and im.getpixel((end,y))==color:end+=1
            hx='#%02X%02X%02X'%color[:3]
            bycolor.setdefault(hx,[]).append(f'M{x} {y}h{end-x}v1h-{end-x}z')
            x=end
    return ''.join(f'<path fill="{c}" d="{"".join(seq)}"/>' for c,seq in sorted(bycolor.items()))

def svg(im,title):return f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64" shape-rendering="crispEdges"><title>{title}</title>{paths(im)}</svg>'

def write_resource(folder):
    ext=[];anim=[];idx=0
    for state,(count,fps,loop) in SPECS.items():
        fs=[]
        for i in range(count):
            idx+=1
            ext.append(f'[ext_resource type="Texture2D" path="res://assets/enemies/ruiduzinho_v2/{folder.name}/frames/{state}/{i:02}.svg" id="{idx}"]')
            fs.append('{"duration": 1.0, "texture": ExtResource("'+str(idx)+'")}')
        anim.append('{"frames": ['+', '.join(fs)+f'], "loop": {str(loop).lower()}, "name": &"{state}", "speed": {float(fps)}'+'}')
    (folder/'spriteframes.tres').write_text(f'[gd_resource type="SpriteFrames" load_steps={idx+1} format=3]\n\n'+'\n\n'.join(ext)+'\n\n[resource]\nanimations = ['+',\n'.join(anim)+']\n')

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    allframes={};metrics=[]
    for variant,(title,description) in VARIANTS.items():
        folder=OUT/variant;folder.mkdir(exist_ok=True)
        metadata={'name':title,'variant':variant,'version':'0.2-concept','description':description,
         'canvas':[64,64],'ground_pivot':[32,54],'centered_sprite_offset':[0,-22],
         'texture_filter':'nearest','recommended_scale':1,'palette':list(PALETTE.values()),
         'provenance':'Redesenho manual da silhueta, rosto e antena da reconstrução Ruídozinho v0.1; não é cópia pixel a pixel.',
         'animations':{}}
        for state,(count,fps,loop) in SPECS.items():
            directory=folder/'frames'/state;directory.mkdir(parents=True,exist_ok=True)
            seq=[];state_bounds=[]
            for i in range(count):
                im=frame(variant,state,i);seq.append(im)
                content=svg(im,f'{title} — {state} {i+1}/{count}')
                target=directory/f'{i:02}.svg';target.write_text(content)
                parsed=ET.fromstring(content)
                assert parsed.attrib['viewBox']=='0 0 64 64'
                assert not parsed.findall('.//{http://www.w3.org/2000/svg}image')
                assert set(im.get_flattened_data())- {(0,0,0,0)} <= {tuple(bytes.fromhex(c[1:]))+(255,) for c in PALETTE.values()},target
                b=im.getbbox();assert b and b[0]>=2 and b[1]>=2 and b[2]<=62 and b[3]<=62,(target,b)
                state_bounds.append(list(b))
            metadata['animations'][state]={'frames':[f'frames/{state}/{i:02}.svg' for i in range(count)],'fps':fps,'loop':loop,'bounds':state_bounds,'duration_seconds':count/fps}
            allframes[variant,state]=seq
        (folder/'animations.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2))
        write_resource(folder)
        (folder/'idle.svg').write_text(svg(allframes[variant,'idle'][0],title))
        metrics.append({'variant':variant,'frames':sum(v[0] for v in SPECS.values()),'nonempty_frames':sum(v[0] for v in SPECS.values())})
    # Inspect actual SVGs by rendering Inkscape, independent of the logical raster authoring.
    import subprocess, tempfile
    font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',16)
    small=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',12)
    contact=Image.new('RGB',(1152,832),'#241508');d=ImageDraw.Draw(contact)
    d.text((24,14),'RUÍDOZINHO • FAMÍLIA VETORIAL 0.2',font=font,fill='#FFD84D')
    d.text((24,42),'Grade 64 × 64 • pivô de chão (32, 54) • variantes para expansão, sem substituir o inimigo atual',font=small,fill='#FFF3CD')
    picks={'idle':0,'patrol':2,'alert':3,'hit':1,'defeated':7}
    labels={'idle':'REPOUSO','patrol':'PATRULHA','alert':'ALERTA','hit':'DANO','defeated':'DERROTA'}
    for row,(variant,(title,_)) in enumerate(VARIANTS.items()):
        top=86+row*246;d.text((24,top),title,font=font,fill='#FFB000')
        for col,state in enumerate(SPECS):
            x=24+col*224;y=top+28;d.rectangle((x,y,x+207,y+207),fill='#302239')
            source=OUT/variant/'frames'/state/f'{picks[state]:02}.svg'
            with tempfile.TemporaryDirectory() as td:
                raster=Path(td)/'frame.png'
                subprocess.run(['inkscape',str(source),'--export-type=png',f'--export-filename={raster}'],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
                rendered=Image.open(raster).convert('RGBA')
            rendered=rendered.resize((192,192),Image.Resampling.NEAREST)
            contact.paste(rendered,(x+8,y+4),rendered)
            d.text((x+8,y+191),labels[state],font=small,fill='#FFF3CD')
    contact.save(OUT/'contact_sheet.png')
    # Discrete full-frame animation: SMIL only for preview, runtime uses all actualSVGframes.
    chunks=['<svg xmlns="http://www.w3.org/2000/svg" width="1152" height="832" viewBox="0 0 1152 832" shape-rendering="crispEdges"><title>Ruídozinho — três variantes e cinco animações</title><rect width="1152" height="832" fill="#241508"/><text x="24" y="35" fill="#FFD84D" font-family="monospace" font-size="20">RUÍDOZINHO — PRÉVIA DE VARIANTES</text><text x="24" y="61" fill="#FFF3CD" font-family="monospace" font-size="13">A prévia repete todos os estados. No jogo, alerta, dano e derrota são finitos.</text>']
    for row,(variant,(title,_)) in enumerate(VARIANTS.items()):
        top=86+row*246;chunks.append(f'<text x="24" y="{top+18}" fill="#FFB000" font-family="monospace" font-size="17">{title}</text>')
        for col,(state,(count,fps,loop)) in enumerate(SPECS.items()):
            x=24+col*224;y=top+28
            chunks.append(f'<rect x="{x}" y="{y}" width="208" height="208" fill="#302239"/><text x="{x+8}" y="{y+203}" fill="#FFF3CD" font-family="monospace" font-size="13">{labels[state]}</text><g transform="translate({x+8} {y+4}) scale(3)">')
            # Nonloops show full sequence, then 0.8s stable rubble/rest and replay.
            hold=0 if loop else math.ceil(fps*.8)
            total=count+hold;duration=total/fps
            for i,im in enumerate(allframes[variant,state]):
                vals=['visible' if j==i or (j>=count and i==count-1) else 'hidden' for j in range(total)]
                vals.append(vals[0]);times=';'.join(f'{j/total:.8f}' for j in range(total+1))
                chunks.append(f'<g visibility="{"visible" if i==0 else "hidden"}">{paths(im)}<animate attributeName="visibility" values="{";".join(vals)}" keyTimes="{times}" dur="{duration:.8f}s" calcMode="discrete" repeatCount="indefinite"/></g>')
            chunks.append('</g>')
    chunks.append('</svg>');(OUT/'animated_preview.svg').write_text(''.join(chunks))
    manifest={'schema_version':1,'canvas':[64,64],'ground_pivot':[32,54],'variants':metrics,'total_frames':sum(m['frames'] for m in metrics),'all_frames_nonempty':True,'validation':'XML, no raster embeds, bounds >=2px margin, fixed palette, PNG rendered from actual SVG using Inkscape.'}
    (OUT/'validation.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2))
    print(json.dumps(manifest,ensure_ascii=False))
if __name__=='__main__':main()
