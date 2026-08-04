class_name Character
extends CharacterBody3D

signal percentage_changed(new_percentage: float)
@warning_ignore("unused_signal")
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

# Convenience accessors (Smash scaled to Godot units via controller)
var move_speed: float:
	get: return controller.get_run_speed() if controller else 10.0

var jump_velocity: float:
	get: return controller.get_jump_velocity() if controller else 14.0

var damage_percentage: float:
	get: return stats.damage_percentage if stats else 0.0

var weight: float:
	get: return stats.weight if stats else 100.0

var pushbox_radius: float = 0.5

const MAX_SHIELD_HEALTH: float = 50.0
const SHIELD_DAMAGE_MULTIPLIER: float = 1.19
const SHIELD_DRAIN_RATE: float = 9.0
const SHIELD_REGEN_RATE: float = 4.8
const SHIELD_BREAK_RESPAWN_HP: float = 37.5

var shield_health: float = 50.0
var shield_release_timer: float = 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	if character_data:
		load_character(character_data)

func load_character(data: CharacterData) -> void:
	character_data = data
	if controller: controller.setup(data)
	if stats: stats.setup(data)
	if attack_controller: attack_controller.setup(data)
	if data:
		pushbox_radius = data.pushbox_radius

	if has_node("Humanoid"):
		var humanoid_node: Node3D = $Humanoid
		var mat := StandardMaterial3D.new()
		mat.albedo_color = data.character_color if data else Color.WHITE
		for child in humanoid_node.get_children():
			if child is MeshInstance3D and child.name != "ShieldMesh" and child.name != "DazeStars":
				child.material_override = mat
				child.visible = true

func set_daze_effects_enabled(enabled: bool) -> void:
	_ensure_daze_stars()
	if has_node("Humanoid/DazeStars"):
		$Humanoid/DazeStars.visible = enabled
	
	if not enabled and character_data:
		load_character(character_data)

func update_daze_effects(delta: float, timer: float) -> void:
	_ensure_daze_stars()
	if has_node("Humanoid/DazeStars"):
		$Humanoid/DazeStars.rotation_degrees.y += 400.0 * delta

	if has_node("Humanoid"):
		var is_flash_red: bool = fmod(timer, 0.2) < 0.1
		var flash_color: Color = Color(1.5, 0.1, 0.1, 1.0) if is_flash_red else (character_data.character_color if character_data else Color.WHITE)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = flash_color
		if is_flash_red:
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.0, 0.0, 1.0)
			mat.emission_energy_multiplier = 2.0
		
		for child in $Humanoid.get_children():
			if child is MeshInstance3D and child.name != "ShieldMesh" and child.name != "DazeStars":
				child.material_override = mat

func _ensure_daze_stars() -> void:
	if has_node("Humanoid") and not has_node("Humanoid/DazeStars"):
		var stars_pivot := Node3D.new()
		stars_pivot.name = "DazeStars"
		stars_pivot.position = Vector3(0, 1.0, 0)
		stars_pivot.visible = false
		$Humanoid.add_child(stars_pivot)
		
		var star_mat := StandardMaterial3D.new()
		star_mat.albedo_color = Color(1.0, 0.9, 0.1)
		star_mat.emission_enabled = true
		star_mat.emission = Color(1.0, 0.85, 0.0)
		star_mat.emission_energy_multiplier = 3.0
		
		var star_mesh := PrismMesh.new()
		star_mesh.size = Vector3(0.12, 0.12, 0.12)
		
		for i in range(3):
			var angle: float = float(i) * (TAU / 3.0)
			var star_inst := MeshInstance3D.new()
			star_inst.mesh = star_mesh
			star_inst.material_override = star_mat
			star_inst.position = Vector3(cos(angle) * 0.45, 0.0, sin(angle) * 0.45)
			stars_pivot.add_child(star_inst)

var _menacing_timer: float = 0.0

