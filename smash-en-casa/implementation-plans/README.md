# Implementation Plans

Esta carpeta separa arquitectura de ejecucion.
No hay fechas ni estimaciones: solo alcance, tareas y criterio de terminado.

## Regla innegociable

Ningun implementation plan puede romper la arquitectura definida en ARCHITECTURE.md.
Toda tarea debe pasar por Architecture Check.

Referencia de reglas: 00-architecture-guardrails.md

## Estructura de esta carpeta

- Planes marco (alto nivel): 01-07
- Planes granulares listos para issues: issues-ready/01-16
- Mapa de trazabilidad epic -> issues: ISSUE-MAP.md

## Como usar estos planes

1. Elegir un issue plan activo por vez (carpeta issues-ready).
2. Marcar tareas en progreso/completadas dentro del archivo.
3. Validar el bloque Architecture Check antes de cerrar.
4. Si aparece trabajo nuevo, crear issue plan nuevo o extender uno existente.
5. Si no aporta al loop principal (select -> battle -> KO -> victory), mover a Post-MVP.

## Flujo recomendado para crear issues

1. Copiar un archivo de issues-ready como cuerpo del issue.
2. Usar el titulo del archivo como titulo del issue.
3. Mantener Objetivo, Alcance, Tareas y Criterio de terminado.
4. No cerrar issue sin tildar Architecture Check.

## Orden sugerido (issues-ready)

1. issues-ready/01-core-autoload-contract.md
2. issues-ready/02-input-map-and-player-actions.md
3. issues-ready/03-player-input-abstraction.md
4. issues-ready/04-character-scene-contract.md
5. issues-ready/05-fsm-core-state-set.md
6. issues-ready/06-attack-state-and-frame-windows.md
7. issues-ready/07-hitbox-hurtbox-impact-contract.md
8. issues-ready/08-damage-percentage-application.md
9. issues-ready/09-knockback-and-hit-reaction.md
10. issues-ready/10-stage-blastzones-and-spawns.md
11. issues-ready/11-battlemanager-stocks-timer-winner.md
12. issues-ready/12-data-model-character-moveset-attack.md
13. issues-ready/13-character-instances-and-selection-pipeline.md
14. issues-ready/14-ui-mainloop-hud-pause-victory.md
15. issues-ready/15-integration-smoke-tests-and-hardening.md
16. issues-ready/16-post-mvp-gacha-boundary.md

## Definicion de terminado global

- Dos personajes pueden pelear de punta a punta.
- Hay dano, knockback, KO, respawn y victoria.
- El cambio de personaje se hace por CharacterData/MoveSet/AttackData.
- No se agregan sistemas fuera de alcance principal.
- Ninguna implementacion rompe boundaries de arquitectura.
