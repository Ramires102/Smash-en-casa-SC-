# ==============================================================================
# RollState — Rodada Evasiva Terrestre
# ==============================================================================
# Desplaza horizontalmente al personaje con intangibilidad temporal y, al
# concluir, gira automáticamente para quedar mirando al rival más cercano.
# ==============================================================================
class_name RollState
extends State

const ROLL_DURATION: float = 0.40
const ROLL_SPEED: float = 340.0

var roll_timer: float = 0.0
var roll_dir: float = 1.0

func enter(msg: Dictionary = {}) -> void:
	var fallback_dir: float = character.get_facing_direction() if character else 1.0
	roll_dir = float(msg.get("dir", fallback_dir))
	roll_timer = ROLL_DURATION
	if character:
		character.set_facing_direction(roll_dir)
		character.set_hurtbox_state(Hurtbox.HurtboxState.INTANGIBLE)
		character.play_anim("Roll")

func exit() -> void:
	if character == null:
		return
	character.set_hurtbox_state(Hurtbox.HurtboxState.NORMAL)

	var parent_node: Node = character.get_parent()
	if parent_node:
		for other in parent_node.get_children():
			if other is Character and other != character and other.visible:
				var dx: float = other.global_position.x - character.global_position.x
				if absf(dx) > 0.01:
					character.set_facing_direction(signf(dx))
					break

func physics_update(delta: float) -> void:
	roll_timer -= delta
	if character:
		character.velocity.x = roll_dir * ROLL_SPEED

	if roll_timer <= 0.0:
		if character:
			character.velocity.x = 0.0
			state_machine.transition_to("Idle" if character.is_on_floor() else "Fall")
