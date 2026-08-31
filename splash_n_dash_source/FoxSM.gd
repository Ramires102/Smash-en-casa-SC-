extends StateMachine

func _ready():
	add_state("idle")
	add_state("run")
	add_state("jump")
	call_deferred("set_state", states.idle)

func _state_logic(delta):
	parent._apply_movement()
	parent._apply_gravity(delta)

func _get_transition(delta):
	match state:
		states.idle:
			if not parent.is_on_floor():
				if parent.velocity.y < 0:
					return states.jump
				elif parent.velocity.y >= 0:
					return states.idle
			elif parent.velocity.x != 0:
				return states.run
		states.run:
			if not parent.is_on_floor():
				if parent.velocity.y < 0:
					return states.jump
				elif parent.velocity.y >= 0:
					return states.idle
			elif parent.velocity.x != 0:
				return states.idle
		states.jump:
			if parent.is_on_floor():
				return state.idle
			elif parent.velocity.y >= 0:
				return states.idle
	return null

func _enter_state(new_state, old_state):
	pass

func _exit_state(old_state, new_state):
	pass


