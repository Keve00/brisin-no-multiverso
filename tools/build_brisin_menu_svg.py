#!/usr/bin/env python3
"""Brisin menu poses: full-resolution source identity and genuine SVG paths."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import math, json, subprocess, xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'godot/assets/player/menu_svg'
RIG_SIZE=(88,80)
SIZE=(176,160); PIVOT=(88,136)
PALETTE=['#F17B08','#D0500C','#AD4212','#FF9E31','#FFBD6D','#091127',
         '#54372C','#68442F','#392B2B','#FAF8FC','#B7B6C4','#0A0C29','#E8E8F0']
INK='#392B2B'; BROWN='#54372C'; LIGHT='#68442F'
READY_ORIGINS={'ready_to_run':0,'ready_middle':2,'ready_high':6}
READY_ORIGINS.update({f'ready_from_{i:02d}':i for i in range(30) if i not in (0,2,6)})
SPECS={'wave':(30,10,True),**{name:(8,12,False) for name in READY_ORIGINS},'run_start':(8,12,False)}
MENU_SELECTION={name:[origin] for name,origin in READY_ORIGINS.items()}

def blank(size=RIG_SIZE):return Image.new('RGBA',size)

def source_layers():
    src=Image.open(ROOT/'godot/assets/player/walk.png').convert('RGBA').crop((0,0,144,128))
    # Preserve every authored source pixel. Rig coordinates remain half-size,
    # but the body/face are no longer reduced and reconstructed from a 72px sample.
    colors=[tuple(bytes.fromhex(c[1:])) for c in PALETTE]
    body=blank(SIZE);face=blank(SIZE)
    for y in range(128):
        for x in range(144):
            r,g,b,a=src.getpixel((x,y))
            if a<160:continue
            c=min(colors,key=lambda c:sum((u-v)**2 for u,v in zip((r,g,b),c)))
            # Remove old limbs, preserving the orange silhouette and dark contour.
            if (y>=76 and x<56) or (y>=80 and x>92):continue
            if y>=104 or (y>=96 and c not in colors[:5]):continue
            if y>=76 and x<64 and c in colors[6:9]:continue
            dst=face if 50<=y<=71 and x>=60 and (min(r,g,b)>120 or r<100) else body
            dst.putpixel((x+16,y+16),c+(255,))
    # Rebuild the left flank below the sail. The old arm cutout was outside
    # the silhouette and remained visible as a hole above the new shoulder.
    # A stepped orange wedge joins sail/body; only its exterior keeps dark ink.
    for y in range(90,106):
        left=60+max(0,y-92)
        for x in range(left,79):
            previous=body.getpixel((x,y))
            if x==left and not body.getpixel((x-1,y))[3]:
                color=(9,17,39,255)
            elif x<=left+2:
                color=(208,80,12,255)
            elif previous[3] and previous[:3] in colors[:5]:
                color=previous
            else:
                color=(241,123,8,255)
            body.putpixel((x,y),color)
    return body,face

BODY,FACE=source_layers()

def joint(point,lean,bob=0):
    # Rigid rotation of body and its attached shoulder; rounded logical coordinates.
    x,y=point; a=math.radians(lean); px,py=44,58
    return (round(px+(x-px)*math.cos(a)-(y-py)*math.sin(a)),
            round(py+(x-px)*math.sin(a)+(y-py)*math.cos(a))+bob)

def limb(im,points,hand=False):
    d=ImageDraw.Draw(im)
    d.line(points,fill=INK,width=4)
    d.line(points,fill=BROWN,width=2)
    if len(points)>1:
        x,y=points[-1]
        if hand:
            d.rectangle((x-2,y-3,x+2,y+1),fill=INK)
            d.rectangle((x-1,y-3,x+1,y),fill=BROWN)
            d.point((x+1,y-2),fill=LIGHT)
            d.rectangle((x-3,y-1,x-2,y),fill=BROWN)
            for dx,top in [(-2,-5),(0,-6),(2,-5)]:
                d.line([(x+dx,y+top),(x+dx,y-2)],fill=BROWN,width=1)
            d.point((x,y-5),fill=LIGHT)
        else:
            d.rectangle((x-1,y-1,x+2,y),fill=INK)
            d.rectangle((x,y-1,x+2,y-1),fill=BROWN)

def wave_rig(i):
    # Lift, three broad hand sweeps, relaxed lowering and two-frame blink at rest.
    # Only upper-body joints rock; the two foot contacts stay fixed on the platform.
    lift=min(1,max(0,i/4)) if i<4 else 1 if i<19 else max(0,(24-i)/5)
    sweep=math.sin((i-4)*math.pi/4) if 4<=i<=19 else 0
    lean=round(-2*math.sin(i*math.tau/30))*lift
    bob=round((.5-.5*math.cos(i*math.tau/15))*lift)
    sh=joint((54,48),lean,bob)
    elbow=(round(56+5*lift+2*sweep*lift),round(51-12*lift)+bob)
    palm=(round(56+9*lift+7*sweep*lift),round(54-27*lift+abs(sweep)*3)+bob)
    return lean,bob,sh,elbow,palm

def flutter(body,phase,strength=1):
    moved=blank(SIZE)
    for y in range(SIZE[1]):
        weight=max(0,min(1,(66-y)/30))
        dx=round(math.sin(phase+(66-y)*.09)*2.5*weight*strength)
        for x in range(SIZE[0]):
            color=body.getpixel((x,y))
            if color[3] and 0<=x+dx<SIZE[0]:moved.putpixel((x+dx,y),color)
    return moved

def pose(state,i):
    lean=0;bob=0;blink=False;phase=0
    arms=blank();legs=blank();body=BODY.copy();face=FACE.copy()
    if state=='wave':
        lean,bob,shoulder,elbow,palm=wave_rig(i)
        phase=i*math.tau/30
        blink=i in (26,27)
        limb(arms,[shoulder,elbow,palm],True)
        limb(arms,[joint((39,48),lean,bob),(32,52+bob),(32,54+bob)])
        limb(legs,[joint((40,55),lean,bob),(38,63),(35,67)])
        limb(legs,[joint((47,55),lean,bob),(51,63),(53,67)])
    elif state.startswith('ready'):
        p=i/7; origin=READY_ORIGINS[state]
        start_lean,start_bob,_,elbow,palm=wave_rig(origin)
        lean=start_lean+(7-start_lean)*p;bob=round(start_bob*(1-p))
        phase=origin*math.tau/30*(1-p)
        lerp=lambda a,b:(round(a[0]+(b[0]-a[0])*p),round(a[1]+(b[1]-a[1])*p))
        limb(arms,[joint((54,48),lean,bob),lerp(elbow,(53,51)),lerp(palm,(49,53))],True)
        limb(arms,[joint((39,48),lean,bob),lerp((32,52+start_bob),(40,53)),lerp((32,54+start_bob),(46,52))])
        limb(legs,[joint((40,55),lean,bob),lerp((38,63),(36,62)),lerp((35,67),(33,67))])
        limb(legs,[joint((47,55),lean,bob),lerp((51,63),(54,61)),lerp((53,67),(56,67))])
        blink=i==0 and origin in (26,27)
    else:
        lean=7;phase=i*math.tau/8
        # Initial running pose EXACTLY matches the last ready pose, then accelerates.
        if i==0:
            limb(arms,[joint((54,48),lean),(53,51),(49,53)],True)
            limb(arms,[joint((39,48),lean),(40,53),(46,52)])
            limb(legs,[joint((40,55),lean),(36,62),(33,67)])
            limb(legs,[joint((47,55),lean),(54,61),(56,67)])
        else:
            p=math.sin(i*math.tau/7)
            limb(arms,[joint((54,48),lean),(round(54-4*p),round(51-3*p)),(round(52-7*p),round(51-5*p))],True)
            limb(arms,[joint((39,48),lean),(round(40+4*p),round(51+3*p)),(round(45+7*p),round(50+5*p))])
            if p>=0:
                limb(legs,[joint((40,55),lean),(round(39-4*p),62),(round(33-3*p),67)])
                limb(legs,[joint((47,55),lean),(round(53+3*p),round(62-5*p)),(round(56+2*p),round(67-8*p))])
            else:
                p=-p
                limb(legs,[joint((40,55),lean),(round(37-3*p),round(62-4*p)),(round(33-3*p),round(67-7*p))])
                limb(legs,[joint((47,55),lean),(round(53+2*p),62),(round(56+3*p),67)])
    # Wave cloth has a readable two-pixel tip drift. Readiness starts at the same
    # cloth phase/amplitude and settles to the exact first running frame.
    cloth_strength=1.8 if state=='wave' else (1.8-.8*(i/7)) if state.startswith('ready') else 1
    body=flutter(body,phase,cloth_strength)
    if blink:
        # Close ONLY the authored eye sockets, preserving eyebrows, cheeks and outline.
        for y in range(66,86):
            for x in range(78,118):
                if face.getpixel((x,y))[3]:face.putpixel((x,y),(241,123,8,255))
        d=ImageDraw.Draw(face)
        d.line([(80,76),(92,76)],fill='#091127',width=2)
        d.line([(106,76),(114,76)],fill='#091127',width=2)
    if lean:
        body=body.rotate(-lean,resample=Image.Resampling.NEAREST,center=(88,116))
        face=face.rotate(-lean,resample=Image.Resampling.NEAREST,center=(88,116))
    if bob:
        moved=blank(SIZE);moved.alpha_composite(body,(0,bob*2));body=moved
        moved=blank(SIZE);moved.alpha_composite(face,(0,bob*2));face=moved
    # Regression: the repaired orange flank must remain opaque through every
    # wave, blink, ready and running pose, including lean and vertical motion.
    # Check the full interior of the rebuilt flank, not just three torso points.
    # Previously those points passed while the large concavity beside them remained.
    flank_points=[(x/2,y/2) for y in range(93,105) for x in range(63+max(0,y-92),79)]
    for point in flank_points:
        x,y=joint(point,lean,bob)
        assert body.getpixel((x*2,y*2))[3]==255,(state,i,"left-flank hole")
    ImageDraw.Draw(legs).rectangle((0,68,87,79),fill=(0,0,0,0))
    return [('legs',legs.resize(SIZE,Image.Resampling.NEAREST)),('arms',arms.resize(SIZE,Image.Resampling.NEAREST)),('body',body),('face',face)]

def paths(im):
    bycolor={}
    for y in range(SIZE[1]):
        x=0
        while x<SIZE[0]:
            c=im.getpixel((x,y))
            if not c[3]:x+=1;continue
            start=x;x+=1
            while x<SIZE[0] and im.getpixel((x,y))==c:x+=1
            color='#%02X%02X%02X'%c[:3]
            bycolor.setdefault(color,[]).append(f'M{start} {y}h{x-start}v1h-{x-start}z')
    return ''.join(f'<path fill="{c}" d="{"".join(p)}"/>' for c,p in bycolor.items())

def svg(layers):
    groups=''.join(f'<g id="{name}">{paths(im)}</g>' for name,im in layers)
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="176" height="160" viewBox="0 0 176 160" shape-rendering="crispEdges">{groups}</svg>'

def check_connected(im):
    pixels={(x,y) for y in range(SIZE[1]) for x in range(SIZE[0]) if im.getpixel((x,y))[3]}
    todo=[pixels.pop()]
    while todo:
        x,y=todo.pop()
        for dx in (-1,0,1):
            for dy in (-1,0,1):
                p=(x+dx,y+dy)
                if p in pixels:pixels.remove(p);todo.append(p)
    assert not pixels,'Detached arm, leg or leftover source pixels'

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    render=OUT/'qa';render.mkdir(exist_ok=True)
    refs=[];frames={};bounds=[]
    for state,(count,fps,loop) in SPECS.items():
        frames[state]=[]
        for i in range(count):
            name=f'{state}_{i:02d}.svg';layers=pose(state,i);s=svg(layers)
            (OUT/name).write_text(s)
            refs.append(name);frames[state].append(name)
            comp=blank(SIZE)
            for _,im in layers:comp.alpha_composite(im)
            check_connected(comp)
            bbox=comp.getbbox();assert bbox and bbox[0]>0 and bbox[1]>0 and bbox[2]<176 and bbox[3]<160,(name,bbox)
            assert bbox[3]==136,(name,'lost ground',bbox)
            bounds.append({'frame':name,'bounds':bbox})
            node=ET.fromstring(s);assert node.attrib['viewBox']=='0 0 176 160'
            assert not any(e.tag.endswith('image') for e in node.iter())
            png=render/(name[:-4]+'.png')
            subprocess.run(['inkscape',str(OUT/name),'--export-type=png',f'--export-filename={png}','--export-width=352'],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
            actual=Image.open(png).convert('RGBA').resize(SIZE,Image.Resampling.NEAREST)
            check_connected(actual)
    # Actual SVG renders verify every click-time handoff; no generic pose can stand
    # in for the live wave frame when its body, cloth or blink differs.
    for state,origin in READY_ORIGINS.items():
        entry=Image.open(render/f'{state}_00.png').convert('RGBA')
        waving=Image.open(render/f'wave_{origin:02d}.png').convert('RGBA')
        exit_pose=Image.open(render/f'{state}_07.png').convert('RGBA')
        running=Image.open(render/'run_start_00.png').convert('RGBA')
        assert entry.tobytes()==waving.tobytes(),(state,'entry pop')
        assert exit_pose.tobytes()==running.tobytes(),(state,'exit pop')
    txt=[f'[gd_resource type="SpriteFrames" load_steps={len(refs)+1} format=3]','']
    ids={}
    for i,n in enumerate(refs,1):
        ids[n]=i;txt.append(f'[ext_resource type="Texture2D" path="res://assets/player/menu_svg/{n}" id="{i}"]')
    txt+=['','[resource]','animations = [']
    for j,(state,(count,fps,loop)) in enumerate(SPECS.items()):
        fs=', '.join('{"duration": 1.0, "texture": ExtResource("%s")}'%ids[n] for n in frames[state])
        txt.append('{"frames": [%s], "loop": %s, "name": &"%s", "speed": %s}%s'%(fs,str(loop).lower(),state,fps,',' if j<len(SPECS)-1 else ''))
    txt.append(']');(OUT/'spriteframes.tres').write_text('\n'.join(txt)+'\n')
    metadata={'canvas':SIZE,'ground_pivot':PIVOT,'source_cell':[144,128],'sample_scale':1.0,'source':'walk.png frame 0; run.png reference for limb preparation','layers':['legs','arms','body','face'],'technique':'Genuine pixel-path SVG frames imported as textures; AnimatedSprite2D controls playback; no SMIL required by Godot','cloth_attachment':[88,66],'wrist_sweep_px':28,'entry_match':'Every wave frame has a matching finite ready animation; all ready exits match run_start frame 0','animations':{s:{'frames':n,'fps':f,'loop':l,'duration':n/f} for s,(n,f,l) in SPECS.items()},'menu_selection':MENU_SELECTION,'bounds':bounds,'checks':{'frames':len(refs),'nonempty':True,'same_canvas':True,'fixed_ground':True,'no_embedded_raster':True,'integer_path_coordinates':True,'connected_limbs_every_render':True,'left_flank_opaque_every_pose':True,'full_flank_region_checked':True,'exact_rendered_entries':30,'exact_rendered_exits':30,'rendered_by':'Inkscape'}}
    metadata['ready_for_wave_frames']=[next(name for name,indices in MENU_SELECTION.items() if i in indices) for i in range(30)]
    (OUT/'animations.json').write_text(json.dumps(metadata,indent=2)+'\n')
    (OUT/'brisin.svg').write_text(svg(pose('wave',29)))
    # Contact sheet consists of ACTUAL SVG renders, not a separately drawn mock-up.
    selected=[('wave',i) for i in [0,3,6,9,12,17,21,25,29]]+[('ready_to_run',i) for i in [0,3,7]]+[('run_start',i) for i in [0,2,5]]+[('ready_middle',0),('ready_middle',7),('ready_high',0),('ready_high',3),('ready_high',7)]
    sheet=Image.new('RGB',(5*360,4*360),'#241508');d=ImageDraw.Draw(sheet)
    font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',17)
    for k,(state,i) in enumerate(selected):
        x=(k%5)*360;y=(k//5)*360
        im=Image.open(render/f'{state}_{i:02d}.png').convert('RGBA');sheet.paste(im,(x+4,y),im)
        d.line((x,y+272,x+358,y+272),fill='#62442A')
        d.text((x+12,y+330),f'{state} {i:02d}',font=font,fill='#FFD84D')
    sheet.save(OUT/'contact_sheet.png')
    # A standalone vector preview; actual Godot playback is AnimatedSprite2D, not SMIL.
    preview_refs=frames['wave']+frames['ready_to_run']+frames['run_start']
    total=len(preview_refs);groups=[];elapsed=0
    for i,n in enumerate(preview_refs):
        content=ET.fromstring((OUT/n).read_text())
        inner=''.join(ET.tostring(e,encoding='unicode') for e in content)
        dt=1/SPECS['wave' if i<30 else 'run_start' if i>=38 else 'ready_to_run'][1]
        groups.append(f'<g visibility="hidden">{inner}<set attributeName="visibility" to="visible" begin="{elapsed:.6f}s; cycle.end+{elapsed:.6f}s" dur="{dt:.6f}s"/></g>');elapsed+=dt
    (OUT/'preview_animated.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="528" height="540" viewBox="0 0 176 180" shape-rendering="crispEdges"><rect width="176" height="180" fill="#241508"/><line x1="8" y1="136" x2="168" y2="136" stroke="#62442A" stroke-width=".25"/><g>{"".join(groups)}</g><rect width="0" height="0"><animate id="cycle" attributeName="x" from="0" to="0" dur="{elapsed:.6f}s" begin="0s;cycle.end"/></rect><text x="88" y="172" text-anchor="middle" font-family="monospace" font-size="6" fill="#FFD84D">ACENO / PREPARAR / CORRER</text></svg>')
    print(json.dumps({'frames':len(refs),'contact_sheet':str(OUT/'contact_sheet.png'),'animations':metadata['animations']}))

if __name__=='__main__':main()
