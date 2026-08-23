# Graph Report - smash-en-casa  (2026-08-22)

## Corpus Check
- 60 files · ~239,619 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 447 nodes · 387 edges · 61 communities
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `7bf50342`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- ARCHITECTURE.md
- Issue Breakdown Granular (para backlog)
- Explicación de los Estados de la FSM (`characters/state_machine/`)
- 🏛️ Contrato de Autoloads (Core Architecture)
- Plan Template
- ISSUE MAP (Epic -> Issues Ready)
- 20. Orden real de desarrollo
- 00 - Architecture Guardrails (Reglas Innegociables)
- Plan 01 - Core + Input
- Plan 02 - Character + FSM Minima
- Plan 03 - Combat + Physics
- Plan 04 - Battle Flow (Reglas de partida)
- Plan 05 - Data-Driven Resources
- Plan 06 - UI del flujo principal
- Plan 07 - Integracion y pulido MVP
- Implementation Plans
- Issue Plan 01 - Core Autoload Contract
- Issue Plan 02 - Input Map and Player Actions
- Issue Plan 03 - PlayerInput Abstraction
- Issue Plan 04 - Character Scene Contract
- Issue Plan 05 - FSM Core State Set
- Issue Plan 06 - Attack State and Frame Windows
- Issue Plan 07 - Hitbox/Hurtbox Impact Contract
- Issue Plan 08 - Damage and Percentage Application
- Issue Plan 09 - Knockback and Hit Reaction
- Issue Plan 10 - Stage BlastZones and Spawns
- Issue Plan 11 - BattleManager Stocks Timer Winner
- Issue Plan 12 - Data Model Character/MoveSet/Attack
- Issue Plan 13 - Character Instances and Selection Pipeline
- Issue Plan 14 - UI Main Loop HUD Pause Victory
- Issue Plan 15 - Integration Smoke Tests and Hardening
- Issue Plan 16 - Post-MVP Gacha Boundary
- Explicación de los Componentes del Personaje (`characters/`)
- Explicación de `characters/character.gd`
- Explicación de `core/input_manager.gd`
- Explicación de `ui/pause.gd`, `ui/gacha.gd` y `ui/victory.gd`
- Explicación de `battle/battle.gd`
- Explicación de `battle/battle_manager.gd`
- Explicación de `battle/spawn_manager.gd`
- Explicación de `battle/stage.gd`
- Explicación de `characters/animation_controller.gd` (Articulación de Codos y Poses)
- Explicación de `combat/damage_calculator.gd`
- Explicación de `combat/hitbox.gd`
- Explicación de `combat/hurtbox.gd`
- Explicación de `core/audio_manager.gd`
- Explicación de `core/events.gd` (EventBus Singleton)
- Explicación de `core/game_manager.gd`
- Explicación de `physics/knockback_calculator.gd`
- Explicación de `resources/attack_data.gd`
- Explicación de `resources/character_data.gd`
- Explicación de `resources/moveset.gd`
- Explicación de `shared/constants.gd`
- Explicación de `shared/helpers.gd`
- Explicación de `shared/utils.gd`
- Explicación de `characters/state_machine/state_machine.gd`
- Explicación de `systems/camera_controller.gd`
- Explicación de `systems/input_buffer.gd`
- Explicación de `systems/screen_shake.gd`
- Explicación de `ui/character_select.gd`
- Explicación de `ui/hud.gd`
- Explicación de `ui/main_menu.gd`

## God Nodes (most connected - your core abstractions)
1. `Issue Breakdown Granular (para backlog)` - 18 edges
2. `Explicación de los Estados de la FSM (`characters/state_machine/`)` - 17 edges
3. `Plan Template` - 11 edges
4. `20. Orden real de desarrollo` - 9 edges
5. `ISSUE MAP (Epic -> Issues Ready)` - 9 edges
6. `00 - Architecture Guardrails (Reglas Innegociables)` - 8 edges
7. `Plan 01 - Core + Input` - 7 edges
8. `Plan 02 - Character + FSM Minima` - 7 edges
9. `Plan 03 - Combat + Physics` - 7 edges
10. `Plan 04 - Battle Flow (Reglas de partida)` - 7 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Communities (61 total, 0 thin omitted)

### Community 0 - "ARCHITECTURE.md"
Cohesion: 0.07
Nodes (28): 10. Stage, 11. Cámara, 12. Input, 13. Input Buffer, 14. Signals, 15. Autoloads, 16. El flujo completo, 17. ¿Y el Gacha? (+20 more)

