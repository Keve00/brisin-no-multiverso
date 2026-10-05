# Brisinho — Costa dos Ventos Conectados

Vertical Slice 0.1 em **Godot 4.5.1**, GDScript e renderer Compatibility.
Especificação principal: `docs/GDD_mundo_1.md`.

## Abrir o projeto

1. Extraia o ZIP do projeto.
2. No Godot 4.5.1, escolha **Importar** e selecione `project.godot`.
3. Aguarde a importação dos assets e pressione **F6** para rodar a cena aberta ou **F5** para rodar o projeto.
4. No menu, escolha **Começar aventura**. Dentro do jogo, F6 alterna arte/blockout.

O projeto é independente: os PNGs tratados e o áudio já estão incluídos. Não precisa instalar Python para jogar no Godot ou no executável Windows.

## Controles

| Ação | Teclado | Gamepad |
|---|---|---|
| Mover | A/D, Setas | Analógico esquerdo, D-pad |
| Pular, sair do rail | Espaço | A / Cross |
| Dash | Shift | X / Square |
| Pulso / ativar Nó | E | B / Circle |
| Pausa / opções | Esc | Start |

Segurar pulo aumenta a altura. O dash recarrega no chão; permite um uso por salto. O vento eleva Brisinho e o rail inicia ao tocar o cabo. Ruídozinho é derrotado por stomp ou dash; o pulso o interrompe por dois segundos. Cair ou receber dano retorna ao último checkpoint, sem penalidade de vidas.

## Percurso

Spawn → fragmentos → saltos → vento vertical → Ruídozinho → Ponto Brisa → rail → salto com dash → Nó → reconexão → ponte → portal.

O Nó muda o estado de OFFLINE para CONNECTING e ONLINE, acende o farol/turbina, adiciona uma camada sonora e torna sólida a ponte antes do portal. A transformação tem efeito sobre a rota. O portal exige ONLINE e apresenta a conclusão do slice; os Mundos 2 e 3 ainda não têm fases.

## Teste e debug

```bash
godot --headless --path . --fixed-fps 60 res://tests/integration.tscn -- --test --blockout
godot --headless --path . --fixed-fps 60 res://tests/integration.tscn -- --test
```

Use o caminho do seu executável Godot no lugar de `godot`, se necessário.

| Tecla dentro do jogo | Função |
|---|---|
| F1 | Colisões |
| F2 | Velocidade |
| F3 | Estado e FPS |
| F4 | Respawn no checkpoint |
| F5 | Limpar progresso e reiniciar |
| F6 | Alternar blockout / arte |
| F7 | Invencibilidade contra inimigo |

Argumentos: `--fresh` ignora o save ao iniciar; `--blockout` começa sem arte; `--test` ignora o save e o menu para testes.

Save: `user://brisinho_v01.json`, incluindo checkpoint, fragmentos salvos, conexão, conclusão e opções. **Nova aventura** limpa o progresso. Na Web, a persistência depende das permissões de armazenamento do navegador.

## Assets e placeholders

Foram analisados os 7 PNGs e 3 vídeos anexados. Os assets fornecidos não foram redesenhados. As pranchas foram recortadas, os fundos quadriculados embutidos foram removidos por máscara e a maior silhueta foi preservada. O cenário é decorativo, com repetição espelhada; colisões são construídas pelo level design e têm borda de contato legível.

Vídeos: extração a 12 FPS, seleção de trecho de 2 segundos, chroma key, exclusão de componentes destacados, remoção de duplicatas próximas, normalização de altura para 100 px, célula 144×128 e pivot (72,120). Spritesheets, bounding boxes e escalas estão em `assets/player/animations.json`. Contato visual em `docs/animation_contact.png`.

Run usa o vídeo Run; Idle usa um frame do Walk; subida/queda usam poses extraídas de Jump. Dash/rail reutilizam Run com trail e tint; Land usa a pose com compressão discreta. Não há takes dedicados de Idle, Dash, Hit ou Celebrate. A normalização reduz jitter de escala/pivot, mas não corrige mudanças de desenho presentes nos vídeos gerados.

**Placeholders porque os assets não foram anexados:** Ruídozinho, Ponto Brisa, Nó, fragmentos, VFX e áudio. O chão usa as ilhas fornecidas; a borda de colisão é funcional, já que não foi entregue um tileset. Áudio é síntese simples de feedback e duas camadas de ambiente; não é trilha final.

## Arquitetura e expansão

- `scripts/player/player.gd`: controlador CharacterBody2D e estados; `PlayerTuning` expõe a física.
- `data/player_tuning.tres`: parâmetros de movimento, coyote, buffer, dash e rail.
- `scripts/world/world.gd`: montagem da fase a partir do JSON; `level_path` é exportado.
- `data/world_01.json`: superfícies, props interativos, rail, vento, posições e tutoriais.
- `scripts/world/platform.gd`: superfícies fixas, ponte e plataforma móvel AnimatableBody2D.
- `scripts/interactables/marker.gd`: fragmento, checkpoint, Nó e portal com sinais.
- `scripts/enemies/noisezinho.gd`: patrulha delimitada pela plataforma, stomp, dash e interrupção.
- `scripts/systems`: estado/save, áudio e HUD/menu/opções.
- `scenes/player`: cena reutilizável; `scenes/world_01`: entrada do slice.

Para os Mundos 2 e 3, adicione novos dados de fase e cenas com outro `level_path`, reutilizando controlador e interativos. Para saves entre vários mundos, estenda WorldState com checkpoints e conexão indexados por ID de mundo antes de ligar portais reais de troca de cena.

Layers em `project.godot`: Player=1, World=2, OneWayPlatform=3, Enemy=4, Hazard=5, Interactable=7, Collectible=8, Trigger=9, Rail=10. O Player colide com World e OneWayPlatform; inimigo/interações usam testes de proximidade controlados em physics ticks. As ações estão no Input Map do projeto e podem ser alteradas no editor.

## Validação e limites

25 verificações passaram no blockout e com arte, incluindo percurso completo por ações de input sem teleporte, salto variável, coyote, buffer, dash aéreo, vento, rail e saídas, checkpoint/respawn, stomp, dash contra inimigo, pulso, coleta, ponte offline, Nó e portal. Relatórios em `docs/test_results_blockout.json` e `docs/test_results_art.json`.

Inspeção visual por execução real do Godot com OpenGL em renderização por software, capturando spawn, vento e final offline/online. Uma advertência de V-Sync do driver virtual é esperada nesse ambiente. Os testes headless finais não registraram erros nem warnings. O áudio teve suas camadas e arquivos integrados, mas não foi avaliado por audição humana.

O build Web e o Windows foram exportados com templates oficiais 4.5.1. O pacote de recursos Web foi também iniciado no runtime Godot para detectar assets ausentes. O executável Windows não foi executado neste ambiente Linux e o runtime WebAssembly não foi testado em navegador. Um controle físico e a meta de 60 FPS em hardware do usuário ainda exigem playtest.

A duração de 3–6 minutos do GDD permanece uma meta de playtest. O trecho é compacto e pode ser percorrido rapidamente por quem conhece a rota; não foram adicionadas esperas artificiais. Esta entrega é o vertical slice, não o Mundo 1 completo: boss, cinco setores, três inimigos e três memórias pertencem ao escopo posterior.

## Reproduzir extração

`tools/prepare_assets.py` precisa de Python com Pillow, numpy, scipy e ffmpeg. Coloque os arquivos originais anexados em uma pasta `upload` ao lado da pasta do projeto e execute o script. Os originais permanecem intactos. A execução normal do projeto usa somente os assets já preparados.
