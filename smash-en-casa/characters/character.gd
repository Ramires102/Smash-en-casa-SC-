class_name Character
extends CharacterBody2D

signal percentage_changed(new_percentage: float)
@warning_ignore("unused_signal")
signal character_ko(player_id: int)

# Constantes de compatibilidad
const MAX_SHIELD_HP: float = ShieldController.MAX_SHIELD_HP
const SHIELD_BREAK_RESPAWN_HP: float = ShieldController.SHIELD_BREAK_RESPAWN_HP
const SHIELD_DRAIN_RATE: float = ShieldController.SHIELD_DRAIN_RATE
const INPUT_BUFFER_WINDOW_SEC: float = 0.12
const COYOTE_TIME_SEC: float = 0.08

# Contrato de nodos para Character.tscn
const REQUIRED_NODE_PATHS: Array[NodePath] = [
	NodePath("Controller"),
	NodePath("Stats"),
	NodePath("AttackController"),
	NodePath("AnimationController"),
	NodePath("StateMachine"),
	NodePath("Hitbox"),
	NodePath("Hurtbox"),
	NodePath("ShieldController"),
	NodePath("VisualController")
]

@export var player_id: int = 1
@export var character_data: CharacterData

# Componentes de arquitectura
@onready var controller: CharacterController = $Controller
@onready var stats: CharacterStats = $Stats
@onready var attack_controller: AttackController = $AttackController
@onready var anim_controller: AnimationController = $AnimationController
@onready var state_machine: StateMachine = $StateMachine
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var shield_controller: ShieldController = get_node_or_null("ShieldController")
@onready var visual_controller: VisualController = get_node_or_null("VisualController")

# Propiedades delegadas al ShieldController
var shield_health: float:
	get: return shield_controller.shield_health if shield_controller else 50.0
	set(val):
		if shield_controller: shield_controller.shield_health = val

var shield_release_timer: float:
	get: return shield_controller.shield_release_timer if shield_controller else 0.0
	set(val):
		if shield_controller: shield_controller.shield_release_timer = val

# Propiedades delegadas al VisualController
var visual_root_3d: Node3D:
	get:
		if visual_controller and visual_controller.visual_root_3d:
			return visual_controller.visual_root_3d
		return get_node_or_null("Humanoid") as Node3D
	set(val):
		if visual_controller:
			visual_controller.visual_root_3d = val

var timestop_shiver_timer: float:
	get: return visual_controller.timestop_shiver_timer if visual_controller else 0.0
	set(val):
		if visual_controller: visual_controller.timestop_shiver_timer = val

# Variables de Input & Buffer
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

# Movilidad Aérea & Barra de Especial
var max_air_jumps: int = 1
var air_jumps_left: int = 1
var can_air_dodge: bool = true
var can_up_special: bool = true
const SPECIAL_DOWN_MAX_CHARGE: float = 100.0
var special_down_charge: float = 0.0

# Stats de daño y peso
var damage_percentage: float:
	get: return stats.damage_percentage if stats else 0.0

var weight: float:
	get: return stats.weight if stats else 100.0

# Variables de Time Stop
var accumulated_timestop_knockback: Vector2 = Vector2.ZERO
var accumulated_timestop_hitstun: int = 0

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

## Configura el personaje con sus datos y componentes modulares
func configure(data: CharacterData) -> void:
	character_data = data
	if not data:
		return
	
	if controller: controller.setup(data)
	if stats: stats.setup(data)
	if attack_controller: attack_controller.setup(data)
	if shield_controller: shield_controller.setup(self)
	if visual_controller: visual_controller.setup(self, data)
	if anim_controller and anim_controller.has_method("setup"):
		anim_controller.setup(data)
	elif has_node("AnimationController"):
		get_node("AnimationController").setup(data)

func _process(delta: float) -> void:
	if visual_controller:
		visual_controller.sync_3d_visuals(delta)

func update_visual_rotation(dir: float) -> void:
	if visual_controller:
		visual_controller.update_rotation(dir)

