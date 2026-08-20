# Plan 02 - Character + FSM Jugable

## Objetivo

Tener un Character reusable para cualquier personaje via data, con FSM jugable completa y estable para pruebas reales.

## Alcance

- Incluye:
- CharacterBody3D + componentes necesarios de movimiento/animacion/ataque.
- Estados base jugables: Idle, Walk, Dash, Run, RunBrake, Pivot, Squat, JumpSquat, Jump, Fall, Attack, Shield, Roll, Spotdodge, Hit, Death.
- Transiciones claras por input, suelo/aire, impacto y KO.

- No incluye:
- Logica de dano/knockback/balance dentro de la FSM (eso va en combate/fisica).

## Dependencias

- Input abstraido del Plan 01.
- Integracion basica con hit/hurtbox del Plan 03.

## Tareas

- [ ] Validar jerarquia de nodos de Character (model/skeleton/hurtbox/hitboxes/state machine).
- [ ] Asegurar API configure(data) para inyectar CharacterData.
- [ ] Revisar transiciones de FSM para evitar loops o estados muertos.
- [ ] Separar logica: FSM decide estado, no calcula dano/knockback.

## Entregables

- Un prefab Character que sirve para 2+ personajes por data.
- FSM estable con transiciones reproducibles.

## Criterio de terminado

- Con el mismo Character, cambiar CharacterData cambia stats/movimientos sin tocar codigo de estado.
