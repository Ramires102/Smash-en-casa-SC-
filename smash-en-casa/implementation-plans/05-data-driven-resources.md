# Plan 05 - Data-Driven Resources

## Objetivo

Consolidar personajes y ataques como datos para escalar sin tocar logica central.

## Alcance

- Incluye:
- CharacterData como configuracion de personaje.
- MoveSet como mapa de acciones a AttackData.
- AttackData como definicion de propiedades de ataque.
- Instancias .tres por personaje.

- No incluye:
- Logica de ejecucion dentro de resources.

## Dependencias

- Character configure(data) operativo (Plan 02).
- Combat leyendo AttackData (Plan 03).

## Tareas

- [ ] Estandarizar campos minimos de CharacterData.
- [ ] Estandarizar slots de MoveSet (ground/air/special).
- [ ] Estandarizar frame data e hitbox config de AttackData.
- [ ] Crear y validar miyabi_data, gogeta_data, sakuya_data.

## Entregables

- Swap de personaje por data sin if hardcodeados.
- Roster extensible agregando resources.

## Criterio de terminado

- Agregar un personaje nuevo implica crear data/assets, no reescribir core.
