# Issue Plan 13 - Character Instances and Selection Pipeline

## Objetivo

Conectar seleccion de personajes con instanciacion de battle via data.

## Alcance

- Incluye: CharacterSelect guarda P1/P2 data en GameManager.
- Incluye: Battle recibe data y configura Character de cada lado.
- No incluye: desbloqueo por gacha o persistencia avanzada.

## Tareas

- [ ] Validar guardado temporal de seleccion.
- [ ] Validar carga de CharacterData en escena battle.
- [ ] Verificar que cada Player usa su data correcta.

## Criterio de terminado

- P1 y P2 entran a battle con datos seleccionados.
- El pipeline no depende de hardcode por nombre de personaje.

## Architecture Check

- [ ] Cumple guardrails de 00-architecture-guardrails.md.
