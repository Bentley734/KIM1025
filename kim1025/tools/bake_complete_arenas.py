"""Bake complete aspect arenas. Original source geometry is never moved.

The user approved deterministic compositing on 2026-10-09. This uses the
scene-specific generated scenery and the exact canonical HD sources.
"""
from pathlib import Path
import json, re, hashlib, argparse
from PIL import Image, ImageChops, ImageDraw

BASE = Path(__file__).resolve().parent.parent
ROOT = BASE / 'KIM1025Release'
CACHE = Path('C:/Users/LSDMTHC/AppData/Roaming/pokemon-love2d/mod_cache/kim1025/kim_assets/files/assets/battle/backgrounds/hd')
OUT = ROOT / 'assets/battle/backgrounds/aspect'
ART = BASE / '.work/kim-1630-art'
GROUND = {
 'portrait':dict(field=.28,forest=.47,road=.51,safari=.43,sea=.48,bridge=.49,cave=.49,gym=.49,league=.52,lab=.49,mansion=.42,tower=.52,powerplant=.51,ship=.53,hideout=.47),
 'widescreen':dict(field=.45,forest=.53,road=.65,safari=.53,sea=.60,bridge=.60,cave=.55,gym=.54,league=.55,lab=.60,mansion=.50,tower=.62,powerplant=.57,ship=.56,hideout=.54),
}
SPECS = {'portrait':(3840,6826,960,2000),'widescreen':(3840,2160,960,512)}
MASK = {}
def profile(file):
 for prefix, result in [('power_plant_exterior','field'),('mt_moon','cave'),('silph_co','lab'),('viridian_forest','forest'),('grass_','field'),('road_','road'),('cave_','cave'),('sea_','sea'),('cerulean_bridge','bridge'),('gym_','gym'),('league_','league'),('oak_lab','lab'),('pokemon_mansion','mansion'),('pokemon_tower','tower'),('power_plant','powerplant'),('ss_anne','ship'),('rocket_hideout','hideout'),('safari','safari')]:
  if file.startswith(prefix): return result
 return 'field'
def surround(file, aspect, size, ground_y):
 p=profile(file)
 name=re.sub(r'_(day|night|sunrise|sunset)$','',file)
 art=Image.open(ART/(name+'.png')).convert('RGB')
 tint=next((t for period,t in [('night',(.52,.62,.86)),('sunrise',(1,.83,.72)),('sunset',(1,.70,.58))] if file.endswith('_'+period)),(1,1,1))
 art=Image.merge('RGB',tuple(c.point(lambda v,m=m:round(v*m)) for c,m in zip(art.split(),tint)))
 if aspect=='widescreen':
  # Recompose the surrounding ceiling/sky and floor for the wide canvas;
  # the canonical arena remains embedded independently at its exact scale.
  return art.resize(size,Image.Resampling.LANCZOS)
 iw,ih=art.size;w,h=size;ground=ih*.38
 s=max(w/iw,h/ih,ground_y/ground,(h-ground_y)/(ih-ground))
 scaled=art.resize((round(iw*s),round(ih*s)),Image.Resampling.LANCZOS)
 x=round((w-scaled.width)/2);y=round(ground_y-ground*s)
 # Safety: rounding must never leave a one-pixel edge exposed.
 x=min(0,max(w-scaled.width,x));y=min(0,max(h-scaled.height,y))
 return scaled.crop((-x,-y,w-x,h-y))
def bake(file, aspect, source):
 global MASK
 w,h,ox,oy=SPECS[aspect]
 image=surround(file,aspect,(w,h),oy+380)
 # Feather only the outer source edges. Both original platform anchor regions
 # are fully opaque and retain their original coordinates, dimensions and art.
 if aspect not in MASK:
  MASK[aspect]=Image.new('L',(1920,950),255);pix=MASK[aspect].load()
  for y in range(950):
   # Replace old ceiling/horizon scenery, retaining the canonical floor and
   # both mound regions. The earliest mound starts below this transition.
   top=(y-300)/100 if aspect=='portrait' else y/90
   fy=max(0,min(1,top,(949-y)/90));fy=fy*fy*(3-2*fy)
   for x in range(1920):
    fx=max(0,min(1,x/90,(1919-x)/90));fx=fx*fx*(3-2*fx)
    pix[x,y]=round(255*min(fx,fy))
 image.paste(source,(ox,oy),MASK[aspect])
 dest=OUT/aspect/(file+'.jpg');dest.parent.mkdir(parents=True,exist_ok=True)
 # 1920-wide output keeps mobile texture dimensions below 4096. The runtime
 # uses explicit sourceScale metadata, so this does not move either mound.
 image=image.resize((w//2,h//2),Image.Resampling.LANCZOS)
 image.save(dest,quality=97,subsampling=0,optimize=True)
 return dest
def main():
 records=[]
 for src in sorted(CACHE.glob('*.png')):
  original=Image.open(src).convert('RGB');assert original.size==(1920,950),src
  for aspect in SPECS:
   dest=bake(src.stem,aspect,original)
   records.append(dict(file=src.stem,aspect=aspect,source_sha256=hashlib.sha256(src.read_bytes()).hexdigest(),path=dest.relative_to(ROOT).as_posix(),bytes=dest.stat().st_size))
  print(src.stem,flush=True)
 assert len(records)==144
 (ROOT/'data/aspect_background_sources.json').write_text(json.dumps(records,indent=2)+'\n')
 print('BAKED',len(records),'images',sum(r['bytes'] for r in records),flush=True)
if __name__=='__main__':
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--canonical-dir',type=Path,default=CACHE)
 parser.add_argument('--art-dir',type=Path,default=ART)
 parser.add_argument('--mod-root',type=Path,default=ROOT)
 args=parser.parse_args();CACHE=args.canonical_dir;ART=args.art_dir;ROOT=args.mod_root;OUT=ROOT/'assets/battle/backgrounds/aspect'
 main()
