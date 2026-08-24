class_name DashState
extends State

var dash_timer: float = 0.0
var dash_dir: float = 1.0
const DASH_DURATION: float = 0.15

func enter(_msg: Dictionary = {}) -> void:
	dash_timer = DASH_DURATION
	if character:
		var input_vec: Vector2 = character.get_input_vector()
		dash_dir = sign(input_vec.x) if abs(input_vec.x) > 0.1 else character.get_facing_direction()
		character.set_facing_direction(dash_dir)
	dbg("enter", {"dash_dir": dash_dir, "dash_timer": snapped(dash_timer, 0.001)})
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Run")

func exit() -> void:
	dbg("exit", {"vx": snapped(character.velocity.x, 0.001)})

func physics_update(delta: float) -> void:
	dash_timer -= delta
	dbg_tick(delta, {
		"dash_timer": snapped(dash_timer, 0.001),
		"vx": snapped(character.velocity.x, 0.001),
		"dash_dir": dash_dir,
		"input_x": snapped(character.get_input_vector().x, 0.001)
	})

	var dash_spd: float = character.controller.get_initial_dash_speed() if character and character.controller else 12.0
	if character and character.controller:
		var walk_spd: float = character.controller.get_walk_speed()
		dash_spd = max(dash_spd, walk_spd + 0.01)
	if character:
		character.velocity.x = dash_dir * dash_spd

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

	if abs(input_vec.x) > 0.1 and sign(input_vec.x) != dash_dir:
		dbg("to_pivot", {"reason": "opposite_input", "input_x": snapped(input_vec.x, 0.001), "dash_dir": dash_dir})
		state_machine.transition_to("Pivot", {"target_dir": sign(input_vec.x)})
		return

	if dash_timer <= 0.0:
		if abs(input_vec.x) > 0.1 and sign(input_vec.x) == dash_dir:
			dbg("to_run", {"reason": "dash_end_hold_direction"})
			state_machine.transition_to("Run")
		else:
			dbg("to_run_brake", {"reason": "dash_end_no_hold"})
			state_machine.transition_to("RunBrake")
