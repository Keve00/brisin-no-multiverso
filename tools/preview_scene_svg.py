from pathlib import Path
import re,sys
ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'godot/assets/world_01/svg'
OUT=Path(sys.argv[1])
OUT.mkdir(exist_ok=True,parents=True)
def body(name):
    s=(SRC/(name+'.svg')).read_text()
    s=re.sub(r'<title>.*?</title>','',s)
    return s[s.index('>')+1:s.rindex('</svg>')]
def anim(cx,cy,seconds,animate):
    return f'<animateTransform attributeName="transform" type="rotate" from="0 {cx} {cy}" to="360 {cx} {cy}" dur="{seconds}s" repeatCount="indefinite"/>' if animate else ''
def object_svg(kind,online,animate=False):
    if kind=='turbine':
        suffix='on' if online else 'off'
        shapes=f'<g transform="translate(32 4)">{body("turbine_base_"+suffix)}</g><g transform="translate(0 -22)"><g>{body("turbine_rotor_"+suffix)}{anim(64,64,4,animate)}</g></g>'
        box='0 0 128 150'
    elif kind=='lighthouse':
        shapes=f'<g transform="translate(60 24)" opacity="{1 if online else .35}">{body("lighthouse_base")}</g>'
        if online:
            for side in [-1,1]:
                shapes+=f'<g transform="translate(101 47)"><g><g transform="scale({side*.45} .45) translate(0 -24)">{body("lighthouse_beam")}</g>'
                if animate:shapes+='<animateTransform attributeName="transform" type="rotate" values="-8;8;-8" dur="7s" repeatCount="indefinite"/>'
                shapes+='</g></g>'
        box='0 0 192 150'
    elif kind=='node':
        shapes=f'<g transform="translate(26 36)">{body("node_base")}</g><g transform="translate(14 14) scale(1.5)" opacity=".4"><g>{body("node_halo")}{anim(24,24,8,animate)}</g></g><g transform="translate(26 26) scale(1.5)">{body("node_core" if online else "node_core_off")}</g>'
        box='0 0 100 100'
    elif kind=='portal':
        shapes=f'<g transform="translate(0 8)" opacity="{1 if online else .4}">{body("portal_frame")}</g><g transform="translate(49 51)"><g opacity="{1 if online else .15}"><g transform="translate(-32 -32)">{body("portal_core")}</g>{anim(0,0,7,animate)}</g></g>'
        box='0 0 100 100'
    else:
        shapes='<path stroke="#3adade" stroke-width="2" d="M8 65L152 35"/>'
        for i in range(5):
            x=8+144*(i/5);y=65-30*(i/5)
            shapes+=f'<g opacity="{.9 if online else .4}" transform="translate({x} {y})"><g transform="translate(-8 -4) rotate(-11.8 8 4)">{body("rail_packet")}</g>'
            if animate:shapes+=f'<animateTransform attributeName="transform" type="translate" values="8 65;152 35" dur="3s" begin="{-i*.6}s" repeatCount="indefinite"/>'
            shapes+='</g>'
        box='0 0 160 100'
    return f'<svg viewBox="{box}" width="220" height="260" preserveAspectRatio="xMidYMid meet">{shapes}</svg>'
names=[('turbine','Turbina'),('lighthouse','Farol'),('rail','Rail'),('node','Nó'),('portal','Portal')]
def sheet(animated=False):
    rows=[True] if animated else [False,True]
    h=340 if animated else 680
    parts=[f'<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="{h}" viewBox="0 0 1200 {h}" shape-rendering="crispEdges"><rect width="1200" height="{h}" fill="#14283c"/>']
    for row,online in enumerate(rows):
        y=row*340
        parts.append(f'<text x="16" y="{y+24}" font-family="sans-serif" font-size="18" fill="#dcffff">{"Online — prévia animada" if animated else ("Online" if online else "Offline")}</text>')
        for i,(key,label) in enumerate(names):
            parts.append(f'<g transform="translate({i*240+10} {y+40})">{object_svg(key,online,animated)}<text x="110" y="286" text-anchor="middle" font-family="sans-serif" font-size="16" fill="#dcffff">{label}</text></g>')
    return ''.join(parts)+'</svg>'
(OUT/'comparacao.svg').write_text(sheet())
(OUT/'previa_animada.svg').write_text(sheet(True))
print(OUT)
