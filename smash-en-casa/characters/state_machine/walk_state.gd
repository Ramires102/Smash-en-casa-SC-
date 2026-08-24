class_name WalkState
extends State

func enter(_msg: Dictionary = {}) -> void:
	dbg("enter")
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Walk")

func exit() -> void:
	dbg("exit")

func physics_update(delta: float) -> void:
	dbg_tick(delta, {
		"vx": snapped(character.velocity.x, 0.001),
		"input_x": snapped(character.get_input_vector().x, 0.001)
	})

	if not character.is_on_floor():
		dbg("to_fall", {"reason": "left_floor"})
		state_machine.transition_to("Fall")
		return

	if character.is_shield_pressed():
		dbg("to_shield", {"reason": "shield_pressed"})
		state_machine.transition_to("Shield")
		return

	var input_vec: Vector2 = character.get_input_vector()
	if abs(input_vec.x) < 0.1:
		var trac: float = character.controller.get_traction() if character and character.controller else 30.0
		character.velocity.x = move_toward(character.velocity.x, 0.0, trac * delta)
		dbg("to_idle", {"reason": "no_horizontal_input"})
		state_machine.transition_to("Idle")
		return

	if input_vec.y < -0.5:
		dbg("to_squat", {"reason": "down_input", "input_y": snapped(input_vec.y, 0.001)})
		state_machine.transition_to("Squat")
		return

	if character.is_dash_intent():
		dbg("to_dash", {"reason": "dash_intent", "input_x": snapped(input_vec.x, 0.001)})
		state_machine.transition_to("Dash")
		return

	var walk_spd: float = character.controller.get_walk_speed() if character.controller else 6.0
	var target_speed_x: float = sign(input_vec.x) * walk_spd
	character.velocity.x = target_speed_x
	character.update_facing_direction(input_vec.x)
	dbg("walk_speed_eval", {
		"walk_spd": snapped(walk_spd, 0.001),
		"target_vx": snapped(target_speed_x, 0.001),
		"real_vx": snapped(character.velocity.x, 0.001)
	})

	if character.is_jump_just_pressed():
		dbg("to_jumpsquat", {"reason": "jump_pressed"})
		state_machine.transition_to("JumpSquat")
		return

	if character.is_attack_just_pressed():
		dbg("to_attack", {"reason": "attack_pressed"})
		state_machine.transition_to("Attack")
		return
