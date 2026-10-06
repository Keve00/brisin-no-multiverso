"""Remove dark outer fringes from isolated light layers, keeping interior shade.

Inputs are the exact SVG rasters produced by Godot's audit_light_layers.gd.
Solid frames, character bodies, unlit states and UI frames are never selected.
"""
from pathlib import Path
from collections import defaultdict
import json
import numpy as np
from PIL import Image
from scipy.ndimage import binary_dilation
ROOT=Path(__file__).resolve().parents[1]

def remove_fringe(im):
    a=np.array(im.convert('RGBA'));opaque=a[:,:,3]>0
    dark=(a[:,:,:3].max(2)<100)&(a[:,:,:3].mean(2)<65)&opaque
    erased=np.zeros(opaque.shape,bool)
    while True:
        boundary=binary_dilation(~opaque,border_value=1)&dark&opaque
        if not boundary.any():break
        opaque[boundary]=False;erased|=boundary
    a[erased]=0
    return Image.fromarray(a),int(erased.sum())

def write(path,im):
    a=np.array(im);groups=defaultdict(list)
    for y in range(im.height):
        x=0
        while x<im.width:
            c=tuple(a[y,x]);start=x;x+=1
            while x<im.width and tuple(a[y,x])==c:x+=1
            if c[3]:groups[c].append(f'M{start} {y}h{x-start}v1h-{x-start}z')
    body=''.join(f'<path fill="#{r:02x}{g:02x}{b:02x}"'+(f' opacity="{alpha/255:.6f}"' if alpha<255 else '')+f' d="{"".join(runs)}"/>' for (r,g,b,alpha),runs in groups.items())
    path.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{im.width}" height="{im.height}" viewBox="0 0 {im.width} {im.height}" shape-rendering="crispEdges">{body}</svg>\n')

def main():
    report=[];previews=[]
    for raster in sorted((ROOT/'godot/docs/light_edges/rasters').glob('*.png')):
        rel=raster.name.removesuffix('.png').replace('__','/')
        file=ROOT/'godot'/rel
        if not file.exists():continue
        before=Image.open(raster).convert('RGBA');after,count=remove_fringe(before)
        report.append({'asset':rel,'dark_fringe_pixels_removed':count})
        if count:
            write(file,after);previews.append((before,after,file.name))
    qa=ROOT/'godot/docs/light_edges';qa.mkdir(parents=True,exist_ok=True)
    (qa/'audit.json').write_text(json.dumps(report,indent=2))
    if previews:
        from PIL import ImageDraw
        sheet=Image.new('RGBA',(640,len(previews)*210),'#fff3cd')
        for n,(before,after,name) in enumerate(previews):
            for k,im in enumerate([before,after]):
                used=im.getbbox();im=im.crop(used) if used else im
                scale=min(270/im.width,170/im.height)
                im=im.resize((round(im.width*scale),round(im.height*scale)),Image.Resampling.NEAREST)
                sheet.alpha_composite(im,(k*320+(320-im.width)//2,n*210+25))
            ImageDraw.Draw(sheet).text((10,n*210+5),name+'   ANTES / DEPOIS',fill='#241508')
        sheet.save(qa/'comparacao_fundo_claro.png')
    print('LIGHT_EDGE_AUDIT:',len(report),'layers,',len(previews),'corrected,',sum(x['dark_fringe_pixels_removed'] for x in report),'dark fringe pixels removed')

if __name__=='__main__':main()
