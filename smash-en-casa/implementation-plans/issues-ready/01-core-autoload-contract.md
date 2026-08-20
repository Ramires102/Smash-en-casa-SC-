# Issue Plan 01 - Core Autoload Contract

## Objetivo

Dejar contrato estable de autoloads minimos y su responsabilidad.

## Alcance

- Incluye: GameManager, AudioManager, InputManager.
- Incluye: responsabilidades y API publica minima de cada singleton.
- No incluye: agregar nuevos managers globales.

## Tareas

- [ ] Documentar responsabilidad exacta por autoload.
- [ ] Verificar que no invadan responsabilidades de battle/combat/character.
- [ ] Listar metodos publicos usados por escenas principales.

## Criterio de terminado

- Cada autoload tiene rol acotado y comprobable.
- No aparece logica de match ni dano dentro de core.

## Architecture Check

- [ ] Cumple guardrails de 00-architecture-guardrails.md.
