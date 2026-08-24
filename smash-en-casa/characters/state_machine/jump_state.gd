class_name JumpState
extends State

func enter(msg: Dictionary = {}) -> void:
	var mult: float = msg.get("multiplier", 1.0)
	character.velocity.y = character.jump_velocity * mult
	dbg("enter", {"jump_mult": mult, "vy": snapped(character.velocity.y, 0.001)})
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Jump")

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

	if character.velocity.y <= 0:
		dbg("to_fall", {"reason": "vy_non_positive", "vy": snapped(character.velocity.y, 0.001)})
		state_machine.transition_to("Fall")
		return

	if character.is_attack_just_pressed():
		dbg("to_attack", {"reason": "attack_pressed_air"})
		state_machine.transition_to("Attack")
		return
