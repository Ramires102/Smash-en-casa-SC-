# Explicación de `characters/character.gd`

## Resumen
Controlador principal de personaje 2.5D (`CharacterBody3D`). Integra la arquitectura de componentes (`CharacterController`, `CharacterStats`, `AttackController`, `AnimationController`, `StateMachine`), constantes de escudo (`MAX_SHIELD_HP`, `SHIELD_BREAK_RESPAWN_HP`, `SHIELD_DRAIN_RATE`), rotura de escudo (Shield Break), estado de mareo (Daze) y articulación visual 3D.

## Constantes de Escudo y Mareo
- `MAX_SHIELD_HP = 50.0`: Salud máxima del escudo 3D.
- `SHIELD_BREAK_RESPAWN_HP = 30.0`: Salud del escudo asignada tras salir del estado de mareo (`DazeState`).
- `SHIELD_DRAIN_RATE = 8.0`: Tasa de desgaste por segundo al mantener el escudo presionado.

## Métodos de Escudo
- `break_shield()`: Agota el escudo a 0 y transiciona la FSM a `Daze`.
- `update_shield_scale()`: Escala el tamaño de la burbuja 3D proporcionalmente a la salud del escudo restante.

## Comunicación e Interacciones
- **Comunica con**: `ShieldState.gd`, `DazeState.gd`, `DamageCalculator`, `KnockbackCalculator`, `Events`, `AudioManager`.
