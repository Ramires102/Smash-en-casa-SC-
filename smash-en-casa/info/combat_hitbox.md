# Explicación de `combat/hitbox.gd`

## Resumen
Subclase de `Area3D` que representa la zona ofensiva de un ataque. Detecta cuando se solapa con una `Hurtbox` enemiga y emite las señales correspondientes enviando los datos del `AttackData`. Incluye comprobación de solapes inmediatos y un registro de Hurtboxes impactadas (`hit_hurtboxes`) para evitar golpes duplicados en un mismo ataque.

## Explicación Línea por Línea
```gdscript
1: class_name Hitbox
2: extends Area3D

4: signal hit_registered(hurtbox: Hurtbox, attack_data: AttackData)
5: @export var attack_data: AttackData
6: var owner_character: Node3D = null
7: var hit_hurtboxes: Array[Hurtbox] = []
```
- Declara la señal `hit_registered`, la referencia al `AttackData` activo, al atacante (`owner_character`) y el array `hit_hurtboxes` para evitar sobre-impactos.

```gdscript
9: func _ready() -> void:
10: 	if owner_character == null:
11: 		owner_character = get_parent()
12: 	area_entered.connect(_on_area_entered)
13: 	monitoring = false
```
- Asigna al personaje padre por defecto e inicia la colisión desactivada (`monitoring = false`).

```gdscript
15: func activate(data: AttackData, attacker: Node3D) -> void:
16: 	attack_data = data
17: 	owner_character = attacker if attacker != null else get_parent()
18: 	hit_hurtboxes.clear()
19: 	monitoring = true
20: 	call_deferred("_check_immediate_overlaps")
```
- `activate`: Limpia los impactos previos, activa el monitoreo de colisión y comprueba inmediatamente las áreas solapadas al instanciarse.

```gdscript
27: func deactivate() -> void:
28: 	monitoring = false
29: 	hit_hurtboxes.clear()
```
- Cierra la ventana ofensiva y restablece el filtro de Hurtboxes.

```gdscript
31: func _on_area_entered(area: Area3D) -> void:
32: 	if not monitoring: return
33: 	if area is Hurtbox and area not in hit_hurtboxes:
34: 		var target_owner: Node3D = area.owner_character
35: 		if target_owner == null: target_owner = area.get_parent()
36: 		if target_owner != owner_character:
37: 			hit_hurtboxes.append(area)
38: 			hit_registered.emit(area, attack_data)
39: 			area.take_hit(attack_data, owner_character)
```
- Valida que el objetivo sea una `Hurtbox` válida, no registrada en la ráfaga actual y perteneciente a un oponente diferente al dueño del ataque.

## Comunicación e Interacciones
- **Comunica con**: `Hurtbox.gd` (mediante `take_hit`) y `AttackController.gd`.
