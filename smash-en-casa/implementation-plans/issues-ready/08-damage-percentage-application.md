# Issue Plan 08 - Damage and Percentage Application

## Objetivo

Aplicar porcentaje de dano de forma centralizada y predecible.

## Alcance

- Incluye: DamageCalculator como fuente de verdad del incremento de dano.
- Incluye: notificacion de cambio de porcentaje para HUD.
- No incluye: calculo de knockback en este issue.

## Tareas

- [ ] Definir formula/base para incremento de porcentaje.
- [ ] Actualizar estado del personaje golpeado.
- [ ] Emitir evento o señal de porcentaje actualizado.

## Criterio de terminado

- El porcentaje sube de forma consistente por ataque.
- HUD puede reaccionar sin polling acoplado.

## Architecture Check

- [ ] Cumple guardrails de 00-architecture-guardrails.md.
