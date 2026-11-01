# ==============================================================================
# RunState — Estado de Carrera Terrestre
# ==============================================================================
# Acelera suavemente hacia la velocidad máxima horizontal en la dirección del
# stick y permite cancelar inmediatamente en Ataque, Salto, Escudo o Caída.
# ==============================================================================
class_name RunState
extends State

func enter(_msg: Dictionary = {}) -> void:
	if character:
		character.play_anim("Run")

func physics_update(delta: float) -> void:
	if character == null:
		return

	if not character.is_on_floor():
		state_machine.transition_to("Fall")
		return
	if character.is_attack_just_pressed():
		state_machine.transition_to("Attack")
		return
	if character.is_jump_just_pressed():
		state_machine.transition_to("Jump")
		return
	if character.is_shield_pressed():
		state_machine.transition_to("Shield")
		return

	var input_vec: Vector2 = character.get_input_vector()
	if character.try_drop_through_platform(input_vec):
		state_machine.transition_to("Fall")
		return

	if absf(input_vec.x) <= 0.1:
		state_machine.transition_to("Idle")
		return

	character.set_facing_direction(1.0 if input_vec.x > 0.0 else -1.0)
	var run_spd: float = character.controller.get_run_speed() if character.controller else (8.6 * Constants.UNIT_SIZE)
	if character.controller:
		character.controller.accelerate_ground_velocity(input_vec.x * run_spd, delta)
