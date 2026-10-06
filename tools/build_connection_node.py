"""Approved connection node: registered layers, clean negative spaces, real SVG."""
from pathlib import Path
from collections import defaultdict
import json, math
import numpy as np
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'godot/assets/world_01/interactive'
SIZE=(160,224); PIVOT=(80,212); CORE=(80,117)

def write(path,im):
    a=np.array(im.convert('RGBA'));groups=defaultdict(list)
    for y in range(im.height):
        x=0
        while x<im.width:
            c=tuple(a[y,x]);start=x;x+=1
            while x<im.width and tuple(a[y,x])==c:x+=1
            if c[3]:groups[c].append(f'M{start} {y}h{x-start}v1h-{x-start}z')
    body=''.join(f'<path fill="#{r:02x}{g:02x}{b:02x}" d="{"".join(runs)}"/>' for (r,g,b,alpha),runs in groups.items())
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{im.width}" height="{im.height}" viewBox="0 0 {im.width} {im.height}" shape-rendering="crispEdges">{body}</svg>\n')
    return body

def cleaned(source):
    rgb=source.convert('RGB');a=np.array(rgb).astype(int)
    r,g,b=a[:,:,0],a[:,:,1],a[:,:,2]
    navy=(r<42)&(g<48)&(g>=r*0.70)&(b>r*1.45)&(b>g*1.4)
    black=(r<12)&(g<12)&(b<20)
    opaque=~(navy|black)
    samples=Image.fromarray(a[opaque].astype('uint8').reshape(1,-1,3))
    palette=samples.quantize(colors=48,dither=Image.Dither.NONE)
    colors=palette.getpalette()
    for i,c in enumerate([(255,176,0),(255,122,0),(255,216,77),(34,207,255),(0,172,232),(255,243,205)],48):colors[3*i:3*i+3]=c
    palette.putpalette(colors)
    out=np.array(rgb.quantize(palette=palette,dither=Image.Dither.NONE).convert('RGBA'))
    out[:,:,3]=np.where(opaque,255,0)
    return Image.fromarray(out)

