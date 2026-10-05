#!/usr/bin/env python3
"""Run isolated desktop/mobile regression scenes and reject native ERROR logs."""
import argparse, concurrent.futures, json, os, re, subprocess, tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
DESKTOP=['integration','coast_extension','enemy_placement','checkpoint_totems','menu_animation','portal_transition','tutorial_choice','important_notices','context_hints','combat_svg','ui_integration']
MOBILE=[]
def main():
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--godot',default='godot')
 args=parser.parse_args()
 version=subprocess.check_output([args.godot,'--version'],text=True).strip()
 if not version.startswith('4.5.1.'): parser.error('Use the matching Godot4.5.1 engine.')
 with tempfile.TemporaryDirectory(prefix='brisin-regressions-') as temporary:
  def run(item):
   name,mobile=item;key=('mobile_' if mobile else 'desktop_')+name
   env=os.environ.copy();env['XDG_DATA_HOME']=str(Path(temporary)/key)
   cmd=[args.godot,'--headless','--fixed-fps','60','--path',str(ROOT/'godot'),'res://tests/'+name+'.tscn','--','--test']
   if mobile:cmd.append('--mobile')
   result=subprocess.run(cmd,env=env,capture_output=True,text=True,timeout=120)
   log=result.stdout+result.stderr
   errors=[line for line in log.splitlines() if 'ERROR:' in line or 'FAIL:' in line or 'SCRIPT ERROR' in line]
   totals=re.findall(r'(\d+)\s+(?:passed|checks|checked)',log)
   passed=int(totals[-1]) if totals else sum(line.startswith('PASS:') for line in log.splitlines())
   record={'scene':name,'profile':'mobile' if mobile else 'desktop','passed_checks':passed,'exit_code':result.returncode,'errors':errors,'ok':result.returncode==0 and not errors}
   print(key+': '+str(passed)+' checks / '+('OK' if record['ok'] else 'FAIL'),flush=True)
   if not record['ok']:print(log,flush=True)
   return record
  with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
   records=list(pool.map(run,[(n,False) for n in DESKTOP]+[(n,True) for n in MOBILE]))
 report={'engine':version,'mode':'headless physics/logic; not physical-device performance or visual approval','tests':records,'passed_checks':sum(r['passed_checks'] for r in records),'ok':all(r['ok'] for r in records)}
 target=ROOT/'docs/menu_web_test_results.json';target.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
 print('RESULT:',report['passed_checks'],'checks;',len(records),'scenes;',report['ok'])
 raise SystemExit(0 if report['ok'] else 1)
if __name__=='__main__':main()
