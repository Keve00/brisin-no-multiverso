# SVGs, animações e interações — entrega

As três pranchas aprovadas foram convertidas em vetores editáveis com paths,
sem imagens raster embutidas. O catálogo novo contém **115 SVGs de produção**:
56 de plataformas (18 completas, 18 módulos de chão, 18 decorações e duas
camadas de vento), 29 camadas dos seis objetos interativos e 30 de cenário/VFX.
Há também uma prévia SVG animada do cenário.

## O que está na fase

As nove famílias de plataformas aparecem no mundo. A extensão após o Nó tem
um percurso inferior até o portal e plataformas opcionais acima, incluindo
pedras que desmoronam e plataformas que dependem de conexão. O portal foi
reposicionado para x=7770. A superfície em degraus exige saltar; a placa da
fase avisa o jogador. O teste de percurso chega ao portal com entradas reais.

Há 23 colocações de decoração, cobrindo as três variantes de cada uma das seis
famílias decorativas: coqueiros, vegetação, pedras/areia, ruínas, postes e
objetos de água. Plantas reagem à passagem; água oscila; luzes respondem à conexão.
Nenhuma dessas decorações cria colisões ou coletáveis.

Turbina, farol, checkpoint, Nó, portal e rail usam as novas camadas SVG e
os estados Offline/Online. A lógica de checkpoint, conexão, rail e conclusão
continua integrada aos sistemas do jogo. Tempos e pivôs estão nos documentos
de cada família.

Gemas coletáveis mantêm a arte laranja facetada e o pulso já aprovados. A coleta
agora dispara uma sequência SVG única de anel, fragmentos e faíscas em 0,48 s.
As três variantes adicionais de gemas e vento ficam disponíveis no catálogo;
elas não substituem automaticamente cada coletável/região da fase.
Vento continua representado por curvas e folhas, sem setas. A nova corrente
Online fica acima da rota segura para auxiliar o percurso opcional.

## Verificação realizada

- Godot 4.5.1: importação sem erros.
- Testes de percurso em blockout: 25 verificações passaram, incluindo o portal
  da extensão. Os testes de cenário/interações usam a apresentação com arte.
- Testes de cenário SVG: 13 verificações passaram.
- Testes novos de interações: 17 verificações passaram — coleta única, descarte
  do efeito, aviso/queda/retorno da pedra, restauração no respawn, estados da
  plataforma de sinal, movimento conjunto da colisão, degraus, vento e salto
  real para a primeira plataforma opcional.
- XML dos SVGs: nenhum raster embutido. Revisão visual das plataformas,
  objetos Offline/Online e cenário em imagens renderizadas pelo Inkscape.
- Escalas uniformes e pivôs documentados; módulos substituem stretch de objetos.

- A atualização mais recente do menu foi incorporada preservando sua animação:
  16 verificações do menu e 38 da interface passaram novamente. O HUD também
  passou a proteger a área do jogador procedural no modo blockout sem tentar
  ler um frame de animação inexistente.

Total: **55 verificações de gameplay/cenário e 54 de menu/interface aprovadas**.
A captura visual do
jogo em execução ficou indisponível neste ambiente; a revisão de imagem foi
dos SVGs renderizados, sem afirmar aprovação visual do jogo no navegador.

## Uso do pacote

O ZIP inclui o projeto Godot editável completo, SVGs, manifests, scripts,
dados da fase, testes e esta documentação. Abra `godot/project.godot` no
Godot 4.5.1 e deixe o editor importar os recursos. As animações do jogo são
controladas por GDScript; não dependem de SMIL dentro das texturas SVG.
`environment/animated_preview.svg` é uma demonstração separada para navegador.


## Atualização integrada — 01/10/2026

Menu SVG com 30 poses de aceno e entradas de preparação correspondentes,
bandeiras com tecido ondulando continuamente, atmosfera apenas nas camadas
fundo, pulso sincronizado à expansão visual com stun de 2 s e dash/pulso
opacos e saturados. Chips SIM brancos usam F / Y, 0,35 s de recarga e 500 px
de alcance. Portal possui 1,8 s de aproximação, atração e fechamento antes
da conclusão; cancelamento restaura visual/simulação e exige sair para rearmar.

Godot 4.5.1 headless com dados isolados e `-- --test`: combate 35/35,
efeitos 13/13, portal 21/21, menu 16/16, cenário 13/13, bandeira 21/21,
fundo 17/17, UI 38/38, integração por inputs spawn→portal 26/26.
A integração verifica entrada sem conclusão imediata e conclusão após a animação.
Frames renderizados e pranchas foram revisados; esta rodada não incluiu revisão
da movimentação no navegador. Consulte as auditorias específicas para detalhes.

## Revisão de menu, HUD, portal e mar

Menu utiliza coastal_0.svg sob os pés e o panorama vetorial animado. Aceno,
vela e corpo ganharam movimento mais legível; entradas/saídas continuam exatas.
Dicas/avisos e contagem de gemas são centralizados no espaço útil após o ícone,
compensando tinta da fonte e sombra da moldura.

Névoa remapeada para18% no céu, aproximadamente55% no horizonte e34% na água
baixa. Ondulações pequenas no mar distante ficam dentro da máscara da água.
O mar próximo y810 é composto por módulos SVG em camadas, espuma, reflexos e
12 frames de superfície; cobertura atéy1034, sem mudança no perigo físico.

Portal mantém moldura fixa com núcleo, pistas, túnel e partículas em movimento;
entrada de1,8s, modo reduzido de fato e conclusão somente após terminar.

Godot4.5.1 headless, dados isolados e `-- --test`: menu19/19, UI41/41,
portal23/23, cenário13/13, mar53/53, fundo19/19, dicas34/34 e percurso26/26.
Previews de SVGs/atlas e keyframes reais foram inspecionados independentemente.
Não houve revisão da movimentação no navegador nesta rodada.

README atualizado com apresentação, instalação, controles, execuçãoHTTP,
exportação portátil e testes; pacote editável inclui README e requisitos.
