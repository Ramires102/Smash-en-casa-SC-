class_name AttackState
extends State

var current_attack_data: AttackData
var frame_cursor: int = 0
var startup_end_frame: int = 0
var active_end_frame: int = 0
var total_end_frame: int = 0
var hitbox_is_active: bool = false

func enter(_msg: Dictionary = {}) -> void:
	current_attack_data = character.get_current_attack()
	frame_cursor = 0
	hitbox_is_active = false
	dbg("enter", {
		"attack": current_attack_data.attack_name if current_attack_data else "None"
	})
	
	var anim_name: String = "Attack"
	if current_attack_data and current_attack_data.animation_name != "":
		anim_name = current_attack_data.animation_name

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
	frame_cursor += 1
	_update_hitbox_window()
	
	var input_vec: Vector2 = character.get_input_vector() if character else Vector2.ZERO
	
	# Manejo de físicas durante el ataque
	if character and character.is_on_floor():
		# En el suelo: fricción y tracción terrestre
		var trac: float = character.controller.get_traction() if character.controller else 30.0
		character.velocity.x = move_toward(character.velocity.x, 0.0, trac * delta)
	elif character and character.controller:
		# En el aire (ataque aéreo): control de inercia y drift aéreo auténtico
		if abs(input_vec.x) > 0.1:
			var target_vx: float = input_vec.x * character.controller.get_air_speed()
			character.controller.accelerate_air_velocity(target_vx, delta)
		else:
			character.controller.apply_air_friction(delta)

	dbg_tick(delta, {
		"frame": frame_cursor,
		"hitbox_active": hitbox_is_active,
		"vx": snapped(character.velocity.x if character else 0.0, 0.001),
		"vy": snapped(character.velocity.y if character else 0.0, 0.001)
	})

	if frame_cursor >= total_end_frame:
		if character and character.is_on_floor():
			if abs(input_vec.x) > 0.1:
				dbg("to_run", {"reason": "attack_finished_ground_move"})
				state_machine.transition_to("Run")
			else:
				dbg("to_idle", {"reason": "attack_finished_ground_neutral"})
				state_machine.transition_to("Idle")
		else:
			dbg("to_fall", {"reason": "attack_finished_air"})
			state_machine.transition_to("Fall")

func exit() -> void:
	if character:
		character.deactivate_hitbox()
	hitbox_is_active = false
	dbg("exit", {"frame": frame_cursor})

func _update_hitbox_window() -> void:
	if character == null or current_attack_data == null:
		return

	var should_be_active: bool = frame_cursor >= startup_end_frame and frame_cursor < active_end_frame
	if should_be_active and not hitbox_is_active:
		character.activate_hitbox(current_attack_data)
		hitbox_is_active = true
		dbg("hitbox_on", {"frame": frame_cursor})
	elif not should_be_active and hitbox_is_active:
		character.deactivate_hitbox()
		hitbox_is_active = false
		dbg("hitbox_off", {"frame": frame_cursor})
