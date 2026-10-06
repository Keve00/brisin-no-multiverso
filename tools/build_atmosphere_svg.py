#!/usr/bin/env python3
"""Increase approved far-background mist without touching foreground colors."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
STRENGTH=1.45
SKY_OPACITY=0.18
BASE_SKY=0.025
base=(ROOT/'tools/reference_art/atmosphere_base.svg').read_text()
svg=re.sub(r'fill-opacity="([0-9.]+)"',lambda m:f'fill-opacity="{SKY_OPACITY+max(0,float(m[1])-BASE_SKY)*STRENGTH:.4f}"',base)
# Keep every opacity/vertical band unchanged; only match the approved warm palette.
svg=svg.replace('#95b4d6','#d6a58e').replace('horizonte azulado','horizonte acobreado')
(ROOT/'godot/assets/background_svg/atmosphere.svg').write_text(svg)
print('Atmosphere: sky18%, horizon55%, lower sea34%; foreground unchanged')