def main():
    source=Image.open(ROOT/'tools/reference_art/cosmic/connection-node-approved.png')
    box=(824,150,1336,872);factor=188/(box[3]-box[1])
    raw=source.crop(box).resize((round((box[2]-box[0])*factor),188),Image.Resampling.NEAREST)
    raw=cleaned(raw);base=Image.new('RGBA',SIZE)
    origin=(80-round((1074-box[0])*factor),24)
    base.alpha_composite(raw,origin)
    a=np.array(base);yy,xx=np.indices(a.shape[:2])
    interior=(xx-CORE[0])**2+(yy-CORE[1])**2<39**2
    # Separate the entire inner opening, including enclosed navy spaces.
    coremask=((xx-CORE[0])**2+(yy-CORE[1])**2<28**2)&(a[:,:,3]>0)&(a[:,:,0]>a[:,:,2]*0.95)
    core=Image.new('RGBA',(96,96));inner=a.copy();inner[~coremask]=0
    core.alpha_composite(Image.fromarray(inner).crop((32,69,128,165)))
    from clean_light_edges import remove_fringe
    core,_=remove_fringe(core)
    # Energy arcs are isolated from the static cradle; no painted duplicate.
    frame=a.copy();frame[interior]=0
    # Strip disconnected board specks / particle scraps from the rigid frame.
    seen=set();components=[]
    for y,x in zip(*np.where(frame[:,:,3]>0)):
        if (x,y) in seen:continue
        todo=[(x,y)];seen.add((x,y));part=[]
        while todo:
            px,py=todo.pop();part.append((px,py))
            for nx,ny in [(px-1,py),(px+1,py),(px,py-1),(px,py+1)]:
                if 0<=nx<SIZE[0] and 0<=ny<SIZE[1] and frame[ny,nx,3] and (nx,ny) not in seen:
                    seen.add((nx,ny));todo.append((nx,ny))
        components.append(part)
    largest=max(components,key=len)
    keep=set(largest)
    for part in components:
        if len(part)>24:keep.update(part)
    # The thin antenna may be detached by the pixel-grid sampling; retain its
    # explicit authored region, never nearby free-floating effect pixels.
    for part in components:
        if len(part)>8 and all(55<=x<=95 and 39<=y<=84 for x,y in part):keep.update(part)
    for part in components:
        for x,y in part:
            if (x,y) not in keep:frame[y,x]=0
    # Signal symbol and sparks are animated separately, not frozen on the frame.
    frame[(yy<53)&(xx>=65)&(xx<=96)]=0
    for part in components:
        px=min(x for x,y in part);py=min(y for x,y in part)
        if len(part)<90 and py<170 and (px<32 or 145<py<165):
            for x,y in part:frame[y,x]=0
    on=Image.fromarray(frame)
    offa=frame.copy();cyan=(offa[:,:,2]>offa[:,:,0]*1.2)&(offa[:,:,1]>95)&(yy>=169)&(yy<=185)
    offa[cyan,:3]=(83,37,112)
    off=Image.fromarray(offa)
    # Offline crystal from approved left panel, same source scale and center.
    left=source.crop((320,397,554,619)).resize((61,58),Image.Resampling.NEAREST)
    left=cleaned(left);la=np.array(left);ly,lx=np.indices(la.shape[:2])
    valid=(la[:,:,3]>0)&(((lx-30)/31)**2+((ly-29)/29)**2<1)
    la[~valid]=0;coreoff=Image.new('RGBA',(96,96));coreoff.alpha_composite(Image.fromarray(la),(18,19))
    arcs=Image.new('RGBA',(96,96));d=ImageDraw.Draw(arcs)
    for start in [15,105,195,285]:
        for angle in range(start,start+38,3):
            x=round(48+34*math.cos(math.radians(angle)));y=round(48+34*math.sin(math.radians(angle)))
            d.rectangle((x-1,y-1,x+1,y+1),fill='#22cfff')
    panel=Image.new('RGBA',(18,4));d=ImageDraw.Draw(panel)
    d.rectangle((0,0,17,3),fill='#22cfff');d.rectangle((2,1,15,2),fill='#fff3cd')
    write(OUT/'node_panel_fill.svg',panel)
    spark=Image.new('RGBA',(12,12));d=ImageDraw.Draw(spark)
    d.rectangle((5,2,6,9),fill='#ffb000');d.rectangle((2,5,9,6),fill='#ffb000');d.rectangle((5,5,6,6),fill='#fff3cd')
    signal=Image.new('RGBA',SIZE);d=ImageDraw.Draw(signal)
    for rad,start,end in [(9,205,335),(15,205,335)]:
        for angle in range(start,end,5):
            x=round(80+rad*math.cos(math.radians(angle)));y=round(47+rad*math.sin(math.radians(angle)))
            d.rectangle((x,y,x+1,y+1),fill='#22cfff')
    for name,im in [('node_frame_on',on),('node_frame_off',off),('node_core',core),('node_core_off',coreoff),('node_halo',arcs),('node_spark',spark),('node_signal',signal)]:write(OUT/(name+'.svg'),im)
    # Standalone animated SVG for review outside Godot; gameplay uses these same
    # real path layers with GDScript, since Godot rasterization ignores SMIL.
    paths={n:write(OUT/(n+'.svg'),im) for n,im in [('node_frame_on',on),('node_frame_off',off),('node_core',core),('node_core_off',coreoff),('node_halo',arcs),('node_signal',signal)]}
    standalone=ROOT/'godot/docs/connection_node';standalone.mkdir(parents=True,exist_ok=True)
    (standalone/'node_connected_animated.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="480" height="672" viewBox="0 0 160 224" shape-rendering="crispEdges">'+paths['node_frame_on']+'<g transform="translate(32 69)"><g>'+paths['node_halo']+'<animateTransform attributeName="transform" type="rotate" from="0 48 48" to="360 48 48" dur="7s" repeatCount="indefinite"/></g><g transform="translate(48 48)"><g><g transform="translate(-48 -48)">'+paths['node_core']+'</g><animateTransform attributeName="transform" type="scale" values="1;1.025;1" dur="2.6s" repeatCount="indefinite"/></g></g></g><g>'+paths['node_signal']+'<animate attributeName="opacity" values="0.35;1;0.35" dur="2.6s" repeatCount="indefinite"/></g></svg>')
    (standalone/'node_disconnected.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="480" height="672" viewBox="0 0 160 224" shape-rendering="crispEdges">'+paths['node_frame_off']+'<g transform="translate(32 69)">'+paths['node_core_off']+'</g></svg>')
    composite=on.copy();composite.alpha_composite(arcs,(32,69));composite.alpha_composite(core,(32,69))
    composite.alpha_composite(signal)
    sheets=Image.new('RGBA',(480,448),'#fff3cd')
    offline=off.copy();offline.alpha_composite(coreoff,(32,69))
    sheets.alpha_composite(offline.resize((240,336),Image.Resampling.NEAREST),(0,55))
    sheets.alpha_composite(composite.resize((240,336),Image.Resampling.NEAREST),(240,55))
    sheets.save(standalone/'recorte_fundo_claro.png')
    on.save(standalone/'frame_transparent.png');core.save(standalone/'core_transparent.png')
    (OUT/'node_manifest.json').write_text(json.dumps({'canvas':SIZE,'ground_pivot':PIVOT,'core_center':CORE,'scale':0.7,'source':'connection-node-approved.png','geometry':'real paths; no raster','layers':['static frame','pulsing crystal','rotating inner arcs','sequential pedestal panels','signal','sparks'],'background_cleanup':'navy and black board excluded in all negative spaces; rigid-frame disconnected particles removed'},indent=2))

if __name__=='__main__':main()
