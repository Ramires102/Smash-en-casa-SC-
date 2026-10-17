class_name AttackState
extends State

var current_attack_data: AttackData
var frame_cursor: int = 0
var startup_end_frame: int = 0
var active_end_frame: int = 0
var total_end_frame: int = 0
var hitbox_is_active: bool = false
var _combo_buffered: bool = false
var _started_in_air: bool = false

func enter(msg: Dictionary = {}) -> void:
	if msg.has("attack_data") and msg["attack_data"] != null:
		current_attack_data = msg["attack_data"]
	else:
		current_attack_data = character.get_current_attack()
		
	frame_cursor = 0
	hitbox_is_active = false
	_combo_buffered = false
	_started_in_air = character != null and not character.is_on_floor()
	dbg("enter", {
		"attack": current_attack_data.attack_name if current_attack_data else "None",
		"started_in_air": _started_in_air
	})
	
	var anim_name: String = "Attack"
	if current_attack_data and current_attack_data.animation_name != "":
		anim_name = current_attack_data.animation_name

	if character and current_attack_data:
		if anim_name == "SpecialUp":
			character.can_up_special = false
		elif anim_name == "SpecialDown" or current_attack_data.is_time_stop:
			if character.has_method("consume_special_down_charge"):
				character.consume_special_down_charge()

	# En ataques terrestres o ataques especiales (ej. SpecialSide / SpecialUp), orientar hacia la dirección presionada
	if character and current_attack_data:
		var enter_input: Vector2 = character.get_input_vector()
		if absf(enter_input.x) > 0.2 and (not current_attack_data.is_aerial or anim_name.begins_with("Special")):
			character.update_facing_direction(enter_input.x)

	if character and character.has_node("AnimationController"):
		var anim_ctrl: Node = character.get_node("AnimationController")
		if anim_ctrl.has_method("play_attack_animation"):
			var total_duration_sec: float
			if current_attack_data:
				total_duration_sec = float(maxi(1, current_attack_data.startup_frames + current_attack_data.active_frames + current_attack_data.recovery_frames)) / 60.0
			else:
				total_duration_sec = 0.2
			anim_ctrl.play_attack_animation(anim_name, total_duration_sec)
		elif anim_ctrl.has_method("play_animation"):
			anim_ctrl.play_animation(anim_name)
		
	if current_attack_data:
		startup_end_frame = maxi(0, current_attack_data.startup_frames)
		active_end_frame = startup_end_frame + maxi(0, current_attack_data.active_frames)
		total_end_frame = active_end_frame + maxi(0, current_attack_data.recovery_frames)
		dbg("windows", {
			"startup_end": startup_end_frame,
			"active_end": active_end_frame,
			"total_end": total_end_frame
		})
		character.execute_attack(current_attack_data)
	else:
		startup_end_frame = 0
		active_end_frame = 0
		total_end_frame = 12

	_update_hitbox_window()

