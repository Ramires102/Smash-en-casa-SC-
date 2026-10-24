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
var _impulse_applied: bool = false
var _is_vaulting_behind: bool = false
var has_hit_target: bool = false
var hit_defender: Node2D = null

func enter(msg: Dictionary = {}) -> void:
	if msg.has("attack_data") and msg["attack_data"] != null:
		current_attack_data = msg["attack_data"]
	else:
		current_attack_data = character.get_current_attack()

	if current_attack_data == null:
		state_machine.transition_to("Idle" if character.is_on_floor() else "Fall")
		return

	frame_cursor = 1
	hitbox_is_active = false
	_combo_buffered = false
	_second_hit_triggered = false
	_impulse_applied = false
	_is_vaulting_behind = false
	has_hit_target = false
	hit_defender = msg["hit_defender"] as Node2D if (msg.has("hit_defender") and is_instance_valid(msg["hit_defender"])) else null
	_started_in_air = character != null and not character.is_on_floor()

	if character:
		character.dragged_defender = hit_defender
		if not current_attack_data.is_telekinesis_hold and not current_attack_data.is_telekinesis_throw and not current_attack_data.is_parry_counter_impale:
			character.telekinesis_throw_dir = Vector2(character.get_facing_direction(), 0.0)
		if current_attack_data.is_parry_counter_impale and is_instance_valid(hit_defender):
			var p_facing: float = character.get_facing_direction()
			hit_defender.global_position = Vector2(character.global_position.x + p_facing * 0.92 * Constants.UNIT_SIZE, character.global_position.y)
			hit_defender.velocity = Vector2.ZERO

	if character and character.hitbox and not character.hitbox.hit_confirmed.is_connected(_on_hitbox_hit_confirmed):
		character.hitbox.hit_confirmed.connect(_on_hitbox_hit_confirmed)

	if character and character.attack_controller:
		_started_in_air = character.attack_controller.apply_enter_mechanics(character, current_attack_data, hit_defender)

	startup_end_frame = maxi(1, current_attack_data.startup_frames)
	active_end_frame = startup_end_frame + maxi(1, current_attack_data.active_frames)
	total_end_frame = active_end_frame + maxi(0, current_attack_data.recovery_frames)
	character.execute_attack(current_attack_data)

	if character and character.anim_controller:
		var anim_name: String = current_attack_data.animation_name if current_attack_data.animation_name != "" else "Attack"
		character.anim_controller.play_attack_animation(anim_name, float(maxi(1, total_end_frame)) / 60.0, current_attack_data)

	_sync_frame_phase()

func _on_hitbox_hit_confirmed(impact: ImpactData) -> void:
	has_hit_target = true
	if impact == null or not is_instance_valid(impact.target) or not (impact.target is Node2D):
		return
	hit_defender = impact.target as Node2D
	if character and character.attack_controller:
		var info: Dictionary = character.attack_controller.apply_hit_confirm_mechanics(character, current_attack_data, hit_defender, frame_cursor, active_end_frame)
		if info.get("is_vaulting_behind", false):
			_is_vaulting_behind = true
		if info.get("clear_defender", false):
			hit_defender = null
			character.dragged_defender = null

func physics_update(delta: float) -> void:
	if character == null or current_attack_data == null:
		return

	if current_attack_data.combo_next != null:
		if character.is_normal_attack_pressed() or character.is_special_attack_pressed():
			_combo_buffered = true

	if character.attack_controller:
		character.attack_controller.process_capture_mechanics(character, current_attack_data, hit_defender, frame_cursor, startup_end_frame, active_end_frame)

	if character.has_method("is_self_hitlag_active") and character.is_self_hitlag_active():
		return

	var input_vec: Vector2 = character.get_input_vector()
	if _apply_attack_movement(delta, input_vec):
		return

	frame_cursor += 1
	_sync_frame_phase()

	if current_attack_data.is_telekinesis_hold and current_attack_data.combo_next != null:
		if frame_cursor > startup_end_frame and input_vec.length() > 0.35:
			character.telekinesis_throw_dir = input_vec.normalized()
			state_machine.transition_to("Attack", {"attack_data": current_attack_data.combo_next, "hit_defender": hit_defender})
			return

	if current_attack_data.auto_followup_on_hit != null and not current_attack_data.is_parry_stance:
		if (has_hit_target or current_attack_data.auto_followup_always) and frame_cursor > active_end_frame:
			state_machine.transition_to("Attack", {"attack_data": current_attack_data.auto_followup_on_hit, "hit_defender": hit_defender})
			return

	if _combo_buffered and current_attack_data.combo_next != null and not current_attack_data.is_telekinesis_hold:
		if frame_cursor > active_end_frame:
			state_machine.transition_to("Attack", {"attack_data": current_attack_data.combo_next, "hit_defender": hit_defender})
			return

	if frame_cursor > total_end_frame:
		if current_attack_data.is_telekinesis_hold:
			hit_defender = null
			character.dragged_defender = null
		_exit_to_next_state()

func _apply_attack_movement(delta: float, input_vec: Vector2) -> bool:
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
		character.velocity.x = CharacterController.damp(character.velocity.x, input_vec.x * character.controller.get_air_speed() * 0.75, 5.0, delta)
	return false

func _sync_frame_phase() -> void:
	if current_attack_data == null or character == null:
		return

	var imp: Vector3 = current_attack_data.self_impulse
	var imp_frame: int = maxi(1, current_attack_data.self_impulse_frame) if current_attack_data.self_impulse_frame > 0 else startup_end_frame
	if not _impulse_applied and (imp.x != 0.0 or imp.y != 0.0) and frame_cursor >= imp_frame:
		_impulse_applied = true
		character.velocity.x = imp.x * character.get_facing_direction() * Constants.UNIT_SIZE
		if imp.y != 0.0:
			if imp.y > 0.0 and character.is_on_floor():
				character.global_position.y -= 2.0
			character.velocity.y = -imp.y * Constants.UNIT_SIZE

	if not _second_hit_triggered and current_attack_data.second_hit_frame > 0 and frame_cursor >= current_attack_data.second_hit_frame:
		_second_hit_triggered = true
		if character.hitbox:
			character.hitbox.reset_hit_registry()

	if current_attack_data.spawns_projectile:
		var target_proj_frame: int = current_attack_data.projectile_spawn_frame if current_attack_data.projectile_spawn_frame > 0 else startup_end_frame
		if frame_cursor == target_proj_frame and character.attack_controller:
			character.attack_controller.spawn_projectiles(character, current_attack_data)

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
		if not hitbox_is_active and not current_attack_data.is_parry_stance and not current_attack_data.is_telekinesis_hold:
			hitbox_is_active = true
			character.activate_hitbox(current_attack_data)
	else:
		phase = "recovery"
		if hitbox_is_active:
			hitbox_is_active = false
			character.deactivate_hitbox()

	if character.anim_controller and character.anim_controller.has_method("update_attack_frame"):
		character.anim_controller.update_attack_frame(frame_cursor, phase, current_attack_data)

func exit() -> void:
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
		state_machine.transition_to("Run" if absf(character.get_input_vector().x) > 0.15 else "Idle")
	else:
		state_machine.transition_to("Fall")