func _ensure_menacing_aura() -> void:
	if has_node("Humanoid") and not has_node("Humanoid/MenacingAura"):
		var aura_node := Node3D.new()
		aura_node.name = "MenacingAura"
		aura_node.position = Vector3(0, 0.4, 0)
		aura_node.visible = false
		$Humanoid.add_child(aura_node)

		var tex_path: String = "res://assets/images/jojo_menacing.png"
		if ResourceLoader.exists(tex_path):
			var tex := load(tex_path) as Texture2D
			var sprite := Sprite3D.new()
			sprite.texture = tex
			sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			sprite.pixel_size = 0.0028
			sprite.transparent = true
			sprite.alpha_cut = Sprite3D.ALPHA_CUT_DISCARD
			sprite.name = "MenacingSprite_0"
			aura_node.add_child(sprite)

func set_menacing_aura_enabled(enabled: bool) -> void:
	if character_data and character_data.character_name == "John Placeholder":
		_ensure_menacing_aura()
		if has_node("Humanoid/MenacingAura"):
			$Humanoid/MenacingAura.visible = enabled

func update_menacing_aura(delta: float) -> void:
	if not (character_data and character_data.character_name == "John Placeholder"):
		return
	_ensure_menacing_aura()
	if not has_node("Humanoid/MenacingAura"):
		return

	var aura: Node3D = $Humanoid/MenacingAura
	if not aura.visible:
		return

	_menacing_timer += delta * 2.0
	var sprite: Sprite3D = aura.get_node_or_null("MenacingSprite_0") as Sprite3D
	if sprite:
		var base_pos := Vector3(0.20, 0.85, -0.20) # Flotando justo detrás de la espalda de John Placeholder
		var float_y: float = sin(_menacing_timer * 1.8) * 0.08
		var float_x: float = cos(_menacing_timer * 0.6) * 0.03
		sprite.position = base_pos + Vector3(float_x, float_y, 0)
		var pulse: float = 1.0 + sin(_menacing_timer * 1.5) * 0.06
		sprite.scale = Vector3(pulse, pulse, pulse)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		var input_vec: Vector2 = get_input_vector()
		var grav: float = controller.get_gravity_value() if controller else 30.0
		var fs: float = controller.get_fall_speed() if controller else 10.0
		var ffs: float = controller.get_fast_fall_speed() if controller else 16.0
		var term_vel: float = -ffs if input_vec.y < -0.5 else -fs
		velocity.y = max(term_vel, velocity.y - grav * delta)

	if shield_release_timer > 0.0:
		shield_release_timer -= delta

	if not is_shielding():
		shield_health = move_toward(shield_health, MAX_SHIELD_HEALTH, SHIELD_REGEN_RATE * delta)

	_handle_ecb_and_pushbox_collisions(delta)

	move_and_slide()
	Helpers.constrain_to_2d_plane(self, Constants.Z_PLANE)

func _handle_ecb_and_pushbox_collisions(delta: float) -> void:
	var parent_node := get_parent()
	if not parent_node:
		return
	var current_state_name: String = state_machine.current_state.name if (state_machine and state_machine.current_state) else ""
	var is_cross_through_state: bool = current_state_name in ["Dash", "Run", "Roll"]

	for other in parent_node.get_children():
		if other is Character and other != self and other.visible:
			var dx: float = global_position.x - other.global_position.x
			var dy: float = global_position.y - other.global_position.y
			var min_dist: float = pushbox_radius + other.pushbox_radius
			
			var other_state_name: String = other.state_machine.current_state.name if (other.state_machine and other.state_machine.current_state) else ""
			var other_cross_through: bool = other_state_name in ["Dash", "Run", "Roll"]

			# 1. ECB Head Sliding (Resbalarse de la cabeza de un rival al caer o saltar sobre él)
			if dy > 0.35 and dy < 2.0 and abs(dx) < min_dist * 0.95:
				var push_side: float = 1.0 if dx >= 0.0 else -1.0
				velocity.x += push_side * 14.0 * delta
			
			# 2. Pushbox Ground Collisions (Caminar/Reposo = empujar sólido / Correr o Rodar = atravesar)
			elif is_on_floor() and other.is_on_floor() and abs(dy) < 1.0:
				if abs(dx) < min_dist and abs(dx) > 0.001:
					if not is_cross_through_state and not other_cross_through:
						var overlap: float = min_dist - abs(dx)
						var push_dir: float = 1.0 if dx >= 0.0 else -1.0
						global_position.x += push_dir * (overlap * 0.5)

