#!/usr/bin/env python3
"""Reproduce approved alien artwork as real pixel paths and Godot frame resources.

References live outside exported assets. No SVG embeds a bitmap. Animations
share a canvas and ground pivot; gameplay collision dimensions are unchanged.
"""
from pathlib import Path
from collections import defaultdict, deque
import json, math
import numpy as np
from PIL import Image, ImageDraw, ImageFont
try:
    from cosmic_enemy_motion import pose
except ImportError:
    from tools.cosmic_enemy_motion import pose

ROOT = Path(__file__).resolve().parents[1]
REF = ROOT/'tools/reference_art/cosmic'
ASSETS = ROOT/'godot/assets'
QA = ROOT/'godot/docs/cosmic_qa'
QA.mkdir(parents=True, exist_ok=True)
MANIFEST = {'theme':'Conexão de Outro Mundo','assets':[], 'animation_backend':'Godot SpriteFrames / GDScript'}

def write(path, im, pivot=None):
    path.parent.mkdir(parents=True,exist_ok=True)
    im=im.convert('RGBA'); a=np.array(im); groups=defaultdict(list)
    for y in range(im.height):
        x=0
        while x<im.width:
            c=tuple(a[y,x]);start=x;x+=1
            while x<im.width and tuple(a[y,x])==c:x+=1
            if c[3]:groups[c].append(f'M{start} {y}h{x-start}v1h-{x-start}z')
    body=''.join(f'<path fill="#{c[0]:02x}{c[1]:02x}{c[2]:02x}"'+(f' opacity="{c[3]/255:.3f}"' if c[3]!=255 else '')+f' d="{"".join(runs)}"/>' for c,runs in groups.items())
    path.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{im.width}" height="{im.height}" viewBox="0 0 {im.width} {im.height}" shape-rendering="crispEdges">{body}</svg>\n')
    MANIFEST['assets'].append({'path':str(path.relative_to(ROOT)), 'canvas':list(im.size),'pivot':pivot, 'geometry':'paths','colors':len(groups)})
    return im

