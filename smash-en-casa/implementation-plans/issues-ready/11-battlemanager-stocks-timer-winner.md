# Issue Plan 11 - BattleManager Stocks Timer Winner

## Objetivo

Implementar arbitraje de partida desacoplado de Character.

## Alcance

- Incluye: control de stocks, timer, KO, respawn, winner.
- Incluye: salida a pantalla de victoria.
- No incluye: logica de movimiento/ataque de personajes.

## Tareas

- [ ] Consumir eventos de KO/fall out of bounds.
- [ ] Restar stock y decidir respawn o fin.
- [ ] Resolver winner por stocks/timer.

## Criterio de terminado

- Character no decide ganador.
- BattleManager controla todo el estado de match.

## Architecture Check

- [ ] Cumple guardrails de 00-architecture-guardrails.md.
