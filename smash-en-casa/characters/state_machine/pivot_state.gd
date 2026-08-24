class_name PivotState
extends State

var pivot_timer: float = 0.0
const PIVOT_DURATION: float = 0.14 # ~9 frames de giro visible
var target_dir: float = 1.0

func enter(msg: Dictionary = {}) -> void:
	pivot_timer = PIVOT_DURATION
	target_dir = msg.get("target_dir", 1.0)
	dbg("enter", {"target_dir": target_dir, "pivot_timer": snapped(pivot_timer, 0.001)})
	if character:
		character.set_facing_direction(target_dir)
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Pivot")

func exit() -> void:
	dbg("exit", {"vx": snapped(character.velocity.x, 0.001)})

func physics_update(delta: float) -> void:
	pivot_timer -= delta
	dbg_tick(delta, {
		"pivot_timer": snapped(pivot_timer, 0.001),
		"target_dir": target_dir,
		"vx": snapped(character.velocity.x, 0.001),
		"input_x": snapped(character.get_input_vector().x, 0.001)
	})
	
	# Desaceleración progresiva de la inercia anterior usando la tracción del luchador
	var trac: float = character.controller.get_traction() if character and character.controller else 30.0
	if character:
		character.velocity.x = move_toward(character.velocity.x, 0.0, trac * 2.5 * delta)

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

	if pivot_timer <= 0.0:
		var input_vec: Vector2 = character.get_input_vector() if character else Vector2.ZERO
		if abs(input_vec.x) > 0.1:
			if sign(input_vec.x) == target_dir:
				dbg("to_run", {"reason": "pivot_resolve_forward", "input_x": snapped(input_vec.x, 0.001)})
				state_machine.transition_to("Run")
			else:
				dbg("to_pivot", {"reason": "pivot_chain_reverse", "input_x": snapped(input_vec.x, 0.001)})
				state_machine.transition_to("Pivot", {"target_dir": sign(input_vec.x)})
		else:
			dbg("to_idle", {"reason": "pivot_resolve_neutral"})
			state_machine.transition_to("Idle")
