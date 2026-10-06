#!/usr/bin/env python3
"""Package a branch-isolated runnable web candidate, without editor/QA assets."""
from pathlib import Path
import zipfile
from bootstrap_web_runtime import restore_runtime
ROOT=Path(__file__).resolve().parents[1]
TARGET=ROOT/'entregas/Brisin_Mobile_Candidata.zip'
README='''# Brisin — candidata mobile web

Versão de avaliação da branch feat/mobile-adaptation. Não substitui a publicação
atual. Android/iPhone físicos, desempenho e revisão visual final ainda pendentes.

Extraia o ZIP, abra o terminal nesta pasta e rode:

    python -m http.server 8000 --directory web

Abra http://localhost:8000 no computador. Para conferir em celular, use o IP do
computador na mesma rede (ex.: http://192.168.1.10:8000). Não abra index.html por
file://. Use paisagem; o jogo não depende de tela cheia.

Toque: direcional, pulo, dash, chip e pulso/conectar. Arraste entre botões.
Pulo completo por toque é o padrão. CONTROLES no menu abre preferências de salto,
repetição de chips, tamanho/posição, layout espelhado e qualidade leve.
Teclado: A/D ou setas, Espaço, Shift, E, F; gamepad conserva A/X/B/Y.

Interrupções exigem CONTINUAR. A escolha FAZER/PULAR TUTORIAL continua antes da
primeira aventura e as pausas de tutorial só ocorrem na primeira sessão optada.
Saves são vinculados à origem: localhost e IP do computador têm saves distintos.

O relatório incluído separa testes automáticos de validação em aparelhos reais.
'''
def main():
 restore_runtime()
 TARGET.parent.mkdir(exist_ok=True)
 temporary=TARGET.with_suffix('.zip.tmp')
 with zipfile.ZipFile(temporary,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as out:
  out.writestr('LEIA-ME.md',README)
  for file in sorted((ROOT/'dist').iterdir()):
   if file.is_file() and file.suffix not in ['.zip','.tmp']:
    out.write(file,'web/'+file.name)
  for name in ['PLANO_MOBILE.md','VALIDACAO_MOBILE.md','mobile_test_results.json']:
   out.write(ROOT/'docs'/name,'docs/'+name)
 with zipfile.ZipFile(temporary) as out:
  assert out.testzip() is None
  for name in ['web/index.html','web/mobile-shell.js','web/index.pck','web/index.js']:
   assert name in out.namelist(),name
 temporary.replace(TARGET)
 print(f'Candidata íntegra: {TARGET.stat().st_size} bytes')
if __name__=='__main__':main()
