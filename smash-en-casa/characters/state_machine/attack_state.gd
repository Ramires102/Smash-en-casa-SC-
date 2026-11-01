# ==============================================================================
# AttackState — Ejecutor de Ataques Basado en Frame Data (60 FPS)
# ==============================================================================
# Ciclo de vida universal de todo movimiento de pelea dividido en 3 fases:
#   1. Startup (Anticipación): el personaje prepara el golpe; Hitbox APAGADA.
#   2. Active (Impacto): la Hitbox se ENCIENDE y puede dañar al rival.
#   3. Recovery (Recuperación): la Hitbox se APAGA; vulnerable si falló, o
#      cancelable hacia el siguiente eslabón del combo (`combo_next`).
# Soporta además proyectiles, Time Stop, Divekicks y agarres cinemáticos.
# ==============================================================================
class_name AttackState
extends State

const DEFAULT_PROJECTILE_SCENE: PackedScene = preload("res://combat/projectile.tscn")

var current_attack_data: AttackData
var frame_cursor: int = 0
var startup_end_frame: int = 0
var active_end_frame: int = 0
var total_end_frame: int = 0
var hitbox_is_active: bool = false

var _combo_buffered: bool = false
var _started_in_air: bool = false
var _second_hit_triggered: bool = false
var _impulse_applied: bool = false
var _is_vaulting_behind: bool = false
var has_hit_target: bool = false
var hit_defender: Node2D = null
var _silk_spear_pending_cost: bool = false

#region Entrada y Preparación del Movimiento
func enter(msg: Dictionary = {}) -> void:
	if msg.has("attack_data") and msg["attack_data"] != null:
		current_attack_data = msg["attack_data"]
	else:
		current_attack_data = character.get_current_attack() if character else null

	if current_attack_data == null or character == null:
		if character:
			state_machine.transition_to("Idle" if character.is_on_floor() else "Fall")
		return

	# Verificación y cobro de Seda (exclusivo de Hornet)
	if character.is_hornet():
		if not character.can_afford_silk(current_attack_data):
			state_machine.transition_to("Idle" if character.is_on_floor() else "Fall")
			return
		if current_attack_data.id == "hornet_special_side":
			character.consume_silk(1)
			_silk_spear_pending_cost = true
		elif current_attack_data.silk_cost > 0:
			character.consume_silk(current_attack_data.silk_cost)
			_silk_spear_pending_cost = false
		else:
			_silk_spear_pending_cost = false
	else:
		_silk_spear_pending_cost = false

	frame_cursor = 1
	hitbox_is_active = false
	_combo_buffered = false
	_second_hit_triggered = false
	_impulse_applied = false
	_is_vaulting_behind = false
	has_hit_target = false
	hit_defender = msg["hit_defender"] as Node2D if (msg.has("hit_defender") and is_instance_valid(msg["hit_defender"])) else null
	_started_in_air = not character.is_on_floor()

	if character.hitbox and not character.hitbox.hit_confirmed.is_connected(_on_hitbox_hit_confirmed):
		character.hitbox.hit_confirmed.connect(_on_hitbox_hit_confirmed)

	var anim_name: String = current_attack_data.animation_name if not current_attack_data.animation_name.is_empty() else "Attack"
	if anim_name == "SpecialUp":
		character.can_up_special = false
	elif current_attack_data.is_time_stop:
		character.consume_special_down_charge()

	_apply_entry_positioning_modifiers(anim_name)

	startup_end_frame = maxi(1, current_attack_data.startup_frames)
	active_end_frame = startup_end_frame + maxi(1, current_attack_data.active_frames)
	total_end_frame = active_end_frame + maxi(0, current_attack_data.recovery_frames)
	character.execute_attack(current_attack_data)

	if character.anim_controller:
		var total_duration_sec: float = float(maxi(1, total_end_frame)) / 60.0
		character.anim_controller.play_attack_animation(anim_name, total_duration_sec, current_attack_data)

	_sync_frame_phase()

