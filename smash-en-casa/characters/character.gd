class_name Character
extends CharacterBody3D

signal percentage_changed(new_percentage: float)
signal character_ko(player_id: int)

@export var player_id: int = 1
@export var character_data: CharacterData

@onready var controller: CharacterController = $Controller
@onready var stats: CharacterStats = $Stats
@onready var attack_controller: AttackController = $AttackController
@onready var anim_controller: AnimationController = $AnimationController
@onready var state_machine: StateMachine = $StateMachine
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox

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
		var mat := StandardMaterial3D.new()
		mat.albedo_color = data.character_color
		for child in humanoid_node.get_children():
			if child is MeshInstance3D and child.name != "ShieldMesh":
				child.material_override = mat

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
	percentage_changed.emit(0.0)
	visible = true
	state_machine.transition_to("Idle")