func get_gravity_value() -> float:
	return -(controller.get_gravity_value() if controller else 30.0)

func get_input_vector() -> Vector2:
	return controller.get_input_vector(player_id) if controller else InputManager.get_move_vector(player_id)

func is_jump_just_pressed() -> bool:
	return InputManager.is_jump_pressed(player_id)

func is_attack_just_pressed() -> bool:
	return InputManager.is_attack_pressed(player_id) or InputManager.is_special_pressed(player_id)

func is_shield_pressed() -> bool:
	return InputManager.is_shield_pressed(player_id)

func set_facing_direction(dir: float) -> void:
	if controller:
		controller.set_facing_direction(dir)

func update_facing_direction(input_x: float) -> void:
	if input_x != 0.0:
		set_facing_direction(sign(input_x))

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
	if is_shielding() or shield_release_timer > 0.0:
		_on_shield_block(attack_data, attacker)
		return

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

func is_shielding() -> bool:
	return state_machine and state_machine.current_state and state_machine.current_state.name == "Shield"

func _on_shield_block(attack_data: AttackData, attacker: Node3D) -> void:
	if shield_release_timer > 0.0:
		_execute_parry(attack_data, attacker)
		return

	velocity.x = 0.0 # El luchador no retrocede
	
	var bonus: float = attack_data.bonus_shield_damage if attack_data and "bonus_shield_damage" in attack_data else 0.0
	var shield_damage: float = (attack_data.damage * SHIELD_DAMAGE_MULTIPLIER) + bonus
	shield_health -= shield_damage
	update_shield_scale()

	var mult: float = 0.33 if (attack_data and "is_aerial" in attack_data and attack_data.is_aerial) else 1.0
	var shieldstun_frames: int = int(floor(attack_data.damage * 0.8 * mult + 2.0))
	var shieldstun_time: float = float(shieldstun_frames) / 60.0

	Events.camera_shake_requested.emit(3.0)
	var attacker_id: int = 0
	if attacker and "player_id" in attacker:
		attacker_id = attacker.player_id
	Events.attack_blocked.emit(player_id, attacker_id)
	
	if state_machine and state_machine.current_state and state_machine.current_state.has_method("apply_shieldstun"):
		state_machine.current_state.apply_shieldstun(shieldstun_time)
	
	if shield_health <= 0.0:
		break_shield()

func _execute_parry(_attack_data: AttackData, _attacker: Node3D) -> void:
	velocity.x = 0.0
	Events.camera_shake_requested.emit(6.0)
	Events.parry_executed.emit(player_id)

func update_shield_scale() -> void:
	if has_node("Humanoid/ShieldMesh"):
		var shield_mesh: Node3D = $Humanoid/ShieldMesh
		var ratio: float = clamp(shield_health / MAX_SHIELD_HEALTH, 0.0, 1.0)
		shield_mesh.scale = Vector3(ratio, ratio, ratio)

func break_shield() -> void:
	shield_health = SHIELD_BREAK_RESPAWN_HP
	if has_node("Humanoid/ShieldMesh"):
		$Humanoid/ShieldMesh.visible = false
	Events.camera_shake_requested.emit(10.0)
	Events.shield_broken.emit(player_id)
	velocity = Vector3(0.0, 10.0, 0.0)
	state_machine.transition_to("Daze")

func get_facing_direction() -> float:
	return controller.facing_direction if controller else 1.0

func reset_player(spawn_position: Vector3) -> void:
	global_position = spawn_position
	velocity = Vector3.ZERO
	if stats: stats.reset()
	shield_health = MAX_SHIELD_HEALTH
	update_shield_scale()
	percentage_changed.emit(0.0)
	visible = true
	var initial_facing: float = 1.0 if player_id == 1 else -1.0
	set_facing_direction(initial_facing)
	state_machine.transition_to("Idle")
