"""Check source walking-surface coverage, including both modular endcaps."""
from pathlib import Path
import re,xml.etree.ElementTree as ET
root=Path(__file__).resolve().parents[1]
checks=0
for family in ('coastal','sand','wind_island','cracked','thin','raft','signal','wood_bridge'):
 for variant in range(2):
  path=root/f'godot/assets/world_01/platforms/{family}_{variant}_ground.svg'
  tree=ET.parse(path).getroot();width=int(tree.attrib['width']);surface=set()
  for node in tree.iter():
   for x,y,span in re.findall(r'M(\d+) (\d+)h(\d+)v1h-\d+z',node.attrib.get('d','')):
    if int(y)<8:surface.update(range(int(x),int(x)+int(span)))
  assert surface and 0 in surface and width-1 in surface,(path,'empty contact endcap')
  gaps=[x for x in range(width) if x not in surface]
  assert not gaps,(path,'holes in walking surface',gaps)
  checks+=1
print(f'PLATFORM_LAYERS: {checks} surfaces cover both endcaps and the entire walking span')