def extract(file,box,div=2,colors=48):
    rgb=Image.open(REF/file).convert('RGB').crop(box)
    rgb=rgb.resize((max(1,round(rgb.width/div)),max(1,round(rgb.height/div))),Image.Resampling.NEAREST)
    a=np.array(rgb).astype(np.int16)
    # Remove the navy board, including negative spaces. Purple object shading
    # has substantially more red than the board and must remain opaque.
    bg=(a[:,:,0]<42)&(a[:,:,1]<65)&(a[:,:,2]>a[:,:,0]*1.5)
    if file=='platforms.png':
        # The source board is blue (R~0, G~23, B~87). Preserve
        # the dark purple rock faces instead of punching holes in them.
        bg=(a[:,:,0]<18)&(a[:,:,2]>a[:,:,1]*2)
    if file=='menu.png':
        bg=(a[:,:,2]>a[:,:,0]*1.25)&(a[:,:,2]>a[:,:,1]*1.1)
    if file=='enemies.png':
        # Only remove board pixels reachable from the crop edge. Dark eyes,
        # mouths and enclosed purple shading belong to the character.
        exterior=np.zeros(bg.shape,dtype=bool);todo=deque()
        h,w=bg.shape
        for x,y in [(x,y) for x in range(w) for y in [0,h-1]]+[(x,y) for y in range(h) for x in [0,w-1]]:
            if bg[y,x] and not exterior[y,x]:exterior[y,x]=True;todo.append((x,y))
        while todo:
            x,y=todo.popleft()
            for nx,ny in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]:
                if 0<=nx<w and 0<=ny<h and bg[ny,nx] and not exterior[ny,nx]:
                    exterior[ny,nx]=True;todo.append((nx,ny))
        bg=exterior
    if file=='enemies.png':
        samples=Image.fromarray(a[~bg].astype('uint8').reshape(1,-1,3))
        palette=samples.quantize(colors=colors,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
        q=rgb.quantize(palette=palette,dither=Image.Dither.NONE).convert('RGB')
    else:q=rgb.quantize(colors=colors,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE).convert('RGB')
    rgba=np.zeros((*a.shape[:2],4),np.uint8);rgba[:,:,:3]=np.array(q);rgba[:,:,3]=np.where(bg,0,255)
    if file=='enemies.png' and box==(1026,694,1448,938):
        # Orbital rings enclose board-colored negative spaces. Keep one pixel
        # of outline beside the bright art, and protect the dark facial ink.
        h,w=bg.shape;yy,xx=np.indices(bg.shape)
        dark=(a[:,:,0]<65)&(a[:,:,1]<36)&(a[:,:,2]>a[:,:,0]*.65)
        ink=(~dark)&(~bg)
        adjacent=np.zeros(bg.shape,dtype=bool)
        for dx,dy in [(0,0),(-1,0),(1,0),(0,-1),(0,1)]:
            adjacent[max(0,dy):min(h,h+dy),max(0,dx):min(w,w+dx)] |= ink[max(0,-dy):min(h,h-dy),max(0,-dx):min(w,w-dx)]
        face=(xx>=35)&(xx<=70)&(yy>=27)&(yy<=53)
        rgba[dark&(~adjacent)&(~face),3]=0
    # Drop isolated scraps from adjacent cells, retaining approved effect specks.
    seen=set()
    for y in range(len(rgba)):
        for x in range(len(rgba[0])):
            if not rgba[y,x,3] or (x,y) in seen:continue
            todo=[(x,y)];part=[];seen.add((x,y))
            while todo:
                px,py=todo.pop();part.append((px,py))
                for nx,ny in [(px-1,py),(px+1,py),(px,py-1),(px,py+1)]:
                    if 0<=ny<len(rgba) and 0<=nx<len(rgba[0]) and rgba[ny,nx,3] and (nx,ny) not in seen:
                        seen.add((nx,ny));todo.append((nx,ny))
            if len(part)<(12 if file=='menu.png' else 3):
                for px,py in part:rgba[py,px,3]=0
    return Image.fromarray(rgba)

def whole_plant(box,div=3):
    im=extract('platforms.png',box,div)
    a=np.array(im);seen=set();parts=[]
    for y,x in zip(*np.where(a[:,:,3]>0)):
        if (x,y) in seen:continue
        todo=[(x,y)];part=[];seen.add((x,y))
        while todo:
            px,py=todo.pop();part.append((px,py))
            for nx,ny in [(px-1,py),(px+1,py),(px,py-1),(px,py+1)]:
                if 0<=nx<im.width and 0<=ny<im.height and a[ny,nx,3] and (nx,ny) not in seen:
                    seen.add((nx,ny));todo.append((nx,ny))
        parts.append(part)
    # Canopies and glowing ornaments may be disconnected from the trunk.
    # Retain every substantial component, removing only tiny source scraps.
    for part in parts:
        if len(part)<6:
            for x,y in part:a[y,x,3]=0
    cleaned=Image.fromarray(a)
    return cleaned.crop(cleaned.getbbox())

def fit(im,size,pivot,height):
    im=im.crop(im.getbbox());factor=min(height/im.height,(size[0]-8)/im.width)
    im=im.resize((round(im.width*factor),round(im.height*factor)),Image.Resampling.NEAREST)
    canvas=Image.new('RGBA',size);canvas.alpha_composite(im,(round(pivot[0]-im.width/2),pivot[1]-im.height))
    return canvas

def sheet(name,ims,labels,cols=3,cell=(300,210)):
    rows=math.ceil(len(ims)/cols);out=Image.new('RGBA',(cols*cell[0],rows*cell[1]),'#11102b');d=ImageDraw.Draw(out)
    for i,(im,label) in enumerate(zip(ims,labels)):
        factor=min((cell[0]-20)/im.width,(cell[1]-35)/im.height)
        show=im.resize((round(im.width*factor),round(im.height*factor)),Image.Resampling.NEAREST)
        x=i%cols*cell[0];y=i//cols*cell[1]
        out.alpha_composite(show,(x+(cell[0]-show.width)//2,y))
        d.text((x+12,y+cell[1]-24),label,fill='#fff3cd')
    out.convert('RGB').save(QA/(name+'.png'))

def platforms():
    out=ASSETS/'world_01/platforms';meta={};imgs=[];labels=[]
    specs={
      'coastal':((24,8,554,338),190),'sand':((586,82,997,322),221),
      'steps':((1024,80,1518,318),129),'thin':((48,355,535,514),416),
      'cracked':((577,344,1006,552),407),'raft':((1034,365,1507,514),405),
      'wood_bridge':((36,571,548,724),587),'signal':((581,552,1001,750),590),
      'wind_island':((1061,533,1518,769),654)}
    for kind,(box,contact) in specs.items():
        raw=extract('platforms.png',box,3)
        if kind=='wind_island':
            a=np.array(raw);white=(a[:,:,0]>150)&(a[:,:,1]>175)&(a[:,:,2]>170)
            a[white,3]=0;raw=Image.fromarray(a)
        surface=round((contact-box[1])/3)
        full=Image.new('RGBA',(200,176));dx=(200-raw.width)//2;dy=64-surface
        full.alpha_composite(raw,(dx,dy))
        ground=raw.crop((0,surface,raw.width,raw.height))
        if kind=='wind_island':
            # Curved wind is a single overlay, never repeated with ground caps.
            a=np.array(ground);white=(a[:,:,0]>150)&(a[:,:,1]>175)&(a[:,:,2]>170)
            a[white,3]=0;ground=Image.fromarray(a)
        if kind!='steps':
            # Fill small painted breaks at contact; the collider stays visible.
            a=np.array(ground);present=np.where((a[:min(5,len(a)),:,3]>0).any(axis=0))[0]
            if len(present):
                ground=ground.crop((int(present.min()),0,int(present.max())+1,ground.height));a=np.array(ground)
                for x in range(ground.width):
                    if not a[:5,x,3].any():
                        cols=np.where(a[:5,:,3].any(axis=0))[0];nx=cols[np.argmin(abs(cols-x))]
                        a[:8,x]=a[:8,nx]
                ground=Image.fromarray(a)
        if kind=='coastal':
            menu=Image.new('RGBA',(200,176));menu.alpha_composite(ground,((200-ground.width)//2,64))
            plant=extract('platforms.png',(630,866,776,986),4)
            menu.alpha_composite(plant,(35,64-plant.height));menu.alpha_composite(plant.transpose(Image.Transpose.FLIP_LEFT_RIGHT),(132,64-plant.height))
            write(out/'cosmic_menu.svg',menu,[100,64])
        # Whole standalone plants share a root pivot. Never split their
        # silhouettes at the platform's horizontal contact line.
        deco=Image.new('RGBA',(200,256))
        plants={'coastal':[(0,750,249,990)],'sand':[(428,807,598,990)],
                'wind_island':[(428,807,598,990),(625,855,780,990)],
                'cracked':[(625,855,780,990)]}
        for i,plant_box in enumerate(plants.get(kind,[])):
            plant=whole_plant(plant_box,2)
            plant=plant.crop(plant.getbbox())
            x=100-plant.width//2+(34 if i else 0)
            deco.alpha_composite(plant,(x,172-plant.height))
        if kind not in plants:
            # Machinery keeps its complete upper layer in the same root space.
            top=full.crop((0,0,200,64))
            deco.alpha_composite(top,(0,106))
        for v in range(2):
            # Mirroring is intentional only for optional variation, uniform.
            f=full if v==0 else full.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            g=ground if v==0 or kind=='steps' else ground.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            dec=deco if v==0 else deco.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            if kind=='steps':
                # Draw lower shelves first. Each variant follows its existing
                # collider coordinates exactly; complete modules stay upright.
                shelves=[(5,68,34),(75,61,11),(32,61,0)] if v==0 else [(2,47,39),(34,60,20),(10,57,0)]
                g=Image.new('RGBA',(137,95))
                block=extract('platforms.png',(1035,129,1218,290),3)
                for x,w,y in shelves:
                    piece=block.crop((0,0,min(block.width,w),block.height))
                    g.alpha_composite(piece,(x,y))
                f=Image.new('RGBA',(200,176));f.alpha_composite(g,(32,64))
                dec=Image.new('RGBA',(200,256))
            else:
                # Adjacent slices share an identical six-pixel seam. Blend
                # only edge colors into the approved source, never stretch it.
                a=np.array(g);cap=min(24,g.width//3);left=cap;right=g.width-cap
                reference=a[:,g.width//2].copy()
                reference[:,3]=np.minimum(reference[:,3],np.minimum(a[:,left-1,3],a[:,right,3]))
                for seam,direction in [(left,-1),(left,1),(right,-1),(right,1)]:
                    for offset in range(6):
                        x=seam+offset if direction==1 else seam-1-offset
                        weight=(6-offset)/6
                        old=a[:,x].copy()
                        a[:,x,:3]=np.round(old[:,:3]*(1-weight)+reference[:,:3]*weight).astype('uint8')
                        a[:,x,3]=reference[:,3] if offset<3 else old[:,3]
                g=Image.fromarray(a)
            stem=f'{kind}_{v}'
            write(out/(stem+'.svg'),f,[100,64]);write(out/(stem+'_ground.svg'),g,[0,0]);write(out/(stem+'_deco.svg'),dec,[100,170])
            if kind=='wind_island':
                fx=Image.new('RGBA',(200,176));p=ImageDraw.Draw(fx)
                p.arc((30,43,165,93),190,350,fill='#d0ffff',width=2)
                p.arc((18,76,179,124),10,175,fill='#f2ffff',width=2)
                write(out/(stem+'_wind.svg'),fx,[100,64])
        meta[kind]=[{'canvas':[200,176],'pivot':[100,64],'ground_size':list(ground.size),'source_crop':list(box),'source_contact_y':contact,'uniform_source_scale':1/3,'cap':min(24,ground.width//3)}]*2
        imgs.append(f);labels.append(kind)
    (out/'manifest.json').write_text(json.dumps(meta,indent=2))
    sheet('platforms',imgs,labels)
    return full

def environment():
    out=ASSETS/'world_01/environment';entries=[];ims=[];labels=[]
    crops={'palms':[(0,750,249,990),(250,775,429,990),(428,807,598,990)],
      'vegetation':[(625,855,780,990),(625,855,780,990),(428,807,598,990)],
      'rocks_sand':[(798,823,891,986),(898,866,1061,986),(910,879,1051,986)],
      'ruins':[(1074,833,1247,986),(1074,833,1247,986),(1082,852,1140,986)],
      'posts':[(1255,859,1371,986),(1255,859,1371,986),(1255,859,1371,986)],
      'water_props':[(1396,889,1518,986),(1396,889,1518,986),(1396,967,1518,986)]}
    for kind,boxes in crops.items():
        for v,box in enumerate(boxes):
            im=whole_plant(box,2 if kind=='palms' else 3) if kind in ['palms','vegetation'] else extract('platforms.png',box,3)
            bbox=im.getbbox();im=im.crop(bbox);im2=Image.new('RGBA',(im.width+10,im.height+10));im2.alpha_composite(im,(5,5));im=im2
            if v==1 and kind in ['ruins','posts']:im=im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            pivot=[im.width//2,im.height-5];name=f'{kind}_{v}'
            write(out/(name+'.svg'),im,pivot)
            if kind=='posts':
                lamp=im.copy();a=np.array(lamp);hot=(a[:,:,0]>160)&(a[:,:,1]>90)&(a[:,:,2]<130);a[:,:,3]=np.where(hot,a[:,:,3],0);write(out/(name+'_lamp.svg'),Image.fromarray(a),pivot)
            entries.append({'id':name,'canvas':list(im.size),'pivot':pivot})
            ims.append(im);labels.append(name)
    old=json.loads((out/'manifest.json').read_text())
    extras=[e for e in old['assets'] if e['id'].split('_')[0] not in crops]
    (out/'manifest.json').write_text(json.dumps({'assets':entries+extras,'source':'tools/reference_art/cosmic/platforms.png'},indent=2))
    sheet('environment',ims,labels,cols=6,cell=(180,180))

def interactive():
    out=ASSETS/'world_01/interactive';ims=[];names=[]
    # Explicit crop, common canvas and placement lock the off/on ground pivot.
    specs={
      'turbine':([(27,88,197,373),(203,76,403,373)],(128,160),(64,156),144),
      'lighthouse':([(429,89,559,373),(566,60,714,373)],(116,156),(63,153),143),
      'checkpoint':([(759,150,908,373),(955,136,1120,373)],(128,140),(54,134),120),
      'node':([(1163,97,1317,373),(1329,94,1510,373)],(120,130),(63,127),118),
      'portal':([(20,436,270,650),(275,433,528,650)],(128,140),(62,136),128)}
    for kind,(boxes,size,pivot,height) in specs.items():
        if kind=='portal':continue # Registered separately, without per-state fitting.
        for state,box in zip(['off','on'],boxes):
            im=fit(extract('interactive.png',box,2),size,pivot,height)
            if kind=='turbine':
                # Rotor is wholly isolated above the pedestal; common center.
                a=np.array(im);yy,xx=np.indices(a.shape[:2]);rotormask=((xx-64)**2+(yy-60)**2<49**2)&~((abs(xx-64)<5)&(yy>68))
                a[:,:,3]=np.where(rotormask,a[:,:,3],0)
                rotor=Image.new('RGBA',(128,128));top=Image.fromarray(a).crop((0,0,128,109));rotor.alpha_composite(top,(0,4))
                base=im.copy();base.paste((0,0,0,0),(0,0,128,91));d=ImageDraw.Draw(base);d.rectangle((60,45,67,112),fill='#685a9d')
                write(out/f'turbine_base_{state}.svg',base,pivot);write(out/f'turbine_rotor_{state}.svg',rotor,[64,64])
            elif kind=='lighthouse':
                lamp=Image.new('RGBA',(20,20));d=ImageDraw.Draw(lamp);d.rectangle((5,5,14,14),fill='#ffb735' if state=='on' else '#593b75')
                write(out/f'lighthouse_base_{state}.svg',im,pivot);write(out/f'lighthouse_lamp_{state}.svg',lamp,[10,10])
            elif kind=='checkpoint':
                # Remove only orange cloth above the terminal; fixed pole stays.
                a=np.array(im);yy,xx=np.indices(a.shape[:2]);flagmask=(yy<70)&(xx>53)&(a[:,:,0]>90)&(a[:,:,0]>a[:,:,2]*1.4)
                flag=Image.fromarray(np.where(flagmask[:,:,None],a,0).astype('uint8'))
                a[flagmask,3]=0;base=Image.fromarray(a)
                flagcanvas=Image.new('RGBA',(128,128));flagcanvas.alpha_composite(flag.crop((0,0,128,100)),(0,10))
                write(out/f'checkpoint_base_{state}.svg',base,pivot);write(out/f'checkpoint_flag_{state}.svg',flagcanvas,[54,24])
                for index in range(8):
                    cloth=Image.new('RGBA',(128,140))
                    for y in range(flag.height):
                        for x in range(flag.width):
                            c=flag.getpixel((x,y))
                            if c[3]:
                                shift=round(math.sin(index*math.tau/8+(x-54)*.10)*min(2,max(0,x-54)/16))
                                cloth.putpixel((x,max(0,min(139,y+shift))),c)
                    write(out/f'checkpoint_flag_{state}_{index:02}.svg',cloth,pivot)
                lamp=Image.new('RGBA',(24,24));d=ImageDraw.Draw(lamp);d.rectangle((8,8,15,15),fill='#ffd84d' if state=='on' else '#463451');write(out/f'checkpoint_lamp_{state}.svg',lamp,[12,12])
            else:
                cx,cy,rad=(63,77,23) if kind=='node' else (62,82,32)
                a=np.array(im);yy,xx=np.indices(a.shape[:2]);mask=(xx-cx)**2+(yy-cy)**2<rad*rad
                core=a.copy();core[:,:,3]=np.where(mask,core[:,:,3],0);a[:,:,3]=np.where(mask,0,a[:,:,3])
                canvas=Image.new('RGBA',(64,64) if kind=='node' else (80,80));c=canvas.width//2
                canvas.alpha_composite(Image.fromarray(core).crop((cx-rad,cy-rad,cx+rad,cy+rad)),(c-rad,c-rad))
                write(out/f'{kind}_frame_{state}.svg',Image.fromarray(a),pivot)
                key=kind+'_core'+('_off' if state=='off' else '')
                write(out/(key+'.svg'),canvas,[c,c])
            ims.append(im);names.append(kind+' '+state)
    # Rail modular art is redrawn directly from the approved segmented strip.
    for state in ['off','on']:
        post=fit(extract('interactive.png',(569,475,709,650),2),(42,52),(21,50),50)
        if state=='off':post=dim(post)
        write(out/f'rail_post_{state}.svg',post,[30,24])
        seg=Image.new('RGBA',(24,18));d=ImageDraw.Draw(seg)
        d.rectangle((0,6,23,11),fill='#302544');d.rectangle((0,7,23,9),fill='#38dced' if state=='on' else '#654487');d.rectangle((2,7,6,8),fill='#e4ffff' if state=='on' else '#9f61ba')
        write(out/f'rail_segment_{state}.svg',seg,[0,9])
    build_gem()
    sheet('interactive',ims,names,cols=5,cell=(220,250))
    build_portal()
    from build_connection_node import main as connection_node
    connection_node()

def build_portal():
    """Register approved states by source aperture center, not bbox center."""
    out=ASSETS/'world_01/interactive'
    for state,box,source_center in [
        ('off',(20,426,290,658),(161,550)),
        ('on',(290,426,561,658),(426,550))]:
        raw=extract('interactive.png',box,2,96)
        # Canvas 160, pivot (80,152); aperture (80,103). Same source scale.
        center=((source_center[0]-box[0])/2,(source_center[1]-box[1])/2)
        im=Image.new('RGBA',(160,160))
        im.alpha_composite(raw,(round(80-center[0]),round(103-center[1])))
        a=np.array(im);yy,xx=np.indices(a.shape[:2])
        opening=(xx-80)**2+(yy-103)**2<=29**2
        core=a.copy();core[:,:,3]=np.where(opening,core[:,:,3],0)
        a[:,:,3]=np.where(opening,0,a[:,:,3])
        # One-pixel overlap hides nearest-neighbor rotation gaps beneath the
        # stationary frame; no structural pixel is ever part of the rotor.
        canvas=Image.new('RGBA',(80,80))
        d=ImageDraw.Draw(canvas);d.ellipse((11,11,69,69),fill='#211137')
        canvas.alpha_composite(Image.fromarray(core).crop((40,63,120,143)),(0,0))
        # Remove detached source-board scraps and tiny outlined specks outside
        # the portal structure. Aperture shading stays inside the rotor.
        seen=set()
        for y,x in zip(*np.where(a[:,:,3]>0)):
            if (x,y) in seen:continue
            todo=[(x,y)];part=[];seen.add((x,y))
            while todo:
                px,py=todo.pop();part.append((px,py))
                for nx,ny in [(px-1,py),(px+1,py),(px,py-1),(px,py+1)]:
                    if 0<=nx<160 and 0<=ny<160 and a[ny,nx,3] and (nx,ny) not in seen:
                        seen.add((nx,ny));todo.append((nx,ny))
            if len(part)<=100 and min(py for px,py in part)<130:
                for px,py in part:a[py,px,3]=0
        write(out/f'portal_frame_{state}.svg',Image.fromarray(a),[80,152])
        write(out/('portal_core.svg' if state=='on' else 'portal_core_off.svg'),canvas,[40,40])
    (out/'portal_layout.json').write_text(json.dumps({'frame_canvas':[160,160],
        'frame_pivot':[80,152],'aperture_center':[80,103],'aperture_radius':29,
        'core_canvas':[80,80],'core_pivot':[40,40],'uniform_scale':1.5,
        'world_center_offset':[0,-73.5],'source_scale':.5},indent=2))

def build_gem():
    # Keep the approved facets at their existing size and pivot. The source
    # board/shadow must never become part of a floating collectible.
    im=fit(extract('interactive.png',(1133,510,1204,637),2),(48,56),(24,52),43)
    a=np.array(im);rgb=a[:,:,:3].astype(np.int16)
    warm=(a[:,:,3]>0)&(rgb[:,:,0]>90)&(rgb[:,:,0]>rgb[:,:,2]*1.35)&(rgb[:,:,1]>rgb[:,:,2]*.5)
    seen=set();components=[]
    for y,x in zip(*np.where(warm)):
        if (x,y) in seen:continue
        todo=[(x,y)];part=[];seen.add((x,y))
        while todo:
            px,py=todo.pop();part.append((px,py))
            for nx,ny in [(px-1,py),(px+1,py),(px,py-1),(px,py+1)]:
                if 0<=ny<im.height and 0<=nx<im.width and warm[ny,nx] and (nx,ny) not in seen:
                    seen.add((nx,ny));todo.append((nx,ny))
        components.append(part)
    body=np.zeros(warm.shape,dtype=bool)
    for x,y in max(components,key=len):body[y,x]=True
    edge=body.copy()
    edge[1:,:]|=body[:-1,:];edge[:-1,:]|=body[1:,:]
    edge[:,1:]|=body[:,:-1];edge[:,:-1]|=body[:,1:]
    a[:,:,3]=np.where(edge,255,0)
    a[edge & ~body,:3]=[33,20,47]
    return write(ASSETS/'world_01/svg/gem_orange.svg',Image.fromarray(a),[24,28])

def dim(im):
    a=np.array(im);a[:,:,:3]=(a[:,:,:3].astype(float)*.58).astype('uint8');return Image.fromarray(a)

def enemies():
    out=ASSETS/'enemies/cosmic';names=['cristal','esporo','magnetico','escavador','plasma','satelite','corrompido','sentinela','orbital']
    boxes=[(169,36,477,300),(643,42,908,298),(1049,42,1380,300),(165,380,473,615),(650,377,912,616),(1026,359,1404,616),(150,697,475,935),(628,686,928,936),(1026,694,1448,938)]
    face_eyes=[[(275,207),(329,207)],[(716,209),(773,209)],[(1180,204),(1237,204)],[(275,516),(332,516)],[(717,519),(773,519)],[(1197,534),(1257,534)],[(268,828),(325,828)],[(720,822),(779,822)],[(1176,846),(1233,846)],[]]
    specs={'idle':(8,8,True),'patrol':(8,12,True),'alert':(6,10,False),'hit':(6,12,False),'defeated':(12,12,False)}
    previews=[];labels=[]
    names.append('etzinho');boxes.append(None)
    for name,box,source_eyes in zip(names,boxes,face_eyes):
        eyes=[]
        if name=='etzinho':
            raw=Image.open(REF/'etzinho.png').convert('RGBA')
            raw=raw.crop(raw.getbbox())
            raw=raw.resize((round(raw.width*100/raw.height),100),Image.Resampling.NEAREST)
            alpha=raw.getchannel('A').point(lambda v:255 if v>=128 else 0)
            raw=raw.convert('RGB').quantize(colors=16,dither=Image.Dither.NONE).convert('RGBA');raw.putalpha(alpha)
            raw=raw.crop(raw.getbbox()) # Discard faint alpha margins before anchoring feet.
        else:
            raw=extract('enemies.png',box,4,96);sx=raw.width/(box[2]-box[0]);sy=raw.height/(box[3]-box[1]);crop=raw.getbbox();raw=raw.crop(crop)
            eyes=[(64-raw.width//2+round((x-box[0])*sx)-crop[0],112-raw.height+round((y-box[1])*sy)-crop[1]) for x,y in source_eyes]
        base=Image.new('RGBA',(128,128));base.alpha_composite(raw,(64-raw.width//2,112-raw.height))
        folder=out/name;ext=[];anim=[];idx=0
        for state,(count,fps,loop) in specs.items():
            for i in range(count):
                im=pose(base,name,state,i,count,eyes)
                path=folder/'frames'/state/f'{i:02}.svg';write(path,im,[64,112]);idx+=1
                ext.append(f'[ext_resource type="Texture2D" path="res://assets/enemies/cosmic/{name}/frames/{state}/{i:02}.svg" id="{idx}"]')
                if i==min(3,count-1):previews.append(im);labels.append(name+' '+state)
            first=idx-count+1
            frames=', '.join('{"duration":1.0,"texture":ExtResource("'+str(n)+'")}' for n in range(first,idx+1))
            anim.append('{"frames":['+frames+'],"loop":'+str(loop).lower()+',"name":&"'+state+'","speed":'+str(float(fps))+'}')
        (folder/'spriteframes.tres').write_text(f'[gd_resource type="SpriteFrames" load_steps={idx+1} format=3]\n\n'+'\n\n'.join(ext)+'\n\n[resource]\nanimations = ['+',\n'.join(anim)+']\n')
        (folder/'animations.json').write_text(json.dumps({'variant':name,'canvas':[128,128],'ground_pivot':[64,112],'sprite_offset':[0,-48],'scale':1,'states':specs,'motion':'Continuous inverse pixel rig: breathing/blink, alternating feet, antenna sway, alert lean, recoil, shrink/disintegration', 'visual_height':100 if name=='etzinho' else raw.height,'behavior':'Existing grounded patrol/combat; variants are cosmetic.'},indent=2))
    sheet('enemies',previews,labels,cols=5,cell=(170,170))
    # Preserve the explicitly approved armed replacement on full regeneration.
    from build_armed_etzinho import main as armed_etzinho
    armed_etzinho()
    return names

def background():
    out=ASSETS/'background_svg';original=Image.open(REF/'background-orange-approved.png').convert('RGB')
    # Resize uniformly to the existing panorama height, then crop width only.
    factor=724/original.height;original=original.resize((round(original.width*factor),724),Image.Resampling.NEAREST)
    original=original.crop(((original.width-2172)//2,0,(original.width-2172)//2+2172,724))
    small=original.resize((1086,362),Image.Resampling.NEAREST).quantize(colors=96,dither=Image.Dither.NONE).convert('RGB').convert('RGBA')
    original=small.resize((2172,724),Image.Resampling.NEAREST)
    # Shared full canvas; immutable geometry avoids coastline/plant drift.
    write(out/'cosmic_panorama.svg',original,[0,0])
    original.save(QA/'background.png')
    (out/'cosmic_manifest.json').write_text(json.dumps({'canvas':[2172,724],'source':'tools/reference_art/cosmic/background-orange-approved.png','grid':2,'parallax':'Shared canvas, horizontal travel, no stretch'},indent=2))

def logo():
    # The selected logo crop ends ABOVE the subtitle and excludes the footer.
    im=extract('menu.png',(217,32,850,330),2,48)
    write(ASSETS/'ui/cosmic_logo.svg',im,[im.width/2,im.height/2]);im.save(QA/'logo.png')

def main():
    platforms();environment();interactive();names=enemies();background();logo()
    MANIFEST['enemy_variants']=names
    MANIFEST['approved_footer_removed']=True
    (ROOT/'godot/docs/cosmic_assets_manifest.json').write_text(json.dumps(MANIFEST,ensure_ascii=False,indent=2))
    print('Cosmic vector assets:',len(MANIFEST['assets']))
    from build_warm_assets import main as warm_assets
    warm_assets()

if __name__=='__main__':main()
