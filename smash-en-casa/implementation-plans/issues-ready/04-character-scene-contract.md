# Issue Plan 04 - Character Scene Contract

## Objetivo

Fijar contrato de nodos y componentes de Character para reutilizacion por data.

## Alcance

- Incluye: estructura de CharacterBody3D y nodos esenciales.
- Incluye: metodo configure(data) para inyeccion de CharacterData.
- No incluye: logica de match/global dentro del personaje.

## Tareas

- [ ] Validar jerarquia minima (model/skeleton/hurtbox/hitboxes/fsm).
- [ ] Documentar dependencias internas entre componentes.
- [ ] Verificar que configure(data) aplique stats y referencias.

## Criterio de terminado

- Un mismo Character soporta multiples CharacterData.
- La escena no esta hardcodeada a un personaje puntual.

## Architecture Check

- [ ] Cumple guardrails de 00-architecture-guardrails.md.
