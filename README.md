# Brisin no Multiverso

Jogo de plataforma 2D em pixel art feito em **Godot 4.5.1**. Brisin viaja por
mundos paralelos para restabelecer suas conexões. Esta versão contém o
**Vertical Slice 0.1 do Mundo 1 — Costa dos Ventos Conectados**, com uma fase
jogável de 15.235 pixels e transformação de Offline para Online.

**[Jogar no navegador](https://brisinho-costa-web.armandocorreiadeoliv.chatgpt.site)**

## O que está implementado

- Movimento, pulo variável, coyote time e jump buffer.
- Dash aéreo, correntes de vento, rail de sinal e plataformas móveis.
- Checkpoint, respawn e progresso salvo localmente.
- Doze Ruídozinhos distribuídos em plataformas, com patrulha, atordoamento,
  reação e derrota.
- Pulso de sinal e lançamento de chips SIM brancos.
- Gemas laranja pulsantes, plataformas desmoronáveis e áreas Online.
- Nó de conexão, transformação do cenário e portal com entrada animada antes
  da conclusão.
- Menu com Brisin animado, cinco gemas flutuantes e música chiptune original;
  HUD, dicas contextuais e opção de reduzir flashes.
- Arte SVG animada pelo Godot: cenário em camadas, plantas, vento, mar,
  plataformas, efeitos de combate e interações.

A Costa é a fase integrada. Mundos 2 e 3 ainda são expansões futuras; variações
presentes no catálogo de assets não são necessariamente usadas no percurso.

## Requisitos

| Uso | Requisitos |
| --- | --- |
| Abrir e jogar no editor | Godot **4.5.1 Standard**, sem necessidade de .NET |
| Rodar a versão web já exportada | Navegador com WebAssembly/WebGL 2 e servidor HTTP local |
| Exportar o jogo | Godot 4.5.1 e templates de exportação da mesma versão |
| Regenerar assets | Python 3.10+, Pillow, NumPy e Inkscape no PATH |
| Verificar/reempacotar o carregador web | Node.js 20+ e Python 3.10+ |

Os assets prontos estão incluídos. Python e Inkscape são necessários apenas
para regenerar arte; não são necessários para jogar no editor.
Para regenerar a música original, instale também FFmpeg e execute
`python tools/generate_menu_theme.py`.

## Instalação e execução no Godot

1. Clone o repositório:

   ```bash
   git clone https://github.com/Keve00/brisin-no-multiverso.git
   cd brisin-no-multiverso
   ```

2. Instale o [Godot 4.5.1](https://godotengine.org/download/archive/4.5.1-stable/).
3. No gerenciador de projetos, clique em **Importar** e selecione
   `godot/project.godot`.
4. Aguarde a importação de texturas/fontes e pressione **F6** para executar a
   cena aberta, ou **F5** para iniciar o projeto completo.

Pela linha de comando, usando `godot` como o executável instalado:

```bash
godot --editor --path godot
godot --path godot
```

Se o executável tiver outro nome ou não estiver no PATH, substitua `godot` pelo
caminho dele. No Windows, o editor também abre `project.godot` por duplo clique.

A branch `main` contém a versão web normal com o menu aprovado. A branch
`feat/mobile-adaptation` contém a adaptação mobile com controles por toque e
HUD legível. O ZIP v17 na raiz é uma entrega antiga; abra o projeto atual em
`godot/project.godot`.

## Controles

| Ação | Teclado | Controle |
| --- | --- | --- |
| Mover | A/D ou setas | Direcional/analógico |
| Pular | Espaço | A |
| Dash | Shift | X |
| Pulso de sinal | E | B |
| Lançar chip | F | Y |
| Pausar | Esc | Start |

Soltar o botão de pulo cedo reduz a altura. O dash pode ser usado uma vez no ar,
com recarga ao aterrissar. O pulso atordoa inimigos e reconecta o Nó; chips,
dash e stomp podem derrotar Ruídozinhos. As dicas aparecem abaixo do HUD quando
uma mecânica está relevante.

## Jogar a exportação web localmente

O GitHub contém o projeto editável e o carregador; os binários gerados
`index.pck`, as três partes WASM e o ZIP de entrega são reconstruídos fora do
repositório portátil. Para jogar localmente no navegador, instale Godot 4.5.1,
Python e Node.js e execute primeiro:

```bash
python tools/export_web.py --godot godot
```

Na primeira execução, o helper baixa cerca de 38 MB do runtime compatível da
versão publicada e verifica seu SHA256; depois exporta o código e assets locais
para `dist/index.pck`. A importação e o jogo no editor funcionam com os assets
incluídos, sem baixar esse runtime. Sirva a raiz do projeto por HTTP; abrir
`index.html` diretamente como `file://` não carrega WebAssembly de forma confiável.

```bash
python -m http.server 8000
```

Abra **http://localhost:8000/dist/**. No Windows, `py -m http.server 8000` pode
ser usado no lugar de `python`.

## Exportação

No editor, instale os templates em **Editor → Gerenciar templates de
exportação**. Depois use **Projeto → Exportar** e o preset **Web** ou **Windows**.
Escolha uma pasta de saída fora de `godot/`.

Para atualizar o pacote web deste repositório preservando seu carregador:

```bash
python tools/export_web.py --godot godot
```

O helper usa caminhos absolutos, recupera o runtime quando necessário, importa os recursos, exporta o PCK, atualiza
o carregador e gera o ZIP do projeto editável. No Windows, passe o caminho
do executável Godot em `--godot` e use `py` se necessário.

O carregador web usa o runtime Godot 4.5.1 sem threads e recompõe o WASM original
a partir de partes. **Exportar um PCK não atualiza o runtime**: se mudar a versão
do Godot ou as opções de exportação, exporte o runtime completo e revise também
o carregador, as partes WASM e seus hashes. A verificação atual compara o
runtime original, compila o WASM e confere tamanho do PCK/limites dos arquivos.
O download depende da versão publicada permanecer disponível. Se usar outro
espelho, `python tools/bootstrap_web_runtime.py --runtime-url URL` aceita apenas
os mesmos bytes verificados pelo manifesto. Alternativamente, exporte um pacote
Web completo no Godot para uma pasta separada e sirva essa exportação padrão.

## Estrutura do projeto

```text
godot/
  project.godot           Configuração principal
  scenes/                Mundo, jogador e cenas auxiliares
  scripts/               Movimento, combate, cenário, interface e sistemas
  assets/                SVGs, sprite sheets, fontes e manifests
  data/                  Fase e parâmetros de movimento
  tests/                 Cenas de regressão automatizadas
  docs/                  GDD e auditorias por sistema
tools/                   Geradores de SVG e ferramentas de empacotamento
docs/                    Prévias vetoriais e keyframes fora do export
qa/                      Pranchas para revisão visual
dist/                    Carregador e arquivos web; binários gerados pelo helper
AGENTS.md                Regras de arte, física, interface e integração
```

## Testes

As cenas de teste rodam no Godot sem janela. `-- --test` evita usar progresso
salvo e pular etapas por causa do menu inicial.

```bash
godot --headless --fixed-fps 60 --path godot res://tests/integration.tscn -- --test
godot --headless --fixed-fps 60 --path godot res://tests/combat_svg.tscn -- --test
godot --headless --fixed-fps 60 --path godot res://tests/context_hints.tscn -- --test
godot --headless --fixed-fps 60 --path godot res://tests/portal_transition.tscn -- --test
```

Ao testar menus/progresso, use um diretório de dados isolado ou preserve o save
existente. Testes de lógica não substituem a revisão visual do jogo no navegador.
As auditorias em `godot/docs/` identificam as evidências e limitações de cada
revisão.

## Regenerar SVGs

```bash
python -m pip install -r tools/requirements.txt
python tools/build_brisin_menu_svg.py
python tools/build_chip_gesture.py
python tools/build_checkpoint_wave.py
python tools/build_atmosphere_svg.py
python tools/build_gameplay_sea_svg.py
python tools/build_far_sea_ripples.py
python tools/build_portal_assets.py
```

Instale também o Inkscape e disponibilize seu executável no PATH para os
renderizadores. Geradores de outras famílias podem exigir a prancha de origem;
consulte a docstring e os documentos em `godot/docs/` antes de executá-los.

Os SVGs são importados como texturas com filtro nearest-neighbor. Os movimentos
são controlados pelo Godot, sem depender de animação SMIL dentro dos arquivos.
Arte rígida conserva escala uniforme e pivôs; comprimento de plataforma/água
é obtido por módulos, não por alongamento.

## Documentação

- [GDD do Mundo 1](godot/docs/GDD_mundo_1.md)
- [Regras de desenvolvimento](AGENTS.md)
- [Integração de assets](godot/docs/asset_integration.md)
- [Combate e chips](godot/docs/combat_svg.md)
- [Gesto de lançamento](godot/docs/chip_gesture.md)
- [Cenário e atmosfera](godot/docs/background_svg.md)
- [Mar em SVG](godot/docs/sea_svg.md)
- [Auditoria da transição do portal](godot/docs/portal_transition_audit.md)
- [Créditos/licenças do runtime Godot](godot/docs/GODOT_COPYRIGHT.txt)

Este repositório reúne o código, os assets e a documentação para continuar
o desenvolvimento do jogo.

## Sincronização de 05/10/2026

Código e assets correspondem à versão publicada e verificada. Metadados de hospedagem, caches e binários gerados PCK/WASM/ZIP ficam fora deste repositório portátil. `tools/export_web.py` recupera o runtime por SHA256 e reconstrói o build.
