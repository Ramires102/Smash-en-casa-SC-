# ==============================================================================
# Character — Nodo Principal del Luchador (Patrón Fachada + Composición)
# ==============================================================================
# Representa el cuerpo físico 2D (CharacterBody2D) de un jugador en combate y
# actúa como "Fachada" (Facade) coordinando sus componentes especializados:
#   - Controller (CharacterController): velocidades, fricción, salto y gravedad.
#   - Stats (CharacterStats): porcentaje de daño acumulado (%) y peso.
#   - AttackController: selección del movimiento según el stick y botones.
#   - ShieldController: vida, desgaste, bloqueo y ruptura del escudo.
#   - VisualController: sincronización entre la física 2D y el modelo 3D.
#   - AnimationController: animaciones por clips GLB o poses procedurales.
#   - StateMachine: Máquina de Estados Finitos (Idle, Run, Jump, Attack, Hit...).
# ==============================================================================
class_name Character
extends CharacterBody2D

signal percentage_changed(new_percentage: float)

#region Constantes de Ventanas de Entrada y Recursos Únicos
const INPUT_BUFFER_WINDOW_SEC: float = 0.15
const COYOTE_TIME_SEC: float = 0.08
const COMBO_WINDOW_SEC: float = 1.45

## Barra de carga para el Down Special (Time Stop) exclusivo de Sakuya.
const SPECIAL_DOWN_MAX_CHARGE: float = 100.0

## Sistema de Seda (Silk) exclusivo de Hornet: máximo 5 cargas, +1 cada 3 golpes.
const SILK_MAX: int = 5
const SILK_HITS_PER_CHARGE: int = 3

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
#endregion

#region Propiedades Exportadas y Referencias a Componentes
@export var player_id: int = 1
@export var character_data: CharacterData

@onready var controller: CharacterController = $Controller
@onready var stats: CharacterStats = $Stats
@onready var attack_controller: AttackController = $AttackController
@onready var anim_controller: AnimationController = $AnimationController
@onready var state_machine: StateMachine = $StateMachine
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var shield_controller: ShieldController = get_node_or_null("ShieldController")
@onready var visual_controller: VisualController = get_node_or_null("VisualController")
#endregion

#region Propiedades Delegadas (Acceso Rápido a Subcomponentes)
var shield_health: float:
	get:
		return shield_controller.shield_health if shield_controller else ShieldController.MAX_SHIELD_HP
	set(val):
		if shield_controller:
			shield_controller.shield_health = val

var visual_root_3d: Node3D:
	get:
		if visual_controller and visual_controller.visual_root_3d:
			return visual_controller.visual_root_3d
		return get_node_or_null("Humanoid") as Node3D
	set(val):
		if visual_controller:
			visual_controller.visual_root_3d = val

var timestop_shiver_timer: float:
	get:
		return visual_controller.timestop_shiver_timer if visual_controller else 0.0
	set(val):
		if visual_controller:
			visual_controller.timestop_shiver_timer = val

var damage_percentage: float:
	get:
		return stats.damage_percentage if stats else 0.0

var weight: float:
	get:
		return stats.weight if stats else 100.0
#endregion

#region Estado Dinámico de Combate y Movimiento
var current_input: PlayerInput = PlayerInput.new()
var _intent_buffer: InputBuffer = InputBuffer.new()
var _coyote_timer: float = 0.0
var _previous_input_y: float = 0.0
var _down_just_pressed: bool = false
var _previous_shield_pressed: bool = false
var _shield_just_pressed: bool = false

var snapped_ledge: LedgePoint = null
var ledge_regrab_timer: float = 0.0
var can_grab_ledge: bool = true

var max_air_jumps: int = 1
var air_jumps_left: int = 1
var can_air_dodge: bool = true
var can_up_special: bool = true

var special_down_charge: float = SPECIAL_DOWN_MAX_CHARGE
var silk_count: int = SILK_MAX
var silk_hit_counter: int = 0

var accumulated_timestop_knockback: Vector2 = Vector2.ZERO
var accumulated_timestop_hitstun: int = 0

var can_act: bool = true
var is_fast_falling: bool = false
var _self_hitlag_remaining: int = 0
var _last_consumed_was_special: bool = false
var combo_window_timer: float = 0.0
var next_combo_override: AttackData = null
#endregion

#region Ciclo de Vida e Inicialización
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
			push_error("Character contract violation: falta el nodo requerido '%s'" % required_path)
			is_valid = false
	return is_valid

