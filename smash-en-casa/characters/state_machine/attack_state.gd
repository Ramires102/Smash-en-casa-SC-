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
var _second_hit_triggered: bool = false
var _impulse_active_frames: int = 0
var _is_vaulting_behind: bool = false
var has_hit_target: bool = false
var hit_defender: Node2D = null

func enter(msg: Dictionary = {}) -> void:
	if msg.has("attack_data") and msg["attack_data"] != null:
		current_attack_data = msg["attack_data"]
	else:
		current_attack_data = character.get_current_attack()

	frame_cursor = 1
	hitbox_is_active = false
	_combo_buffered = false
	_second_hit_triggered = false
	_impulse_active_frames = 0
	_is_vaulting_behind = false
	has_hit_target = false
	hit_defender = null
	_started_in_air = character != null and not character.is_on_floor()

	if msg.has("hit_defender") and is_instance_valid(msg["hit_defender"]):
		hit_defender = msg["hit_defender"] as Node2D

	if character and character.hitbox:
		if not character.hitbox.hit_confirmed.is_connected(_on_hitbox_hit_confirmed):
			character.hitbox.hit_confirmed.connect(_on_hitbox_hit_confirmed)

	var anim_name: String = "Attack"
	if current_attack_data and current_attack_data.animation_name != "":
		anim_name = current_attack_data.animation_name

	if character and current_attack_data:
		if anim_name == "SpecialUp":
			character.can_up_special = false
		elif anim_name == "SpecialDown" or current_attack_data.is_time_stop:
			if character.has_method("consume_special_down_charge"):
				character.consume_special_down_charge()

	var anim_ctrl: Node = character.get_node_or_null("AnimationController") if character else null

	# 1. Flip facing direction on start (Gogeta Down Special 2: Giro suave de 180° y Patada)
	if character and current_attack_data and current_attack_data.flip_facing_on_start:
		var new_dir: float = -character.get_facing_direction()
		character.set_facing_direction(new_dir)
		if anim_ctrl and anim_ctrl.has_method("set_facing_direction"):
			anim_ctrl.set_facing_direction(new_dir, true)
		if is_instance_valid(hit_defender):
			hit_defender.global_position.x = character.global_position.x + new_dir * 0.96 * Constants.UNIT_SIZE
			hit_defender.global_position.y = minf(hit_defender.global_position.y, character.global_position.y - 0.44 * Constants.UNIT_SIZE)
			hit_defender.velocity = Vector2(0.0, -1.8 * Constants.UNIT_SIZE)
	elif character and current_attack_data:
		var enter_input: Vector2 = character.get_input_vector()
		if absf(enter_input.x) > 0.2 and (not current_attack_data.is_aerial or anim_name.begins_with("Special")):
			character.update_facing_direction(enter_input.x)

	# 2. Posicionamiento automático frente al rival en Up Special Follow-up Punch
	if character and current_attack_data and current_attack_data.pose_style == "up_special_followup_punch":
		var target_opp: Node2D = hit_defender if is_instance_valid(hit_defender) else _find_opponent()
		if is_instance_valid(target_opp):
			var facing: float = character.get_facing_direction()
			target_opp.global_position = Vector2(
				character.global_position.x + facing * 0.88 * Constants.UNIT_SIZE,
				character.global_position.y - 0.06 * Constants.UNIT_SIZE
			)
			target_opp.velocity = Vector2(0.0, -2.2 * Constants.UNIT_SIZE)
		character.velocity = Vector2(character.get_facing_direction() * 1.8 * Constants.UNIT_SIZE, -2.6 * Constants.UNIT_SIZE)

	# 3. Snap in front of opponent (Gogeta Side Special 3: Patada de Hacha)
	if character and current_attack_data and current_attack_data.snap_in_front_of_opponent:
		var opp: Node2D = _find_opponent()
		if is_instance_valid(opp):
			var dx: float = opp.global_position.x - character.global_position.x
			var dir_to_opp: float = (1.0 if dx >= 0.0 else -1.0) if absf(dx) > 4.0 else character.get_facing_direction()
			character.set_facing_direction(dir_to_opp)
			character.global_position.x = opp.global_position.x - dir_to_opp * 1.12 * Constants.UNIT_SIZE
			character.global_position.y = minf(character.global_position.y, opp.global_position.y - 0.42 * Constants.UNIT_SIZE)
			character.velocity = Vector2(0.0, -1.5 * Constants.UNIT_SIZE)
			_started_in_air = true

	# 4. Divekick initial stall or jump lift (Gogeta Down Air)
	if character and current_attack_data and current_attack_data.is_divekick:
		character.is_fast_falling = false
		if character.is_on_floor():
			character.global_position.y -= 2.0
			character.velocity.y = -8.5 * Constants.UNIT_SIZE
			character.velocity.x = character.get_facing_direction() * 1.5 * Constants.UNIT_SIZE
			_started_in_air = true
		else:
			character.velocity.x *= 0.25
			character.velocity.y = minf(0.0, character.velocity.y * 0.15)

	if current_attack_data:
		startup_end_frame = maxi(1, current_attack_data.startup_frames)
		active_end_frame = startup_end_frame + maxi(1, current_attack_data.active_frames)
		total_end_frame = active_end_frame + maxi(0, current_attack_data.recovery_frames)
		character.execute_attack(current_attack_data)
	else:
		startup_end_frame = 1
		active_end_frame = 2
		total_end_frame = 12

	if anim_ctrl:
		if anim_ctrl.has_method("play_attack_animation"):
			var total_duration_sec: float = float(maxi(1, total_end_frame)) / 60.0
			anim_ctrl.play_attack_animation(anim_name, total_duration_sec, current_attack_data)
		elif anim_ctrl.has_method("play_animation"):
			anim_ctrl.play_animation(anim_name)

	_update_hitbox_window()
	_sync_anim_controller_phase()

