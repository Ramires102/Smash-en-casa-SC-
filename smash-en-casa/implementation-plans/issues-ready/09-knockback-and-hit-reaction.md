# Issue Plan 09 - Knockback and Hit Reaction

## Objetivo

Aplicar knockback desde calculadora fisica y pasar a reaccion de golpe.

## Alcance

- Incluye: KnockbackCalculator con inputs de dano/peso/angulo/base/growth.
- Incluye: aplicacion de velocidad al Character afectado.
- Incluye: entrada a HitState cuando corresponde.
- No incluye: KO/stock logic en este issue.

## Tareas

- [ ] Definir interfaz de KnockbackCalculator.
- [ ] Aplicar vector de lanzamiento sobre Character.velocity.
- [ ] Integrar reaccion de hit en FSM.

## Criterio de terminado

- Knockback coherente con porcentaje acumulado.
- Transicion a HitState consistente.

## Architecture Check

- [ ] Cumple guardrails de 00-architecture-guardrails.md.