## Inicializa todos los subcontroladores con los datos del personaje elegido.
func configure(data: CharacterData) -> void:
	character_data = data
	if not data:
		return

	_reset_character_unique_meters()

	if controller:
		controller.setup(data)
	if stats:
		stats.setup(data)
	if attack_controller:
		attack_controller.setup(data)
	if shield_controller:
		shield_controller.setup(self)
	if visual_controller:
		visual_controller.setup(self, data)
	if anim_controller:
		anim_controller.setup(data)
#endregion

#region Bucles de Renderizado (_process) y Física (_physics_process)
func _process(delta: float) -> void:
	if visual_controller:
		visual_controller.sync_3d_visuals(delta)

func _physics_process(delta: float) -> void:
	# Si el tiempo está detenido por Sakuya, todos los demás luchadores quedan congelados
	if Events.is_time_stopped and self != Events.time_stop_instigator:
		velocity = Vector2.ZERO
		return

	if combo_window_timer > 0.0:
		combo_window_timer = maxf(0.0, combo_window_timer - delta)
		if combo_window_timer <= 0.0:
			next_combo_override = null

	current_input = InputManager.get_player_input(player_id)
	_update_directional_input_edges()
	_update_button_input_edges()
	_register_input_intents()

	# Hitstop propio al conectar un golpe (pausa física y animación unos frames)
	if _self_hitlag_remaining > 0:
		_self_hitlag_remaining -= 1
		if anim_controller:
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
			velocity.y += get_gravity_value() * delta
			var max_fall: float = get_terminal_fall_speed()
			if velocity.y > max_fall:
				velocity.y = max_fall
		elif not in_hitstate:
			# Al tocar el suelo fuera de hitstun se restauran todos los recursos aéreos
			is_fast_falling = false
			air_jumps_left = max_air_jumps
			can_air_dodge = true
			can_up_special = true
			ledge_regrab_timer = 0.0

	move_and_slide()

func get_gravity_value() -> float:
	return controller.get_gravity_value() if controller else (26.0 * Constants.UNIT_SIZE)

func get_terminal_fall_speed() -> float:
	return controller.get_terminal_fall_speed(is_fast_falling) if controller else (22.0 * Constants.UNIT_SIZE)
#endregion

#region Lectura de Controles, Input Buffer y Coyote Time
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
	if raw_pressed or _intent_buffer.is_action_buffered(action_name):
		_intent_buffer.consume_action(action_name)
		return true
	return false

func has_coyote_jump() -> bool:
	return _coyote_timer > 0.0

func consume_coyote_jump() -> void:
	_coyote_timer = 0.0

func get_input_vector() -> Vector2:
	return current_input.movement if can_act else Vector2.ZERO

func is_dash_intent() -> bool:
	return current_input.is_dash if can_act else false

func is_jump_just_pressed() -> bool:
	if not can_act:
		return false
	return _consume_buffered_action("jump", current_input.jump_pressed)

func is_jump_held() -> bool:
	return current_input.jump_held if can_act else false

## Consulta sin consumir el buffer si el jugador presionó Ataque durante JumpSquat (Short-Hop Aerial).
func has_attack_buffered() -> bool:
	if not can_act:
		return false
	return current_input.attack_pressed or _intent_buffer.is_action_buffered("attack")

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
	if _consume_buffered_action("special", current_input.special_pressed):
		if not _can_execute_requested_special():
			return false
		_last_consumed_was_special = true
		return true
	if _consume_buffered_action("attack", current_input.attack_pressed):
		_last_consumed_was_special = false
		return true
	return false

func is_normal_attack_pressed() -> bool:
	if not can_act:
		return false
	var pressed: bool = _consume_buffered_action("attack", current_input.attack_pressed)
	if pressed:
		_last_consumed_was_special = false
	return pressed

func is_special_attack_pressed() -> bool:
	if not can_act:
		return false
	var pressed: bool = _consume_buffered_action("special", current_input.special_pressed)
	if pressed:
		if not _can_execute_requested_special():
			return false
		_last_consumed_was_special = true
	return pressed

func is_shield_pressed() -> bool:
	return current_input.shield_pressed if can_act else false

func is_shield_just_pressed() -> bool:
	return _shield_just_pressed if can_act else false

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

## Permite atravesar plataformas superiores semitransparentes al pulsar abajo rápidamente.
func try_drop_through_platform(input_vec: Vector2) -> bool:
	if input_vec.y < -0.65 and global_position.y < -10.0 and is_down_just_pressed():
		global_position.y += 12.0
		velocity.y = maxf(velocity.y, 60.0)
		return true
	return false
#endregion

#region Mecánicas Exclusivas (Sakuya Time Stop y Hornet Seda)
func is_sakuya() -> bool:
	return character_data != null and character_data.character_name.to_lower().contains("sakuya")

func is_hornet() -> bool:
	return character_data != null and character_data.character_name.to_lower().contains("hornet")

