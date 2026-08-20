# Issue Plan 05 - FSM Core State Set

## Objetivo

Consolidar una FSM jugable completa para el personaje, con todos los estados de movimiento/defensa/esquiva ya implementados, para evitar retrabajo y permitir pruebas reales de animaciones (ej: Miyabi).

## Alcance

- Incluye estados base: Idle, Walk, Dash, Run, RunBrake, Pivot, Squat, JumpSquat, Jump, Fall, Attack, Shield, Roll, Spotdodge, Hit, Death.
- Incluye transiciones por suelo/aire/input/impacto/KO, incluyendo entrada a Death antes de respawn o fin de partida.
- Incluye compatibilidad por autoinyeccion de estados faltantes en escenas que no los tengan instanciados.
- No incluye: logica de dano, knockback o reglas de balance de combate dentro de la FSM.

## Tareas

- [ ] Validar que cada estado del set completo exista y sea alcanzable por transicion real.
- [ ] Revisar transiciones criticas de piso (Idle/Walk/Dash/Run/RunBrake/Pivot/Squat/Shield).
- [ ] Revisar transiciones de aire/combate (JumpSquat/Jump/Fall/Attack/Hit/Death).
- [ ] Eliminar loops peligrosos y estados muertos.
- [ ] Mantener contrato de responsabilidades: FSM solo orquesta estados/transiciones.
- [ ] Ejecutar smoke test de jugabilidad con personaje animado (Miyabi): mover, dash, crouch, shield, roll, jump, attack, hit, KO, respawn.

## Criterio de terminado

- FSM estable y deterministica para loop principal con set completo de estados.
- Shield y Squat funcionan en runtime desde Idle/Run/Walk.
- Dash/Pivot/RunBrake/JumpSquat encadenan sin errores de estado inexistente.
- KO entra en Death antes de respawn/fin de partida.
- No hay calculo de dano/knockback dentro de FSM.

## Architecture Check

- [ ] Cumple guardrails de 00-architecture-guardrails.md.
