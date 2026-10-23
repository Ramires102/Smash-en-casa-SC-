class_name DashState
extends State

var dash_timer: float = 0.0
var dash_dir: float = 1.0
const DASH_DURATION: float = 0.18 # ~11 frames de ventana de Initial Dash (estándar Smash)

func enter(_msg: Dictionary = {}) -> void:
	dash_timer = DASH_DURATION
	if character:
		var input_vec: Vector2 = character.get_input_vector()
		dash_dir = signf(input_vec.x) if absf(input_vec.x) > 0.1 else character.get_facing_direction()
		character.set_facing_direction(dash_dir)
		if InputManager.has_method("consume_dash_intent"):
			InputManager.consume_dash_intent(character.player_id)
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Run")

func physics_update(delta: float) -> void:
	if character == null:
		return

	dash_timer -= delta

	if not character.is_on_floor():
		state_machine.transition_to("Fall")
		return

	var input_vec: Vector2 = character.get_input_vector()

	# DASH-DANCE REAL: si invierte el stick durante el Initial Dash, reiniciar Dash instantáneamente hacia el otro lado
	if absf(input_vec.x) > 0.35 and signf(input_vec.x) != dash_dir:
		dash_dir = signf(input_vec.x)
		dash_timer = DASH_DURATION
		character.set_facing_direction(dash_dir)
		if InputManager.has_method("consume_dash_intent"):
			InputManager.consume_dash_intent(character.player_id)

	var dash_spd: float = character.controller.get_initial_dash_speed() if character.controller else 380.0
	character.velocity.x = dash_dir * dash_spd

	if character.is_jump_just_pressed():
		state_machine.transition_to("JumpSquat")
		return

	if character.is_attack_just_pressed():
		state_machine.transition_to("Attack")
		return

	if character.is_shield_pressed():
		state_machine.transition_to("Shield")
		return

	# Agacharse cancela el Dash (Crouch Cancel / Wavebounce terrestre)
	if input_vec.y < -0.65 and absf(input_vec.x) < 0.4:
		state_machine.transition_to("Squat")
		return

	if dash_timer <= 0.0:
		if absf(input_vec.x) > 0.25 and signf(input_vec.x) == dash_dir:
			state_machine.transition_to("Run")
		else:
			state_machine.transition_to("Idle")