func _reset_character_unique_meters() -> void:
	if is_sakuya():
		special_down_charge = 0.0
		Events.special_meter_changed.emit(player_id, special_down_charge, SPECIAL_DOWN_MAX_CHARGE)
	elif is_hornet():
		silk_count = SILK_MAX
		silk_hit_counter = 0
		_emit_silk_meter_changed()
	else:
		special_down_charge = SPECIAL_DOWN_MAX_CHARGE

func is_special_move(atk: AttackData) -> bool:
	if atk == null:
		return false
	return atk.is_special_attack or atk.animation_name.begins_with("Special") or atk.is_time_stop

func on_non_special_hit_connected(atk: AttackData) -> void:
	# Sakuya recarga su reloj al conectar golpes normales fuera del Time Stop
	if is_sakuya() and not is_special_move(atk) and not Events.is_time_stopped:
		var gain: float = clampf(atk.damage * 2.5, 16.0, 28.0) if atk else 20.0
		add_special_down_charge(gain)

	# Hornet regenera 1 carrete de Seda cada 3 impactos conectados
	if is_hornet() and silk_count < SILK_MAX:
		silk_hit_counter += 1
		if silk_hit_counter >= SILK_HITS_PER_CHARGE:
			silk_hit_counter = 0
			silk_count = mini(silk_count + 1, SILK_MAX)
		_emit_silk_meter_changed()

func add_special_down_charge(amount: float) -> void:
	if not is_sakuya():
		return
	special_down_charge = clampf(special_down_charge + amount, 0.0, SPECIAL_DOWN_MAX_CHARGE)
	Events.special_meter_changed.emit(player_id, special_down_charge, SPECIAL_DOWN_MAX_CHARGE)

func can_use_special_down() -> bool:
	if not is_sakuya():
		return true
	return special_down_charge >= SPECIAL_DOWN_MAX_CHARGE

func consume_special_down_charge() -> void:
	if not is_sakuya():
		return
	special_down_charge = 0.0
	Events.special_meter_changed.emit(player_id, special_down_charge, SPECIAL_DOWN_MAX_CHARGE)

func consume_silk(amount: int) -> bool:
	if not is_hornet():
		return true
	if silk_count < amount:
		return false
	silk_count -= amount
	_emit_silk_meter_changed()
	return true

func can_afford_silk(atk: AttackData) -> bool:
	if not is_hornet() or atk == null:
		return true
	return silk_count >= atk.silk_cost

func _emit_silk_meter_changed() -> void:
	if not is_hornet():
		return
	var total_charge: float = float(silk_count)
	if silk_count < SILK_MAX:
		total_charge += float(silk_hit_counter) / float(SILK_HITS_PER_CHARGE)
	Events.special_meter_changed.emit(player_id, total_charge, float(SILK_MAX))
#endregion

#region Orientación, Animación y Ejecución de Ataques
func play_anim(anim_name: String, speed: float = 1.0, blend: float = 0.03) -> void:
	if anim_controller:
		anim_controller.play_animation(anim_name, speed, blend)

func update_visual_rotation(dir: float, smooth_turn: bool = false) -> void:
	if visual_controller:
		visual_controller.update_rotation(dir, smooth_turn)

func update_facing_direction(input_x: float) -> void:
	if controller and can_act:
		controller.set_facing_direction(input_x)

func set_facing_direction(dir: float, smooth_turn: bool = false) -> void:
	if controller:
		controller.set_facing_direction(dir, smooth_turn)

func get_facing_direction() -> float:
	return controller.facing_direction if controller else 1.0

func get_current_attack() -> AttackData:
	if not attack_controller:
		return null
	if current_input and _last_consumed_was_special:
		current_input.special_pressed = true

	# Continuar cadenas de Jab (1->2->3) o Side Special Rekka (1->2->3) dentro de la ventana activa
	if next_combo_override != null and combo_window_timer > 0.0:
		if _last_consumed_was_special and next_combo_override.animation_name.begins_with("SpecialSide"):
			return next_combo_override
		if not _last_consumed_was_special and next_combo_override.animation_name.begins_with("AttackNeutral"):
			return next_combo_override

	return attack_controller.get_attack_data_for_input(current_input, is_on_floor(), get_facing_direction())

func execute_attack(attack_data: AttackData) -> void:
	if attack_data and attack_data.combo_next != null:
		next_combo_override = attack_data.combo_next
		combo_window_timer = COMBO_WINDOW_SEC
	else:
		next_combo_override = null
		combo_window_timer = 0.0

func activate_hitbox(attack_data: AttackData) -> void:
	if attack_controller:
		attack_controller.enable_hitbox(attack_data, self)

