# Distribuição ampliada dos Ruídozinhos — 01/10/2026

A fase de 9.600 px passou de cinco para doze encontros, preservando sprite,
pivô e escala. Novos encontros ocupam pisos planos após o aquecimento inicial,
rail, plataformas intermediárias e o Nó. Nenhum foi colocado sob jangadas
opcionais, pois a rota superior pode provocar stomp e bounce inesperados.

| Patrulha X | Piso Y | Situação |
| --- | --- | --- |
| 916–1000 | 520 | Novo, após trecho inicial seguro |
| 1740–1940 | 320 | Mantido |
| 3240–3290 | 420 | Novo, após saída do rail |
| 3656–3718 | 400 | Novo |
| 4210–4320 | 380 | Novo |
| 4780–4890 | 340 | Novo |
| 5950–6050 | 340 | Novo, depois do Nó |
| 6240–6340 | 340 | Novo, combate à distância antes do salto |
| 6630–6718 | 340 | Mantido, reserva de aterrissagem |
| 7440–7520 | 340 | Recuado para separar encontros |
| 7750–7850 | 340 | Recuado para separar encontros |
| 8240–8310 | 205 | Mantido, plataforma de sinal Online |

Apoio real, margens e presença Offline/Online passaram em 991 verificações
ao longo de 640 ticks. Travessia completa passou em 26 verificações, chegando
ao portal em (9306,31; 279,93), com sete saltos na extensão e conclusão após
1,8 s de animação. São execuções headless por inputs, sem teleporte na rota.

O piloto anterior combatia só `world.enemy` no primeiro trecho. Agora percorre
a coleção e usa chips antes de encontros perto de saltos, além do dash de
curta distância. Dash tem recarga/estado verificados e soltura após dois ticks;
repetir press a cada tick renovava a soltura e deixava o botão preso. Uma rota
só de dash falhou perto do salto 7060 após a nova distribuição; os chips
permitem eliminar ameaças sem consumir a trajetória de entrada. Não aumente
densidade sem testar as ações disponíveis e o espaço para reagir.