func _physics_process(delta: float) -> void:
	# Congelación Física Total durante Time Stop
	if Events.is_time_stopped and self != Events.time_stop_instigator:
		velocity = Vector2.ZERO
		return

	current_input = InputManager.get_player_input(player_id)
	_update_directional_input_edges()
	_update_button_input_edges()
	_register_input_intents()

	if _self_hitlag_remaining > 0:
		_self_hitlag_remaining -= 1
		if anim_controller and anim_controller.has_method("set_paused"):
			anim_controller.set_paused(_self_hitlag_remaining > 0)
		return

	if ledge_regrab_timer > 0.0:
		ledge_regrab_timer -= delta

	_update_coyote_timer(delta)

	var in_hitstate: bool = _is_current_state("Hit")
	var in_defender_hitlag: bool = false
	if in_hitstate and state_machine and state_machine.current_state:
		if "_hitlag_remaining" in state_machine.current_state:
			in_defender_hitlag = state_machine.current_state._hitlag_remaining > 0

	if not in_defender_hitlag:
		if not is_on_floor():
			var grav_mult: float = 0.55 if in_hitstate else 1.0
			velocity.y += get_gravity_value() * grav_mult * delta
			var max_fall: float = get_terminal_fall_speed()
			if not in_hitstate and velocity.y > max_fall:
				velocity.y = max_fall
		else:
			if not in_hitstate:
				is_fast_falling = false
				air_jumps_left = max_air_jumps
				can_air_dodge = true
				can_up_special = true
				ledge_regrab_timer = 0.0

		move_and_slide()


func get_gravity_value() -> float:
	return controller.get_gravity_value() if controller else 1320.0

func get_terminal_fall_speed() -> float:
	return controller.get_terminal_fall_speed(is_fast_falling) if controller else 500.0

# ── Buffer de Intenciones & Coyote ─────────────────────────────────────────
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

var _last_consumed_was_special: bool = false

func _can_execute_requested_special() -> bool:
	if not current_input:
		return true
	if current_input.movement.y > 0.3 and not can_up_special:
		return false
	if current_input.movement.y < -0.3 and not can_use_special_down():
		return false
	return true

func is_attack_just_pressed() -> bool:
	if not can_act:
		return false
	var special_intent: bool = _consume_buffered_action("special", current_input.special_pressed)
	if special_intent:
		if not _can_execute_requested_special():
			return false
		_last_consumed_was_special = true
		return true
	var normal_intent: bool = _consume_buffered_action("attack", current_input.attack_pressed)
	if normal_intent:
		_last_consumed_was_special = false
		return true
	return false

func is_normal_attack_pressed() -> bool:
	if not can_act:
		return false
	var res: bool = _consume_buffered_action("attack", current_input.attack_pressed)
	if res:
		_last_consumed_was_special = false
	return res

func is_special_attack_pressed() -> bool:
	if not can_act:
		return false
	var res: bool = _consume_buffered_action("special", current_input.special_pressed)
	if res:
		if not _can_execute_requested_special():
			return false
		_last_consumed_was_special = true
	return res

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

# ── Dirección, Barra de Especial y Ataques ────────────────────────────────
func is_special_move(atk: AttackData) -> bool:
	if atk == null:
		return false
	return atk.is_special_attack or atk.animation_name.begins_with("Special") or atk.is_time_stop

func on_non_special_hit_connected(atk: AttackData) -> void:
	if is_special_move(atk) or Events.is_time_stopped:
		return
	var gain: float = clampf(atk.damage * 2.5, 16.0, 28.0) if atk else 20.0
	add_special_down_charge(gain)

func add_special_down_charge(amount: float) -> void:
	special_down_charge = clampf(special_down_charge + amount, 0.0, SPECIAL_DOWN_MAX_CHARGE)
	Events.special_meter_changed.emit(player_id, special_down_charge, SPECIAL_DOWN_MAX_CHARGE)

func can_use_special_down() -> bool:
	return special_down_charge >= SPECIAL_DOWN_MAX_CHARGE

func consume_special_down_charge() -> void:
	special_down_charge = 0.0
	Events.special_meter_changed.emit(player_id, special_down_charge, SPECIAL_DOWN_MAX_CHARGE)

func update_facing_direction(input_x: float) -> void:
	if controller and can_act:
		controller.set_facing_direction(input_x)

func set_facing_direction(dir: float) -> void:
	if controller:
		controller.set_facing_direction(dir)

func get_facing_direction() -> float:
	return controller.facing_direction if controller else 1.0

func get_current_attack() -> AttackData:
	if not attack_controller:
		return null
	if current_input and _last_consumed_was_special:
		current_input.special_pressed = true
	return attack_controller.get_attack_data_for_input(current_input, is_on_floor(), get_facing_direction())

