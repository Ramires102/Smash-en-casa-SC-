class_name Character
extends CharacterBody2D

signal percentage_changed(new_percentage: float)
@warning_ignore("unused_signal")
signal character_ko(player_id: int)

# Constantes de Escudo y Mareo (Shield & Daze)
const MAX_SHIELD_HP: float = 50.0
const SHIELD_BREAK_RESPAWN_HP: float = 30.0
const SHIELD_DRAIN_RATE: float = 8.0
const INPUT_BUFFER_WINDOW_SEC: float = 0.12
const COYOTE_TIME_SEC: float = 0.08

# Contrato minimo de nodos para Character.tscn
const REQUIRED_NODE_PATHS: Array[NodePath] = [
	NodePath("Controller"),
	NodePath("Stats"),
	NodePath("AttackController"),
	NodePath("AnimationController"),
	NodePath("StateMachine"),
	NodePath("Hitbox"),
	NodePath("Hurtbox")
]

@export var player_id: int = 1
@export var character_data: CharacterData
@export var visual_root_3d: Node3D = null  ## Contenedor 3D visual para renderizado

@onready var controller: CharacterController = $Controller
@onready var stats: CharacterStats = $Stats
@onready var attack_controller: AttackController = $AttackController
@onready var anim_controller: AnimationController = $AnimationController
@onready var state_machine: StateMachine = $StateMachine
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox

var shield_health: float = 50.0
var shield_release_timer: float = 0.0
var current_input: PlayerInput = PlayerInput.new()
var _intent_buffer: InputBuffer = InputBuffer.new()
var _coyote_timer: float = 0.0
var _previous_input_y: float = 0.0
var _down_just_pressed: bool = false
var _previous_shield_pressed: bool = false
var _shield_just_pressed: bool = false

# Variables de Ledge Grab (2D)
var snapped_ledge: LedgePoint = null
var ledge_regrab_timer: float = 0.0
var can_grab_ledge: bool = true

# Movilidad Aérea (Doble Salto & Air Dodge)
var max_air_jumps: int = 1
var air_jumps_left: int = 1
var can_air_dodge: bool = true

var damage_percentage: float:
	get: return stats.damage_percentage if stats else 0.0

var weight: float:
	get: return stats.weight if stats else 100.0

# Variables de Time Stop (Acumulación Cinética 2D)
var accumulated_timestop_knockback: Vector2 = Vector2.ZERO
var accumulated_timestop_hitstun: int = 0
var timestop_shiver_timer: float = 0.0

var can_act: bool = true
var is_fast_falling: bool = false
var _self_hitlag_remaining: int = 0

func _ready() -> void:
	if not _validate_required_nodes():
		set_physics_process(false)
		return

	_intent_buffer.buffer_window_seconds = INPUT_BUFFER_WINDOW_SEC
	_coyote_timer = COYOTE_TIME_SEC

	var ledge_det: Area2D = get_node_or_null("LedgeDetector")
	if ledge_det:
		ledge_det.area_entered.connect(_on_ledge_detector_area_entered)

	add_to_group("characters")
	Events.time_stop_started.connect(_on_time_stop_started)
	Events.time_stop_ended.connect(_on_time_stop_ended)

	if character_data:
		configure(character_data)

	if visual_root_3d == null and has_node("Humanoid"):
		visual_root_3d = $Humanoid

func _exit_tree() -> void:
	if Events.time_stop_started.is_connected(_on_time_stop_started):
		Events.time_stop_started.disconnect(_on_time_stop_started)
	if Events.time_stop_ended.is_connected(_on_time_stop_ended):
		Events.time_stop_ended.disconnect(_on_time_stop_ended)

func _validate_required_nodes() -> bool:
	var is_valid: bool = true
	for required_path in REQUIRED_NODE_PATHS:
		if get_node_or_null(required_path) == null:
			push_error("Character contract violation: missing required node '%s'" % required_path)
			is_valid = false
	return is_valid