func physics_update(delta: float) -> void:
	# Permitir buffer de combo incluso durante hitlag del atacante
	if character and current_attack_data and current_attack_data.combo_next != null:
		if character.is_normal_attack_pressed():
			_combo_buffered = true

	if character and character.has_method("is_self_hitlag_active") and character.is_self_hitlag_active():
		return


	frame_cursor += 1
	_update_hitbox_window()
	
	var input_vec: Vector2 = character.get_input_vector() if character else Vector2.ZERO
	
	# Manejo de físicas 2D durante el ataque
	if character and character.is_on_floor():
		var trac: float = character.controller.get_traction() if character.controller else 900.0
		character.velocity.x = move_toward(character.velocity.x, 0.0, trac * delta)
	elif character and character.controller:
		character.controller.apply_snd_air_movement(input_vec.x, delta)

	# Ataques aéreos: al aterrizar entran en landing lag dedicado o auto-cancel.
	if character and _started_in_air and current_attack_data and current_attack_data.is_aerial and character.is_on_floor():
		var is_autocancel: bool = false
		if current_attack_data.autocancel_before > 0 and frame_cursor <= current_attack_data.autocancel_before:
			is_autocancel = true
		elif current_attack_data.autocancel_after > 0 and frame_cursor >= current_attack_data.autocancel_after:
			is_autocancel = true

		var landing_lag: int
		if is_autocancel:
			landing_lag = Constants.NORMAL_LANDING_LAG_FRAMES
		else:
			var remaining_recovery: int = maxi(0, total_end_frame - frame_cursor)
			var dynamic_landing_lag: int = maxi(Constants.NORMAL_LANDING_LAG_FRAMES, mini(18, remaining_recovery))
			var configured_landing_lag: int = maxi(0, current_attack_data.landing_lag_frames)
			landing_lag = configured_landing_lag if configured_landing_lag > 0 else dynamic_landing_lag

		dbg("aerial_landing_lag", {
			"landing_lag": landing_lag,
			"is_autocancel": is_autocancel,
			"configured": current_attack_data.landing_lag_frames,
			"remaining_recovery": maxi(0, total_end_frame - frame_cursor)
		})
		_cancel_attack_into_landing_lag(landing_lag)
		return

	# ── Aplicación de Impulso Propio 2D ──
	if current_attack_data and (current_attack_data.self_impulse.x != 0.0 or current_attack_data.self_impulse.y != 0.0):
		var target_impulse_frame: int = current_attack_data.self_impulse_frame
		if target_impulse_frame == 0:
			target_impulse_frame = startup_end_frame
		if frame_cursor == target_impulse_frame and character:
			var facing: float = character.get_facing_direction()
			if current_attack_data.self_impulse.y != 0.0:
				character.velocity.y = -current_attack_data.self_impulse.y * Constants.UNIT_SIZE
			if current_attack_data.self_impulse.x != 0.0:
				character.velocity.x = facing * current_attack_data.self_impulse.x * Constants.UNIT_SIZE
			dbg("self_impulse_applied", {
				"vx": snapped(character.velocity.x, 0.01),
				"vy": snapped(character.velocity.y, 0.01)
			})

	# ── Disparo de Proyectiles ──
	if current_attack_data and current_attack_data.spawns_projectile:
		var target_proj_frame: int = current_attack_data.projectile_spawn_frame
		if target_proj_frame == 0:
			target_proj_frame = startup_end_frame
		if frame_cursor == target_proj_frame and character:
			_spawn_projectiles()

	# ── Time Stop (Private Square / ZA WARUDO) ──
	if current_attack_data and current_attack_data.is_time_stop:
		var target_stop_frame: int = current_attack_data.time_stop_frame
		if target_stop_frame == 0:
			target_stop_frame = startup_end_frame
		if frame_cursor == target_stop_frame and character:
			_apply_time_stop()

	if current_attack_data and current_attack_data.disable_gravity_during_active and hitbox_is_active:
		if character and not character.is_on_floor():
			character.velocity.y = minf(character.velocity.y, 0.0)

	dbg_tick(delta, {
		"frame": frame_cursor,
		"hitbox_active": hitbox_is_active,
		"vx": snapped(character.velocity.x if character else 0.0, 0.001),
		"vy": snapped(character.velocity.y if character else 0.0, 0.001)
	})

	# Buffer de combo
	if current_attack_data and current_attack_data.combo_next != null:
		if character.is_normal_attack_pressed():
			_combo_buffered = true

	# Transición al siguiente ataque del combo apenas termina la ventana activa
	if _combo_buffered and current_attack_data and current_attack_data.combo_next != null:
		if frame_cursor >= active_end_frame:
			dbg("to_combo_attack", {
				"next": current_attack_data.combo_next.attack_name
			})
			state_machine.transition_to("Attack", {"attack_data": current_attack_data.combo_next})
			return

	# FAF (First Actionable Frame / IASA): cancelación anticipada del recovery
	var faf_target: int = current_attack_data.faf_frame if (current_attack_data and current_attack_data.faf_frame > 0) else total_end_frame
	if current_attack_data and current_attack_data.combo_next != null and current_attack_data.combo_window_frames > 0:
		faf_target = maxi(faf_target, active_end_frame + mini(current_attack_data.combo_window_frames, current_attack_data.recovery_frames))
	if frame_cursor >= faf_target and frame_cursor < total_end_frame and character:

		if character.is_jump_just_pressed():
			dbg("faf_cancel_jump", {"frame": frame_cursor})
			state_machine.transition_to("JumpSquat")
			return
		if character.is_on_floor() and character.is_shield_pressed():
			dbg("faf_cancel_shield", {"frame": frame_cursor})
			state_machine.transition_to("Shield")
			return
		if character.is_on_floor():
			var faf_move: Vector2 = character.get_input_vector()
			if absf(faf_move.x) > 0.15:
				dbg("faf_cancel_move", {"frame": frame_cursor, "dir": faf_move.x})
				state_machine.transition_to("Run" if absf(faf_move.x) > 0.6 else "Walk")
				return

	# Fin del ataque
	if frame_cursor >= total_end_frame:
		dbg("attack_finished", {"total_frames": total_end_frame})
		_exit_to_next_state()

