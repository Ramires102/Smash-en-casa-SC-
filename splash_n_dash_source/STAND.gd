extends State


func logic():
	.logic()
	if jump == true:
		frame = 0
		next_state = states["JUMP_SQUAT"]
		$State.text = str(next_state)
	if dirV < 0:
		next_state = states["CROUCH"]
		frame = 0
		$State.text = str(next_state)
	if dir > 0:
		player.velocity.x = RUNSPEED
		next_state = states["DASH"]
		$State.text = str(next_state)
		$Sprite.flip_h = false
		
		frame = 0
	elif dir < 0:
		player.velocity.x = - RUNSPEED
		next_state = states["DASH"]
		$State.text = str(next_state)
		$Sprite.flip_h = true
		frame = 0
	if player.velocity.x > 0 and states["STAND"]:
		player.velocity.x = player.velocity.x - TRACTION * 2
	elif player.velocity.x < 0 and states["STAND"]:
		player.velocity.x = player.velocity.x + TRACTION * 2
pass