## Configura el personaje con sus datos y modelo 3D
func configure(data: CharacterData) -> void:
	character_data = data
	if not data:
		return
	
	if controller: controller.setup(data)
	if stats: stats.setup(data)
	if attack_controller: attack_controller.setup(data)
	_setup_visuals(data)
	if anim_controller and anim_controller.has_method("setup"):
		anim_controller.setup(data)
	elif has_node("AnimationController"):
		get_node("AnimationController").setup(data)


func _setup_visuals(data: CharacterData) -> void:
	if visual_root_3d == null:
		visual_root_3d = get_node_or_null("Humanoid")
	if visual_root_3d == null:
		return
		
	if data.model_scene:
		for child in visual_root_3d.get_children():
			if child.name.begins_with("Debug") or child.name in ["ShieldMesh", "DazeStars", "MenacingAura", "ModelRoot"]:
				continue
			if child is CanvasItem or child is Node3D:
				child.visible = false
					
		var old_model: Node = visual_root_3d.get_node_or_null("ModelRoot")
		if old_model:
			old_model.queue_free()
			
		var model_instance: Node3D = data.model_scene.instantiate()
		model_instance.name = "ModelRoot"
		model_instance.position = data.model_offset
		var s: float = data.model_scale
		model_instance.scale = Vector3(s, s, s)
		visual_root_3d.add_child(model_instance)
	else:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = data.character_color
		_apply_material_recursive(visual_root_3d, mat)

func _apply_material_recursive(node: Node, mat: Material) -> void:
	for child in node.get_children():
		if child.name.begins_with("Debug") or child.name in ["ShieldMesh", "DazeStars", "MenacingAura"]:
			continue
		if child is MeshInstance3D:
			child.material_override = mat
			child.visible = true
		_apply_material_recursive(child, mat)

func _process(delta: float) -> void:
	_sync_3d_visuals(delta)

## Sincroniza la posición y rotación del modelo 3D con el cuerpo 2D
func _sync_3d_visuals(delta: float) -> void:
	if visual_root_3d == null:
		return
		
	# Mapeo 2D a 3D: X es X / UNIT_SIZE, Y es -Y / UNIT_SIZE
	var target_3d_pos := Vector3(
		global_position.x / Constants.UNIT_SIZE,
		-global_position.y / Constants.UNIT_SIZE,
		0.0
	)
	
	if timestop_shiver_timer > 0.0:
		timestop_shiver_timer -= delta
		target_3d_pos.x += randf_range(-0.06, 0.06)
		
	visual_root_3d.global_position = target_3d_pos

func update_visual_rotation(dir: float) -> void:
	if visual_root_3d:
		visual_root_3d.rotation_degrees.y = 90.0 if dir > 0 else -90.0

func _physics_process(delta: float) -> void:
	# ── Congelación Física Total durante Time Stop ──
	if Events.is_time_stopped and self != Events.time_stop_instigator:
		velocity = Vector2.ZERO
		return

	if _self_hitlag_remaining > 0:
		_self_hitlag_remaining -= 1
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if ledge_regrab_timer > 0.0:
		ledge_regrab_timer -= delta

	current_input = InputManager.get_player_input(player_id)
	_update_directional_input_edges()
	_update_button_input_edges()
	_register_input_intents()
	_update_coyote_timer(delta)

	if not is_on_floor():
		velocity.y += get_gravity_value() * delta
		var max_fall: float = get_terminal_fall_speed()
		if velocity.y > max_fall:
			velocity.y = max_fall
	else:
		is_fast_falling = false
		air_jumps_left = max_air_jumps
		can_air_dodge = true
		ledge_regrab_timer = 0.0

	move_and_slide()

func get_gravity_value() -> float:
	return controller.get_gravity_value() if controller else 1320.0

func get_terminal_fall_speed() -> float:
	return controller.get_terminal_fall_speed(is_fast_falling) if controller else 500.0

func _register_input_intents() -> void:
	if current_input.jump_pressed:
		_intent_buffer.register_action("jump")
	if current_input.attack_pressed:
		_intent_buffer.register_action("attack")
	if current_input.special_pressed:
		_intent_buffer.register_action("special")

