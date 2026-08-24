class_name RunBrakeState
extends State

var brake_timer: float = 0.0
const BRAKE_DURATION: float = 0.20 # 12 frames de frenado de carrera visible

func enter(_msg: Dictionary = {}) -> void:
	brake_timer = BRAKE_DURATION
	dbg("enter", {"brake_timer": snapped(brake_timer, 0.001)})
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("RunBrake")

func exit() -> void:
	dbg("exit", {"vx": snapped(character.velocity.x, 0.001)})

func physics_update(delta: float) -> void:
	brake_timer -= delta
	dbg_tick(delta, {
		"brake_timer": snapped(brake_timer, 0.001),
		"vx": snapped(character.velocity.x, 0.001),
		"input_x": snapped(character.get_input_vector().x, 0.001)
	})
	var trac: float = character.controller.get_traction() if character and character.controller else 30.0
	if character:
		character.velocity.x = move_toward(character.velocity.x, 0.0, trac * delta)

	if character.is_jump_just_pressed():
		dbg("to_jumpsquat", {"reason": "jump_pressed"})
		state_machine.transition_to("JumpSquat")
		return

	if character.is_attack_just_pressed():
		dbg("to_attack", {"reason": "attack_pressed"})
		state_machine.transition_to("Attack")
		return

	if character.is_shield_pressed():
		dbg("to_shield", {"reason": "shield_pressed"})
		state_machine.transition_to("Shield")
		return

	var input_vec: Vector2 = character.get_input_vector()
	if abs(input_vec.x) > 0.1:
		var current_facing: float = character.get_facing_direction()
		if sign(input_vec.x) != current_facing:
			dbg("to_pivot", {"reason": "opposite_input", "input_x": snapped(input_vec.x, 0.001), "facing": current_facing})
			state_machine.transition_to("Pivot", {"target_dir": sign(input_vec.x)})
		else:
			dbg("to_run", {"reason": "resume_run", "input_x": snapped(input_vec.x, 0.001)})
			state_machine.transition_to("Run")
		return

	if brake_timer <= 0.0:
		dbg("to_idle", {"reason": "brake_finished"})
		state_machine.transition_to("Idle")
