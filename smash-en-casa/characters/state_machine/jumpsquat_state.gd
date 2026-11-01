# ==============================================================================
# JumpSquatState — Preparación de Salto (Out-of-Shield y Jump-Cancels)
# ==============================================================================
# Estado puente al saltar desde el escudo (`ShieldState`), permitiendo ejecutar
# opciones avanzadas de juegos de pelea como Up-Special o Up-Smash Out-of-Shield
# y el macro de Short-Hop Aerial.
# ==============================================================================
class_name JumpSquatState
extends State

var squat_frames_left: int = 3
var is_short_hop: bool = true
var buffered_shorthop_aerial: bool = false

func enter(_msg: Dictionary = {}) -> void:
	squat_frames_left = character.controller.get_jumpsquat_frames() if (character and character.controller) else 3
	is_short_hop = true
	buffered_shorthop_aerial = false
	if character:
		character.play_anim("JumpSquat")

func physics_update(delta: float) -> void:
	squat_frames_left -= 1

	if character and character.controller:
		var trac: float = character.controller.get_traction() * 0.45
		character.velocity.x = move_toward(character.velocity.x, 0.0, trac * delta)

	if character:
		var in_vec: Vector2 = character.get_input_vector()

		# 1. Jump-Cancel Up-Special (Out of Shield)
		if in_vec.y > 0.35 and character.is_special_attack_pressed():
			state_machine.transition_to("Attack")
			return

		# 2. Jump-Cancel Up-Smash
		if in_vec.y > 0.55 and character.is_dash_intent() and character.is_normal_attack_pressed():
			state_machine.transition_to("Attack")
			return

		# 3. Short-Hop Aerial Macro si se presiona Ataque durante la flexión
		if character.has_attack_buffered():
			buffered_shorthop_aerial = true

	if squat_frames_left <= 0:
		if character:
			is_short_hop = (not character.is_jump_held()) or buffered_shorthop_aerial
		var input_vec: Vector2 = character.get_input_vector() if character else Vector2.ZERO
		state_machine.transition_to("Jump", {
			"short_hop": is_short_hop,
			"initial_vx": character.velocity.x if character else 0.0,
			"input_x": input_vec.x,
			"instant_aerial": buffered_shorthop_aerial
		})
