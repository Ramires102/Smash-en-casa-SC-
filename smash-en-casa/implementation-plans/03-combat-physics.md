# Plan 03 - Combat + Physics

## Objetivo

Cerrar el corazon jugable: golpes detectan, aplican dano y knockback coherente.

## Alcance

- Incluye:
- Hitbox activa por ventanas de ataque.
- Hurtbox recibe impacto y emite eventos de dano.
- DamageCalculator suma porcentaje.
- KnockbackCalculator produce velocidad de lanzamiento.

- No incluye:
- Sistemas cosmeticos avanzados de VFX/SFX complejos.
- Balance fino de roster completo.

## Dependencias

- AttackState funcional (Plan 02).
- AttackData base disponible (Plan 05).

## Tareas

- [ ] Definir contrato de impacto (quien golpea, a quien, con que AttackData).
- [ ] Prevenir multi-hit accidental del mismo golpe en la misma ventana.
- [ ] Aplicar dano y knockback con orden fijo y reproducible.
- [ ] Disparar cambio a HitState cuando corresponde.

## Entregables

- Dos personajes prototipo se pueden pegar entre si.
- El porcentaje sube y el lanzamiento cambia con dano acumulado.

## Criterio de terminado

- Flujo completo de golpe: AttackState -> Hitbox -> Hurtbox -> Damage -> Knockback -> HitState.
