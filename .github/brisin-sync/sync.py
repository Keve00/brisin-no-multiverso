"""One-time synchronization of the already reviewed, published Brisin sources."""
import hashlib,json,os,pathlib,re,subprocess,tempfile,urllib.request,zipfile,sys
HERE=pathlib.Path(__file__).resolve().parent
ARCHIVE=json.loads((HERE/'archive.json').read_text())
MOBILE=json.loads((HERE/'mobile.json').read_text())
TARGETS=[('web','feat/planeta-extraterrestre','5a931fc3740866d5d4984c3b94f12bd7fd819ce3'),('mobile','feat/planeta-extraterrestre-mobile','ab59f552d5f9ca823916bc9d553a3d5a8e02bf02')]
def run(*args,cwd=None):return subprocess.check_output(args,cwd=cwd,text=True).strip()
def sha(data):return hashlib.sha256(data).hexdigest()
def extract(archive,dest):
 with zipfile.ZipFile(archive) as z:
  assert z.testzip() is None
  for name in z.namelist():
   if not name.startswith('Brisin/') or name.endswith('/'):continue
   rel=pathlib.PurePosixPath(name[7:])
   assert rel.parts and '..' not in rel.parts and not rel.is_absolute()
   assert rel.parts[0] not in {'.git','.github','.openai','.sites-runtime'}
   if str(rel)=='.gitignore':continue
   target=dest/str(rel);target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(z.read(name))
def apply_mobile(dest):
 for rel,text in MOBILE['updates'].items():
  target=dest/rel;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(text)
 for rel in MOBILE['delete']:(dest/rel).unlink(missing_ok=True)
 for rel,colors in MOBILE['rgb'].items():
  p=dest/rel;p.write_text(re.sub(r'#[0-9a-fA-F]{6}',lambda m:colors.get(m[0],m[0]),p.read_text()))
 p=dest/'godot/assets/warm_palette_manifest.json'; current=json.loads(p.read_text())['files'];current.update(MOBILE['ledger']['updates'])
 records={key:current[key] for key in MOBILE['ledger']['keys']}
 p.write_text(json.dumps({**MOBILE['ledger']['meta'],'files':records},ensure_ascii=False,separators=(',',':'))+'\n')
 for rel,digest in MOBILE['expected'].items():assert sha((dest/rel).read_bytes())==digest,rel

def main():
 dry='--check' in sys.argv
 temp=pathlib.Path(tempfile.mkdtemp(prefix='brisin-published-'))
 archive=pathlib.Path(sys.argv[sys.argv.index('--archive')+1]) if '--archive' in sys.argv else temp/'published.zip'
 if not archive.exists():
  request=urllib.request.Request(ARCHIVE['url'],headers={'User-Agent':'Mozilla/5.0'})
  with urllib.request.urlopen(request,timeout=180) as response,archive.open('wb') as out:
   while block:=response.read(1048576):out.write(block)
 assert sha(archive.read_bytes())==ARCHIVE['sha256'],'Published archive checksum mismatch'
 commits=[]
 if not dry:
  run('git','fetch','origin',*[branch for _,branch,_ in TARGETS])
  for _,branch,expected in TARGETS:assert run('git','rev-parse','origin/'+branch)==expected,'Branch changed: '+branch
 for version,branch,expected in TARGETS:
  dest=temp/version
  if dry:dest.mkdir()
  else:run('git','worktree','add','--detach',str(dest),expected)
  extract(archive,dest)
  if version=='mobile':apply_mobile(dest)
  if dry:
   print(version,'published sources and mobile hashes verified');continue
  # Retain the GitHub exclusions and add the current source's new temporary-file rules.
  ignore=dest/'.gitignore';lines=ignore.read_text().splitlines()
  for line in ['.openai/','.sites-runtime/','dist/index.pck','dist/index.wasm.part*','dist/Brisin_SVGs_e_Interacoes.zip','dist/.Brisin_SVGs_e_Interacoes.zip.tmp.*']:
   if line not in lines:lines.append(line)
  ignore.write_text('\n'.join(lines)+'\n')
  run('git','config','user.name','github-actions[bot]',cwd=dest)
  run('git','config','user.email','41898282+github-actions[bot]@users.noreply.github.com',cwd=dest)
  run('git','add','-A',cwd=dest)
  run('git','diff','--cached','--check',cwd=dest)
  run('git','commit','-m','Centraliza HUD e botões; integra paleta quente, contraste e animações ('+version+')',cwd=dest)
  commit=run('git','rev-parse','HEAD',cwd=dest);commits.append((branch,commit));print(version,commit)
 if not dry:
  run('git','push','--atomic','origin',*[commit+':refs/heads/'+branch for branch,commit in commits])
  actual=dict(line.split()[::-1] for line in run('git','ls-remote','origin',*[('refs/heads/'+b) for b,_ in commits]).splitlines())
  for branch,commit in commits:assert actual['refs/heads/'+branch]==commit
  print('Both existing branches updated and verified.')
if __name__=='__main__':main()
