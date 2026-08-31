class_name RunState
extends State

const RUN_TO_WALK_THRESHOLD: float = 0.55

func enter(_msg: Dictionary = {}) -> void:
	dbg("enter")
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Run")

func exit() -> void:
	dbg("exit", {"vx": snapped(character.velocity.x, 0.001)})

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

	if input_vec.y < -0.5:
		dbg("to_squat", {"reason": "down_input_from_run", "input_y": snapped(input_vec.y, 0.001)})
		state_machine.transition_to("Squat")
		return

	if abs(input_vec.x) < 0.1:
		dbg("to_run_brake", {"reason": "no_horizontal_input"})
		state_machine.transition_to("RunBrake")
		return

	if abs(input_vec.x) < RUN_TO_WALK_THRESHOLD:
		dbg("to_walk", {
			"reason": "below_run_threshold",
			"input_x": snapped(input_vec.x, 0.001),
			"threshold": RUN_TO_WALK_THRESHOLD
		})
		state_machine.transition_to("Walk")
		return

	var current_facing: float = character.get_facing_direction()
	if sign(input_vec.x) != current_facing and abs(input_vec.x) > 0.1:
		dbg("to_pivot", {
			"reason": "opposite_input",
			"input_x": snapped(input_vec.x, 0.001),
			"facing": current_facing
		})
		state_machine.transition_to("Pivot", {"target_dir": sign(input_vec.x)})
		return

	var run_spd: float = character.controller.get_run_speed() if character.controller else 10.0
	var target_speed_x: float = sign(input_vec.x) * run_spd
	if character and character.controller:
		character.controller.accelerate_ground_velocity(target_speed_x, delta, 1.2)
	character.update_facing_direction(input_vec.x)
	dbg("run_speed_eval", {
		"run_spd": snapped(run_spd, 0.001),
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
