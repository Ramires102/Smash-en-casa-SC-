# ==============================================================================
# DeathState — Estado Inactivo tras Salir de la Blastzone (KO)
# ==============================================================================
# Oculta al luchador, detiene su velocidad y desactiva su Hurtbox mientras
# `BattleManager` espera el tiempo de respawn (si aún le quedan vidas/stocks).
# ==============================================================================
class_name DeathState
extends State

func enter(_msg: Dictionary = {}) -> void:
	if character:
		character.play_anim("Death")
		character.velocity = Vector2.ZERO
		character.visible = false
		character.set_hurtbox_state(Hurtbox.HurtboxState.INVULNERABLE)
