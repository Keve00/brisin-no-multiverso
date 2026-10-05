"""Brisin: editable SVG layers and an original 5x7 bitmap UI font."""
from pathlib import Path
from PIL import Image
import unicodedata
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'godot/assets/ui'
OUT.mkdir(parents=True, exist_ok=True)
GLYPHS = {
'A':'01110/10001/10001/11111/10001/10001/10001',
'B':'11110/10001/10001/11110/10001/10001/11110',
'C':'01111/10000/10000/10000/10000/10000/01111',
'D':'11110/10001/10001/10001/10001/10001/11110',
'E':'11111/10000/10000/11110/10000/10000/11111',
'F':'11111/10000/10000/11110/10000/10000/10000',
'G':'01111/10000/10000/10111/10001/10001/01111',
'H':'10001/10001/10001/11111/10001/10001/10001',
'I':'11111/00100/00100/00100/00100/00100/11111',
'J':'00111/00010/00010/00010/10010/10010/01100',
'K':'10001/10010/10100/11000/10100/10010/10001',
'L':'10000/10000/10000/10000/10000/10000/11111',
'M':'10001/11011/10101/10101/10001/10001/10001',
'N':'10001/11001/11001/10101/10011/10011/10001',
'O':'01110/10001/10001/10001/10001/10001/01110',
'P':'11110/10001/10001/11110/10000/10000/10000',
'Q':'01110/10001/10001/10001/10101/10010/01101',
'R':'11110/10001/10001/11110/10100/10010/10001',
'S':'01111/10000/10000/01110/00001/00001/11110',
'T':'11111/00100/00100/00100/00100/00100/00100',
'U':'10001/10001/10001/10001/10001/10001/01110',
'V':'10001/10001/10001/10001/10001/01010/00100',
'W':'10001/10001/10001/10101/10101/11011/10001',
'X':'10001/10001/01010/00100/01010/10001/10001',
'Y':'10001/10001/01010/00100/00100/00100/00100',
'Z':'11111/00001/00010/00100/01000/10000/11111',
'0':'01110/10001/10011/10101/11001/10001/01110',
'1':'00100/01100/00100/00100/00100/00100/01110',
'2':'01110/10001/00001/00010/00100/01000/11111',
'3':'11110/00001/00001/01110/00001/00001/11110',
'4':'00010/00110/01010/10010/11111/00010/00010',
'5':'11111/10000/10000/11110/00001/00001/11110',
'6':'01110/10000/10000/11110/10001/10001/01110',
'7':'11111/00001/00010/00100/01000/01000/01000',
'8':'01110/10001/10001/01110/10001/10001/01110',
'9':'01110/10001/10001/01111/00001/00001/01110',
' ':'00000/00000/00000/00000/00000/00000/00000',
'.':'00000/00000/00000/00000/00000/00110/00110',
',':'00000/00000/00000/00000/00110/00100/01000',
':':'00000/00110/00110/00000/00110/00110/00000',
';':'00000/00110/00110/00000/00110/00100/01000',
'!':'00100/00100/00100/00100/00100/00000/00100',
'?':'01110/10001/00001/00010/00100/00000/00100',
'-':'00000/00000/00000/11111/00000/00000/00000',
'/':'00001/00001/00010/00100/01000/10000/10000',
'[':'01110/01000/01000/01000/01000/01000/01110',
']':'01110/00010/00010/00010/00010/00010/01110',
'(':'00010/00100/01000/01000/01000/00100/00010',
')':'01000/00100/00010/00010/00010/00100/01000',
'+':'00000/00100/00100/11111/00100/00100/00000',
'%':'11001/11010/00100/01000/10110/00110/00000',
'•':'00000/00000/00100/01110/00100/00000/00000',
'…':'00000/00000/00000/00000/00000/00000/10101',
'—':'00000/00000/00000/11111/00000/00000/00000',
'|':'00100/00100/00100/00100/00100/00100/00100',
'◇':'00100/01010/10001/10001/01010/00100/00000',
'→':'00000/00100/00010/11111/00010/00100/00000',
'←':'00000/00100/01000/11111/01000/00100/00000',
}