func _on_hitbox_hit_confirmed(impact: ImpactData) -> void:
	has_hit_target = true
	if impact == null or not is_instance_valid(impact.target) or not (impact.target is Node2D):
		return
	hit_defender = impact.target as Node2D
	var facing: float = character.get_facing_direction()

	# A. Jab 3: Doble Mazo y Voltereta detrás del rival (vault_behind_on_hit)
	if current_attack_data and current_attack_data.vault_behind_on_hit:
		_is_vaulting_behind = true
		character.global_position.y -= 2.0
		character.velocity.x = facing * 9.2 * Constants.UNIT_SIZE
		character.velocity.y = -7.8 * Constants.UNIT_SIZE
		_override_defender_pending_kb(Vector2(facing * 1.5 * Constants.UNIT_SIZE, -6.4 * Constants.UNIT_SIZE))

	# B. Up Special: Arrastre en la voltereta diagonal (drag_defender_on_hit)
	if current_attack_data and current_attack_data.drag_defender_on_hit:
		_extend_defender_hitstun((active_end_frame - frame_cursor) + 20)
		_override_defender_pending_kb(Vector2(character.velocity.x, minf(character.velocity.y, -8.5 * Constants.UNIT_SIZE)))

	# C. Down Special 1: Codazo que levanta al rival por encima del hombro (toss_behind_on_hit)
	if current_attack_data and current_attack_data.toss_behind_on_hit:
		hit_defender.global_position.x = character.global_position.x + facing * 0.78 * Constants.UNIT_SIZE
		hit_defender.global_position.y = minf(hit_defender.global_position.y, character.global_position.y - 0.24 * Constants.UNIT_SIZE)
		_extend_defender_hitstun((active_end_frame - frame_cursor) + 32)
		_override_defender_pending_kb(Vector2(-facing * 2.2 * Constants.UNIT_SIZE, -6.8 * Constants.UNIT_SIZE))

	# D. Down Air: Derribo deslizante por el piso (sliding_knockdown)
	if current_attack_data and current_attack_data.sliding_knockdown:
		_extend_defender_hitstun(38)
		_override_defender_pending_kb(Vector2(facing * 13.2 * Constants.UNIT_SIZE, -0.3 * Constants.UNIT_SIZE))
		var def_anim: Node = hit_defender.get_node_or_null("AnimationController")
		if def_anim and "is_sliding_knockdown" in def_anim:
			def_anim.is_sliding_knockdown = true