func _update_coyote_timer(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = COYOTE_TIME_SEC
	elif _coyote_timer > 0.0:
		_coyote_timer = maxf(0.0, _coyote_timer - delta)

func _consume_buffered_action(action_name: String, raw_pressed: bool) -> bool:
	if raw_pressed:
		_intent_buffer.consume_action(action_name)
		return true
	if _intent_buffer.is_action_buffered(action_name):
		_intent_buffer.consume_action(action_name)
		return true
	return false

func has_coyote_jump() -> bool:
	return _coyote_timer > 0.0

func consume_coyote_jump() -> void:
	_coyote_timer = 0.0

# ── Consultas de Intenciones (PlayerInput) ──────────────────────────────────
func get_input_vector() -> Vector2:
	if not can_act:
		return Vector2.ZERO
	return current_input.movement

func is_dash_intent() -> bool:
	if not can_act:
		return false
	return current_input.is_dash

func is_jump_just_pressed() -> bool:
	if not can_act:
		return false
	return _consume_buffered_action("jump", current_input.jump_pressed)

func is_jump_held() -> bool:
	if not can_act:
		return false
	return current_input.jump_held

func is_attack_just_pressed() -> bool:
	if not can_act:
		return false
	var normal_intent: bool = _consume_buffered_action("attack", current_input.attack_pressed)
	var special_intent: bool = _consume_buffered_action("special", current_input.special_pressed)
	return normal_intent or special_intent

func is_normal_attack_pressed() -> bool:
	if not can_act:
		return false
	return _consume_buffered_action("attack", current_input.attack_pressed)

func is_special_attack_pressed() -> bool:
	if not can_act:
		return false
	return _consume_buffered_action("special", current_input.special_pressed)

func is_shield_pressed() -> bool:
	if not can_act:
		return false
	return current_input.shield_pressed

func is_shield_just_pressed() -> bool:
	if not can_act:
		return false
	return _shield_just_pressed

func is_down_just_pressed() -> bool:
	return _down_just_pressed

func _update_directional_input_edges() -> void:
	var current_y: float = current_input.movement.y if current_input else 0.0
	_down_just_pressed = _previous_input_y >= -0.55 and current_y < -0.55
	_previous_input_y = current_y

func _update_button_input_edges() -> void:
	var current_shield: bool = current_input.shield_pressed if current_input else false
	_shield_just_pressed = (not _previous_shield_pressed) and current_shield
	_previous_shield_pressed = current_shield

func update_facing_direction(input_x: float) -> void:
	if controller and can_act:
		controller.set_facing_direction(input_x)

func set_facing_direction(dir: float) -> void:
	if controller:
		controller.set_facing_direction(dir)

func get_facing_direction() -> float:
	return controller.facing_direction if controller else 1.0

func get_current_attack() -> AttackData:
	return attack_controller.get_attack_data_for_input(current_input, is_on_floor(), get_facing_direction()) if attack_controller else null

func execute_attack(attack_data: AttackData) -> void:
	if attack_controller:
		attack_controller.start_attack(attack_data, self)

func activate_hitbox(attack_data: AttackData) -> void:
	if attack_controller:
		attack_controller.enable_hitbox(attack_data, self)

func deactivate_hitbox() -> void:
	if attack_controller:
		attack_controller.disable_hitbox()

func break_shield() -> void:
	shield_health = 0.0
	state_machine.transition_to("Daze")

func update_shield_scale() -> void:
	if visual_root_3d and visual_root_3d.has_node("ShieldMesh"):
		var shield_mesh: Node3D = visual_root_3d.get_node("ShieldMesh")
		var scale_ratio: float = clamp(shield_health / MAX_SHIELD_HP, 0.2, 1.0)
		shield_mesh.scale = Vector3.ONE * scale_ratio

func set_menacing_aura_enabled(enabled: bool) -> void:
	if visual_root_3d:
		var aura_node: Node3D = visual_root_3d.get_node_or_null("MenacingAura")
		if aura_node:
			aura_node.visible = enabled

func update_menacing_aura(delta: float) -> void:
	if visual_root_3d:
		var aura_node: Node3D = visual_root_3d.get_node_or_null("MenacingAura")
		if aura_node and aura_node.visible:
			aura_node.rotate_y(delta * 1.2)

func set_daze_effects_enabled(enabled: bool) -> void:
	if visual_root_3d:
		var stars: Node3D = visual_root_3d.get_node_or_null("DazeStars")
		if stars:
			stars.visible = enabled

func update_daze_effects(delta: float, _timer: float) -> void:
	if visual_root_3d:
		var stars: Node3D = visual_root_3d.get_node_or_null("DazeStars")
		if stars and stars.visible:
			stars.rotate_y(delta * 4.0)

func _is_current_state(state_name: String) -> bool:
	if state_machine == null or state_machine.current_state == null:
		return false
	return state_machine.current_state.name.to_lower() == state_name.to_lower()

func _compute_impact_shake_intensity(impact: ImpactData, is_blocked: bool = false) -> float:
	if impact == null or is_blocked:
		return 0.0
	# En Smash, los golpes estándar (jabs, tilts, proyectiles) no sacuden la cámara.
	# Solo activamos un impacto sutil en remates con alto knockback (KB >= 35.0 o Daño >= 16.0).
	if impact.knockback_magnitude < 35.0 and impact.damage < 16.0:
		return 0.0
	var value: float = 8.0 + (impact.damage * 0.12) + (impact.knockback_magnitude * 0.08)
	return clampf(value, 8.0, 12.0)

func _apply_shield_pushback(impact: ImpactData) -> void:
	if impact == null:
		return

	var away_dir: float = -impact.attacker_facing
	if impact.attacker and "global_position" in impact.attacker:
		away_dir = signf(global_position.x - impact.attacker.global_position.x)
	if absf(away_dir) < 0.01:
		away_dir = 1.0

	var push_speed: float = Constants.SHIELD_PUSHBACK_BASE + (impact.knockback_magnitude * Constants.SHIELD_PUSHBACK_KB_MULT)
	push_speed = clampf(push_speed, Constants.SHIELD_PUSHBACK_BASE, Constants.SHIELD_PUSHBACK_MAX)
	velocity.x = away_dir * push_speed

	if impact.attacker is Character:
		var attacker_character: Character = impact.attacker as Character
		if attacker_character:
			attacker_character.velocity.x = -away_dir * push_speed * Constants.SHIELD_ATTACKER_PUSHBACK_MULT

func _handle_shield_impact(impact: ImpactData) -> bool:
	if impact == null:
		return false
	if not _is_current_state("shield"):
		return false

	var bonus_shield_damage: float = 0.0
	if impact and impact.attack_data:
		bonus_shield_damage = impact.attack_data.bonus_shield_damage
	var shield_damage: float = maxf(0.0, impact.damage + bonus_shield_damage)

	shield_health = maxf(0.0, shield_health - shield_damage)
	update_shield_scale()

	Events.attack_blocked.emit(player_id, impact.attacker_id)
	if impact.attack_data and impact.attack_data.hit_sfx:
		AudioManager.play_sfx(impact.attack_data.hit_sfx, 0.85)

	if shield_health <= 0.0:
		Events.shield_broken.emit(player_id)
		Events.camera_shake_requested.emit(8.5)
		break_shield()
		return true

	var shieldstun_frames: int = maxi(2, int(floor((shield_damage * Constants.SHIELD_STUN_DAMAGE_MULT) + Constants.SHIELD_STUN_BASE_FRAMES)))
	if state_machine and state_machine.current_state and state_machine.current_state.has_method("apply_shieldstun"):
		state_machine.current_state.call("apply_shieldstun", float(shieldstun_frames) / 60.0)

	_apply_shield_pushback(impact)
	return true

func on_impact_received(impact: ImpactData) -> void:
	if impact == null:
		return
	if Events.is_time_stopped and self == Events.time_stop_instigator:
		return

	if _handle_shield_impact(impact):
		return

	var new_percent: float = stats.add_damage(impact.damage)
	impact.target_percent_after = new_percent
	percentage_changed.emit(new_percent)
	Events.player_damaged.emit(player_id, new_percent, impact)
	
	var shake_val: float = _compute_impact_shake_intensity(impact, false)
	if shake_val > 0.0:
		Events.camera_shake_requested.emit(shake_val)
	
	if impact.attack_data and impact.attack_data.hit_sfx:
		AudioManager.play_sfx(impact.attack_data.hit_sfx)

	# ── Acumulación Cinética durante Time Stop ──
	if Events.is_time_stopped and self != Events.time_stop_instigator:
		accumulated_timestop_knockback += impact.knockback_vector * 0.95
		accumulated_timestop_hitstun = maxi(accumulated_timestop_hitstun, impact.hitstun_frames)
		timestop_shiver_timer = 0.2
		Events.camera_shake_requested.emit(5.0)
		return
	
	state_machine.transition_to("Hit", {
		"knockback": impact.knockback_vector,
		"hitstun_frames": impact.hitstun_frames,
		"hitlag_frames": impact.hitlag_frames,
		"knockback_scalar": impact.knockback_magnitude,
		"hdecay": impact.hdecay,
		"vdecay": impact.vdecay,
		"impact": impact
	})

func _on_time_stop_started(_duration: float, _instigator: Node) -> void:
	if self != Events.time_stop_instigator:
		velocity = Vector2.ZERO
		accumulated_timestop_knockback = Vector2.ZERO
		accumulated_timestop_hitstun = 0

func _on_time_stop_ended() -> void:
	if self != Events.time_stop_instigator and accumulated_timestop_knockback.length_squared() > 1.0:
		var final_kb := accumulated_timestop_knockback
		var final_stun := maxi(24, accumulated_timestop_hitstun)
		accumulated_timestop_knockback = Vector2.ZERO
		accumulated_timestop_hitstun = 0
		
		Events.camera_shake_requested.emit(14.0)
		state_machine.transition_to("Hit", {
			"knockback": final_kb,
			"hitstun_frames": final_stun,
			"hitlag_frames": 8,
			"knockback_scalar": final_kb.length() / Constants.KB_VELOCITY_SCALE,
			"hdecay": 0.0,
			"vdecay": 0.0,
			"impact": null
		})

func snap_to_ledge(ledge: LedgePoint) -> void:
	if not can_grab_ledge or ledge_regrab_timer > 0.0 or is_on_floor():
		return
	if ledge == null or not ledge.can_occupy(self):
		return

	if state_machine and state_machine.current_state:
		var st_name: String = state_machine.current_state.name.to_lower()
		if st_name in ["daze", "death", "ledge", "ledgegetup"]:
			return

	snapped_ledge = ledge
	air_jumps_left = max_air_jumps
	can_air_dodge = true
	state_machine.transition_to("Ledge", {"ledge": ledge})

func release_ledge(cooldown_sec: float = 0.6) -> void:
	if snapped_ledge:
		snapped_ledge.release(self)
		snapped_ledge = null
	ledge_regrab_timer = cooldown_sec

func _on_ledge_detector_area_entered(area: Area2D) -> void:
	if area is LedgePoint and area.is_in_group("LedgePoint"):
		if not is_on_floor() and velocity.y >= -50.0:
			snap_to_ledge(area as LedgePoint)

func set_hurtbox_state(new_state: Hurtbox.HurtboxState) -> void:
	if hurtbox:
		hurtbox.set_state(new_state)

func reset_player(spawn_position: Vector2) -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	_self_hitlag_remaining = 0
	release_ledge(0.0)
	air_jumps_left = max_air_jumps
	can_air_dodge = true
	_intent_buffer = InputBuffer.new()
	_intent_buffer.buffer_window_seconds = INPUT_BUFFER_WINDOW_SEC
	_coyote_timer = COYOTE_TIME_SEC
	_previous_input_y = 0.0
	_down_just_pressed = false
	_previous_shield_pressed = false
	_shield_just_pressed = false
	if stats: stats.reset()
	if hurtbox:
		hurtbox.clear_received_swings()
		hurtbox.set_state(Hurtbox.HurtboxState.NORMAL)
	shield_health = MAX_SHIELD_HP
	percentage_changed.emit(0.0)
	visible = true
	state_machine.transition_to("Idle")

func apply_self_hitlag(frames: int) -> void:
	_self_hitlag_remaining = maxi(_self_hitlag_remaining, maxi(frames, 0))

func is_self_hitlag_active() -> bool:
	return _self_hitlag_remaining > 0