def cells(char):
    decomposed = unicodedata.normalize('NFD', char.upper())
    base = decomposed[0]
    rows = GLYPHS.get(base, GLYPHS['?']).split('/')
    points = [(x,y+3) for y,row in enumerate(rows) for x,v in enumerate(row) if v=='1']
    if '\u0301' in decomposed: points += [(2,1),(3,0)]
    if '\u0300' in decomposed: points += [(1,0),(2,1)]
    if '\u0302' in decomposed: points += [(1,1),(2,0),(3,1)]
    if '\u0303' in decomposed: points += [(0,1),(1,0),(2,1),(3,1),(4,0)]
    if '\u0308' in decomposed: points += [(1,1),(3,1)]
    if '\u0327' in decomposed: points += [(2,10),(1,11)]
    return points

chars = list(dict.fromkeys(''.join(GLYPHS) + 'abcdefghijklmnopqrstuvwxyzÁÀÂÃÄÉÊÍÓÔÕÖÚÜÇáàâãäéêíóôõöúüç'))
atlas = Image.new('RGBA', (128, ((len(chars)+15)//16)*12))
lines = ['info face="Brisin Pixel" size=12 bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=0,0',f'common lineHeight=12 base=10 scaleW=128 scaleH={atlas.height} pages=1 packed=0','page id=0 file="brisin_pixel.png"',f'chars count={len(chars)}']
for n,ch in enumerate(chars):
    x,y=(n%16)*8,(n//16)*12
    for px,py in cells(ch): atlas.putpixel((x+px,y+py),(255,255,255,255))
    lines.append(f'char id={ord(ch)} x={x} y={y} width=5 height=12 xoffset=0 yoffset=0 xadvance=6 page=0 chnl=15')
atlas.save(OUT/'brisin_pixel.png')
(OUT/'brisin_pixel.fnt').write_text('\n'.join(lines)+'\n')

# Same pixel geometry for the web loader: no external font dependency.
fb = FontBuilder(768, isTTF=True)
names = ['.notdef'] + [f'uni{ord(ch):04X}' for ch in chars]
fb.setupGlyphOrder(names)
fb.setupCharacterMap({ord(ch): names[n+1] for n,ch in enumerate(chars)})
glyphs = {}
for name,ch in [('.notdef','?')] + list(zip(names[1:], chars)):
    pen = TTGlyphPen(None)
    for x,y in cells(ch):
        x0,y0=x*64,(9-y)*64
        pen.moveTo((x0,y0)); pen.lineTo((x0,y0+64))
        pen.lineTo((x0+64,y0+64)); pen.lineTo((x0+64,y0)); pen.closePath()
    glyphs[name] = pen.glyph()
fb.setupGlyf(glyphs)
fb.setupHorizontalMetrics({name:(384,0) for name in names})
fb.setupHorizontalHeader(ascent=640, descent=-128)
fb.setupNameTable({'familyName':'Brisin Pixel','styleName':'Regular','uniqueFontIdentifier':'BrisinPixel-v1','fullName':'Brisin Pixel','psName':'BrisinPixel'})
fb.setupOS2(sTypoAscender=640,sTypoDescender=-128,usWinAscent=640,usWinDescent=128)
fb.setupPost()
fb.save(OUT/'brisin_pixel.ttf')

def rect(x,y,w,h,color): return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{color}"/>'
def svg(name,w,h,body):
    (OUT/f'{name}.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}" shape-rendering="crispEdges">{body}</svg>')
def frame(w,h,border='#FFB000',fill='#241508'):
    return (f'<path fill="#100A04" d="M8 4H{w-8}V8H{w-4}V{h-4}H8Z"/>'
       +f'<path fill="{border}" d="M8 0H{w-12}V4H{w-8}V8H{w-4}V{h-12}H{w-8}V{h-8}H8V{h-12}H4V8H8Z"/>'
       +f'<path fill="{fill}" d="M12 4H{w-16}V8H{w-12}V12H{w-8}V{h-16}H{w-12}V{h-12}H12V{h-16}H8V12H12Z"/>')
for name,w,h in [('menu_panel',560,520),('objective_frame',360,72),('counter_frame',160,54),('toast_frame',520,84),('hint_frame',288,48)]: svg(name,w,h,frame(w,h))
svg('button',360,60,frame(360,60))
svg('button_focus',360,60,frame(360,60,'#FFD84D','#B84800')+rect(16,8,324,4,'#FF7A00'))
svg('button_pressed',360,60,frame(360,60,'#FFF3CD','#7A3000'))
svg('focus_arrow',16,16,'<path fill="#FFD84D" d="M4 0H8V4H12V6H16V10H12V12H8V16H4Z"/>')
icons = {
'signal':rect(0,16,4,8,'#FFB000')+rect(8,8,4,16,'#FFD84D')+rect(16,0,4,24,'#FFF3CD'),
'flag':rect(4,0,4,24,'#FFD84D')+rect(8,4,16,8,'#FFB000')+rect(8,12,12,4,'#FF7A00')+rect(0,20,16,4,'#FFF3CD'),
'bolt':'<path fill="#FFD84D" d="M12 0H24L16 8H24L8 24H4L8 12H0Z"/>',
'diamond':'<path fill="#FFD84D" d="M8 0H16V4H20V8H24V16H20V20H16V24H8V20H4V16H0V8H4V4H8Z"/>'+rect(8,4,8,4,'#FFF3CD'),
'pause':rect(4,0,6,24,'#FFB000')+rect(16,0,6,24,'#FFB000'),
'packet':rect(4,4,8,8,'#FFD84D')+rect(0,8,4,4,'#FF7A00')+rect(12,4,4,4,'#FFF3CD'),
}
for name,body in icons.items(): svg(name,16 if name=='packet' else 24,16 if name=='packet' else 24,body)
# Canonical logo approved by the user; never regenerate it from bitmap font glyphs.
(OUT/'logo.svg').write_bytes((ROOT/'tools/reference_art/brisin-logo.svg').read_bytes())
wind=''
for x,y,w,h in [(4,72,80,8),(76,64,64,8),(132,56,64,8),(188,48,56,8),(236,40,48,8),(276,24,8,24),(252,16,32,8),(244,24,8,16),(252,40,16,8),(0,92,108,4),(108,84,92,4),(200,76,80,4)]: wind+=rect(x,y,w,h,'#FFD84D')
svg('wind',288,104,wind)
ledge='<path fill="#FFB000" d="M0 16H16V8H80V0H192V8H304V16H368V24H384V56H0Z"/><path fill="#D95B16" d="M8 48H376V80H360V112H320V144H96V128H48V104H16Z"/><path fill="#8E3416" d="M40 72H112V80H80V112H40ZM208 56H232V144H208ZM312 80H352V112H312Z"/>'
for x,y,w in [(16,24,56),(96,16,80),(232,24,64),(296,32,72)]: ledge+=rect(x,y,w,8,'#FFD84D')
svg('title_ledge',384,144,ledge)
wave=''.join(rect(x,16+(i%3)*8,32 if i%2 else 56,4,'#FFD84D') for i,x in enumerate(range(0,480,64)))
svg('wave',512,48,wave)
portal=''
for x,y,w,h,c in [(8,0,48,4,'#FFB000'),(4,4,4,56,'#FFB000'),(56,4,4,56,'#FFB000'),(8,60,48,4,'#FFB000'),(12,12,40,40,'#7A3000'),(20,16,28,4,'#FFD84D'),(44,20,4,24,'#FFD84D'),(20,40,24,4,'#FFD84D'),(16,20,4,24,'#FFD84D'),(20,20,16,4,'#FFD84D'),(32,24,4,12,'#FFD84D'),(24,32,8,4,'#FFF3CD')]: portal+=rect(x,y,w,h,c)
svg('portal',64,64,portal)
svg('portal_frame',64,64,rect(8,0,48,4,'#FFB000')+rect(4,4,4,56,'#FFB000')+rect(56,4,4,56,'#FFB000')+rect(8,60,48,4,'#FFB000')+rect(12,12,40,40,'#7A3000'))
svg('portal_core',64,64,rect(20,16,28,4,'#FFD84D')+rect(44,20,4,24,'#FFD84D')+rect(20,40,24,4,'#FFD84D')+rect(16,20,4,24,'#FFD84D')+rect(20,20,16,4,'#FFD84D')+rect(32,24,4,12,'#FFD84D')+rect(24,32,8,4,'#FFF3CD'))
print(f'Created {len(list(OUT.glob("*.svg")))} SVG layers and the bitmap font.')