### Community 1 - "Issue Breakdown Granular (para backlog)"
Cohesion: 0.11
Nodes (18): Epic #10 - Stage BlastZones and Spawns, Epic #11 - BattleManager Stocks Timer Winner, Epic #12 - Data Model Character/MoveSet/Attack, Epic #13 - Character Instances and Selection Pipeline, Epic #14 - UI Main Loop HUD Pause Victory, Epic #15 - Integration Smoke Tests and Hardening, Epic #16 - Post-MVP Gacha Boundary, Epic #1 - Core Autoload Contract (+10 more)

### Community 2 - "Explicación de los Estados de la FSM (`characters/state_machine/`)"
Cohesion: 0.11
Nodes (17): 10. `jump_state.gd` (`JUMP_F` / `JUMP_B`), 11. `fall_state.gd` (`FALL` / `FAST_FALL`), 12. `shield_state.gd` (`GUARD_ON` / `GUARD` / `GUARD_OFF`), 13. `roll_state.gd` (`ESCAPE_F` / `ESCAPE_B`), 14. `spotdodge_state.gd` (`ESCAPE_N`), 15. `daze_state.gd` (`DAZE`), 1. `state_machine.gd` (Mapeo ACMD Action States), 2. `walk_state.gd` (`WALK`) (+9 more)

### Community 3 - "🏛️ Contrato de Autoloads (Core Architecture)"
Cohesion: 0.13
Nodes (14): 1. GameManager (`res://core/game_manager.gd`), 2. InputManager (`res://core/input_manager.gd`), 3. AudioManager (`res://core/audio_manager.gd`), 4. Matriz de Responsabilidades y Límites, API Pública Mínima, API Pública Mínima, API Pública Mínima, 🏛️ Contrato de Autoloads (Core Architecture) (+6 more)

### Community 4 - "Plan Template"
Cohesion: 0.17
Nodes (11): Alcance, Architecture Check, Criterio de terminado, Dependencias, Entregables, Issue metadata, Objetivo, Plan Template (+3 more)

### Community 5 - "ISSUE MAP (Epic -> Issues Ready)"
Cohesion: 0.20
Nodes (9): Epic 01 - Core + Input, Epic 02 - Character + FSM, Epic 03 - Combat + Physics, Epic 04 - Battle Flow, Epic 05 - Data-Driven Resources, Epic 06 - UI Flow, Epic 07 - Integration and Polish, Gate obligatorio antes de cerrar cada issue (+1 more)

### Community 6 - "20. Orden real de desarrollo"
Cohesion: 0.22
Nodes (9): 20. Orden real de desarrollo, Fase 1 — Prototipo, Fase 2 — Primer golpe, Fase 3 — FSM, Fase 4 — Data Driven, Fase 5 — Primer personaje real, Fase 6 — Segundo y tercero, Fase 7 — UI (+1 more)

### Community 7 - "00 - Architecture Guardrails (Reglas Innegociables)"
Cohesion: 0.22
Nodes (8): 00 - Architecture Guardrails (Reglas Innegociables), Checklist de validacion arquitectonica, Limites de arquitectura, Objetivo, Politica para issues, Prohibiciones (anti-patrones), Regla principal, Separacion de responsabilidades obligatoria

### Community 8 - "Plan 01 - Core + Input"
Cohesion: 0.25
Nodes (7): Alcance, Criterio de terminado, Dependencias, Entregables, Objetivo, Plan 01 - Core + Input, Tareas

### Community 9 - "Plan 02 - Character + FSM Minima"
Cohesion: 0.25
Nodes (7): Alcance, Criterio de terminado, Dependencias, Entregables, Objetivo, Plan 02 - Character + FSM Minima, Tareas

### Community 10 - "Plan 03 - Combat + Physics"
Cohesion: 0.25
Nodes (7): Alcance, Criterio de terminado, Dependencias, Entregables, Objetivo, Plan 03 - Combat + Physics, Tareas

### Community 11 - "Plan 04 - Battle Flow (Reglas de partida)"
Cohesion: 0.25
Nodes (7): Alcance, Criterio de terminado, Dependencias, Entregables, Objetivo, Plan 04 - Battle Flow (Reglas de partida), Tareas

### Community 12 - "Plan 05 - Data-Driven Resources"
Cohesion: 0.25
Nodes (7): Alcance, Criterio de terminado, Dependencias, Entregables, Objetivo, Plan 05 - Data-Driven Resources, Tareas

