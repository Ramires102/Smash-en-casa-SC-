# Issue Plan 10 - Stage BlastZones and Spawns

## Objetivo

Consolidar Stage como espacio de batalla con limites y puntos de spawn.

## Alcance

- Incluye: plataformas y colisiones de escenario.
- Incluye: blast zones top/bottom/left/right.
- Incluye: spawn points para inicio/respawn.
- No incluye: reglas de stock o winner (BattleManager).

## Tareas

- [ ] Validar colisiones de piso/plataformas.
- [ ] Configurar zonas de salida de mapa.
- [ ] Estandarizar puntos de aparicion por jugador.

## Criterio de terminado

- Stage expone correctamente limites y spawns.
- Salir de blast zone genera evento consumible por battle.

## Architecture Check

- [ ] Cumple guardrails de 00-architecture-guardrails.md.
