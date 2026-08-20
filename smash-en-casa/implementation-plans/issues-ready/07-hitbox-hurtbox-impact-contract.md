# Issue Plan 07 - Hitbox/Hurtbox Impact Contract

## Objetivo

Definir contrato de impacto robusto entre atacante y defensor.

## Alcance

- Incluye: deteccion de colision hitbox->hurtbox.
- Incluye: payload de impacto (attacker, target, attack_data, direccion).
- No incluye: calculo de winner ni stocks.

## Tareas

- [ ] Estandarizar señal/evento de hit recibido.
- [ ] Evitar multi-hit accidental del mismo swing.
- [ ] Asegurar trazabilidad del atacante y ataque aplicado.

## Criterio de terminado

- Cada impacto produce un evento consistente.
- No hay dobles impactos no deseados por frame.

## Architecture Check

- [ ] Cumple guardrails de 00-architecture-guardrails.md.
