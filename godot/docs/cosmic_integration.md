# Conexão de Outro Mundo — integração

Título aprovado: **Brisin — Conexão de Outro Mundo**. Menu sem a frase de rodapé. Arte dos conceitos aprovados em 05/10/2026.

## Catálogo e uso

523 SVGs novos/regenerados, com paths reais e sem bitmaps embutidos. Canvases, pivôs e origem estão em `cosmic_assets_manifest.json`.

| Família | Integração |
| --- | --- |
| Fundo | Panorama alienígena vetorial, parallax, névoa restrita ao fundo e iluminação de relays |
| Plataformas | Nove famílias; bases modulares, decoração separada, variação espelhada documentada |
| Decoração | Árvores alienígenas maiores que Brisin, cogumelos, arbustos, minerais, ruínas, luminárias e boias |
| Objetos | Turbina, farol/antena, checkpoint com bandeira, Nó, portal e rail com estados Offline/Online |
| Inimigos | Cristal, Esporo, Magnético, Escavador, Plasma, Satélite, Corrompido, Sentinela, Orbital e Etzinho; todos aparecem no percurso |
| Menu | Logo orbital vetorial, título nativo, botões reais, Brisin acenando/preparando corrida e cinco gemas |
| Efeitos | Gemas redesenhadas; chips, pulso, dash, vento, coleta e água mantêm os sistemas SVG existentes |

## Animação e gameplay

Cada inimigo possui idle 8 frames/8fps, patrol 8/12fps, alert 6/10fps, hit 6/12fps e defeated 12/12fps. Canvas128×128, pivô64,112, escala uniforme1; colisão do corpo52×56 preservada. As dez variações são cosméticas nesta entrega.

A bandeira possui oito frames em cada estado, com mastro/base fixos. Rotor, núcleos e interior do portal têm camadas próprias. A entrada do portal mantém1,8s e conclusão única após a animação. Física, posições, controles e IDs foram preservados. O arquivo de progresso do planeta é separado do antigo save costeiro.

## Reprodução

`python tools/build_cosmic_assets.py` regenera arte e SpriteFrames das referências em `tools/reference_art/cosmic/`.
`python tools/export_web.py --godot CAMINHO_GODOT_4_5_1` importa, exporta, atualiza o carregador, verifica áudio e empacota o projeto.

## Verificação

Relatório: `docs/cosmic_test_results.json`. Validação de geometria vetorial, estados, nove variantes efetivamente carregadas, cobertura da câmera, pivôs e ausência do rodapé:1139 verificações. Regressões de percurso por inputs, patrulhas/apoio, checkpoints/respawn/save, chip/pulso, portal e cancelamento, menu/tutorial e UI passaram.

Inspeção visual em renders reais do Godot/OpenGL: menu, início, vento, Nó Offline/Online e portal. Foram corrigidos recortes, pixels de fundo nas pranchas, escala/encaixe de objetos, acesso do planeta no menu e repetição de efeitos de vento. Renders de QA ficam fora do pacote/export.

Não houve medição de FPS em aparelho físico nem escuta do áudio nesta rodada. O mix e guard de áudio web seguem os verificadores existentes.

## Correção do portal e revisão dos inimigos — 05/10/2026

A área do portal agora considera o corpo dentro da abertura visível, inclusive durante um salto; a distância entre os pés e o pivô do chão podia ignorar essa entrada. `portal_entry` reproduzia a falha e agora valida entrada, bloqueio Offline e conclusão persistida. A dica Offline explica a necessidade de ativar o Nó.

Os frames transformam a silhueta completa, evitando cortes de pernas na linha compartilhada entre corpo e pés. A transparência preserva detalhes escuros internos; a paleta é calculada só com pixels do personagem. Etzinho tem referência transparente própria e os mesmos cinco estados do restante do elenco.

Etzinho aparece nas patrulhas x916–1000 (início), x5950–6050 (após o Nó) e x14080–14180 (trecho final), sempre sobre as plataformas já existentes. O quinto campo opcional de cada patrulha fixa sua variante sem depender da ordem do catálogo.

## Animações completas — 05/10/2026

Todos os dez personagens possuem rig contínuo de pixels com respiração/piscada, passos alternados e balanço de corpo/antenas, inclinação de alerta, recuo de dano e contração/desintegração. O mapeamento inverso preserva a superfície e os encaixes dos membros, sem cortes fixos. Etzinho foi ampliado uniformemente de74 para100px de altura (~35%); seu combate usa área60×86 para corresponder à cabeça/corpo. Canvas128×128, pivô64,112 e pés no chão permanecem. Durações e lifecycle não mudaram.

`cosmic_animation` valida poses distintas, ciclos, canvas, dano/atordoamento, retomada, derrota e reset para as dez variantes. Prévia gerada dos SVGs finais: `cosmic_animations.gif`.

## Alinhamento dos Etzinhos

O recorte considera a transparência após a quantização. Os pés das animações idle, patrol e alert ficam no pivô y=112, alinhados à superfície. Verificação: cosmic_animation, 583 checks sem falhas.
