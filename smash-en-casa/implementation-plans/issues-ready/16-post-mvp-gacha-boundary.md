# Issue Plan 16 - Post-MVP Gacha Boundary

## Objetivo

Definir frontera de gacha para evitar desvio de alcance antes de cerrar combate.

## Alcance

- Incluye: dejar gacha explicitamente como Post-MVP.
- Incluye: contrato de integracion futura sin tocar core de combate.
- No incluye: implementar economia, drop rates, persistencia final.

## Tareas

- [ ] Documentar que gacha no bloquea loop principal.
- [ ] Definir interfaces futuras minimas (si aplica).
- [ ] Evitar dependencias de gacha en battle/combat/character.

## Criterio de terminado

- El equipo tiene claridad de que gacha va despues del MVP.
- No hay acoplamiento prematuro con sistemas centrales.

## Architecture Check

- [ ] Cumple guardrails de 00-architecture-guardrails.md.