func _apply_entry_positioning_modifiers(anim_name: String) -> void:
	# 1. Giro de 180° al iniciar (ej. Gogeta Down Special 2)
	if current_attack_data.flip_facing_on_start:
		var new_dir: float = -character.get_facing_direction()
		character.set_facing_direction(new_dir, true)
		if is_instance_valid(hit_defender):
			hit_defender.global_position.x = character.global_position.x + new_dir * 0.96 * Constants.UNIT_SIZE
			hit_defender.global_position.y = minf(hit_defender.global_position.y, character.global_position.y - 0.44 * Constants.UNIT_SIZE)
			hit_defender.velocity = Vector2(0.0, -1.8 * Constants.UNIT_SIZE)
			if hit_defender.has_method("set_facing_direction"):
				hit_defender.set_facing_direction(-new_dir)
	else:
		var enter_input: Vector2 = character.get_input_vector()
		if absf(enter_input.x) > 0.25 and (not current_attack_data.is_aerial or anim_name.begins_with("Special")):
			character.update_facing_direction(enter_input.x)

	# 2. Remate aéreo: alinear al rival frente al puño (Gogeta Up Special 2)
	if current_attack_data.pose_style == "up_special_followup_punch":
		var target_opp: Node2D = hit_defender if is_instance_valid(hit_defender) else _find_opponent()
		if is_instance_valid(target_opp):
			var facing: float = character.get_facing_direction()
			target_opp.global_position = Vector2(
				character.global_position.x + facing * 0.88 * Constants.UNIT_SIZE,
				character.global_position.y - 0.06 * Constants.UNIT_SIZE
			)
			target_opp.velocity = Vector2(0.0, -2.2 * Constants.UNIT_SIZE)
		character.velocity = Vector2(character.get_facing_direction() * 1.8 * Constants.UNIT_SIZE, -2.6 * Constants.UNIT_SIZE)

	# 3. Teletransporte frente al rival (Gogeta Side Special 3)
	if current_attack_data.snap_in_front_of_opponent:
		var opp: Node2D = _find_opponent()
		if is_instance_valid(opp):
			var dx: float = opp.global_position.x - character.global_position.x
			var dir_to_opp: float = (1.0 if dx >= 0.0 else -1.0) if absf(dx) > 2.0 else character.get_facing_direction()
			character.set_facing_direction(dir_to_opp)
			character.global_position.x = opp.global_position.x - dir_to_opp * 1.12 * Constants.UNIT_SIZE
			character.global_position.y = minf(character.global_position.y, opp.global_position.y - 0.42 * Constants.UNIT_SIZE)
			character.velocity = Vector2(0.0, -1.5 * Constants.UNIT_SIZE)
			_started_in_air = true

	# 4. Salto o suspensión inicial para patadas en picada (Divekick)
	if current_attack_data.is_divekick:
		character.is_fast_falling = false
		if character.is_on_floor():
			character.global_position.y -= 2.0
			character.velocity = Vector2(character.get_facing_direction() * 1.5 * Constants.UNIT_SIZE, -8.5 * Constants.UNIT_SIZE)
			_started_in_air = true
		else:
			character.velocity.x *= 0.25
			character.velocity.y = minf(0.0, character.velocity.y * 0.15)
#endregion

#region Avance por Frame, Físicas de Ataque y Cadenas de Combo
func physics_update(delta: float) -> void:
	if character == null or current_attack_data == null:
		return

	if current_attack_data.combo_next != null:
		if character.is_normal_attack_pressed() or character.is_special_attack_pressed():
			_combo_buffered = true

	_process_defender_capture_mechanics()

	if character.is_self_hitlag_active():
		return

	if _update_attack_movement(delta):
		return

	frame_cursor += 1
	_sync_frame_phase()

	# Encadenamiento automático al conectar (ej. Up-B Remate / Down-B Patada)
	if current_attack_data.auto_followup_on_hit != null:
		if (has_hit_target or current_attack_data.auto_followup_always) and frame_cursor > active_end_frame:
			state_machine.transition_to("Attack", {
				"attack_data": current_attack_data.auto_followup_on_hit,
				"hit_defender": hit_defender
			})
			return

	# Cancelación del recovery hacia el siguiente golpe del combo (Jab 1->2->3 o Rekka 1->2->3)
	if _combo_buffered and current_attack_data.combo_next != null and frame_cursor > active_end_frame:
		state_machine.transition_to("Attack", {
			"attack_data": current_attack_data.combo_next,
			"hit_defender": hit_defender
		})
		return

	if frame_cursor > total_end_frame:
		_exit_to_next_state()

