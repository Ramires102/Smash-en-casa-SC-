# Explicación de `combat/hurtbox.gd`

## Resumen
Subclase de `Area3D` que representa la zona vulnerable / cuerpo del personaje. Recibe los impactos de las `Hitbox` y los retransmite a su `Character` dueño.

## Explicación Línea por Línea
```gdscript
1: class_name Hurtbox
2: extends Area3D

4: signal hit_received(attack_data: AttackData, attacker: Node3D)
5: @export var owner_character: Node3D
```
- Define la señal `hit_received` y la referencia obligatoria a su `owner_character`.

```gdscript
7: func take_hit(attack_data: AttackData, attacker: Node3D) -> void:
8: 	if owner_character and owner_character.has_method("on_hit_received"):
9: 		owner_character.on_hit_received(attack_data, attacker)
10: 	hit_received.emit(attack_data, attacker)
```
- `take_hit`: Método invocado por la `Hitbox`. Notifica al script `Character.gd` de su dueño mediante `on_hit_received` y emite la señal local.

## Comunicación e Interacciones
- **Comunica con**: `Character.gd` (invocando `on_hit_received`) y `Hitbox.gd`.