func deactivate_hitbox() -> void:
	if attack_controller:
		attack_controller.disable_hitbox()

func break_shield() -> void:
	if shield_controller:
		shield_controller.break_shield()
	elif state_machine:
		state_machine.transition_to("Daze")

func update_shield_scale() -> void:
	if shield_controller:
		shield_controller.update_shield_scale()

func _is_current_state(state_name: String) -> bool:
	if state_machine == null or state_machine.current_state == null:
		return false
	return state_machine.current_state.name.to_lower() == state_name.to_lower()
#endregion

#region Recepción de Impactos, Time Stop y Hitlag
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

	if impact.attack_data and impact.attack_data.hit_sfx:
		AudioManager.play_sfx(impact.attack_data.hit_sfx)

	# Si el tiempo está detenido, acumular el knockback para liberarlo de golpe al reanudar
	if Events.is_time_stopped and self != Events.time_stop_instigator:
		accumulated_timestop_knockback += impact.knockback_vector * 0.95
		accumulated_timestop_hitstun = maxi(accumulated_timestop_hitstun, impact.hitstun_frames)
		timestop_shiver_timer = 0.2
		Events.camera_shake_requested.emit(5.0)
		return

	can_up_special = true
	next_combo_override = null
	combo_window_timer = 0.0
	if impact.attacker_facing != 0.0:
		set_facing_direction(-impact.attacker_facing)

	var is_slide_kd: bool = impact.attack_data.sliding_knockdown if impact.attack_data else false
	state_machine.transition_to("Hit", {
		"knockback": impact.knockback_vector,
		"hitstun_frames": impact.hitstun_frames,
		"hitlag_frames": impact.hitlag_frames,
		"knockback_scalar": impact.knockback_magnitude,
		"sliding_knockdown": is_slide_kd,
		"impact": impact
	})

func _on_time_stop_started(_duration: float, _instigator: Node) -> void:
	if self != Events.time_stop_instigator:
		velocity = Vector2.ZERO
		accumulated_timestop_knockback = Vector2.ZERO
		accumulated_timestop_hitstun = 0

func _on_time_stop_ended() -> void:
	if self != Events.time_stop_instigator and accumulated_timestop_knockback.length_squared() > 1.0:
		var final_kb: Vector2 = accumulated_timestop_knockback
		var final_stun: int = maxi(24, accumulated_timestop_hitstun)
		accumulated_timestop_knockback = Vector2.ZERO
		accumulated_timestop_hitstun = 0
		Events.camera_shake_requested.emit(14.0)
		can_up_special = true
		state_machine.transition_to("Hit", {
			"knockback": final_kb,
			"hitstun_frames": final_stun,
			"hitlag_frames": 8,
			"knockback_scalar": final_kb.length() / Constants.UNIT_SIZE,
			"impact": null
		})

func apply_self_hitlag(frames: int) -> void:
	_self_hitlag_remaining = maxi(_self_hitlag_remaining, maxi(frames, 0))
	if _self_hitlag_remaining > 0 and anim_controller:
		anim_controller.set_paused(true)

func is_self_hitlag_active() -> bool:
	return _self_hitlag_remaining > 0

func set_hurtbox_state(new_state: Hurtbox.HurtboxState) -> void:
	if hurtbox:
		hurtbox.set_state(new_state)
#endregion

#region Agarre de Bordes (Ledge) y Reaparición (Respawn)
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

## Restaura al luchador a su estado limpio tras perder un stock o reiniciar partida.
func reset_player(spawn_position: Vector2) -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	_self_hitlag_remaining = 0
	is_fast_falling = false
	accumulated_timestop_knockback = Vector2.ZERO
	accumulated_timestop_hitstun = 0
	timestop_shiver_timer = 0.0

	release_ledge(0.0)
	air_jumps_left = max_air_jumps
	can_air_dodge = true
	can_up_special = true
	next_combo_override = null
	combo_window_timer = 0.0

	_intent_buffer.clear()
	_intent_buffer.buffer_window_seconds = INPUT_BUFFER_WINDOW_SEC
	_coyote_timer = COYOTE_TIME_SEC
	_previous_input_y = 0.0
	_down_just_pressed = false
	_previous_shield_pressed = false
	_shield_just_pressed = false

	if stats:
		stats.reset()
	if shield_controller:
		shield_controller.reset()
	if hurtbox:
		hurtbox.clear_received_swings()
		hurtbox.set_state(Hurtbox.HurtboxState.NORMAL)
	if anim_controller:
		anim_controller.set_paused(false)

	_reset_character_unique_meters()
	percentage_changed.emit(0.0)
	visible = true
	state_machine.transition_to("Idle")
#endregion
