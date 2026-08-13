class_name Character
extends CharacterBody3D

signal percentage_changed(new_percentage: float)
signal character_ko(player_id: int)

# Constantes de Escudo y Mareo (Shield & Daze)
const MAX_SHIELD_HP: float = 50.0
const SHIELD_BREAK_RESPAWN_HP: float = 30.0
const SHIELD_DRAIN_RATE: float = 8.0

@export var player_id: int = 1
@export var character_data: CharacterData

@onready var controller: CharacterController = $Controller
@onready var stats: CharacterStats = $Stats
@onready var attack_controller: AttackController = $AttackController
@onready var anim_controller: AnimationController = $AnimationController
@onready var state_machine: StateMachine = $StateMachine
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox

var shield_health: float = 50.0
var shield_release_timer: float = 0.0

var move_speed: float:
	get: return controller.move_speed if controller else 8.0

var jump_velocity: float:
	get: return controller.jump_velocity if controller else 14.0

var damage_percentage: float:
	get: return stats.damage_percentage if stats else 0.0

var weight: float:
	get: return stats.weight if stats else 100.0

func _ready() -> void:
	if character_data:
		load_character(character_data)

func load_character(data: CharacterData) -> void:
	character_data = data
	if controller: controller.setup(data)
	if stats: stats.setup(data)
	if attack_controller: attack_controller.setup(data)
	
	if has_node("Humanoid"):
		var humanoid_node: Node3D = $Humanoid
<<<<<<< HEAD
		if data and data.model_scene:
			# Ocultar los meshes placeholder (excepto ShieldMesh y efectos)
			for child in humanoid_node.get_children():
				if child is MeshInstance3D and child.name != "ShieldMesh":
					child.visible = false
				elif child.name not in ["ShieldMesh", "DazeStars", "MenacingAura"]:
					if child is Node3D and child.name != "ModelRoot":
						child.visible = false
			# Eliminar modelo anterior si ya existia (para recargas)
			var old_model: Node = humanoid_node.get_node_or_null("ModelRoot")
			if old_model:
				old_model.queue_free()
			# Instanciar el modelo real
			var model_instance: Node3D = data.model_scene.instantiate()
			model_instance.name = "ModelRoot"
			model_instance.position = data.model_offset
			var s: float = data.model_scale
			model_instance.scale = Vector3(s, s, s)
			humanoid_node.add_child(model_instance)
		else:
			# Fallback: meshes placeholder con color del personaje
			var mat := StandardMaterial3D.new()
			mat.albedo_color = data.character_color if data else Color.WHITE
			for child in humanoid_node.get_children():
				if child is MeshInstance3D and child.name != "ShieldMesh" and child.name != "DazeStars":
					child.material_override = mat
					child.visible = true
=======
		var mat := StandardMaterial3D.new()
		mat.albedo_color = data.character_color
		_apply_material_recursive(humanoid_node, mat)
>>>>>>> fe9df12bbf99b5edd5976e0a9bc83f58365ed2be

func _apply_material_recursive(node: Node, mat: Material) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and child.name != "ShieldMesh":
			child.material_override = mat
		_apply_material_recursive(child, mat)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += get_gravity_value() * delta

	move_and_slide()
	Helpers.constrain_to_2d_plane(self, Constants.Z_PLANE)

func get_gravity_value() -> float:
	return -30.0

func get_input_vector() -> Vector2:
	return controller.get_input_vector(player_id) if controller else InputManager.get_move_vector(player_id)

func is_jump_just_pressed() -> bool:
	return InputManager.is_jump_pressed(player_id)

func is_attack_just_pressed() -> bool:
	return InputManager.is_attack_pressed(player_id) or InputManager.is_special_pressed(player_id)

func is_shield_pressed() -> bool:
	return InputManager.is_shield_pressed(player_id)

func update_facing_direction(input_x: float) -> void:
	if controller:
		controller.apply_horizontal_movement(input_x)

func get_current_attack() -> AttackData:
	return attack_controller.get_attack_data_for_input(player_id, get_input_vector(), is_on_floor()) if attack_controller else null

func execute_attack(attack_data: AttackData) -> void:
	if attack_controller:
		attack_controller.start_attack(attack_data, self)
		attack_controller.enable_hitbox(attack_data, self)

func deactivate_hitbox() -> void:
	if attack_controller:
		attack_controller.disable_hitbox()

func break_shield() -> void:
	shield_health = 0.0
	state_machine.transition_to("Daze")

func update_shield_scale() -> void:
	if has_node("Humanoid/ShieldMesh"):
		var shield_mesh: Node3D = $Humanoid/ShieldMesh
		var scale_ratio: float = clamp(shield_health / MAX_SHIELD_HP, 0.2, 1.0)
		shield_mesh.scale = Vector3.ONE * scale_ratio

func set_daze_effects_enabled(_enabled: bool) -> void:
	pass

func update_daze_effects(_delta: float, _daze_timer: float) -> void:
	pass

func on_hit_received(attack_data: AttackData, attacker: Node3D) -> void:
	var new_percent: float = stats.add_damage(attack_data.damage)
	percentage_changed.emit(new_percent)
	Events.player_damaged.emit(player_id, new_percent, attack_data)
	
	var attacker_facing: float = 1.0
	if attacker and attacker.has_method("get_facing_direction"):
		attacker_facing = attacker.get_facing_direction()
	elif attacker:
		attacker_facing = sign(global_position.x - attacker.global_position.x)
		if attacker_facing == 0.0: attacker_facing = 1.0
			
	var knockback_vec: Vector3 = KnockbackCalculator.calculate_knockback_vector(
		new_percent,
		attack_data.damage,
		stats.weight,
		attack_data.base_knockback,
		attack_data.knockback_scaling,
		attack_data.angle_degrees,
		attacker_facing
	)
	
	AudioManager.play_sfx(attack_data.hit_sfx)
	state_machine.transition_to("Hit", {"knockback": knockback_vec})

func get_facing_direction() -> float:
	return controller.facing_direction if controller else 1.0

func reset_player(spawn_position: Vector3) -> void:
	global_position = spawn_position
	velocity = Vector3.ZERO
	if stats: stats.reset()
	shield_health = MAX_SHIELD_HP
	percentage_changed.emit(0.0)
	visible = true
	state_machine.transition_to("Idle")
