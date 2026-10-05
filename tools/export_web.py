#!/usr/bin/env python3
"""Export the editable Godot project into the existing compatible web runtime."""
from pathlib import Path
import argparse,subprocess,sys
from bootstrap_web_runtime import restore_runtime
ROOT=Path(__file__).resolve().parents[1]
def main():
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--godot',default='godot',help='Godot4.5.1 executable name or path')
 args=parser.parse_args()
 version=subprocess.check_output([args.godot,'--version'],text=True).strip()
 if not version.startswith('4.5.1.'):
  parser.error('The included web runtime requires Godot4.5.1. Export a complete matching runtime before using another version.')
 restore_runtime()
 commands=[[args.godot,'--headless','--path',str(ROOT/'godot'),'--editor','--import'],
 [args.godot,'--headless','--path',str(ROOT/'godot'),'--export-pack','Web',str(ROOT/'dist/index.pck')],
 ['node','tools/update_web_pack_size.cjs'],
 ['node','tools/fix_web_audio_pause.cjs'],['node','tools/verify_web_audio.cjs'],
 ['node','verify-loader.cjs'],
 [sys.executable,'tools/package_svg_delivery.py']]
 for command in commands:subprocess.run(command,cwd=ROOT,check=True)
 print('Web export and editable archive ready in dist/')
if __name__=='__main__':main()
