#!/usr/bin/env python3
"""Render real Godot scenes using an isolated software-rendered X display."""
from pathlib import Path
import os,subprocess,socket,time,argparse
ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--scene',default='menu_web_capture');args=parser.parse_args()
env=os.environ.copy();env['LD_LIBRARY_PATH']='/tmp/brisin-xvfb/usr/lib/x86_64-linux-gnu';env['DISPLAY']='127.0.0.1:98';env['XDG_DATA_HOME']='/tmp/brisin-cosmic-capture-data'
with open('/tmp/brisin-cosmic-xvfb.log','w') as f:
 x=subprocess.Popen(['/tmp/brisin-xvfb/usr/bin/Xvfb',':98','-screen','0','1152x648x24','-ac','-listen','tcp','-nolisten','unix'],env=env,stdout=f,stderr=f)
 try:
  for i in range(30):
   try:s=socket.create_connection(('127.0.0.1',6098),.1);s.close();break
   except OSError:time.sleep(.1)
  r=subprocess.run([os.environ.get('GODOT_BIN','godot'),'--display-driver','x11','--audio-driver','Dummy','--path',str(ROOT/'godot'),'--rendering-method','gl_compatibility','res://tests/'+args.scene+'.tscn','--','--test'],env=env,capture_output=True,text=True,timeout=90)
  (ROOT/'godot/docs/cosmic_qa'/('render_'+args.scene+'.log')).write_text(r.stdout+r.stderr)
  print(r.returncode);print((r.stdout+r.stderr)[-1800:]);raise SystemExit(r.returncode)
 finally:x.terminate();x.wait()