func physics_update(delta: float) -> void:
	if character == null:
		return

	if current_attack_data and current_attack_data.combo_next != null:
		if character.is_normal_attack_pressed() or character.is_special_attack_pressed():
			_combo_buffered = true

	_process_defender_capture_mechanics()

	if character.has_method("is_self_hitlag_active") and character.is_self_hitlag_active():
		return

	frame_cursor += 1
	if _impulse_active_frames > 0:
		_impulse_active_frames -= 1

	_update_hitbox_window()
	_sync_anim_controller_phase()

	var input_vec: Vector2 = character.get_input_vector()

	# ── 1. Impulso Propio 2D (Lunges, Rekkas, Up-B, Down-B) ─────────────
	if current_attack_data and (current_attack_data.self_impulse.x != 0.0 or current_attack_data.self_impulse.y != 0.0):
		var target_impulse_frame: int = current_attack_data.self_impulse_frame
		if target_impulse_frame <= 0:
			target_impulse_frame = maxi(1, startup_end_frame)
		if frame_cursor == target_impulse_frame:
			var facing: float = character.get_facing_direction()
			if current_attack_data.self_impulse.y != 0.0:
				if current_attack_data.self_impulse.y > 0.0 and character.is_on_floor():
					character.global_position.y -= 2.0
				character.velocity.y = -current_attack_data.self_impulse.y * Constants.UNIT_SIZE
			if current_attack_data.self_impulse.x != 0.0:
				character.velocity.x = facing * current_attack_data.self_impulse.x * Constants.UNIT_SIZE
			_impulse_active_frames = maxi(10, current_attack_data.active_frames + 5)

	# ── 2. Físicas de Divekick (Down Air de Gogeta) ─────────────────────
	if current_attack_data and current_attack_data.is_divekick:
		var facing: float = character.get_facing_direction()
		if frame_cursor <= startup_end_frame:
			character.velocity.x = move_toward(character.velocity.x, 0.0, 450.0 * delta)
			character.velocity.y = -character.get_gravity_value() * delta * 0.90
		elif frame_cursor <= active_end_frame:
			if character.is_on_floor() and frame_cursor > startup_end_frame + 2:
				if hitbox_is_active:
					hitbox_is_active = false
					character.deactivate_hitbox()
				Events.camera_shake_requested.emit(6.0)
				character.velocity.x = facing * 4.5 * Constants.UNIT_SIZE
				character.velocity.y = 0.0
				# Pasa a los frames de landing recovery en cuclillas (como en attack_state.ts)
				frame_cursor = active_end_frame + 1
				var land_rec: int = current_attack_data.landing_lag_frames if current_attack_data.landing_lag_frames > 0 else 9
				total_end_frame = active_end_frame + land_rec
				_sync_anim_controller_phase()
				return
			else:
				character.velocity.x = facing * 13.5 * Constants.UNIT_SIZE
				character.velocity.y = 20.0 * Constants.UNIT_SIZE
		else:
			if character.is_on_floor():
				character.velocity.x = move_toward(character.velocity.x, 0.0, 950.0 * delta)
	elif not _is_vaulting_behind:
		# ── 3. Físicas Terrestres / Aéreas Estándar ─────────────────────
		if character.is_on_floor():
			var trac: float = character.controller.get_traction() if character.controller else 950.0
			if _impulse_active_frames > 0:
				trac *= 0.20
			elif hitbox_is_active:
				trac *= 0.50
			character.velocity.x = move_toward(character.velocity.x, 0.0, trac * delta)
		elif character.controller and _impulse_active_frames <= 0:
			character.controller.apply_snd_air_movement(input_vec.x, delta)

	# ── 4. Disparo de Proyectiles (Sans, Sakuya, etc.) ──────────────────
	if current_attack_data and current_attack_data.spawns_projectile:
		var target_proj_frame: int = current_attack_data.projectile_spawn_frame
		if target_proj_frame == 0:
			target_proj_frame = startup_end_frame
		if frame_cursor == target_proj_frame and character:
			_spawn_projectiles()

	# ── 5. Time Stop (Private Square / The World) ───────────────────────
	if current_attack_data and current_attack_data.is_time_stop:
		var target_stop_frame: int = current_attack_data.time_stop_frame
		if target_stop_frame == 0:
			target_stop_frame = startup_end_frame
		if frame_cursor == target_stop_frame and character:
			_apply_time_stop()

	# ── 6. Reseteo de Hitbox para Multi-Hit (Jab 1 y Up-B) ──────────────
	if current_attack_data and current_attack_data.second_hit_frame > 0:
		if frame_cursor >= current_attack_data.second_hit_frame and not _second_hit_triggered:
			_second_hit_triggered = true
			if character.hitbox:
				character.hitbox.reset_hit_registry()

	# ── 7. Auto-Followup en Impacto (Up-B -> Piña / Down-B -> Patada) ───
	if current_attack_data and current_attack_data.auto_followup_on_hit != null:
		if (has_hit_target or current_attack_data.auto_followup_always) and frame_cursor > active_end_frame:
			var follow_up: AttackData = current_attack_data.auto_followup_on_hit
			var pass_def: Node2D = hit_defender
			state_machine.transition_to("Attack", {"attack_data": follow_up, "hit_defender": pass_def})
			return

	# ── 8. Cadena de Combo Buffer (Jab 1->2->3 / Rekka 1->2->3) ─────────
	if _combo_buffered and current_attack_data and current_attack_data.combo_next != null:
		if frame_cursor > active_end_frame:
			state_machine.transition_to("Attack", {"attack_data": current_attack_data.combo_next, "hit_defender": hit_defender})
			return

	# ── 9. FAF (First Actionable Frame / IASA) ──────────────────────────
	var faf_target: int = current_attack_data.faf_frame if (current_attack_data and current_attack_data.faf_frame > 0) else total_end_frame
	if current_attack_data and current_attack_data.combo_next != null and current_attack_data.combo_window_frames > 0:
		faf_target = maxi(faf_target, active_end_frame + mini(current_attack_data.combo_window_frames, current_attack_data.recovery_frames))
	if frame_cursor >= faf_target and frame_cursor < total_end_frame and character:
		if character.is_jump_just_pressed():
			state_machine.transition_to("JumpSquat")
			return
		if character.is_on_floor() and character.is_shield_pressed():
			state_machine.transition_to("Shield")
			return
		if character.is_on_floor():
			var faf_move: Vector2 = character.get_input_vector()
			if absf(faf_move.x) > 0.15:
				state_machine.transition_to("Run" if absf(faf_move.x) > 0.65 else "Walk")
				return

	if frame_cursor > total_end_frame:
		_exit_to_next_state()

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

