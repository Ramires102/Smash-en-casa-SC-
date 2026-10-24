class_name JumpState
extends State

func enter(msg: Dictionary = {}) -> void:
	if character == null:
		return
	var is_double_jump: bool = msg.get("is_double_jump", false)
	var mult: float = 0.94 if is_double_jump else float(msg.get("multiplier", 1.0))
	var jump_vel: float = character.controller.get_jump_velocity() if character.controller else (12.4 * Constants.UNIT_SIZE)

	character.velocity.y = -jump_vel * mult
	if msg.has("initial_vx"):
		character.velocity.x = msg["initial_vx"]

	if character.anim_controller:
		character.anim_controller.is_double_jumping = is_double_jump
		character.anim_controller.play_animation("DoubleJump" if is_double_jump else "Jump")

func exit() -> void:
	if character and character.anim_controller:
		character.anim_controller.is_double_jumping = false

func physics_update(delta: float) -> void:
	if character == null:
		return

	var input_vec: Vector2 = character.get_input_vector()
	if absf(input_vec.x) > 0.1 and character.controller:
		var target_vx: float = input_vec.x * character.controller.get_air_speed()
		character.velocity.x = CharacterController.damp(character.velocity.x, target_vx, 8.0, delta)

	if character.is_attack_just_pressed():
		state_machine.transition_to("Attack")
		return

	if character.air_jumps_left > 0 and character.is_jump_just_pressed():
		character.air_jumps_left -= 1
		state_machine.transition_to("Jump", {"is_double_jump": true})
		return

	if character.is_shield_pressed() and character.can_air_dodge:
		state_machine.transition_to("AirDodge")
		return

	if character.velocity.y >= 0.0:
		state_machine.transition_to("Fall")