### Community 13 - "Plan 06 - UI del flujo principal"
Cohesion: 0.25
Nodes (7): Alcance, Criterio de terminado, Dependencias, Entregables, Objetivo, Plan 06 - UI del flujo principal, Tareas

### Community 14 - "Plan 07 - Integracion y pulido MVP"
Cohesion: 0.25
Nodes (7): Alcance, Criterio de terminado, Dependencias, Entregables, Objetivo, Plan 07 - Integracion y pulido MVP, Tareas

### Community 15 - "Implementation Plans"
Cohesion: 0.25
Nodes (7): Como usar estos planes, Definicion de terminado global, Estructura de esta carpeta, Flujo recomendado para crear issues, Implementation Plans, Orden sugerido (issues-ready), Regla innegociable

### Community 16 - "Issue Plan 01 - Core Autoload Contract"
Cohesion: 0.29
Nodes (6): Alcance, Architecture Check, Criterio de terminado, Issue Plan 01 - Core Autoload Contract, Objetivo, Tareas

### Community 17 - "Issue Plan 02 - Input Map and Player Actions"
Cohesion: 0.29
Nodes (6): Alcance, Architecture Check, Criterio de terminado, Issue Plan 02 - Input Map and Player Actions, Objetivo, Tareas

### Community 18 - "Issue Plan 03 - PlayerInput Abstraction"
Cohesion: 0.29
Nodes (6): Alcance, Architecture Check, Criterio de terminado, Issue Plan 03 - PlayerInput Abstraction, Objetivo, Tareas

### Community 19 - "Issue Plan 04 - Character Scene Contract"
Cohesion: 0.29
Nodes (6): Alcance, Architecture Check, Criterio de terminado, Issue Plan 04 - Character Scene Contract, Objetivo, Tareas

### Community 20 - "Issue Plan 05 - FSM Core State Set"
Cohesion: 0.29
Nodes (6): Alcance, Architecture Check, Criterio de terminado, Issue Plan 05 - FSM Core State Set, Objetivo, Tareas

### Community 21 - "Issue Plan 06 - Attack State and Frame Windows"
Cohesion: 0.29
Nodes (6): Alcance, Architecture Check, Criterio de terminado, Issue Plan 06 - Attack State and Frame Windows, Objetivo, Tareas

### Community 22 - "Issue Plan 07 - Hitbox/Hurtbox Impact Contract"
Cohesion: 0.29
Nodes (6): Alcance, Architecture Check, Criterio de terminado, Issue Plan 07 - Hitbox/Hurtbox Impact Contract, Objetivo, Tareas

### Community 23 - "Issue Plan 08 - Damage and Percentage Application"
Cohesion: 0.29
Nodes (6): Alcance, Architecture Check, Criterio de terminado, Issue Plan 08 - Damage and Percentage Application, Objetivo, Tareas

### Community 24 - "Issue Plan 09 - Knockback and Hit Reaction"
Cohesion: 0.29
Nodes (6): Alcance, Architecture Check, Criterio de terminado, Issue Plan 09 - Knockback and Hit Reaction, Objetivo, Tareas

### Community 25 - "Issue Plan 10 - Stage BlastZones and Spawns"
Cohesion: 0.29
Nodes (6): Alcance, Architecture Check, Criterio de terminado, Issue Plan 10 - Stage BlastZones and Spawns, Objetivo, Tareas

### Community 26 - "Issue Plan 11 - BattleManager Stocks Timer Winner"
Cohesion: 0.29
Nodes (6): Alcance, Architecture Check, Criterio de terminado, Issue Plan 11 - BattleManager Stocks Timer Winner, Objetivo, Tareas

### Community 27 - "Issue Plan 12 - Data Model Character/MoveSet/Attack"
Cohesion: 0.29
Nodes (6): Alcance, Architecture Check, Criterio de terminado, Issue Plan 12 - Data Model Character/MoveSet/Attack, Objetivo, Tareas

### Community 28 - "Issue Plan 13 - Character Instances and Selection Pipeline"
Cohesion: 0.29
Nodes (6): Alcance, Architecture Check, Criterio de terminado, Issue Plan 13 - Character Instances and Selection Pipeline, Objetivo, Tareas

### Community 29 - "Issue Plan 14 - UI Main Loop HUD Pause Victory"
Cohesion: 0.29
Nodes (6): Alcance, Architecture Check, Criterio de terminado, Issue Plan 14 - UI Main Loop HUD Pause Victory, Objetivo, Tareas

