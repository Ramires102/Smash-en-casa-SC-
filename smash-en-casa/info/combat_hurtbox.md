# Explicación de `combat/hurtbox.gd`

## Resumen
Subclase de `Area3D` que representa la zona vulnerable / cuerpo del personaje. Recibe los impactos de las `Hitbox` y los retransmite a su `Character` dueño. Asigna automáticamente a su personaje padre en `_ready()` si la referencia `owner_character` no fue establecida en el inspector.

## Explicación Línea por Línea
```gdscript
1: class_name Hurtbox
2: extends Area3D

4: signal hit_received(attack_data: AttackData, attacker: Node3D)
5: @export var owner_character: Node3D

7: func _ready() -> void:
8: 	if owner_character == null:
9: 		owner_character = get_parent()
```
- Vincula automáticamente el `owner_character` al nodo padre (`Character`) para garantizar la recepción de notificaciones de daño.

```gdscript
11: func take_hit(attack_data: AttackData, attacker: Node3D) -> void:
12: 	if owner_character and owner_character.has_method("on_hit_received"):
13: 		owner_character.on_hit_received(attack_data, attacker)
14: 	hit_received.emit(attack_data, attacker)
```
- `take_hit`: Método invocado por la `Hitbox`. Notifica al script `Character.gd` de su dueño mediante `on_hit_received` y emite la señal local.

## Comunicación e Interacciones
- **Comunica con**: `Character.gd` (invocando `on_hit_received`) y `Hitbox.gd`.