## Actualiza el movimiento del atacante; devuelve `true` si un Divekick aterrizó en este frame.
func _update_attack_movement(delta: float) -> bool:
	var input_vec: Vector2 = character.get_input_vector()

	if current_attack_data.is_divekick:
		var facing: float = character.get_facing_direction()
		if frame_cursor <= startup_end_frame:
			character.velocity.x = CharacterController.damp(character.velocity.x, 0.0, 7.5, delta)
			character.velocity.y = -character.get_gravity_value() * delta
		elif frame_cursor <= active_end_frame:
			if character.is_on_floor() and frame_cursor > startup_end_frame + 1:
				if hitbox_is_active:
					hitbox_is_active = false
					character.deactivate_hitbox()
				Events.camera_shake_requested.emit(6.0)
				character.velocity = Vector2(facing * 4.5 * Constants.UNIT_SIZE, 0.0)
				frame_cursor = active_end_frame + 1
				var land_rec: int = current_attack_data.landing_lag_frames if current_attack_data.landing_lag_frames > 0 else 9
				total_end_frame = active_end_frame + land_rec
				_sync_frame_phase()
				return true
			character.velocity = Vector2(facing * 13.5 * Constants.UNIT_SIZE, 20.0 * Constants.UNIT_SIZE)
		elif character.is_on_floor():
			character.velocity.x = CharacterController.damp(character.velocity.x, 0.0, CharacterController.TS_GROUND_FRICTION * 1.6, delta)
	elif character.is_on_floor() and not _is_vaulting_behind:
		character.velocity.x = CharacterController.damp(character.velocity.x, 0.0, CharacterController.TS_GROUND_FRICTION * 0.85, delta)
	elif not _is_vaulting_behind and absf(input_vec.x) > 0.1 and character.controller:
		character.velocity.x = CharacterController.damp(
			character.velocity.x,
			input_vec.x * character.controller.get_air_speed() * 0.75,
			5.0,
			delta
		)
	return false
#endregion

#region Sincronización de Fases (Startup / Active / Recovery)
func _sync_frame_phase() -> void:
	if current_attack_data == null or character == null:
		return

	# Impulso propio (tolera Vector2 o Vector3 serializado en recursos .tres)
	var raw_imp: Variant = current_attack_data.self_impulse
	var imp: Vector2 = Vector2.ZERO
	if raw_imp is Vector2:
		imp = raw_imp
	elif raw_imp is Vector3:
		imp = Vector2(raw_imp.x, raw_imp.y)

	var imp_frame: int = maxi(1, current_attack_data.self_impulse_frame) if current_attack_data.self_impulse_frame > 0 else startup_end_frame
	if not _impulse_applied and (imp.x != 0.0 or imp.y != 0.0) and frame_cursor >= imp_frame:
		_impulse_applied = true
		var facing: float = character.get_facing_direction()
		character.velocity.x = imp.x * facing * Constants.UNIT_SIZE
		if imp.y != 0.0:
			if imp.y > 0.0 and character.is_on_floor():
				character.global_position.y -= 2.0
			character.velocity.y = -imp.y * Constants.UNIT_SIZE

	# Reactivación limpia de Hitbox para ataques de doble impacto (ej. Jab 1 / Up-B)
	if not _second_hit_triggered and current_attack_data.second_hit_frame > 0 and frame_cursor >= current_attack_data.second_hit_frame:
		_second_hit_triggered = true
		if character.hitbox:
			character.hitbox.reset_hit_registry()

	# Invocación de proyectiles y activación de Time Stop
	if current_attack_data.spawns_projectile:
		var target_proj_frame: int = current_attack_data.projectile_spawn_frame if current_attack_data.projectile_spawn_frame > 0 else startup_end_frame
		if frame_cursor == target_proj_frame:
			_spawn_projectiles()

	if current_attack_data.is_time_stop:
		var target_stop_frame: int = current_attack_data.time_stop_frame if current_attack_data.time_stop_frame > 0 else startup_end_frame
		if frame_cursor == target_stop_frame:
			Events.trigger_time_stop(current_attack_data.time_stop_duration_sec, character)
			Events.camera_shake_requested.emit(8.0)

	var phase: String = "startup"
	if frame_cursor <= startup_end_frame:
		phase = "startup"
		if hitbox_is_active:
			hitbox_is_active = false
			character.deactivate_hitbox()
	elif frame_cursor <= active_end_frame:
		phase = "active"
		if not hitbox_is_active:
			hitbox_is_active = true
			character.activate_hitbox(current_attack_data)
	else:
		phase = "recovery"
		if hitbox_is_active:
			hitbox_is_active = false
			character.deactivate_hitbox()

	if character.anim_controller:
		character.anim_controller.update_attack_frame(frame_cursor, phase, current_attack_data)
