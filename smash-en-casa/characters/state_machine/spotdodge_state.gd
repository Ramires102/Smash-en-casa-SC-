class_name SpotDodgeState
extends State

var dodge_timer: float = 0.0
const DODGE_DURATION: float = 0.35

func enter(_msg: Dictionary = {}) -> void:
	dodge_timer = DODGE_DURATION
	if character:
		character.velocity.x = 0.0
	if character and character.hurtbox:
		character.hurtbox.monitoring = false # Invulnerable en el sitio
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation("Spotdodge")

func exit() -> void:
	if character and character.hurtbox:
		character.hurtbox.monitoring = true

func physics_update(delta: float) -> void:
	dodge_timer -= delta
	if character:
		character.velocity.x = 0.0
	
	if dodge_timer <= 0.0:
		if character and character.is_on_floor():
			state_machine.transition_to("Idle")
		else:
			state_machine.transition_to("Fall")
