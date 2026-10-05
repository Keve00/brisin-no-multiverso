"""Reproduz recorte/chroma key sem redesenhar os originais. Requer Pillow, numpy, scipy, ffmpeg."""
from pathlib import Path
import subprocess,json
import numpy as np
from PIL import Image,ImageDraw
from scipy import ndimage
ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT.parent/'upload'
OUT=ROOT/'assets'
# Regiões de cada objeto na prancha original (frações).
regions={'farol.png':{'lighthouse_off':(.10,.12,.31,.86),'lighthouse_on':(.65,.12,.87,.86)},'Ilhas flutuantes.png':{'island':(.26,.14,.70,.81),'small_island':(.03,.44,.32,.91)},'Turbina.png':{'turbine_off':(.12,.07,.48,.94),'turbine_on':(.56,.07,.89,.94)},'Jangada plataforma.png':{'raft':(.16,.13,.78,.86)},'Rail de sinal.png':{'rail':(.055,.10,.47,.27)},'portal.png':{'portal':(.17,.04,.85,.93)}}
report={'source_images':{'CENARIO.png':{'size':[2048,1143],'use':'background decorativo com cópia espelhada para repetição'}},'animations':{},'missing':['tileset','Ruídozinho','checkpoint','Nó de Sinal','fragmentos','idle/dash/hit dedicados','áudio original']}
Image.open(SRC/'CENARIO.png').resize((1536,857),Image.Resampling.LANCZOS).save(OUT/'world_01/background.png')
for name,items in regions.items():
 src=Image.open(SRC/name).convert('RGBA');w,h=src.size
 report['source_images'][name]={'size':[w,h],'alpha':'quadriculado embutido; máscara de fundo neutro'}
 for key,r in items.items():
  im=src.crop(tuple(int(v*(w if i%2==0 else h)) for i,v in enumerate(r)));a=np.array(im);rgb=a[:,:,:3].astype(int)
  if name=='Rail de sinal.png': mask=((rgb.max(2)-rgb.min(2))<24)&(rgb.max(2)<85)
  else: mask=((rgb.max(2)-rgb.min(2))<10)&(rgb.max(2)>35)&(rgb.max(2)<170)
  # Só regiões grandes do fundo, não pequenos detalhes neutros do objeto.
  lab,n=ndimage.label(mask);sizes=np.bincount(lab.ravel());remove=mask&(sizes[lab]>75)
  a[:,:,3][remove]=0
  im=Image.fromarray(a);bbox=im.getbbox();im=im.crop(bbox)
  im.thumbnail((650,650),Image.Resampling.NEAREST);im.save(OUT/'world_01'/f'{key}.png')
for p in (OUT/'world_01').glob('*.png'):
 if p.stem=='background': continue
 im=Image.open(p).convert('RGBA');a=np.array(im);rgb=a[:,:,:3].astype(int)
 mask=((rgb.max(2)-rgb.min(2))<20)&(rgb.max(2)>140)&(rgb.max(2)<245)
 lab,n=ndimage.label(mask);sizes=np.bincount(lab.ravel());a[:,:,3][mask&(sizes[lab]>60)]=0
 lab,n=ndimage.label(a[:,:,3]>0);sizes=np.bincount(lab.ravel());sizes[0]=0;a[:,:,3][lab!=sizes.argmax()]=0
 im=Image.fromarray(a).crop(Image.fromarray(a).getbbox());im.save(p)
 if p.stem=='lighthouse_on':
  a=np.array(im);h,w=a.shape[:2];yy,xx=np.mgrid[:h,:w];rgb=a[:,:,:3].astype(int);neutral=(rgb.max(2)-rgb.min(2))<80
  a[:,:,3][neutral&((xx<w*.30)|(xx>w*.82))&(yy<h*.24)]=0;Image.fromarray(a).save(p)
Image.open(OUT/'world_01/background.png').transpose(Image.Transpose.FLIP_LEFT_RIGHT).save(OUT/'world_01/background_mirror.png')
for name,clip in [('run','run-brisinho.mp4'),('walk','walk- brisinho.mp4'),('jump','salto-brisinho.mp4')]:
 tmp=ROOT/'tools'/f'frames_{name}';tmp.mkdir(exist_ok=True)
 subprocess.run(['ffmpeg','-v','error','-i',str(SRC/clip),'-vf','fps=12','-y',str(tmp/'%04d.png')],check=True)
 frames=[];last=None;meta=[]
 # 2 segundos centrais de cada take: animação reduzida, 12 FPS.
 for p in sorted(tmp.glob('*.png'))[12:36]:
  a=np.array(Image.open(p).convert('RGBA'));rgb=a[:,:,:3].astype(float)
  green=(rgb[:,:,1]>rgb[:,:,0]*1.35)&(rgb[:,:,1]>rgb[:,:,2]*1.35)&(rgb[:,:,1]>70)
  a[:,:,3][green]=0
  lab,n=ndimage.label(a[:,:,3]>0);sizes=np.bincount(lab.ravel());sizes[0]=0;mask=lab==sizes.argmax();a[:,:,3][~mask]=0
  # Exclui poeira/objetos destacados; mantém maior silhueta e fixa pivot no pé.
  ys,xs=np.where(mask);box=(int(xs.min()),int(ys.min()),int(xs.max()+1),int(ys.max()+1))
  im=Image.fromarray(a).crop(box);scale=100/im.height;im=im.resize((round(im.width*scale),100),Image.Resampling.NEAREST)
  canvas=Image.new('RGBA',(144,128));canvas.alpha_composite(im,((144-im.width)//2,120-im.height))
  arr=np.array(canvas)
  if last is not None and np.mean(np.abs(arr.astype(float)-last.astype(float)))<.4: continue
  last=arr;frames.append(canvas);meta.append({'source_frame':int(p.stem),'bbox':box,'pivot':[72,120],'scale':round(scale,4)})
 sheet=Image.new('RGBA',(144*len(frames),128))
 for i,im in enumerate(frames):sheet.alpha_composite(im,(144*i,0))
 sheet.save(OUT/'player'/f'{name}.png')
 report['animations'][name]={'fps':12,'frames':len(frames),'cell':[144,128],'pivot':[72,120],'source':clip,'metadata':meta}
 for p in tmp.glob('*.png'):p.unlink()
 tmp.rmdir()
(OUT/'player/animations.json').write_text(json.dumps(report['animations'],indent=2))
(ROOT/'docs/asset_audit.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
# Contato visual dos frames normalizados.
preview=Image.new('RGB',(864,384),'#123043')
for row,name in enumerate(['run','walk','jump']):
 sh=Image.open(OUT/'player'/f'{name}.png')
 for i in range(6):preview.paste(sh.crop((i*144,0,(i+1)*144,128)),(i*144,row*128),sh.crop((i*144,0,(i+1)*144,128)))
preview.save(ROOT/'docs/animation_contact.png')
print('Assets preparados')