### Community 30 - "Issue Plan 15 - Integration Smoke Tests and Hardening"
Cohesion: 0.29
Nodes (6): Alcance, Architecture Check, Criterio de terminado, Issue Plan 15 - Integration Smoke Tests and Hardening, Objetivo, Tareas

### Community 31 - "Issue Plan 16 - Post-MVP Gacha Boundary"
Cohesion: 0.29
Nodes (6): Alcance, Architecture Check, Criterio de terminado, Issue Plan 16 - Post-MVP Gacha Boundary, Objetivo, Tareas

### Community 32 - "Explicación de los Componentes del Personaje (`characters/`)"
Cohesion: 0.29
Nodes (6): 1. `attack_controller.gd`, 2. `character_stats.gd`, 3. `character_controller.gd`, Comunicación e Interacciones, Explicación de los Componentes del Personaje (`characters/`), Resumen

### Community 33 - "Explicación de `characters/character.gd`"
Cohesion: 0.33
Nodes (5): Comunicación e Interacciones, Constantes de Escudo y Mareo, Explicación de `characters/character.gd`, Métodos de Escudo, Resumen

### Community 34 - "Explicación de `core/input_manager.gd`"
Cohesion: 0.33
Nodes (5): Comunicación e Interacciones, Explicación de `core/input_manager.gd`, 🕹️ Funcionalidades del Script, 🎮 Mapa de Acciones Normalizado por Jugador, Resumen

### Community 35 - "Explicación de `ui/pause.gd`, `ui/gacha.gd` y `ui/victory.gd`"
Cohesion: 0.33
Nodes (5): 1. `ui/pause.gd`, 2. `ui/gacha.gd`, 3. `ui/victory.gd`, Comunicación e Interacciones, Explicación de `ui/pause.gd`, `ui/gacha.gd` y `ui/victory.gd`

### Community 36 - "Explicación de `battle/battle.gd`"
Cohesion: 0.40
Nodes (4): Comunicación e Interacciones, Explicación de `battle/battle.gd`, Explicación Línea por Línea, Resumen

### Community 37 - "Explicación de `battle/battle_manager.gd`"
Cohesion: 0.40
Nodes (4): Comunicación e Interacciones, Explicación de `battle/battle_manager.gd`, Explicación Línea por Línea, Resumen

### Community 38 - "Explicación de `battle/spawn_manager.gd`"
Cohesion: 0.40
Nodes (4): Comunicación e Interacciones, Explicación de `battle/spawn_manager.gd`, Explicación Línea por Línea, Resumen

### Community 39 - "Explicación de `battle/stage.gd`"
Cohesion: 0.40
Nodes (4): Comunicación e Interacciones, Explicación de `battle/stage.gd`, Explicación Línea por Línea, Resumen

### Community 40 - "Explicación de `characters/animation_controller.gd` (Articulación de Codos y Poses)"
Cohesion: 0.40
Nodes (4): Articulación de la Pose DIO (Idle), Comunicación e Interacciones, Explicación de `characters/animation_controller.gd` (Articulación de Codos y Poses), Resumen

### Community 41 - "Explicación de `combat/damage_calculator.gd`"
Cohesion: 0.40
Nodes (4): Comunicación e Interacciones, Explicación de `combat/damage_calculator.gd`, Explicación Línea por Línea, Resumen

### Community 42 - "Explicación de `combat/hitbox.gd`"
Cohesion: 0.40
Nodes (4): Comunicación e Interacciones, Explicación de `combat/hitbox.gd`, Explicación Línea por Línea, Resumen

### Community 43 - "Explicación de `combat/hurtbox.gd`"
Cohesion: 0.40
Nodes (4): Comunicación e Interacciones, Explicación de `combat/hurtbox.gd`, Explicación Línea por Línea, Resumen

### Community 44 - "Explicación de `core/audio_manager.gd`"
Cohesion: 0.40
Nodes (4): Comunicación e Interacciones, Explicación de `core/audio_manager.gd`, Explicación Línea por Línea, Resumen

### Community 45 - "Explicación de `core/events.gd` (EventBus Singleton)"
Cohesion: 0.40
Nodes (4): Comunicación e Interacciones, Explicación de `core/events.gd` (EventBus Singleton), Explicación Línea por Línea, Resumen

### Community 46 - "Explicación de `core/game_manager.gd`"
Cohesion: 0.40
Nodes (4): Comunicación e Interacciones, Explicación de `core/game_manager.gd`, Explicación Línea por Línea, Resumen

### Community 47 - "Explicación de `physics/knockback_calculator.gd`"
Cohesion: 0.40
Nodes (4): Comunicación e Interacciones, Explicación de `physics/knockback_calculator.gd`, Explicación Línea por Línea, Resumen

