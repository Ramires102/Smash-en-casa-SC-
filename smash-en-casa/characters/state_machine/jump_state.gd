class_name JumpState
extends State

func enter(msg: Dictionary = {}) -> void:
	var mult: float = msg.get("multiplier", 1.0)
	var jump_vel: float = character.jump_velocity if character else 14.0
	if character:
		character.velocity.y = jump_vel * mult
		if msg.has("initial_vx"):
			character.velocity.x = msg["initial_vx"]
	
	dbg("enter", {
		"jump_mult": mult,
		"vy": snapped(character.velocity.y if character else 0.0, 0.001),
		"vx": snapped(character.velocity.x if character else 0.0, 0.001)
	})
	
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Jump")

func exit() -> void:
	dbg("exit", {
		"vx": snapped(character.velocity.x if character else 0.0, 0.001),
		"vy": snapped(character.velocity.y if character else 0.0, 0.001)
	})

func physics_update(delta: float) -> void:
	var input_vec: Vector2 = character.get_input_vector() if character else Vector2.ZERO
	
	# Control de Air Drift auténtico con aceleración y fricción aérea
	if character and character.controller:
		if abs(input_vec.x) > 0.1:
			var target_vx: float = input_vec.x * character.controller.get_air_speed()
			character.controller.accelerate_air_velocity(target_vx, delta)
			character.update_facing_direction(input_vec.x)
		else:
			character.controller.apply_air_friction(delta)
	
	dbg_tick(delta, {
		"vx": snapped(character.velocity.x if character else 0.0, 0.001),
		"vy": snapped(character.velocity.y if character else 0.0, 0.001),
		"input_x": snapped(input_vec.x, 0.001)
	})

	# Al alcanzar el ápice del salto (vy <= 0) transiciona a caída
	if character and character.velocity.y <= 0.0:
		dbg("to_fall", {"reason": "apex_reached", "vy": snapped(character.velocity.y, 0.001)})
		state_machine.transition_to("Fall")
		return

	if character and character.is_attack_just_pressed():
		dbg("to_attack", {"reason": "attack_pressed_air"})
		state_machine.transition_to("Attack")
		return
