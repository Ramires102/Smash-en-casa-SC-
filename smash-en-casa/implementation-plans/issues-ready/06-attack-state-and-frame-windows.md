# Issue Plan 06 - Attack State and Frame Windows

## Objetivo

Implementar ejecucion de ataque basada en ventanas de startup/active/recovery.

## Alcance

- Incluye: AttackState leyendo datos de AttackData.
- Incluye: control de activacion/desactivacion de hitbox por ventanas.
- No incluye: logica de dano dentro de AttackData.

## Tareas

- [ ] Definir flujo de animacion + ventanas de ataque.
- [ ] Activar hitbox solo en active frames.
- [ ] Cerrar ataque y retornar a estado correspondiente.

## Criterio de terminado

- AttackData describe; AttackState ejecuta.
- No hay ataques permanentes ni ventanas incorrectas.

## Architecture Check

- [ ] Cumple guardrails de 00-architecture-guardrails.md.
