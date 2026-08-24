class_name FallState
extends State

func enter(_msg: Dictionary = {}) -> void:
	dbg("enter", {
		"vx": snapped(character.velocity.x if character else 0.0, 0.001),
		"vy": snapped(character.velocity.y if character else 0.0, 0.001)
	})
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Fall")

func exit() -> void:
	dbg("exit", {
		"vx": snapped(character.velocity.x if character else 0.0, 0.001),
		"vy": snapped(character.velocity.y if character else 0.0, 0.001)
	})

func physics_update(delta: float) -> void:
	var input_vec: Vector2 = character.get_input_vector() if character else Vector2.ZERO
	
	# Control de Air Drift auténtico (aceleración y fricción aérea)
	if character and character.controller:
		if abs(input_vec.x) > 0.1:
			var target_vx: float = input_vec.x * character.controller.get_air_speed()
			character.controller.accelerate_air_velocity(target_vx, delta)
			character.update_facing_direction(input_vec.x)
		else:
			character.controller.apply_air_friction(delta)
			
		# Detección de Fast Fall auténtico (toque firme hacia abajo durante caída)
		if input_vec.y < -0.6 and not character.is_fast_falling:
			character.is_fast_falling = true
			character.velocity.y = -character.controller.get_fast_fall_speed()
			dbg("fast_fall_activated", {"vy": snapped(character.velocity.y, 0.001)})

	dbg_tick(delta, {
		"vx": snapped(character.velocity.x if character else 0.0, 0.001),
		"vy": snapped(character.velocity.y if character else 0.0, 0.001),
		"fast_fall": character.is_fast_falling if character else false,
		"input_x": snapped(input_vec.x, 0.001)
	})

	# Aterrizaje suave en el suelo
	if character and character.is_on_floor():
		character.is_fast_falling = false
		if abs(input_vec.x) > 0.1:
			dbg("to_run", {"reason": "landed_with_input", "input_x": snapped(input_vec.x, 0.001)})
			state_machine.transition_to("Run")
		else:
			dbg("to_idle", {"reason": "landed_no_input"})
			state_machine.transition_to("Idle")
		return

	if character and character.is_attack_just_pressed():
		dbg("to_attack", {"reason": "attack_pressed_air"})
		state_machine.transition_to("Attack")
		return
