# Menu — gemas flutuantes e remoção da guia amarela

Integrado em `scripts/systems/hud.gd`; previews regeneráveis por
`python tools/preview_menu_gems.py`, em `docs/menu_qa/` na raiz do projeto.

## Alteração

Os traços amarelos vinham do asset de interface `ui/wave.svg`, instanciado abaixo da ilha em (604,578) e movido horizontalmente. Essa instância e sua referência/processamento foram removidas. O mar real do panorama SVG permanece.

Cinco gemas usam os recursos reais `world_01/svg/gem_orange.svg` e `gem_glow.svg`: corpo laranja opaco, facetas douradas, halo discreto. Órbita elíptica centrada em (866,346), raios (176,164), velocidade 0,42 rad/s (~15 s/ciclo). Escala 1,5 uniforme com pulsação de ±5%. A posição é alinhada a pixels inteiros. Gems ficam em z=1 no arco superior, atrás do avatar z=2; arco inferior z=3 passa à frente da ilha. Não há traços/linhas de órbita.

Redução de flashes: velocidade 0,26 rad/s (~24 s/ciclo), pulso ±1,5% e halo constante alpha 0,12; corpo da gema continua alpha 1. O relógio só avança quando a tela inicial está visível e reinicia com sua reconstrução. Preparação/aceno/corrida/botões mantêm o fluxo existente. As gemas são decorativas: nenhuma coleta, colisão ou mudança de progresso.

## Evidência

`tools/preview_menu_gems.py` monta previews com SVGs reais e fonte atlas.
`menu_gems_00.png`, `_01.png`, `_02.png` e a folha de contato mostram três fases
da órbita. São renders CPU de composição, não capturas do navegador.

A auditoria amostra um ciclo completo em 721 passos × 5 gemas × 2 modos; o bbox da tinta original da gema multiplicado pela escala não cruza o rosto (798..970,282..434), incluindo deslocamento de 40 px da corrida de saída, nem a área dos textos/botões/rodapé. Sugestão de teste após integração: suítes `menu_animation` e `ui_integration`, mais instanciar título/reabrir configurações/fechar/abrir e confirmar cinco gemas sem instâncias residuais; examinar posições e z=1/3 em um ciclo, diferenças do modo reduzido e handoff finito que continua uma única vez.

## Erro e regra preventiva

Traços de interface reaproveitados como água ficaram parecidos com guias de contato/desenho sob a plataforma. Regra: ornamentos de menu devem usar assets reconhecíveis aprovados; não usar linhas/ondas geométricas de UI para sugerir mar quando há mar SVG real. Revise decorativos sobre um ciclo inteiro com bbox da tinta, protegendo rosto/textos e identidade da cena; redução de flashes deve alterar movimento/pulsação/halo sem apagar o corpo.
