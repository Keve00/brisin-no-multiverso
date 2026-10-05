# Integração SVG e contexto — 01/10/2026

## Resultado integrado

- Panorama aprovado convertido em nove camadas SVG vetoriais reais. O Godot usa parallax contínuo ao longo de 9600 px; rotores possuem pivôs próprios, mastros separados e margem de giro. Reflexos e faróis variam suavemente.
- Cinco Ruídozinhos vinculados às superfícies reais. A terceira patrulha reserva 130 px para aterrissagem; a quinta acompanha a plataforma de sinal móvel e seu estado Online.
- Dash e pulso usam SVGs, faíscas e fade. O pulso conserva origem global e alcance; efeitos desaparecem no respawn e em DISABLED.
- Dicas deixam de ser placas persistentes. Uma faixa sob o HUD usa elegibilidade real, prioridades e orçamento de leitura de 4,5 s por contexto.
- `AGENTS.md`, projeto editável no ZIP e pacote web são atualizados juntos. O carregador valida também o tamanho anunciado do PCK.

## Evidências

| Verificação | Resultado |
| --- | --- |
| Apoio, bordas, movimento e estados dos inimigos | 417 passaram, zero falhas |
| Efeitos de ações SVG | 13 passaram, zero falhas |
| Dicas contextuais | 25 passaram, zero falhas |
| Interface | 38 passaram, zero falhas |
| Cobertura e proporções do fundo | 15 passaram, zero falhas |
| Percurso completo até o portal, após integração do fundo | 25 passaram, zero falhas |

Testes executados em Godot 4.5.1 headless com `-- --test`; o percurso usa 60 FPS fixos. Foram inspecionadas prévias rasterizadas dos SVGs de efeitos/interface e do fundo em repouso e com hélices rotacionadas, incluindo revisão independente a 90°. Os SVGs do fundo não contêm imagem raster embutida. Essas evidências não equivalem a uma captura de gameplay no navegador.

A geração inicial do conceito foi rejeitada por divergir da pixel art atual; a revisão usou a referência fornecida pelo usuário. O panorama estendido foi aprovado antes da conversão. A fonte aprovada e o gerador vetorial estão preservados em `tools/reference_art` e `tools/trace_background_svg.py`.
