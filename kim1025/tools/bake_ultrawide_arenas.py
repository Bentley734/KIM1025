"""Bake 32:9 scenery with multiscale edge blending and protected original mounds.
Deterministic compositing was explicitly approved by the user on 2026-10-09.
"""
from pathlib import Path
import json,re,hashlib
import numpy as np
from PIL import Image,ImageFilter,ImageDraw,ImageOps
import argparse
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--canonical',type=Path,required=True,help='Directory containing the 72 canonical PNGs')
parser.add_argument('--scenery',type=Path,required=True,help='Directory containing 36 refined location PNGs')
parser.add_argument('--root',type=Path,default=Path(__file__).resolve().parent.parent)
args=parser.parse_args()
ROOT=args.root
CACHE=args.canonical
ART=args.scenery
OUT=ROOT/'assets/battle/backgrounds/aspect/ultrawide'
W,H,OX,OY=4096,1152,1568,256
def pyramid(image,levels=4):
 out=[image]
 for _ in range(levels-1):
  p=out[-1];out.append(p.filter(ImageFilter.GaussianBlur(2)).resize((p.width//2,p.height//2),Image.Resampling.BILINEAR))
 return out
def up(array,size):
 return np.stack([np.asarray(Image.fromarray(array[:,:,i]).resize(size,Image.Resampling.BILINEAR)) for i in range(array.shape[2])],axis=2)
def blend(source,backdrop,mask):
 a=pyramid(source);b=pyramid(backdrop);m=pyramid(mask)
 result=None
 for i in range(len(a)-1,-1,-1):
  aa=np.asarray(a[i],dtype=np.float32);bb=np.asarray(b[i],dtype=np.float32)
  alpha=np.asarray(m[i],dtype=np.float32)[:,:,None]/255
  if result is None:result=aa*alpha+bb*(1-alpha)
  else:
   al=aa-up(np.asarray(a[i+1],dtype=np.float32),a[i].size)
   bl=bb-up(np.asarray(b[i+1],dtype=np.float32),b[i].size)
   result=up(result,a[i].size)+al*alpha+bl*(1-alpha)
 return Image.fromarray(np.clip(np.rint(result),0,255).astype(np.uint8))
def bake(src):
 name=re.sub(r'_(day|night|sunrise|sunset)$','',src.stem)
 art=Image.open(ART/(name+'.png')).convert('RGB')
 bg=ImageOps.fit(art,(W,H),Image.Resampling.LANCZOS,centering=(.5,1))
 original=Image.open(src).convert('RGB').resize((960,475),Image.Resampling.LANCZOS)
 # Match low-frequency color along each source row, including its exact time
 # variant. Smooth the gain so matching does not produce horizontal bands.
 s=np.asarray(original,dtype=np.float32);b=np.asarray(bg,dtype=np.float32)
 target=np.concatenate((s[:,:60],s[:,-60:]),axis=1).mean(axis=1)
 refs=json.loads((ROOT/'data/ultrawide_art_prompts.json').read_text())
 reference_file=refs['locations'][name]
 baseline=np.asarray(Image.open(CACHE/(reference_file+'.png')).convert('RGB').resize((960,475),Image.Resampling.LANCZOS),dtype=np.float32)
 reference=np.concatenate((baseline[:,:60],baseline[:,-60:]),axis=1).mean(axis=1)
 gain=np.clip((target+20)/(reference+20),.15,2.5)
 gain=np.pad(gain,((OY,H-OY-475),(0,0)),mode='edge')
 gain=np.stack([np.convolve(np.pad(gain[:,i],(48,48),mode='edge'),np.ones(97)/97,mode='valid') for i in range(3)],axis=1)[:,None,:]
 bg=Image.fromarray(np.clip(np.rint(b*gain),0,255).astype(np.uint8))
 profiles={n:[(int(x1),int(y1)),(int(x2),int(y2))] for n,x1,y1,x2,y2 in re.findall(r'([a-z0-9_]+)=\{player=\{(\d+),(\d+)\},enemy=\{(\d+),(\d+)\}\}',(ROOT/'data/hd_battle_backgrounds.lua').read_text())}
 # Blend only the original mound-bearing floor; architectural scenery is the
 # repaired continuous panorama, so there is no rectangular original layer.
 bounds=json.loads((ROOT/'data/ultrawide_mound_masks.json').read_text())[name]
 protection=Image.new('L',original.size);d=ImageDraw.Draw(protection)
 for cx,cy,rx,ry in bounds:
  cx/=2;cy/=2;rx/=2;ry/=2
  d.ellipse((cx-rx-3,cy-ry-2,cx+rx+3,cy+ry+2),fill=255)
 protection=protection.filter(ImageFilter.GaussianBlur(3))
 d=ImageDraw.Draw(protection)
 for cx,cy,rx,ry in bounds:
  cx/=2;cy/=2;rx/=2;ry/=2
  d.ellipse((cx-rx,cy-ry,cx+rx,cy+ry),fill=255)
 for x,y in (profiles[name] if bounds else []):
  x/=2;y/=2
  d.rectangle((x-42,y-18,x+42,y+18),fill=255)
 for box in json.loads((ROOT/'data/ultrawide_mound_occluders.json').read_text()).get(name,[]):
  d.rectangle(tuple(v/2 for v in box),fill=0)
 foreground=bg.copy();foreground.paste(original,(OX,OY),protection)
 mask=Image.new('L',(W,H));mask.paste(protection,(OX,OY))
 result=blend(foreground,bg,mask)
 result.paste(original,(OX,OY),protection)
 dest=OUT/(src.stem+'.jpg');dest.parent.mkdir(parents=True,exist_ok=True)
 result.save(dest,quality=97,subsampling=0,optimize=True)
 return {'file':src.stem,'path':dest.relative_to(ROOT).as_posix(),'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'scenery_sha256':hashlib.sha256((ART/(name+'.png')).read_bytes()).hexdigest(),'bytes':dest.stat().st_size}
def main():
 records=[]
 for src in sorted(CACHE.glob('*.png')):
  records.append(bake(src));print(src.stem,flush=True)
 assert len(records)==72
 (ROOT/'data/ultrawide_background_sources.json').write_text(json.dumps(records,indent=2)+'\n')
 print('BAKED',len(records),sum(r['bytes'] for r in records),flush=True)
if __name__=='__main__':main()


