class_name AttackState
extends State

var attack_timer: float = 0.0
var current_attack_data: AttackData

func enter(_msg: Dictionary = {}) -> void:
	current_attack_data = character.get_current_attack()
	
	var anim_name: String = "Attack"
	if current_attack_data and current_attack_data.animation_name != "":
		anim_name = current_attack_data.animation_name
		
	if character and character.has_node("AnimationController"):
		character.get_node("AnimationController").play_animation(anim_name)

	if current_attack_data:
		attack_timer = float(current_attack_data.startup_frames + current_attack_data.active_frames + current_attack_data.recovery_frames) / 60.0
		character.execute_attack(current_attack_data)
	else:
		attack_timer = 0.2

func physics_update(delta: float) -> void:
	attack_timer -= delta
	
	if character.is_on_floor():
		var trac: float = character.controller.get_traction() if character and character.controller else 30.0
		character.velocity.x = move_toward(character.velocity.x, 0.0, trac * delta)

	if attack_timer <= 0.0:
		character.deactivate_hitbox()
		if character.is_on_floor():
			if abs(character.get_input_vector().x) > 0.1:
				state_machine.transition_to("Run")
			else:
				state_machine.transition_to("Idle")
		else:
			state_machine.transition_to("Fall")