#endregion

#region Mecánicas Cinemáticas al Conectar Impacto
func _on_hitbox_hit_confirmed(impact: ImpactData) -> void:
	has_hit_target = true
	if _silk_spear_pending_cost and character:
		_silk_spear_pending_cost = false
		character.consume_silk(1)

	if impact == null or not is_instance_valid(impact.target) or not (impact.target is Node2D):
		return

	hit_defender = impact.target as Node2D
	var facing: float = character.get_facing_direction()

	if current_attack_data.vault_behind_on_hit:
		_is_vaulting_behind = true
		character.global_position.y -= 2.0
		character.velocity = Vector2(facing * 9.2 * Constants.UNIT_SIZE, -7.8 * Constants.UNIT_SIZE)
		_override_defender_pending_kb(Vector2(facing * 1.5 * Constants.UNIT_SIZE, -6.4 * Constants.UNIT_SIZE))

	if current_attack_data.drag_defender_on_hit:
		character._self_hitlag_remaining = mini(character._self_hitlag_remaining, 2)
		_set_defender_hitlag_and_hitstun(2, maxi(26, (active_end_frame - frame_cursor) + 18))
		_override_defender_pending_kb(Vector2(character.velocity.x, minf(character.velocity.y, -8.5 * Constants.UNIT_SIZE)))

	if current_attack_data.toss_behind_on_hit:
		hit_defender.global_position.x = character.global_position.x + facing * 0.78 * Constants.UNIT_SIZE
		hit_defender.global_position.y = minf(hit_defender.global_position.y, character.global_position.y - 0.24 * Constants.UNIT_SIZE)
		character._self_hitlag_remaining = 9
		_set_defender_hitlag_and_hitstun(9, 46)
		_override_defender_pending_kb(Vector2(-facing * 2.2 * Constants.UNIT_SIZE, -6.8 * Constants.UNIT_SIZE))

	if current_attack_data.sliding_knockdown:
		character._self_hitlag_remaining = 8
		_set_defender_hitlag_and_hitstun(8, 38)
		_override_defender_pending_kb(Vector2(facing * 13.2 * Constants.UNIT_SIZE, -0.3 * Constants.UNIT_SIZE))
		if "state_machine" in hit_defender and hit_defender.state_machine and hit_defender.state_machine.current_state:
			var st: Node = hit_defender.state_machine.current_state
			if "_is_sliding_knockdown" in st:
				st._is_sliding_knockdown = true

func _process_defender_capture_mechanics() -> void:
	if current_attack_data == null or not is_instance_valid(hit_defender):
		return
	var facing: float = character.get_facing_direction()

	if current_attack_data.drag_defender_on_hit and frame_cursor <= active_end_frame:
		var target_pos := Vector2(
			character.global_position.x + facing * 0.78 * Constants.UNIT_SIZE,
			character.global_position.y - 0.10 * Constants.UNIT_SIZE
		)
		hit_defender.global_position = hit_defender.global_position.lerp(target_pos, 0.5)
		hit_defender.velocity = character.velocity
		_override_defender_pending_kb(character.velocity)

	if current_attack_data.toss_behind_on_hit and frame_cursor <= active_end_frame:
		var active_len: int = maxi(1, active_end_frame - startup_end_frame)
		var active_progress: float = clampf(float(frame_cursor - startup_end_frame) / float(active_len), 0.0, 1.0)
		var arc_t: float = smoothstep(0.32, 1.0, active_progress)
		var local_offset_x: float = lerpf(0.78, -0.98, arc_t) * facing * Constants.UNIT_SIZE
		var arc_height: float = (0.26 + sin(arc_t * PI) * 0.62 + arc_t * 0.20) * Constants.UNIT_SIZE
		var target_vec := Vector2(character.global_position.x + local_offset_x, character.global_position.y - arc_height)
		var launch_vel := Vector2(-facing * 1.2 * Constants.UNIT_SIZE, -2.0 * Constants.UNIT_SIZE)
		hit_defender.global_position = hit_defender.global_position.lerp(target_vec, 0.55)
		hit_defender.velocity = launch_vel
		_override_defender_pending_kb(launch_vel)

	if current_attack_data.flip_facing_on_start and frame_cursor <= startup_end_frame:
		var target_vec := Vector2(
			character.global_position.x + facing * 0.96 * Constants.UNIT_SIZE,
			character.global_position.y - 0.44 * Constants.UNIT_SIZE
		)
		var hold_vel := Vector2(0.0, -1.4 * Constants.UNIT_SIZE)
		hit_defender.global_position = hit_defender.global_position.lerp(target_vec, 0.45)
		hit_defender.velocity = hold_vel
		_override_defender_pending_kb(hold_vel)

