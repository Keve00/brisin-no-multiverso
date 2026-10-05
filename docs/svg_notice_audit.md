# Auditoria de arte e primeira leitura

## Farol e portal

`scenery_svg.gd` carrega `assets/world_01/interactive/*.svg`. Bases, lâmpadas, feixe, moldura e núcleo contêm paths vetoriais reais, sem imagem PNG embutida. Os PNGs antigos de world_01 não são carregados pelas cenas/scripts atuais. Offline mantém feixe apagado e interior do portal parado; Online ativa feixes, núcleo, túnel, pistas e partículas, mantendo moldura e pivôs fixos. Não foi necessário gerar uma nova imagem conceitual nesta rodada.

## Menu

O ornamento amarelo do anexo era `ui/wind.svg`, instanciado por build_title. Ele e o pequeno packet foram removidos. As cinco gemas usam tamanhos base1,05/1,65/1,25/1,85/1,40, órbita186×174 e pulsação uniforme. A órbita original sobrepunha gemas maiores ao rosto; o teste contínuo identificou e preveniu a sobreposição. Prévia renderizada em docs/menu_qa.

## Avisos

Primeiro checkpoint, primeiro início de conexão e primeira costa Online pausam até confirmação. Chime original de0,64s, pico−6,38dBFS, respeita SFX. A confirmação é gravada no save; novas aventuras limpam o registro. Repetições permanecem transitórias. Dicas comuns não pausam.

Testes: important_notices, menu_animation, ui_integration, context_hints, scenery_svg e integration. Testes headless verificam estado, origem SVG, freeze e playback ativo; não constituem audição em navegador.

A travessia revelou erro nativo ao retomar durante callback físico/deferred. A confirmação agora solicita retomada, concluída no `_process` do HUD; a nova execução passou sem erros nativos. Relato upstream correspondente: https://github.com/godotengine/godot/issues/122378 . A primeira leitura antes do primeiro tick também revelou animação default inexistente: o avatar agora inicializa walk e valida a animação ao trocar SpriteFrames.
