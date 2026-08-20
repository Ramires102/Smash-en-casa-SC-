# Plan 04 - Battle Flow (Reglas de partida)

## Objetivo

Definir reglas de match independientes de Character: stocks, timer, KO, respawn y winner.

## Alcance

- Incluye:
- BattleManager como arbitro.
- Stage con blast zones y spawn points.
- SpawnManager para inicio y respawn.
- Condiciones de game over y pantalla de victoria.

- No incluye:
- Modo torneo, brackets o metagame.

## Dependencias

- Combat estable (Plan 03).
- Escena battle con nodos principales.

## Tareas

- [ ] Detectar salida de blast zone por jugador.
- [ ] Restar stock y decidir respawn vs game over.
- [ ] Aplicar respawn invulnerable basico si lo usan.
- [ ] Notificar winner para UI de victoria.

## Entregables

- Match completo jugable de inicio a fin.
- Reglas desacopladas del script de Character.

## Criterio de terminado

- Character no decide ganador ni stocks.
- BattleManager resuelve resultados de la partida.
