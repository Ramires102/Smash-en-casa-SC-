# Issue Plan 02 - Input Map and Player Actions

## Objetivo

Normalizar acciones de input para P1/P2 y contrato de acciones del juego.

## Alcance

- Incluye: acciones move, jump, attack, special, shield para ambos jugadores.
- Incluye: mapeo teclado/joystick consistente.
- No incluye: logica de combate dentro de InputManager.

## Tareas

- [ ] Auditar acciones existentes y limpiar duplicados.
- [ ] Definir nombres estables para acciones por jugador.
- [ ] Validar que ambos jugadores puedan ejecutar mismo set de acciones.

## Criterio de terminado

- Action names estables y sin ambiguedad.
- Input reproducible en runtime para P1 y P2.

## Architecture Check

- [ ] Cumple guardrails de 00-architecture-guardrails.md.
