class_name AttackState
extends State

var attack_timer: float = 0.0
var current_attack_data: AttackData

func enter(_msg: Dictionary = {}) -> void:
	current_attack_data = character.get_current_attack()
	if current_attack_data:
		attack_timer = float(current_attack_data.startup_frames + current_attack_data.active_frames + current_attack_data.recovery_frames) / 60.0
		character.execute_attack(current_attack_data)
	else:
		attack_timer = 0.2

func physics_update(delta: float) -> void:
	attack_timer -= delta
	if attack_timer <= 0.0:
		character.deactivate_hitbox()
		if character.is_on_floor():
			state_machine.transition_to("Idle")
		else:
			state_machine.transition_to("Fall")
