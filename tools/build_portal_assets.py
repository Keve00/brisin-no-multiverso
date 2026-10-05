"""Editable native SVG pixel geometry for the portal depth layers.
All canvases retain their center and rendered size; no bitmap is embedded.
"""
from collections import defaultdict
from math import atan2, cos, hypot, pi, sin
from pathlib import Path
OUT=Path(__file__).resolve().parents[1]/'godot/assets/world_01/portal_transition'
def write(name,n,pixel):
    paths=defaultdict(list)
    for y in range(n):
        x=0
        while x<n:
            color=pixel(x+.5-n/2,y+.5-n/2)
            if not color: x+=1;continue
            start=x;x+=1
            while x<n and pixel(x+.5-n/2,y+.5-n/2)==color: x+=1
            paths[color].append(f'M{start} {y}h{x-start}v1h-{x-start}z')
    text=f'<svg xmlns="http://www.w3.org/2000/svg" width="{n*2}" height="{n*2}" viewBox="0 0 {n} {n}" shape-rendering="crispEdges"><!-- Fixed center {n/2:g},{n/2:g}; 1-unit vector pixel cells, no raster image. -->'
    text+=''.join(f'<path fill="{color}" d="{"".join(rows)}"/>' for color,rows in paths.items())+'</svg>\n'
    (OUT/(name+'.svg')).write_text(text)
def ring(x,y):
    radius=hypot(x,y);angle=atan2(y,x)
    if not 34<=radius<40:return None
    if radius<35 or radius>=39:return '#073C53'
    if radius<36:return '#A6FFF0'
    if .15<angle%pi<.28:return '#FFB936'
    return '#B7FFF0' if angle<-.7 and radius>37 else '#27D8D0' if radius>37 else '#119AAA'
def tunnel(x,y):
    r=hypot(x,y)
    if r>=28:return None
    if 27<=r:return '#0B354D'
    if 23<=r:return '#135F72'
    if 19<=r:return '#0C485F'
    if 15<=r:return '#093449'
    if 10<=r:return '#06273E'
    return '#051A30'
def arcs(x,y):
    r=hypot(x,y);a=atan2(y,x)%(2*pi)
    if not ((27<=r<29 and .15<a%pi<2.4) or (18<=r<19.5 and .75<a%pi<2.85)):return None
    if .15<a%pi<.32:return '#FFB936'
    return '#B7FFF0' if r>28 else '#26DCCF' if r>19 or r>27 else '#138AA0'
def spiral(x,y):
    r=hypot(x,y);a=atan2(y,x)
    if r<3:return '#E0FFF7'
    if r>29:return None
    # Three narrowing, curved lanes; all cells remain on the same pixel grid.
    phase=(a+r*.19)%(2*pi/3)
    if phase>.21:return None
    return '#B7FFF0' if phase<.07 else '#21CFC6' if r<20 else '#138FA1'
write('ring',96,ring)
write('tunnel',64,tunnel)
write('arcs',72,arcs)
write('spiral',72,spiral)
print(OUT)