func _process_defender_capture_mechanics() -> void:
	if current_attack_data == null or not is_instance_valid(hit_defender):
		return

	var facing: float = character.get_facing_direction()

	# Arrastre durante Up-B (Somersault)
	if current_attack_data.drag_defender_on_hit and frame_cursor <= active_end_frame:
		var target_pos := Vector2(
			character.global_position.x + facing * 0.78 * Constants.UNIT_SIZE,
			character.global_position.y - 0.10 * Constants.UNIT_SIZE
		)
		hit_defender.global_position = hit_defender.global_position.lerp(target_pos, 0.55)
		hit_defender.velocity = character.velocity
		_override_defender_pending_kb(character.velocity)

	# Codazo Cambia-Lado (Down Special 1): 35% en el codo, 65% arco sobre el hombro hacia la espalda
	if current_attack_data.toss_behind_on_hit and frame_cursor <= active_end_frame:
		var active_len: int = maxi(1, active_end_frame - startup_end_frame)
		var active_progress: float = clampf(float(frame_cursor - startup_end_frame) / float(active_len), 0.0, 1.0)
		var arc_t: float = smoothstep(0.32, 1.0, active_progress)
		var local_offset_x: float = lerpf(0.78, -0.98, arc_t) * facing * Constants.UNIT_SIZE
		var arc_height: float = (0.26 + sin(arc_t * PI) * 0.62 + arc_t * 0.20) * Constants.UNIT_SIZE
		var target_vec := Vector2(character.global_position.x + local_offset_x, character.global_position.y - arc_height)
		hit_defender.global_position = hit_defender.global_position.lerp(target_vec, 0.55)
		hit_defender.velocity = Vector2(-facing * 1.2 * Constants.UNIT_SIZE, -2.0 * Constants.UNIT_SIZE)
		_override_defender_pending_kb(Vector2.ZERO)

	# Suspensión del rival frente al nuevo lado durante el giro de 180° en Down Special 2
	if current_attack_data.flip_facing_on_start and frame_cursor <= startup_end_frame:
		var target_vec := Vector2(
			character.global_position.x + facing * 0.96 * Constants.UNIT_SIZE,
			character.global_position.y - 0.44 * Constants.UNIT_SIZE
		)
		hit_defender.global_position = hit_defender.global_position.lerp(target_vec, 0.45)
		hit_defender.velocity = Vector2(0.0, -1.4 * Constants.UNIT_SIZE)
		_override_defender_pending_kb(Vector2.ZERO)

