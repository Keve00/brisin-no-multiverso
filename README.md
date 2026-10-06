# Brisin — Conexão de Outro Mundo

Jogo de plataforma 2D em pixel art feito em **Godot 4.5.1**. Brisin explora um planeta alienígena para restabelecer sua rede de comunicação. Esta branch contém o
**Vertical Slice 0.1 — Conexão de Outro Mundo**, com uma fase
jogável de 15.235 pixels e transformação de Offline para Online.

**[Jogar no navegador](https://brisinho-costa-web.armandocorreiadeoliv.chatgpt.site)**

## O que está implementado

- Movimento, pulo variável, coyote time e jump buffer.
- Dash aéreo, correntes de vento, rail de sinal e plataformas móveis.
- Checkpoint, respawn e progresso salvo localmente.
- Nove variações coloridas de Ruídozinho distribuídas em plataformas, com patrulha, atordoamento,
  reação e derrota.
- Pulso de sinal e lançamento de chips SIM brancos.
- Gemas laranja pulsantes, plataformas desmoronáveis e áreas Online.
- Nó de conexão, transformação do cenário e portal com entrada animada antes
  da conclusão.
- Menu com Brisin animado, cinco gemas flutuantes e música chiptune original;
  HUD, dicas contextuais e opção de reduzir flashes.
- Arte SVG animada pelo Godot: cenário em camadas, plantas, vento, mar,
  plataformas, efeitos de combate e interações.

O planeta alienígena é a fase integrada. Mundos 2 e 3 ainda são expansões futuras; variações
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

Este repositório é privado. O clone HTTPS exige autenticação de uma conta com
acesso; para um serviço de deploy, cadastre a chave pública em **Settings →
Deploy keys**, mantenha a privada no serviço e use
`git@github.com:Keve00/brisin-no-multiverso.git`. Somente leitura basta para
clonar e atualizar o deploy. Chaves privadas nunca fazem parte do projeto.

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
com recarga ao aterrissar. O pulso neutraliza tiros do Etzinho, atordoa inimigos e reconecta o Nó; chips,
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

## Tema extraterrestre — 05/10/2026

Branch `feat/planeta-extraterrestre`. Título aprovado: **Conexão de Outro Mundo**, sem a frase de rodapé. O menu mantém o aceno e a preparação para correr; cenário, nove famílias de plataformas, vegetação, checkpoint, farol, turbina, Nó, rail e portal usam a arte extraterrestre.

Cristal, Esporo, Magnético, Escavador, Plasma, Satélite, Corrompido, Sentinela e Orbital têm cinco estados animados e preservam o combate atual. As variações são visuais, sem novos poderes. O percurso continua com 15.235 pixels; movimento, chips, pulso, checkpoint e entrada de portal de 1,8 s foram preservados.

A fonte dos conceitos fica em `tools/reference_art/cosmic/`. Execute `python tools/build_cosmic_assets.py` para regenerar a arte. O processo produz SVGs com paths reais, canvases/pivôs documentados e SpriteFrames; não utiliza bitmaps embutidos ou SMIL. Consulte `godot/docs/cosmic_integration.md`. O ZIP editável inclui os conceitos novos, projeto, scripts e documentação; omite referências costeiras antigas e PNGs de fundo que não são mais usados.

## Ataque do Etzinho — 06/10/2026

Etzinho detecta Brisin a até 360 pixels quando há visão livre, para e sinaliza a mira por 0,65 s. Sua pequena arma dispara energia em direção fixa a 270 px/s, com pausa de 1,6 s entre ataques. Paredes bloqueiam visão e disparos. O pulso (E/B na web, botão PULSO no mobile) destrói projéteis ao cruzar seu anel e interrompe a mira quando alcança o inimigo. Tiros duram no máximo 480 pixels; respawn e entrada no portal limpam o combate.

Testado em ambas as versões: ataque/defesa (16), combate SVG (36), animações (583), apoio dos inimigos (1811) e transição do portal (23). Mobile: controles por toque (120), informações em quatro tamanhos (90), percurso completo com defesa por toque (26). A arma e os avisos foram conferidos em capturas do renderizador Godot.

## Paleta quente de todos os assets

Plataformas, personagens, objetos e efeitos usam amostras da seleção de contraste aprovada. `python tools/build_warm_assets.py` transfere cores preservando geometria e transparência. Corrida, caminhada e salto também usam 64 SVGs nativos; os atlas originais ficam como fonte. O export aplica a paleta automaticamente, junto da auditoria de bordas das luzes. Consulte `godot/docs/warm_assets.md`.