func execute_attack(attack_data: AttackData) -> void:
	if attack_controller:
		attack_controller.start_attack(attack_data, self)

func activate_hitbox(attack_data: AttackData) -> void:
	if attack_controller:
		attack_controller.enable_hitbox(attack_data, self)

func deactivate_hitbox() -> void:
	if attack_controller:
		attack_controller.disable_hitbox()

# ── Métodos Puente para Shield & VFX (100% retrocompatibilidad) ───────────
func break_shield() -> void:
	if shield_controller:
		shield_controller.break_shield()
	elif state_machine:
		state_machine.transition_to("Daze")

func update_shield_scale() -> void:
	if shield_controller:
		shield_controller.update_shield_scale()

func set_menacing_aura_enabled(enabled: bool) -> void:
	if visual_controller:
		visual_controller.set_menacing_aura_enabled(enabled)

func update_menacing_aura(delta: float) -> void:
	if visual_controller:
		visual_controller.update_menacing_aura(delta)

func set_daze_effects_enabled(enabled: bool) -> void:
	if visual_controller:
		visual_controller.set_daze_effects_enabled(enabled)

func update_daze_effects(delta: float, timer: float = 0.0) -> void:
	if visual_controller:
		visual_controller.update_daze_effects(delta, timer)

func _is_current_state(state_name: String) -> bool:
	if state_machine == null or state_machine.current_state == null:
		return false
	return state_machine.current_state.name.to_lower() == state_name.to_lower()

# ── Combate & Recepción de Impacto ────────────────────────────────────────
func on_impact_received(impact: ImpactData) -> void:
	if impact == null:
		return
	if Events.is_time_stopped and self == Events.time_stop_instigator:
		return

	if shield_controller and shield_controller.handle_shield_impact(impact):
		return

	if impact.attacker and impact.attacker != self and impact.attacker.has_method("on_non_special_hit_connected"):
		impact.attacker.on_non_special_hit_connected(impact.attack_data)

	var new_percent: float = stats.add_damage(impact.damage)
	impact.target_percent_after = new_percent
	percentage_changed.emit(new_percent)
	Events.player_damaged.emit(player_id, new_percent, impact)
	
	if impact.attack_data and impact.attack_data.hit_sfx:
		AudioManager.play_sfx(impact.attack_data.hit_sfx)

	# Acumulación Cinética durante Time Stop
	if Events.is_time_stopped and self != Events.time_stop_instigator:
		accumulated_timestop_knockback += impact.knockback_vector * 0.95
		accumulated_timestop_hitstun = maxi(accumulated_timestop_hitstun, impact.hitstun_frames)
		timestop_shiver_timer = 0.2
		Events.camera_shake_requested.emit(5.0)
		return
	
	can_up_special = true
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
		can_up_special = true
		state_machine.transition_to("Hit", {
			"knockback": final_kb,
			"hitstun_frames": final_stun,
			"hitlag_frames": 8,
			"knockback_scalar": final_kb.length() / Constants.KB_VELOCITY_SCALE,
			"hdecay": 0.0,
			"vdecay": 0.0,
			"impact": null
		})

# ── Ledge Grab (2D) ───────────────────────────────────────────────────────
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
	can_up_special = true
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
	can_up_special = true
	_intent_buffer = InputBuffer.new()
	_intent_buffer.buffer_window_seconds = INPUT_BUFFER_WINDOW_SEC
	_coyote_timer = COYOTE_TIME_SEC
	_previous_input_y = 0.0
	_down_just_pressed = false
	_previous_shield_pressed = false
	_shield_just_pressed = false
	if stats: stats.reset()
	if shield_controller: shield_controller.reset()
	if hurtbox:
		hurtbox.clear_received_swings()
		hurtbox.set_state(Hurtbox.HurtboxState.NORMAL)
	percentage_changed.emit(0.0)
	visible = true
	state_machine.transition_to("Idle")

func apply_self_hitlag(frames: int) -> void:
	_self_hitlag_remaining = maxi(_self_hitlag_remaining, maxi(frames, 0))
	if _self_hitlag_remaining > 0 and anim_controller and anim_controller.has_method("set_paused"):
		anim_controller.set_paused(true)

func is_self_hitlag_active() -> bool:
	return _self_hitlag_remaining > 0

