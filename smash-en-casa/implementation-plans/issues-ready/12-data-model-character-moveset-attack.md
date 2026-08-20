# Issue Plan 12 - Data Model Character/MoveSet/Attack

## Objetivo

Definir modelo de datos final para roster y ataques sin logica embebida.

## Alcance

- Incluye: campos minimos de CharacterData.
- Incluye: slots de MoveSet (ground/air/special).
- Incluye: frame data y parametros de AttackData.
- No incluye: ejecucion runtime del ataque.

## Tareas

- [ ] Cerrar schema de CharacterData.
- [ ] Cerrar schema de MoveSet.
- [ ] Cerrar schema de AttackData.
- [ ] Revisar compatibilidad con Character y AttackState.

## Criterio de terminado

- Datos suficientes para drivear gameplay sin if hardcodeados.
- Resources no contienen logica de combate.

## Architecture Check

- [ ] Cumple guardrails de 00-architecture-guardrails.md.