func _cancel_attack_into_landing_lag(landing_lag: int) -> void:
	if hitbox_is_active:
		hitbox_is_active = false
		if character:
			character.deactivate_hitbox()
	state_machine.transition_to("Idle", {"landing_lag": landing_lag})

func _update_hitbox_window() -> void:
	if current_attack_data == null:
		return

	if frame_cursor >= startup_end_frame and frame_cursor < active_end_frame:
		if not hitbox_is_active:
			hitbox_is_active = true
			if character:
				character.activate_hitbox(current_attack_data)
			dbg("hitbox_opened", {"frame": frame_cursor})
	else:
		if hitbox_is_active:
			hitbox_is_active = false
			if character:
				character.deactivate_hitbox()
			dbg("hitbox_closed", {"frame": frame_cursor})

func exit() -> void:
	if hitbox_is_active:
		hitbox_is_active = false
		if character:
			character.deactivate_hitbox()
	dbg("exit", {
		"frame_cursor": frame_cursor,
		"vx": snapped(character.velocity.x if character else 0.0, 0.001),
		"vy": snapped(character.velocity.y if character else 0.0, 0.001)
	})

func _exit_to_next_state() -> void:
	if character == null:
		return
	if character.is_on_floor():
		var input_vec: Vector2 = character.get_input_vector()
		if abs(input_vec.x) > 0.1:
			dbg("to_run", {"reason": "attack_end_ground_input"})
			state_machine.transition_to("Run")
		else:
			dbg("to_idle", {"reason": "attack_end_ground_idle"})
			state_machine.transition_to("Idle")
	else:
		dbg("to_fall", {"reason": "attack_end_air"})
		state_machine.transition_to("Fall")

func _spawn_projectiles() -> void:
	if not character or not current_attack_data:
		return
		
	var proj_scene: PackedScene = current_attack_data.projectile_scene
	if proj_scene == null:
		proj_scene = preload("res://combat/projectile.tscn")
		
	var facing: float = character.get_facing_direction() if character else 1.0
	var char_pos: Vector2 = Vector2(character.global_position.x, character.global_position.y) if character else Vector2.ZERO
	var spawn_pos: Vector2 = char_pos + Vector2(
		current_attack_data.projectile_offset.x * Constants.UNIT_SIZE * facing,
		-current_attack_data.projectile_offset.y * Constants.UNIT_SIZE
	)
	
	var spread: Array[float] = current_attack_data.projectile_spread_angles
	if spread.is_empty():
		spread = [0.0]
		
	var parent_tree: Node = character.get_parent()
	if parent_tree == null:
		parent_tree = character
		
	var is_airborne: bool = character != null and not character.is_on_floor()
	var aerial_offset: float = current_attack_data.aerial_projectile_angle_offset if is_airborne else 0.0

	for angle_offset_deg in spread:
		var proj_inst: Node = proj_scene.instantiate()
		parent_tree.add_child(proj_inst)
		if proj_inst is Projectile:
			proj_inst.global_position = spawn_pos
			var base_angle_rad: float = 0.0 if facing > 0.0 else PI
			var combined_angle_deg: float = (angle_offset_deg + aerial_offset) * facing
			var angle_rad: float = base_angle_rad + deg_to_rad(combined_angle_deg)
			var dir := Vector2(cos(angle_rad), sin(angle_rad))
			proj_inst.setup(
				current_attack_data,
				character,
				dir,
				current_attack_data.projectile_speed,
				current_attack_data.projectile_lifetime
			)

func _apply_time_stop() -> void:
	if not character:
		return
	Events.trigger_time_stop(current_attack_data.time_stop_duration_sec, character)
	Events.camera_shake_requested.emit(8.0)