func _set_defender_hitlag_and_hitstun(hitlag_f: int, hitstun_f: int) -> void:
	if is_instance_valid(hit_defender) and "state_machine" in hit_defender and hit_defender.state_machine and hit_defender.state_machine.current_state:
		var st: Node = hit_defender.state_machine.current_state
		if "_hitlag_remaining" in st:
			st._hitlag_remaining = hitlag_f
		if "_hitstun_remaining" in st:
			st._hitstun_remaining = maxi(st._hitstun_remaining, hitstun_f)

func _override_defender_pending_kb(new_kb: Vector2) -> void:
	if is_instance_valid(hit_defender) and "state_machine" in hit_defender and hit_defender.state_machine and hit_defender.state_machine.current_state:
		var st: Node = hit_defender.state_machine.current_state
		if "_pending_knockback" in st:
			st._pending_knockback = new_kb

func _find_opponent() -> Node2D:
	if character == null or character.get_parent() == null:
		return null
	for child in character.get_parent().get_children():
		if child != character and child is CharacterBody2D:
			return child as Node2D
	return null
#endregion

#region Invocación de Proyectiles y Limpieza de Salida
func _spawn_projectiles() -> void:
	if not character or not current_attack_data:
		return
	var proj_scene: PackedScene = current_attack_data.projectile_scene if current_attack_data.projectile_scene != null else DEFAULT_PROJECTILE_SCENE
	var facing: float = character.get_facing_direction()
	var spawn_pos: Vector2 = character.global_position + Vector2(
		current_attack_data.projectile_offset.x * Constants.UNIT_SIZE * facing,
		-current_attack_data.projectile_offset.y * Constants.UNIT_SIZE
	)
	var spread: Array[float] = current_attack_data.projectile_spread_angles
	if spread.is_empty():
		spread = [0.0]

	var parent_tree: Node = character.get_parent() if character.get_parent() else character
	var aerial_offset: float = current_attack_data.aerial_projectile_angle_offset if not character.is_on_floor() else 0.0

	for angle_offset_deg in spread:
		var proj_inst: Node = proj_scene.instantiate()
		parent_tree.add_child(proj_inst)
		if proj_inst is Projectile:
			proj_inst.global_position = spawn_pos
			var base_angle_rad: float = 0.0 if facing > 0.0 else PI
			var combined_angle_deg: float = (angle_offset_deg + aerial_offset) * facing
			var angle_rad: float = base_angle_rad + deg_to_rad(combined_angle_deg)
			proj_inst.setup(
				current_attack_data,
				character,
				Vector2(cos(angle_rad), sin(angle_rad)),
				current_attack_data.projectile_speed,
				current_attack_data.projectile_lifetime
			)

func exit() -> void:
	if _silk_spear_pending_cost and character:
		_silk_spear_pending_cost = false
		character.consume_silk(1)
	if character and character.hitbox and character.hitbox.hit_confirmed.is_connected(_on_hitbox_hit_confirmed):
		character.hitbox.hit_confirmed.disconnect(_on_hitbox_hit_confirmed)
	if hitbox_is_active:
		hitbox_is_active = false
		if character:
			character.deactivate_hitbox()
	if _is_vaulting_behind and character:
		_is_vaulting_behind = false
		character.set_facing_direction(-character.get_facing_direction(), true)

func _exit_to_next_state() -> void:
	if character == null:
		return
	if character.is_on_floor():
		var input_vec: Vector2 = character.get_input_vector()
		state_machine.transition_to("Run" if absf(input_vec.x) > 0.15 else "Idle")
	else:
		state_machine.transition_to("Fall")
#endregion
