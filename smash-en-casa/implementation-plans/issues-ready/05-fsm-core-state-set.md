# Issue Plan 05 - FSM Core State Set

## Objetivo

Asegurar FSM minima obligatoria y transiciones base del combate.

## Alcance

- Incluye: Idle, Run, Jump, Fall, Attack, Hit, Death.
- Incluye: transiciones por suelo/aire/input/impacto/KO.
- No incluye: estados avanzados no bloqueantes para MVP.

## Tareas

- [ ] Revisar transiciones validas entre estados minimos.
- [ ] Eliminar loops peligrosos y estados muertos.
- [ ] Definir reglas de interrupcion por hit y por death.

## Criterio de terminado

- FSM estable y deterministica para loop principal.
- No hay calculo de dano/knockback dentro de FSM.

## Architecture Check

- [ ] Cumple guardrails de 00-architecture-guardrails.md.
