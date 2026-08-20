# Issue Plan 03 - PlayerInput Abstraction

## Objetivo

Convertir input fisico en intenciones de juego consumibles por Character.

## Alcance

- Incluye: estructura PlayerInput (move/jump/attack/special/shield).
- Incluye: lectura por frame desacoplada de teclas concretas.
- No incluye: polling de teclas dentro de Character para decisiones de gameplay.

## Tareas

- [ ] Diseñar estructura de datos de intenciones.
- [ ] Enviar PlayerInput a Character/FSM.
- [ ] Remover dependencias directas a teclas de gameplay principal.

## Criterio de terminado

- Character responde a intenciones, no a teclas.
- Se puede cambiar dispositivo sin tocar logica de character.

## Architecture Check

- [ ] Cumple guardrails de 00-architecture-guardrails.md.
