# Explicación de `combat/hitbox.gd`

## Resumen
Subclase de `Area3D` que representa la zona ofensiva de un ataque. Detecta cuando se solapa con una `Hurtbox` enemiga y emite las señales correspondientes enviando los datos del `AttackData`.

## Explicación Línea por Línea
```gdscript
1: class_name Hitbox
2: extends Area3D

4: signal hit_registered(hurtbox: Hurtbox, attack_data: AttackData)
5: @export var attack_data: AttackData
6: var owner_character: Node3D = null
```
- Declara la señal `hit_registered`, la referencia al `AttackData` activo y al dueño del ataque (`owner_character`) para evitar autogolpes.

```gdscript
8: func _ready() -> void:
9: 	area_entered.connect(_on_area_entered)
10: 	monitoring = false
```
- Inicia desactivada (`monitoring = false`) por seguridad.

```gdscript
12: func activate(data: AttackData, attacker: Node3D) -> void:
13: 	attack_data = data
14: 	owner_character = attacker
15: 	monitoring = true

17: func deactivate() -> void:
18: 	monitoring = false
```
- `activate` / `deactivate`: Controla la ventana de colisión durante la fase activa del ataque.

```gdscript
20: func _on_area_entered(area: Area3D) -> void:
21: 	if area is Hurtbox and area.owner_character != owner_character:
22: 		hit_registered.emit(area, attack_data)
23: 		area.take_hit(attack_data, owner_character)
```
- Al colisionar, verifica si la otra área es una `Hurtbox` y no pertenece al propio personaje atacante. Invoca `take_hit()` en la Hurtbox.

## Comunicación e Interacciones
- **Comunica con**: `Hurtbox.gd` (mediante `take_hit`), `Character.gd` (llamado por `execute_attack`).