### Community 48 - "Explicación de `resources/attack_data.gd`"
Cohesion: 0.40
Nodes (4): Comunicación e Interacciones, Explicación de `resources/attack_data.gd`, Explicación Línea por Línea, Resumen

### Community 49 - "Explicación de `resources/character_data.gd`"
Cohesion: 0.40
Nodes (4): Comunicación e Interacciones, Explicación de `resources/character_data.gd`, Explicación Línea por Línea, Resumen

### Community 50 - "Explicación de `resources/moveset.gd`"
Cohesion: 0.40
Nodes (4): Comunicación e Interacciones, Explicación de `resources/moveset.gd`, Explicación Línea por Línea, Resumen

### Community 51 - "Explicación de `shared/constants.gd`"
Cohesion: 0.40
Nodes (4): Comunicación e Interacciones, Explicación de `shared/constants.gd`, Explicación Línea por Línea, Resumen

### Community 52 - "Explicación de `shared/helpers.gd`"
Cohesion: 0.40
Nodes (4): Comunicación e Interacciones, Explicación de `shared/helpers.gd`, Explicación Línea por Línea, Resumen

### Community 53 - "Explicación de `shared/utils.gd`"
Cohesion: 0.40
Nodes (4): Comunicación e Interacciones, Explicación de `shared/utils.gd`, Explicación Línea por Línea, Resumen

### Community 54 - "Explicación de `characters/state_machine/state_machine.gd`"
Cohesion: 0.40
Nodes (4): Comunicación e Interacciones, Explicación de `characters/state_machine/state_machine.gd`, Explicación Línea por Línea, Resumen

### Community 55 - "Explicación de `systems/camera_controller.gd`"
Cohesion: 0.40
Nodes (4): Comunicación e Interacciones, Explicación de `systems/camera_controller.gd`, Explicación Línea por Línea, Resumen

### Community 56 - "Explicación de `systems/input_buffer.gd`"
Cohesion: 0.40
Nodes (4): Comunicación e Interacciones, Explicación de `systems/input_buffer.gd`, Explicación Línea por Línea, Resumen

### Community 57 - "Explicación de `systems/screen_shake.gd`"
Cohesion: 0.40
Nodes (4): Comunicación e Interacciones, Explicación de `systems/screen_shake.gd`, Explicación Línea por Línea, Resumen

### Community 58 - "Explicación de `ui/character_select.gd`"
Cohesion: 0.40
Nodes (4): Comunicación e Interacciones, Explicación de `ui/character_select.gd`, Explicación Línea por Línea, Resumen

### Community 59 - "Explicación de `ui/hud.gd`"
Cohesion: 0.40
Nodes (4): Comunicación e Interacciones, Explicación de `ui/hud.gd`, Explicación Línea por Línea, Resumen

### Community 60 - "Explicación de `ui/main_menu.gd`"
Cohesion: 0.40
Nodes (4): Comunicación e Interacciones, Explicación de `ui/main_menu.gd`, Explicación Línea por Línea, Resumen

## Knowledge Gaps
- **321 isolated node(s):** `1. Arquitectura general`, `2. Estructura definitiva`, `3. ¿Qué es realmente un personaje?`, `4. CharacterData`, `5. MoveSet` (+316 more)
  These have ≤1 connection - possible missing edges or undocumented components.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `20. Orden real de desarrollo` connect `20. Orden real de desarrollo` to `ARCHITECTURE.md`?**
  _High betweenness centrality (0.003) - this node is a cross-community bridge._
- **What connects `1. Arquitectura general`, `2. Estructura definitiva`, `3. ¿Qué es realmente un personaje?` to the rest of the system?**
  _321 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `ARCHITECTURE.md` be split into smaller, more focused modules?**
  _Cohesion score 0.06896551724137931 - nodes in this community are weakly interconnected._
- **Should `Issue Breakdown Granular (para backlog)` be split into smaller, more focused modules?**
  _Cohesion score 0.10526315789473684 - nodes in this community are weakly interconnected._
- **Should `Explicación de los Estados de la FSM (`characters/state_machine/`)` be split into smaller, more focused modules?**
  _Cohesion score 0.1111111111111111 - nodes in this community are weakly interconnected._
- **Should `🏛️ Contrato de Autoloads (Core Architecture)` be split into smaller, more focused modules?**
  _Cohesion score 0.13333333333333333 - nodes in this community are weakly interconnected._