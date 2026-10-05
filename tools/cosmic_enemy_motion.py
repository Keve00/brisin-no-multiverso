"""Continuous pixel deformation: shared joints, fixed canvas and ground pivot."""
import math
import numpy as np
from PIL import Image, ImageDraw

def smooth(v):
    v=np.clip(v,0,1)
    return v*v*(3-2*v)

def blink(base,name,eyes):
    im=base.copy();d=ImageDraw.Draw(im)
    if name=='etzinho':
        # Individually authored eyelids follow the approved angled alien eyes.
        skin=base.getpixel((62,46))
        d.polygon([(53,48),(73,55),(72,69),(55,61)],fill=skin)
        d.line([(55,56),(70,62)],fill='#251033',width=2)
        d.polygon([(79,54),(89,49),(89,66),(78,69)],fill=skin)
        d.line([(79,63),(88,58)],fill='#251033',width=2)
        return im
    # Authored face landmarks avoid selecting similarly colored body pixels.
    for cx,cy in eyes:
        skin=base.getpixel((cx,cy-6))
        d.rectangle((cx-3,cy-3,cx+3,cy+3),fill=skin)
        d.line((cx-3,cy,cx+3,cy),fill='#24122f',width=2)
    return im

def pose(base,name,state,i,count,eyes=()):
    """Inverse-map one continuous surface; never cut limbs at a shared row."""
    source=blink(base,name,eyes) if state=='idle' and i==6 else base
    a=np.array(source);y,x=np.indices(a.shape[:2],dtype=float)
    top=base.getbbox()[1];height=112-top
    phase=2*math.pi*i/count
    sx=x.copy();sy=y.copy()
    upper=smooth((112-y)/height)
    if state=='idle':
        breathe=math.sin(phase)*.025
        sx=64+(x-64)/(1+breathe)
        sy=112+(y-112)/(1+breathe)
        sx-=math.sin(phase)*upper*1.5
    elif state=='patrol':
        stride=math.sin(phase)
        # The alien has articulated long legs; robot feet use a shorter rig.
        hip=88 if name=='etzinho' else 100
        leg=smooth((y-hip)/(112-hip))
        side=np.tanh((x-64)/7)
        sx-=side*stride*leg*(6 if name=='etzinho' else 4)
        sy+=np.maximum(0,side*stride)*leg*(4 if name=='etzinho' else 3)
        sy+=abs(math.sin(phase))*upper*2
        sx-=math.sin(phase)*upper*2.5
        # Antennae/appendages sway continuously from their attachment.
        sx-=math.sin(phase+math.pi/3)*smooth((top+height*.3-y)/(height*.3))*2
    elif state=='alert':
        lean=[0,-2,-4,-3,-1,0][i]
        sx-=lean*upper
        stretch=[1,1.02,1.06,1.05,1.02,1][i]
        sy=112+(y-112)/stretch
    elif state=='hit':
        angle=math.radians([0,-9,5,-3,1,0][i])
        dx=x-64;dy=y-112
        sx=64+dx*math.cos(angle)-dy*math.sin(angle)
        sy=112+dx*math.sin(angle)+dy*math.cos(angle)
    elif state=='defeated':
        factor=[1,.94,.86,.78,.70,.62,.54,.46,.38,.30,.22,.14][i]
        sx=64+(x-64)/factor;sy=112+(y-112)/factor
    ix=np.rint(sx).astype(int);iy=np.rint(sy).astype(int)
    inside=(ix>=0)&(ix<128)&(iy>=0)&(iy<128)
    out=np.zeros_like(a);out[inside]=a[iy[inside],ix[inside]]
    im=Image.fromarray(out)
    if state in ['alert','hit'] and i in [1,2,3]:
        d=ImageDraw.Draw(im)
        for px,py in [(25,65),(103,57)]:
            d.line((px-3,py,px+3,py),fill='#ffd84d',width=2)
            d.line((px,py-3,px,py+3),fill='#fff3cd',width=2)
    if state=='defeated' and i>=3:
        scattered=Image.new('RGBA',(128,128));progress=(i-3)/8
        for py in range(0,128,4):
            for px in range(0,128,4):
                if (px*17+py*11)%31<progress*31:continue
                tile=im.crop((px,py,px+4,py+4))
                nx=round(px+(px-64)*progress*.65)
                ny=round(py-20*progress)
                if 0<=nx<=124 and 0<=ny<=124:scattered.alpha_composite(tile,(nx,ny))
        im=scattered
    return im
