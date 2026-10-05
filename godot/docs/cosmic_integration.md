# Conexão de Outro Mundo — integração

Título aprovado: **Brisin — Conexão de Outro Mundo**. Menu sem a frase de rodapé. Arte dos conceitos aprovados em 05/10/2026.

## Catálogo e uso

483 SVGs novos/regenerados, com paths reais e sem bitmaps embutidos. Canvases, pivôs e origem estão em `cosmic_assets_manifest.json`.

| Família | Integração |
| --- | --- |
| Fundo | Panorama alienígena vetorial, parallax, névoa restrita ao fundo e iluminação de relays |
| Plataformas | Nove famílias; bases modulares, decoração separada, variação espelhada documentada |
| Decoração | Árvores alienígenas maiores que Brisin, cogumelos, arbustos, minerais, ruínas, luminárias e boias |
| Objetos | Turbina, farol/antena, checkpoint com bandeira, Nó, portal e rail com estados Offline/Online |
| Inimigos | Cristal, Esporo, Magnético, Escavador, Plasma, Satélite, Corrompido, Sentinela e Orbital; todos aparecem no percurso |
| Menu | Logo orbital vetorial, título nativo, botões reais, Brisin acenando/preparando corrida e cinco gemas |
| Efeitos | Gemas redesenhadas; chips, pulso, dash, vento, coleta e água mantêm os sistemas SVG existentes |

## Animação e gameplay

Cada inimigo possui idle 8 frames/8fps, patrol 8/12fps, alert 6/10fps, hit 6/12fps e defeated 12/12fps. Canvas128×128, pivô64,112, escala uniforme1; colisão do corpo52×56 preservada. As nove variações são cosméticas nesta entrega.

A bandeira possui oito frames em cada estado, com mastro/base fixos. Rotor, núcleos e interior do portal têm camadas próprias. A entrada do portal mantém1,8s e conclusão única após a animação. Física, posições, controles e IDs foram preservados. O arquivo de progresso do planeta é separado do antigo save costeiro.

## Reprodução

`python tools/build_cosmic_assets.py` regenera arte e SpriteFrames das referências em `tools/reference_art/cosmic/`.
`python tools/export_web.py --godot CAMINHO_GODOT_4_5_1` importa, exporta, atualiza o carregador, verifica áudio e empacota o projeto.

## Verificação

Relatório: `docs/cosmic_test_results.json`. Validação de geometria vetorial, estados, nove variantes efetivamente carregadas, cobertura da câmera, pivôs e ausência do rodapé:1139 verificações. Regressões de percurso por inputs, patrulhas/apoio, checkpoints/respawn/save, chip/pulso, portal e cancelamento, menu/tutorial e UI passaram.

Inspeção visual em renders reais do Godot/OpenGL: menu, início, vento, Nó Offline/Online e portal. Foram corrigidos recortes, pixels de fundo nas pranchas, escala/encaixe de objetos, acesso do planeta no menu e repetição de efeitos de vento. Renders de QA ficam fora do pacote/export.

Não houve medição de FPS em aparelho físico nem escuta do áudio nesta rodada. O mix e guard de áudio web seguem os verificadores existentes.
