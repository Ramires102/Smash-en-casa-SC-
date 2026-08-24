class_name FallState
extends State

func enter(_msg: Dictionary = {}) -> void:
	dbg("enter")
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Fall")

func exit() -> void:
	dbg("exit", {"vx": snapped(character.velocity.x, 0.001), "vy": snapped(character.velocity.y, 0.001)})

func physics_update(_delta: float) -> void:
	var input_vec: Vector2 = character.get_input_vector()
	var air_spd: float = character.controller.get_air_speed() if character and character.controller else 6.0
	character.velocity.x = input_vec.x * air_spd
	character.update_facing_direction(input_vec.x)
	dbg_tick(_delta, {
		"vx": snapped(character.velocity.x, 0.001),
		"vy": snapped(character.velocity.y, 0.001),
		"input_x": snapped(input_vec.x, 0.001)
	})

	if character.is_on_floor():
		if abs(input_vec.x) > 0.1:
			dbg("to_run", {"reason": "landed_with_input", "input_x": snapped(input_vec.x, 0.001)})
			state_machine.transition_to("Run")
		else:
			dbg("to_idle", {"reason": "landed_no_input"})
			state_machine.transition_to("Idle")
		return

	if character.is_attack_just_pressed():
		dbg("to_attack", {"reason": "attack_pressed_air"})
		state_machine.transition_to("Attack")
		return
