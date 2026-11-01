# ==============================================================================
# SpotDodgeState — Esquive Estático en el Sitio
# ==============================================================================
# Vuelve intangible la Hurtbox durante 0.35s sin desplazar al personaje, ideal
# para esquivar un ataque en escudo manteniendo la posición en el escenario.
# ==============================================================================
class_name SpotDodgeState
extends State

const DODGE_DURATION: float = 0.35

var dodge_timer: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	dodge_timer = DODGE_DURATION
	if character:
		character.velocity.x = 0.0
		character.set_hurtbox_state(Hurtbox.HurtboxState.INTANGIBLE)
		character.play_anim("Spotdodge")

func exit() -> void:
	if character:
		character.set_hurtbox_state(Hurtbox.HurtboxState.NORMAL)

func physics_update(delta: float) -> void:
	dodge_timer -= delta
	if character:
		character.velocity.x = 0.0

	if dodge_timer <= 0.0 and character:
		state_machine.transition_to("Idle" if character.is_on_floor() else "Fall")
