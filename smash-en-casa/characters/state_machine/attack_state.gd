class_name AttackState
extends State

var current_attack_data: AttackData
var attack_elapsed: float = 0.0
var startup_duration: float = 0.0
var active_duration: float = 0.0
var total_duration: float = 0.0

var _hitbox_activated: bool = false
var _hitbox_deactivated: bool = false

func enter(_msg: Dictionary = {}) -> void:
	current_attack_data = character.get_current_attack()
	attack_elapsed = 0.0
	_hitbox_activated = false
	_hitbox_deactivated = false
	
	var anim_name: String = "Attack"
	if current_attack_data and current_attack_data.animation_name != "":
		anim_name = current_attack_data.animation_name
		
	if current_attack_data:
		startup_duration = float(current_attack_data.startup_frames) / 60.0
		active_duration = float(current_attack_data.active_frames) / 60.0
		var recovery_duration: float = float(current_attack_data.recovery_frames) / 60.0
		total_duration = startup_duration + active_duration + recovery_duration
		
		# Iniciar ataque (notificar a controladores), pero NO activar hitbox aún
		if character:
			character.execute_attack(current_attack_data)
	else:
		startup_duration = 0.06
		active_duration = 0.10
		total_duration = 0.28

	# Reproducir animación sincronizada con la duración del ataque
	if character and character.has_node("AnimationController"):
		var anim_ctrl: AnimationController = character.get_node("AnimationController")
		anim_ctrl.play_attack_animation(anim_name, total_duration)

func physics_update(delta: float) -> void:
	attack_elapsed += delta
	
	# Manejo de tracción/fricción mientras ataca en el suelo
	if character and character.is_on_floor():
		var trac: float = character.controller.get_traction() if character.controller else 30.0
		character.velocity.x = move_toward(character.velocity.x, 0.0, trac * delta)
	
	# Fase 2: Ventana Activa (Active frames) -> Activar Hitbox al terminar el startup
	if not _hitbox_activated and attack_elapsed >= startup_duration:
		_hitbox_activated = true
		if character and current_attack_data:
			character.activate_hitbox(current_attack_data)
	
	# Fase 3: Recuperación (Endlag) -> Desactivar Hitbox en cuanto termina la ventana activa
	if _hitbox_activated and not _hitbox_deactivated and attack_elapsed >= (startup_duration + active_duration):
		_hitbox_deactivated = true
		if character:
			character.deactivate_hitbox()
			
	# Fase 4: Fin de Ataque -> Transición de vuelta a Idle o Fall
	if attack_elapsed >= total_duration:
		if not _hitbox_deactivated:
			if character:
				character.deactivate_hitbox()
		if character.is_on_floor():
			if abs(character.get_input_vector().x) > 0.1:
				state_machine.transition_to("Run")
			else:
				state_machine.transition_to("Idle")
		else:
			state_machine.transition_to("Fall")

func exit() -> void:
	# Asegurar que el hitbox siempre se desactive al salir del estado
	if character:
		character.deactivate_hitbox()