func _sync_anim_controller_phase() -> void:
	if character == null:
		return
	var anim_ctrl: Node = character.get_node_or_null("AnimationController")
	if anim_ctrl and anim_ctrl.has_method("update_attack_frame"):
		var phase: String = "startup"
		if frame_cursor <= startup_end_frame:
			phase = "startup"
		elif frame_cursor <= active_end_frame:
			phase = "active"
		else:
			phase = "recovery"
		anim_ctrl.update_attack_frame(frame_cursor, phase, current_attack_data)

func _extend_defender_hitstun(min_frames: int) -> void:
	if is_instance_valid(hit_defender) and "state_machine" in hit_defender and hit_defender.state_machine and hit_defender.state_machine.current_state:
		var st: Node = hit_defender.state_machine.current_state
		if "_hitstun_remaining" in st:
			st._hitstun_remaining = maxi(st._hitstun_remaining, min_frames)

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

func _update_hitbox_window() -> void:
	if current_attack_data == null:
		return
	if frame_cursor > startup_end_frame and frame_cursor <= active_end_frame:
		if not hitbox_is_active:
			hitbox_is_active = true
			if character:
				character.activate_hitbox(current_attack_data)
	else:
		if hitbox_is_active:
			hitbox_is_active = false
			if character:
				character.deactivate_hitbox()

func exit() -> void:
	if character and character.hitbox and character.hitbox.hit_confirmed.is_connected(_on_hitbox_hit_confirmed):
		character.hitbox.hit_confirmed.disconnect(_on_hitbox_hit_confirmed)
	if hitbox_is_active:
		hitbox_is_active = false
		if character:
			character.deactivate_hitbox()
	if _is_vaulting_behind and character:
		_is_vaulting_behind = false
		var new_dir: float = -character.get_facing_direction()
		character.set_facing_direction(new_dir)
		var anim_ctrl: Node = character.get_node_or_null("AnimationController")
		if anim_ctrl and anim_ctrl.has_method("set_facing_direction"):
			anim_ctrl.set_facing_direction(new_dir, true)

func _exit_to_next_state() -> void:
	if character == null:
		return
	if character.is_on_floor():
		var input_vec: Vector2 = character.get_input_vector()
		if absf(input_vec.x) > 0.15:
			state_machine.transition_to("Run" if absf(input_vec.x) > 0.65 else "Walk")
		else:
			state_machine.transition_to("Idle")
	else:
		state_machine.transition_to("Fall")
