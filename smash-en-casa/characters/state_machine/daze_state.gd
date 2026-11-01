# ==============================================================================
# DazeState — Aturdimiento por Ruptura de Escudo (Shield Break)
# ==============================================================================
# Deja al luchador mareado de 4 a 10 segundos (según su % de daño). El jugador
# puede machacar botones (`handle_input`) para reducir el tiempo de penalización.
# ==============================================================================
class_name DazeState
extends State

var daze_timer: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	var damage_pct: float = character.damage_percentage if character else 0.0
	daze_timer = clampf(4.0 + (damage_pct * 0.05), 4.0, 10.0)
	if character:
		character.play_anim("Hit")

func handle_input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo():
		daze_timer -= 0.15

func physics_update(delta: float) -> void:
	daze_timer -= delta
	if character:
		var trac: float = character.controller.get_traction() if character.controller else 30.0
		character.velocity.x = move_toward(character.velocity.x, 0.0, trac * delta)

	if daze_timer <= 0.0 and character:
		if character.shield_controller:
			character.shield_controller.restore_after_break()
		state_machine.transition_to("Idle" if character.is_on_floor() else "Fall")
