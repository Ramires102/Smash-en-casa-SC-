# Explicación de `characters/character.gd`

## Resumen
Controlador principal de personaje 2.5D (`CharacterBody3D`). Gestiona la carga de `CharacterData`, entradas, estado de porcentaje %, colisión de Hitbox/Hurtbox, recepción de golpes, física de movimiento y comunicación con la Máquina de Estados (FSM).

## Explicación Línea por Línea
```gdscript
1: class_name Character
2: extends CharacterBody3D
```
- Declara la clase `Character` heredando de `CharacterBody3D` (cuerpo de física 3D en Godot 4).

```gdscript
4: signal percentage_changed(new_percentage: float)
5: signal character_ko(player_id: int)
```
- Señales emitidas cuando el daño % cambia o el jugador es noqueado.

```gdscript
7: @export var player_id: int = 1
8: @export var character_data: CharacterData
```
- Exporta ID de jugador (1 o 2) y el `CharacterData` asignado.

```gdscript
10: var damage_percentage: float = 0.0
11: var move_speed: float = 8.0
12: var jump_velocity: float = 14.0
13: var weight: float = 100.0
14: var facing_direction: float = 1.0 # 1.0 = derecha, -1.0 = izquierda
```
- Variables de estado interno actualizadas dinámicamente mediante el Resource `CharacterData`.

```gdscript
16: @onready var state_machine: StateMachine = $StateMachine
17: @onready var hitbox: Hitbox = $Hitbox
18: @onready var hurtbox: Hurtbox = $Hurtbox
19: @onready var mesh_instance: MeshInstance3D = $MeshInstance3D
```
- Referencias directas a los nodos hijos de la escena.

```gdscript
21: func _ready() -> void:
22: 	if character_data:
23: 		load_character(character_data)
```
- Al iniciar, invoca `load_character()` si existe un `character_data` asignado.

```gdscript
25: func load_character(data: CharacterData) -> void:
26: 	character_data = data
27: 	move_speed = data.move_speed
28: 	jump_velocity = data.jump_velocity
29: 	weight = data.weight
30: 	if mesh_instance and mesh_instance.material_override:
31: 		var mat: StandardMaterial3D = mesh_instance.material_override.duplicate()
32: 		mat.albedo_color = data.character_color
33: 		mesh_instance.material_override = mat
```
- `load_character`: Carga los atributos físicos del Resource y cambia el color del material de la malla 3D.

```gdscript
35: func _physics_process(delta: float) -> void:
36: 	if not is_on_floor():
37: 		velocity.y += get_gravity_value() * delta
38: 	move_and_slide()
39: 	Helpers.constrain_to_2d_plane(self, Constants.Z_PLANE)
```
- Bucle de física: Aplica gravedad, ejecuta `move_and_slide()` y bloquea el eje Z en 0 con `Helpers.constrain_to_2d_plane()`.

```gdscript
44: func get_input_vector() -> Vector2:
45: 	return InputManager.get_move_vector(player_id)
```
- Delegación limpia de entradas al `InputManager`.

```gdscript
57: func get_current_attack() -> AttackData:
```
- Selecciona el `AttackData` adecuado según la dirección presionada (Neutral, Tilt, Air, Special).

```gdscript
78: func on_hit_received(attack_data: AttackData, attacker: Node3D) -> void:
```
- Procesa el impacto recibido: incrementa daño en %, calcula vector de retroceso con `KnockbackCalculator`, reproduce SFX y transiciona la FSM al estado `Hit`.

## Comunicación e Interacciones
- **Comunica con**: `InputManager`, `DamageCalculator`, `KnockbackCalculator`, `AudioManager`, `StateMachine`, `Hitbox`, `Hurtbox`, `HUD`.
