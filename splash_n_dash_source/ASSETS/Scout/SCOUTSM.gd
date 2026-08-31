extends StateMachine
var id
var cooldown_gun = 0
func _ready():
	self.id = get_parent().id
	add_state("STAND")
	add_state("JUMP_SQUAT")
	add_state("FULL_HOP")
	add_state("SHORT_HOP")
	add_state("MOONWALK")
	add_state("DASH")
	add_state("RUN")
	add_state("WALK")
	add_state("TURN")
	add_state("CROUCH")
	add_state("AIR")
	add_state("FREE_FALL")
	add_state("AIR_DODGE")
	add_state("LANDING")
	add_state("LEDGE_CATCH")
	add_state("LEDGE_HOLD")
	add_state("LEDGE_CLIMB")
	add_state("LEDGE_JUMP")
	add_state("LEDGE_ROLL")
	add_state("HITSTUN")
	add_state("TUMBLE")
	add_state("PARRY")
	add_state("ROLL_RIGHT")
	add_state("ROLL_LEFT")
	add_state("TECH")
	add_state("TECH_GROUND")
	add_state("TECH_FORWARD")
	add_state("TECH_BACKWARD")
	add_state("GROUND_ATTACK")
	add_state("UP_TILT")

	add_state("DOWN_TILT")
	add_state("FORWARD_TILT")
	add_state("JAB")
	add_state("JAB_1")
	add_state("SPECIAL")
	add_state("DOWN_SPECIAL")
	add_state("FORWARD_SPECIAL")
	add_state("NEUTRAL_SPECIAL")
	add_state("UP_SPECIAL")
	add_state("UP_SPECIAL_1")
	add_state("AIR_ATTACK")
	add_state("NAIR")
	add_state("UAIR")
	add_state("BAIR")
	add_state("FAIR")
	add_state("DAIR")
	add_state("SMASH_ATTACK")
	add_state("DOWN_SMASH")
	add_state("DOWN_SMASH_1")
	add_state("UP_SMASH")
	add_state("UP_SMASH_1")
	add_state("FORWARD_SMASH")
	add_state("FORWARD_SMASH_1")
	add_state("RESPAWN")
	add_state("DEAD")

	call_deferred("set_state", states.STAND)

func state_logic(delta):
	parent.updateframes()
	
	parent._physics_process(delta)


	parent.down_buffer()
	parent.up_buffer()
	parent.right_buffer()
	parent.left_buffer()
	parent.shield_buffer()

	
	parent.techwindow()
	parent.invis_frames()
	parent.cooldown()
	if parent.regrab > 0:
		parent.regrab -= 1
	char_angle_reset()


func get_transition(delta):
	var snap = Vector2.DOWN if not AIREAL() else Vector2.ZERO
	parent.movement = parent.move_and_slide_with_snap(parent.velocity * 2, snap, Vector2.UP)
	
	Platform_Drop()
	

	if Falling() == true:
		return states.AIR


	if parent.frame > 0:
		if Landing() == true:
			parent.frame()
			return states.LANDING


	if Ledge() == true:
		parent.frame()
		return states.LEDGE_CATCH
	
	var PlatDrop
	PlatDrop = Platform_Drop()
	
	if parent.invis_frames == 0:
		enable_HurtBox()
	
	if Ledge() == false:
		parent.reset_ledge()

	if right_stick() == true and TILT() == true:
		if Input.is_action_pressed("r_up_%s" % id):
			parent.frame()
			return states.UP_TILT
		if Input.is_action_pressed("r_right_%s" % id):
			parent.frame()
			parent.turn(false)
			return states.FORWARD_TILT
		if Input.is_action_pressed("r_down_%s" % id):
			parent.frame()
			return states.DOWN_TILT
		if Input.is_action_pressed("r_left_%s" % id):
			parent.frame()
			parent.turn(true)
			return states.FORWARD_TILT

	if right_stick() == true and AIREAL() == true:
		if Input.is_action_pressed("r_up_%s" % id):
			parent.frame()
			return states.UAIR
		match parent.direction():
			1:
				if Input.is_action_pressed("r_left_%s" % id):
					parent.frame()
					return states.BAIR
				if Input.is_action_pressed("r_right_%s" % id):
					parent.frame()
					return states.FAIR
			- 1:
				if Input.is_action_pressed("r_right_%s" % id):
					parent.frame()
					return states.BAIR
				if Input.is_action_pressed("r_left_%s" % id):
					parent.frame()
					return states.FAIR
		if Input.is_action_pressed("r_down_%s" % id):
			parent.frame()
			return states.DAIR

	if Input.is_action_just_pressed("attack_%s" % id) and Input.is_action_pressed("down_%s" % id) and parent.down_buffer < 4 and TILT() == true:
		if TILT() == true:
			parent.frame()
			return states.SMASH_ATTACK
	if Input.is_action_just_pressed("attack_%s" % id) and Input.is_action_pressed("up_%s" % id) and parent.up_buffer < 4 and TILT() == true:
		if TILT() == true:
			parent.frame()
			return states.SMASH_ATTACK
	if Input.is_action_pressed("right_%s" % id) and Input.is_action_just_pressed("attack_%s" % id) and parent.right_buffer < 4 and TILT() == true:
		if TILT() == true:
			parent.turn(false)
			parent.frame()
			return states.SMASH_ATTACK
	if Input.is_action_pressed("left_%s" % id) and Input.is_action_just_pressed("attack_%s" % id) and parent.left_buffer < 4 and TILT() == true:
		if TILT() == true:
			parent.turn(true)
			parent.frame()
			return states.SMASH_ATTACK

	if Input.is_action_just_pressed("attack_%s" % id) and TILT() == true:
		parent.frame()
		return states.GROUND_ATTACK

	if Input.is_action_just_pressed("attack_%s" % id) and AIREAL() == true:
			if Input.is_action_pressed("up_%s" % id):
				parent.frame()
				return states.UAIR
			if Input.is_action_pressed("down_%s" % id):
				parent.frame()
				return states.DAIR
			match parent.direction():
				1:
					if Input.is_action_pressed("left_%s" % id):
						parent.frame()
						return states.BAIR
					if Input.is_action_pressed("right_%s" % id):
						parent.frame()
						return states.FAIR
				- 1:
					if Input.is_action_pressed("right_%s" % id):
						parent.frame()
						return states.BAIR
					if Input.is_action_pressed("left_%s" % id):
						parent.frame()
						return states.FAIR
			parent.frame()
			return states.NAIR

	if Input.is_action_just_pressed("special_%s" % id) and SPECIAL() == true:
		parent.frame()
		return states.SPECIAL

	if Input.is_action_pressed("shield_%s" % id) and can_roll() == true and parent.cooldown == 0 and parent.shield_buffer == 2:
		if Input.is_action_pressed("right_%s" % id):
			parent.frame()
			return states.ROLL_RIGHT
		elif Input.is_action_pressed("left_%s" % id):
			parent.frame()
			return states.ROLL_LEFT
		else:
			parent.frame()
			return states.PARRY

	match state:
		states.STAND:
			Edge_Hog()
			parent._reset_Jumps()
			if Input.is_action_just_pressed("jump_%s" % id):
				parent.frame()
				return states.JUMP_SQUAT
			if Input.is_action_pressed("down_%s" % id):
				parent.frame()
				
				return states.CROUCH
			if Input.get_action_strength("right_%s" % id) == 1:
				parent.velocity.x = parent.RUNSPEED
				parent.frame()
				parent.turn(false)
				
				return states.DASH
			if Input.get_action_strength("right_%s" % id) < 1 and Input.get_action_strength("right_%s" % id) > 0.1:
				parent.velocity.x = parent.WALKSPEED
				parent.frame()
				parent.turn(false)
				
				return states.WALK
			if Input.get_action_strength("left_%s" % id) == 1:
				parent.velocity.x = - parent.RUNSPEED
				parent.frame()
				parent.turn(true)
				
				return states.DASH
			if Input.get_action_strength("left_%s" % id) < 1 and Input.get_action_strength("left_%s" % id) > 0.1:
				parent.velocity.x = parent.WALKSPEED
				parent.frame()
				parent.turn(true)
				
				return states.WALK
			if parent.velocity.x > 0 and state == states.STAND:
				parent.velocity.x += - parent.TRACTION * 1
				parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
			elif parent.velocity.x < 0 and state == states.STAND:
				parent.velocity.x += parent.TRACTION * 1
				parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)

				
		states.JUMP_SQUAT:
			if parent.frame < parent.jump_squat_duration:
				if not parent.buffer_dodge:
					parent.buffer_dodge = Input.is_action_just_pressed("shield_%s" % id)
			if parent.frame == parent.jump_squat_duration:
				if (Input.is_action_pressed("shield_%s" % id)) and (Input.is_action_pressed("left_%s" % id) or Input.is_action_pressed("right_%s" % id)):
					if Input.is_action_pressed("right_%s" % id):
						parent.velocity.x = parent.air_dodge_speed / parent.perfect_wavedash_modifier
					if Input.is_action_pressed("left_%s" % id):
						parent.velocity.x = - parent.air_dodge_speed / parent.perfect_wavedash_modifier
					parent.lag_frames = 6
					parent.frame()
					return states.LANDING


				elif not Input.is_action_pressed("jump_%s" % id):
					parent.velocity.x = lerp(parent.velocity.x, 0, 0.08)
					parent.frame()
					return states.SHORT_HOP
				else:
					parent.velocity.x = lerp(parent.velocity.x, 0, 0.08)
					parent.frame()
					return states.FULL_HOP
				parent.buffer_dodge = false

		states.FULL_HOP:
			if Input.is_action_just_released("shield_%s" % id):
				parent.frame()
				return states.AIR_DODGE
			parent.velocity.y = - parent.MAX_JUMPFORCE
			sound_play($"../Jump")
			parent.frame()
			return states.AIR


		states.SHORT_HOP:
			if Input.is_action_just_pressed("shield_%s" % id):
				parent.frame()
				return states.AIR_DODGE
			parent.velocity.y = - parent.JUMPFORCE
			sound_play($"../Jump")
			parent.frame()
			return states.AIR

		states.MOONWALK:
			if Input.is_action_just_pressed("jump_%s" % id):
				parent.frame()
				return states.JUMP_SQUAT

			elif Input.is_action_pressed("left_%s" % id) and parent.direction() == 1:
				if parent.velocity.x > 0:
					parent.frame()
				parent.velocity.x += - parent.AIR_ACCEL * Input.get_action_strength("left_%s" % id)
				parent.velocity.x = clamp(parent.velocity.x, - parent.DASHSPEED * 1.4, parent.velocity.x)
				if parent.frame <= parent.dash_duration * 2:
					parent.turn(false)
					return states.MOONWALK
				else:
					parent.turn(true)
					parent.frame()
					return states.STAND

			elif Input.is_action_pressed("right_%s" % id) and parent.direction() == - 1:
				if parent.velocity.x < 0:
					parent.frame()
				parent.velocity.x += parent.AIR_ACCEL * Input.get_action_strength("right_%s" % id)
				parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, parent.DASHSPEED * 1.5)
				if parent.frame <= parent.dash_duration * 2:
					parent.turn(true)
					return states.MOONWALK
				else:
					parent.turn(false)
					parent.frame()
					return states.STAND

			else:
				if parent.frame >= parent.dash_duration - 1:
					for state in states:
						if state != "JUMP_SQUAT":
							sound_play($"../Dash_Stop")
							return states.STAND
			if PlatDrop == true:
				return states.AIR

		states.DASH:
			Edge_Hog()
			
			
			
			if Input.is_action_just_pressed("jump_%s" % id):
				parent.frame()
				return states.JUMP_SQUAT

			elif Input.is_action_pressed("left_%s" % id):
				if parent.velocity.x > 0:
					sound_play($"../Dash_Left")
					parent.frame()
				parent.velocity.x = - parent.DASHSPEED
				if parent.frame <= parent.dash_duration - 1:
					if Input.is_action_just_pressed("down_%s" % id):
						parent.frame()
						return states.MOONWALK
					parent.turn(true)
					return states.DASH
				else:
					parent.turn(true)
					parent.frame()
					return states.RUN

			elif Input.is_action_pressed("right_%s" % id):
				if parent.velocity.x < 0:
					sound_play($"../Dash_Right")
					parent.frame()
				parent.velocity.x = parent.DASHSPEED
				if parent.frame <= parent.dash_duration - 1:
					if Input.is_action_just_pressed("down_%s" % id):
						parent.frame()
						return states.MOONWALK
					parent.turn(false)
					return states.DASH
				else:
					parent.turn(false)
					parent.frame()
					return states.RUN
			else:
				if parent.frame >= parent.dash_duration - 1:
					for state in states:
						if state != "JUMP_SQUAT":
							sound_play($"../Dash_Stop")
							parent.frame()
							return states.STAND
			if PlatDrop == true:
				parent.frame()
				return states.AIR
			

		states.RUN:
			if Input.is_action_just_pressed("jump_%s" % id):
				parent.frame()
				return states.JUMP_SQUAT
			if Input.is_action_just_pressed("down_%s" % id):
				parent.frame()
				return states.CROUCH
			if Input.get_action_strength("left_%s" % id):
				if parent.velocity.x <= 0:
					parent.velocity.x = - parent.RUNSPEED
					parent.turn(true)
				else:
					parent.frame()
					return states.TURN
			elif Input.get_action_strength("right_%s" % id):
				if parent.velocity.x >= 0:
					parent.velocity.x = parent.RUNSPEED
					parent.turn(false)
				else:
					parent.frame()
					return states.TURN
			else:
				
				
				
				
				
				
			
				
				parent.frame()
				return states.STAND
			if PlatDrop == true:
				parent.frame()
				return states.AIR

		states.WALK:
			if parent.frame < 5:
				if Input.get_action_strength("left_%s" % id) == 1:
					parent.velocity.x = - parent.RUNSPEED
					parent.frame()
					parent.turn(true)
					
					return states.DASH
				if Input.get_action_strength("right_%s" % id) == 1:
					parent.velocity.x = parent.RUNSPEED
					parent.frame()
					parent.turn(false)
					
					return states.DASH
			if Input.is_action_just_pressed("jump_%s" % id):
				parent.frame()
				return states.JUMP_SQUAT
			if Input.is_action_just_pressed("down_%s" % id):
				parent.frame()
				return states.CROUCH
			if Input.get_action_strength("left_%s" % id):
				parent.velocity.x = - parent.WALKSPEED * Input.get_action_strength("left_%s" % id)
				parent.turn(true)
			elif Input.get_action_strength("right_%s" % id):
				parent.velocity.x = parent.WALKSPEED * Input.get_action_strength("right_%s" % id)
				parent.turn(false)
			else:
				parent.frame()
				return states.STAND
			if PlatDrop == true:
				parent.frame()
				return states.AIR
			Edge_Hog()

		states.TURN:
			sound_play($"../Dash_Stop")
			if Input.is_action_just_pressed("jump_%s" % id):
				parent.frame()
				return states.JUMP_SQUAT
			if parent.velocity.x > 0:
				parent.turn(true)
				parent.velocity.x += - parent.TRACTION * 2
				parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
			elif parent.velocity.x < 0:
				parent.turn(false)
				parent.velocity.x += parent.TRACTION * 2
				parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
			else:
				if not Input.is_action_pressed("left_%s" % id) and not Input.is_action_pressed("right_%s" % id):
					parent.frame()
					return states.STAND
				else:
					parent.frame()
					return states.RUN

		states.CROUCH:
			if Input.is_action_just_pressed("jump_%s" % id):
				parent.frame()
				return states.JUMP_SQUAT
			if Input.is_action_just_released("down_%s" % id):
				sound_play($"../Dash_Stop")
				parent.frame()
				return states.STAND
			elif parent.velocity.x > 0:
				if parent.velocity.x > parent.RUNSPEED:
					parent.velocity.x += - (parent.TRACTION * 4)
					parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
				else:
					parent.velocity.x += - (parent.TRACTION / 2)
					parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
			elif parent.velocity.x < 0:
				if abs(parent.velocity.x) > parent.RUNSPEED:
					parent.velocity.x += (parent.TRACTION * 4)
					parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
				else:
					parent.velocity.x += (parent.TRACTION / 2)
					parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
			if PlatDrop == true:
				parent.frame()
				return states.AIR


		states.AIR:
			AIRMOVEMENT()
			if Input.is_action_just_pressed("shield_%s" % id):
				parent.frame()
				return states.AIR_DODGE
			if Input.is_action_just_pressed("jump_%s" % id) and parent.airJump > 0:
				parent.fastfall = false
				parent.velocity.x = 0
				parent.velocity.y = - parent.DOUBLEJUMPFORCE
				parent.airJump -= 1
				sound_play($"../Air Jump")
				sound_play($"../Air_jump_2")
				if Input.is_action_pressed("left_%s" % id):
					parent.velocity.x = - parent.MAXAIRSPEED
				elif Input.is_action_pressed("right_%s" % id):
					parent.velocity.x = parent.MAXAIRSPEED

			if Input.is_action_just_pressed("special_%s" % id) and Input.is_action_pressed("up_%s" % id):
				parent.frame()
				return states.UP_SPECIAL
			if Input.is_action_just_pressed("special_%s" % id) and Input.is_action_pressed("down_%s" % id):
				
				
				print(parent.cooldown)
				if parent.cooldown == 0:
					parent.frame()
					return states.DOWN_SPECIAL
				else:
					parent.frame()
					return states.AIR
			if Input.is_action_just_pressed("special_%s" % id) and Input.is_action_pressed("left_%s" % id):
				parent.turn(true)
				parent.frame()
				return states.FORWARD_SPECIAL
			if Input.is_action_just_pressed("special_%s" % id) and Input.is_action_pressed("right_%s" % id):
				parent.turn(false)
				parent.frame()
				return states.FORWARD_SPECIAL
			if Input.is_action_just_pressed("special_%s" % id):
				parent.frame()
				return states.NEUTRAL_SPECIAL


				

		states.FREE_FALL:
			if parent.velocity.y < parent.MAXFALLSPEED:
				parent.velocity.y += parent.FALLSPEED

			if Input.is_action_just_pressed("down_%s" % id) and parent.velocity.y > 0 and not parent.fastfall:
				parent.velocity.y = parent.MAXFALLSPEED
				parent.fastfall = true

			if abs(parent.velocity.x) >= abs(parent.MAXAIRSPEED):
				if parent.velocity.x > 0:
					if Input.is_action_pressed("left_%s" % id):
						parent.velocity.x += - parent.AIR_ACCEL
					elif Input.is_action_pressed("right_%s" % id):
							parent.velocity.x = parent.velocity.x
				if parent.velocity.x < 0:
					if Input.is_action_pressed("left_%s" % id):
						parent.velocity.x = parent.velocity.x
					elif Input.is_action_pressed("right_%s" % id):
						parent.velocity.x += parent.AIR_ACCEL
					
			elif abs(parent.velocity.x) < abs(parent.MAXAIRSPEED):
				if Input.is_action_pressed("left_%s" % id):
					parent.velocity.x += - parent.AIR_ACCEL
				if Input.is_action_pressed("right_%s" % id):
					parent.velocity.x += parent.AIR_ACCEL
			if not Input.is_action_pressed("left_%s" % id) and not Input.is_action_pressed("right_%s" % id):
				
				if parent.velocity.x < 0:
					parent.velocity.x += (parent.AIR_ACCEL / 2)
				elif parent.velocity.x > 0:
					parent.velocity.x += ( - parent.AIR_ACCEL / 2)
					

		states.LANDING:
			Edge_Hog()
			parent.connected = false
			if parent.tech_frames < 20:
				return states.TECH
			if parent.frame <= parent.landing_frames + parent.lag_frames:
				if parent.frame == 1:
					pass
				if parent.velocity.x > 0:
					parent.velocity.x = parent.velocity.x - parent.TRACTION / 2
					parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
				elif parent.velocity.x < 0:
					parent.velocity.x = parent.velocity.x + parent.TRACTION / 2
					parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
				if Input.is_action_just_pressed("jump_%s" % id):
					parent.frame()
					return states.JUMP_SQUAT
			else:
				if Input.is_action_pressed("down_%s" % id):
					parent.lag_frames = 0
					parent.frame()
					return states.CROUCH
				else:
					parent.frame()
					parent.lag_frames = 0
					return states.STAND
				parent.lag_frames = 0

		states.AIR_DODGE:
			sound_play($"../Shoulder Press")
			if parent.frame == 1:
				parent.velocity.x = 0
				parent.velocity.y = 0
				
				var deadzone = (Input.get_action_strength("right_%s" % id) - Input.get_action_strength("left_%s" % id) in range( - 0.2, 1.2) and Input.get_action_strength("up_%s" % id) - Input.get_action_strength("down_%s" % id) in range( - 0.2, 1.2))
				var direction = Vector2(Input.get_action_strength("right_%s" % id) - Input.get_action_strength("left_%s" % id), Input.get_action_strength("down_%s" % id) - Input.get_action_strength("up_%s" % id))
				if deadzone:
					direction = Vector2(0, 0)
				parent.velocity = parent.air_dodge_speed * direction.normalized()
				if abs(parent.velocity.x) == abs(parent.velocity.y):
					parent.velocity.x = parent.velocity.x / 1.15
					parent.velocity.y = parent.velocity.y / 1.15
				parent.lag_frames = 3

			if parent.frame >= 4 and parent.frame <= 10:
				parent.hurtbox.disabled = true
				sound_play($"../Airdodge")
				if parent.frame == 5:
				
					pass
				parent.velocity.x = parent.velocity.x / 1.15
				parent.velocity.y = parent.velocity.y / 1.15
			if parent.frame >= 10 and parent.frame < 20:
				parent.velocity.x = 0
				parent.velocity.y = 0
			elif parent.frame == 20:
				parent.lag_frames = 8
				parent.frame = 0
				parent.frame()
				return states.FREE_FALL
			if parent.is_on_floor():
				parent.frame = 0
				if parent.velocity.y > 0:
					parent.velocity.y = 0
				parent._reset_Jumps()
				parent.reset_platform()
				parent.fastfall = false
				parent.frame()
				return states.LANDING



		states.LEDGE_CATCH:
				parent.hurtbox.disabled = true
				if parent.frame > 7:
					parent.lag_frames = 0
					parent._reset_Jumps()
					parent.frame()
					return states.LEDGE_HOLD



		states.LEDGE_HOLD:
			if parent.frame <= 30:
				parent.hurtbox.disabled = true
			else:
				parent.hurtbox.disabled = false
			if parent.frame >= 390:
				self.parent.position.y += - 25
				parent.frame()
				return states.TUMBLE
			if Input.is_action_just_pressed("down_%s" % id):
				parent.fastfall = true
				parent.regrab = 30
				parent.reset_ledge()
				self.parent.position.y += - 25
				parent.catch = false
				parent.frame()
				return states.AIR
				
				
				
			
			elif parent.Ledge_Grab_F.get_cast_to().x > 0:
				if Input.is_action_just_pressed("left_%s" % id):
					parent.velocity.x = (parent.AIR_ACCEL / 2)
					parent.regrab = 30
					parent.reset_ledge()
					self.parent.position.y += - 25
					parent.catch = false
					parent.frame()
					return states.AIR
					
					
				
				elif Input.is_action_just_pressed("right_%s" % id):
					parent.frame()
					return states.LEDGE_CLIMB
				elif Input.is_action_just_pressed("shield_%s" % id):
					parent.frame()
					return states.LEDGE_ROLL
				elif Input.is_action_just_pressed("jump_%s" % id):
					parent.frame()
					return states.LEDGE_JUMP

					
						
			
			elif parent.Ledge_Grab_F.get_cast_to().x < 0:
				if Input.is_action_just_pressed("right_%s" % id):
					parent.velocity.x = (parent.AIR_ACCEL / 2)
					parent.regrab = 30
					parent.reset_ledge()
					self.parent.position.y += - 25
					parent.frame()
					return states.AIR
					
					
				
				elif Input.is_action_just_pressed("left_%s" % id):
					parent.frame()
					return states.LEDGE_CLIMB
				elif Input.is_action_just_pressed("shield_%s" % id):
					parent.frame()
					return states.LEDGE_ROLL
				elif Input.is_action_just_pressed("jump_%s" % id):
					parent.frame()
					return states.LEDGE_JUMP

		states.LEDGE_CLIMB:
			if parent.frame == 1:
				parent.hurtbox.disabled = true
			if parent.frame == 5:
				parent.position.y -= 25
			if parent.frame == 10:
				parent.position.y -= 25
			
			if parent.frame == 20:
				parent.position.y -= 25
			
			if parent.frame == 22:
				parent.catch = false
				parent.position.y -= 25
				parent.position.x += 50 * parent.direction()
				
			if parent.frame == 25:
				parent.velocity.y = 0
				parent.velocity.x = 0
				parent.move_and_collide(Vector2(parent.direction() * 20, 50))
				parent.hurtbox.disabled = false
			if parent.frame == 30:
				parent.reset_ledge()
				parent.frame()
				return states.STAND

		states.LEDGE_JUMP:
				if parent.frame > 14:
					if Input.is_action_just_pressed("attack_%s" % id):
						parent.frame()
						return states.AIR_ATTACK
					if Input.is_action_just_pressed("special_%s" % id):
						parent.frame()
						return states.SPECIAL
				if parent.frame == 5:
					parent.reset_ledge()
					parent.position.y -= 20
				if parent.frame == 10:
					parent.catch = false
					parent.position.y -= 20
					if Input.is_action_just_pressed("jump_%s" % id) and parent.airJump > 0:
						parent.fastfall = false
						parent.velocity.y = - parent.DOUBLEJUMPFORCE
						parent.velocity.x = 0
						parent.airJump -= 1
						parent.frame()
						return states.AIR
				if parent.frame == 15:
					parent.position.y -= 20
					parent.velocity.y -= parent.DOUBLEJUMPFORCE
					parent.velocity.x += 220 * parent.direction()
					if Input.is_action_just_pressed("jump_%s" % id) and parent.airJump > 0:
						parent.fastfall = false
						parent.velocity.y = - parent.DOUBLEJUMPFORCE
						parent.velocity.x = 0
						parent.airJump -= 1
						parent.frame()
						return states.AIR
					if Input.is_action_just_pressed("attack_%s" % id):
						parent.frame()
						return states.AIR_ATTACK
				elif parent.frame > 15 and parent.frame < 20:
					parent.velocity.y += parent.FALLSPEED
					if Input.is_action_just_pressed("jump_%s" % id) and parent.airJump > 0:
						parent.fastfall = false
						parent.velocity.y = - parent.DOUBLEJUMPFORCE
						parent.velocity.x = 0
						parent.airJump -= 1
						parent.frame()
						return states.AIR
					if Input.is_action_just_pressed("attack_%s" % id):
						parent.frame()
						return states.AIR_ATTACK
				if parent.frame == 20:
					parent.frame()
					return states.AIR

		states.LEDGE_ROLL:
			if parent.frame == 1:
				parent.hurtbox.disabled = true
			if parent.frame == 5:
				parent.position.y -= 30
			if parent.frame == 10:
				parent.position.y -= 30
			
			if parent.frame == 20:
				parent.catch = false
				parent.position.y -= 30
			
			if parent.frame == 22:
				parent.position.y -= 30
				parent.position.x += 50 * parent.direction()
			
			if parent.frame > 22 and parent.frame < 28:
				parent.position.x += 30 * parent.direction()
				parent.hurtbox.disabled = false
		
			if parent.frame == 29:
				parent.move_and_collide(Vector2(parent.direction() * 20, 50))
			if parent.frame == 30:
				parent.velocity.y = 0
				parent.velocity.x = 0
				parent.reset_ledge()
				parent.frame()
				return states.STAND

		states.HITSTUN:
			
			if parent.knockback >= 18:
				var bounce = parent.move_and_collide(parent.velocity * delta)
				if bounce:
					parent.velocity = parent.velocity.bounce(bounce.normal) * 0.6








			if parent.velocity.y < 0:
				parent.velocity.y += parent.vdecay * 0.5
				parent.velocity.y = clamp(parent.velocity.y, parent.velocity.y, 0)
			if parent.velocity.x < 0:
				parent.velocity.x += (parent.hdecay) * 0.4 * - 1
				parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
			elif parent.velocity.x > 0:
				parent.velocity.x -= parent.hdecay * 0.4
				parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
			
			if parent.frame == parent.hitstun:
				
				if parent.knockback >= 24:
					parent.frame()
					return states.TUMBLE
				else:
					parent.frame()
					return states.AIR


		states.TUMBLE:
		
			AIRMOVEMENT()
			if Input.is_action_just_pressed("jump_%s" % id) and parent.airJump > 0:
				parent.fastfall = false
				parent.velocity.y = - parent.DOUBLEJUMPFORCE
				parent.airJump -= 1
				if Input.is_action_pressed("left_%s" % id):
					parent.velocity.x = - parent.MAXAIRSPEED
				elif Input.is_action_pressed("right_%s" % id):
					parent.velocity.x = parent.MAXAIRSPEED
				return states.AIR
			if AIREAL() == true:
				pass
			if Input.is_action_pressed("shield_%s" % id) and parent.shield_buffer >= 5:
				parent.frame()
				return states.AIR_DODGE
			
			if Input.is_action_just_pressed("shield_%s" % id) and parent.cooldown == 0:
				parent.tech()
				parent.cooldown = 40
			else:
				if Landing() == true:
					if parent.tech_frames >= 20:
						parent.lag_frames = 7
					parent.frame()
					return states.LANDING
			if parent.GroundL.is_colliding() and not parent.GroundR.is_colliding():
				Edge_Hog()

		states.PARRY:
				if parent.velocity.x > 0:
					parent.velocity.x += - parent.TRACTION * 10
					parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
				elif parent.velocity.x < 0:
					parent.velocity.x += parent.TRACTION * 10
					parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
				if parent.frame >= 3 and parent.frame <= 10:
					parent.hurtbox.disabled = true
				if parent.frame >= 11:
					parent.hurtbox.disabled = false
				if parent.frame == 30:
					parent.frame()
					return states.STAND

		states.ROLL_RIGHT:
			parent.turn(false)
			if parent.frame == 1:
				parent.velocity.x = 0
			if parent.frame == 4:
				parent.velocity.x = parent.ROLL_DISTANCE
				parent.hurtbox.disabled = true
			if parent.frame == 20:
				parent.hurtbox.disabled = false
			if parent.frame > 19:
				parent.velocity.x = parent.velocity.x - parent.TRACTION * 5
				parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
				if parent.velocity.x == 0:
					parent.cooldown = 20
					parent.lag_frames = 10
					parent.frame()
					return states.LANDING
		states.ROLL_LEFT:
			parent.turn(true)
			if parent.frame == 1:
				parent.velocity.x = 0
			if parent.frame == 4:
				parent.velocity.x = - parent.ROLL_DISTANCE
				parent.hurtbox.disabled = true
			if parent.frame == 20:
				parent.hurtbox.disabled = false
			if parent.frame > 19:
				print(parent.frame)
				parent.velocity.x = parent.velocity.x + parent.TRACTION * 5
				parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
				if parent.velocity.x == 0:
					parent.cooldown = 20
					parent.lag_frames = 10
					parent.frame()
					return states.LANDING
		states.TECH:
			if (Input.is_action_pressed("left_%s" % id) or Input.is_action_pressed("right_%s" % id)):
				parent.frame()
				if Input.is_action_pressed("left_%s" % id):
					parent.turn(false)
					parent.frame()
					return states.TECH_FORWARD
				if Input.is_action_pressed("right_%s" % id):
					parent.turn(true)
					parent.frame()
					return states.TECH_BACKWARD
			else:
				parent.frame()
				return states.TECH_GROUND

		states.TECH_GROUND:
			parent.hurtbox.disabled = true
			if parent.frame == 15:
				parent.hurtbox.disabled = false
			if parent.frame == 19:
				if Input.is_action_pressed("down_%s" % id):
					parent.frame()
					return states.CROUCH
				else:
					parent.frame()
					return states.STAND

		states.TECH_FORWARD:
			Edge_Hog()
			parent.hurtbox.disabled = true
			if parent.frame == 4:
				parent.velocity.x = - parent.ROLL_DISTANCE * 1.25
			if parent.frame == 15:
				parent.hurtbox.disabled = false
			if parent.frame == 19:
					parent.lag_frames = 20
					parent.frame()
					return states.LANDING

		states.TECH_BACKWARD:
			Edge_Hog()
			parent.hurtbox.disabled = true
			if parent.frame == 4:
				parent.velocity.x = parent.ROLL_DISTANCE * 1.25
			if parent.frame == 15:
				parent.hurtbox.disabled = false
			if parent.frame == 19:
					parent.lag_frames = 20
					parent.frame()
					return states.LANDING

		states.UP_TILT:
			if parent.frame == 0:
				parent.frame()
				parent.UP_TILT()
			if parent.frame >= 1:
				if parent.velocity.x > 0:
					parent.velocity.x += - parent.TRACTION * 3
					parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
				elif parent.velocity.x < 0:
					parent.velocity.x += parent.TRACTION * 3
					parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
			if parent.UP_TILT() == true:
				parent.frame()
				return states.STAND

		states.DOWN_TILT:
			parent.invis_frames = 0
			if parent.frame == 0:
				parent.DOWN_TILT()
			if parent.frame >= 1:
				if parent.velocity.x > 0:
					parent.velocity.x += - parent.TRACTION * 3
					parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
				elif parent.velocity.x < 0:
					parent.velocity.x += parent.TRACTION * 3
					parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
			if parent.DOWN_TILT() == true:
				if Input.is_action_pressed("down_%s" % id):
					parent.frame()
					return states.CROUCH
				else:
					parent.frame()
					return states.STAND

		states.FORWARD_TILT:
			parent.invis_frames = 0
			Edge_Hog()
			if parent.frame <= 1:
				if parent.velocity.x > 0:
					if parent.velocity.x > parent.DASHSPEED:
						parent.velocity.x = parent.DASHSPEED
					parent.velocity.x = parent.velocity.x - parent.TRACTION * 2
					parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
				elif parent.velocity.x < 0:
					if parent.velocity.x < - parent.DASHSPEED:
						parent.velocity.x = - parent.DASHSPEED
					parent.velocity.x = parent.velocity.x + parent.TRACTION * 2
					parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
				parent.FORWARD_TILT()
			if parent.FORWARD_TILT() == true and parent.frame > 12:
				if Input.is_action_pressed("left_%s" % id):
					if parent.velocity.x < - parent.DASHSPEED:
						parent.velocity.x = - parent.DASHSPEED
					parent.velocity.x = parent.velocity.x + parent.TRACTION / 2
					parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
					parent.frame()
					return states.WALK
				if Input.is_action_pressed("right_%s" % id):
					if parent.velocity.x > parent.DASHSPEED:
						parent.velocity.x = parent.DASHSPEED
					parent.velocity.x = parent.velocity.x - parent.TRACTION / 2
					parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
					parent.frame()
					return states.WALK
				else:
					parent.frame()
					return states.STAND

		states.JAB:
			parent.invis_frames = 0
			if parent.frame <= 1:
				if parent.velocity.x > 0:
					if parent.velocity.x > parent.DASHSPEED:
						parent.velocity.x = parent.DASHSPEED
					parent.velocity.x = parent.velocity.x - parent.TRACTION * 20
					parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
				elif parent.velocity.x < 0:
					if parent.velocity.x < - parent.DASHSPEED:
						parent.velocity.x = - parent.DASHSPEED
					parent.velocity.x = parent.velocity.x + parent.TRACTION * 20
					parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
				parent.JAB()
			if parent.JAB() == true:
				if Input.is_action_pressed("down_%s" % id):
					parent.frame()
					return states.CROUCH
				else:
					parent.frame()
					return states.STAND
			if parent.JAB() == false:
				parent.frame()
				return states.JAB_1
		states.JAB_1:
			parent.invis_frames = 0
			if parent.frame <= 1:
				if parent.velocity.x > 0:
					if parent.velocity.x > parent.DASHSPEED:
						parent.velocity.x = parent.DASHSPEED
					parent.velocity.x = parent.velocity.x - parent.TRACTION * 20
					parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
				elif parent.velocity.x < 0:
					if parent.velocity.x < - parent.DASHSPEED:
						parent.velocity.x = - parent.DASHSPEED
					parent.velocity.x = parent.velocity.x + parent.TRACTION * 20
					parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
				parent.JAB_1()
			if parent.JAB_1() == true:
				if Input.is_action_pressed("down_%s" % id):
					parent.frame()
					return states.CROUCH
				else:
					parent.frame()
					return states.STAND

		states.SMASH_ATTACK:
			parent.invis_frames = 0
			if Input.is_action_pressed("up_%s" % id):
				parent.frame()
				return states.UP_SMASH
			if Input.is_action_pressed("down_%s" % id):
				parent.frame()
				return states.DOWN_SMASH
			if (Input.is_action_pressed("left_%s" % id) or Input.is_action_pressed("right_%s" % id)):
				parent.frame()
				if Input.is_action_pressed("left_%s" % id):
					parent.turn(true)
					parent.frame()
					return states.FORWARD_SMASH
				if Input.is_action_pressed("right_%s" % id):
					parent.turn(false)
					parent.frame()
					return states.FORWARD_SMASH

		states.GROUND_ATTACK:
			parent.invis_frames = 0
			if Input.is_action_pressed("up_%s" % id):
				parent.frame()
				return states.UP_TILT
			if Input.is_action_pressed("down_%s" % id):
				parent.frame()
				return states.DOWN_TILT
			if (Input.is_action_pressed("left_%s" % id) or Input.is_action_pressed("right_%s" % id)):
				parent.frame()
				if Input.is_action_pressed("left_%s" % id):
					parent.turn(true)
					parent.frame()
					return states.FORWARD_TILT
				if Input.is_action_pressed("right_%s" % id):
					parent.turn(false)
					parent.frame()
					return states.FORWARD_TILT
			parent.frame()
			return states.JAB


		states.SPECIAL:
			parent.invis_frames = 0
			if Input.is_action_pressed("up_%s" % id):
				parent.frame()
				return states.UP_SPECIAL
			if Input.is_action_pressed("down_%s" % id):
				
				
				print(parent.cooldown)
				if parent.cooldown == 0:
					parent.frame()
					return states.DOWN_SPECIAL
				else:
					parent.frame()
					return states.AIR
			if Input.is_action_pressed("left_%s" % id):
				parent.turn(true)
				parent.frame()
				return states.FORWARD_SPECIAL
			elif Input.is_action_pressed("right_%s" % id):
				parent.turn(false)
				parent.frame()
				return states.FORWARD_SPECIAL
			else:
				parent.frame()
				return states.NEUTRAL_SPECIAL

			if Input.is_action_pressed("up_%s" % id):
				parent.frame()
				return states.UP_SPECIAL
			if Input.is_action_pressed("down_%s" % id):
				parent.frame()
				return states.DOWN_SPECIAL
			if (Input.is_action_pressed("left_%s" % id) or Input.is_action_pressed("right_%s" % id)):
				parent.frame()
				if Input.is_action_pressed("left_%s" % id):
					parent.turn(true)
					parent.frame()
					return states.FORWARD_SPECIAL
				if Input.is_action_pressed("right_%s" % id):
					parent.turn(false)
					parent.frame()
					return states.FORWARD_SPECIAL
			parent.frame()
			return states.NEUTRAL_SPECIAL


		states.NEUTRAL_SPECIAL:
			parent.invis_frames = 0
			if parent.frame <= 1:
				if AIREAL() == false:
					if parent.frame <= 1:
						if parent.velocity.x > 0:
							if parent.velocity.x > parent.DASHSPEED:
								parent.velocity.x = parent.DASHSPEED
							parent.velocity.x = parent.velocity.x - parent.TRACTION * 10
							parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
						elif parent.velocity.x < 0:
							if parent.velocity.x < - parent.DASHSPEED:
								parent.velocity.x = - parent.DASHSPEED
							parent.velocity.x = parent.velocity.x + parent.TRACTION * 10
							parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
						if cooldown_gun == 1:
							cooldown_gun -= 1
						
							return states.NEUTRAL_SPECIAL
						if cooldown_gun == 0:
							cooldown_gun += 1
							parent.frame()
							parent.NEUTRAL_SPECIAL()
			if AIREAL() == true:
				AIRMOVEMENT()
				if parent.frame <= 1:
					if cooldown_gun == 1:
						cooldown_gun = - 1
					if cooldown_gun == 0:
						cooldown_gun += 1
						parent.frame()
						parent.NEUTRAL_SPECIAL()
			if parent.frame < 14:
				if Input.is_action_just_pressed("special_%s" % id):
					parent.frame()
					return states.NEUTRAL_SPECIAL
			if parent.NEUTRAL_SPECIAL() == true:
				if AIREAL() == true:
					return states.AIR
				if AIREAL() == false:
					if parent.frame < 14:
						if Input.is_action_just_pressed("special_%s" % id):
							return states.NEUTRAL_SPECIAL
					if parent.frame == 14:
						if Input.is_action_pressed("down_%s" % id):
							parent.frame()
							return states.CROUCH
						else:
							print("yo")
							parent.frame()
							return states.STAND


		states.FORWARD_SPECIAL:
			parent.invis_frames = 0
			if AIREAL() == false:
				if parent.frame <= 1:
					parent.velocity.x = 0
				if parent.frame == 11:
						parent.velocity.x = (parent.DOUBLEJUMPFORCE * parent.direction())
				Edge_Hog()
			if AIREAL() == true:
				if parent.frame == 1:
					parent.velocity.x = 0
				if parent.frame == 11:
						parent.velocity.x = (parent.DOUBLEJUMPFORCE * parent.direction())
				if parent.velocity.y < 0:
					parent.velocity.y += parent.FALLSPEED * 8
					parent.velocity.y = clamp(parent.velocity.y, parent.velocity.y, 0)
				if parent.velocity.y > 0:
					parent.velocity.y += - (parent.FALLSPEED * 8)
					parent.velocity.y = clamp(parent.velocity.y, 0, parent.velocity.y)
			if parent.FORWARD_SPECIAL() == true:
				if AIREAL() == false:
					Edge_Hog()
					if Input.is_action_pressed("down_%s" % id):
						parent.frame()
						return states.CROUCH
					else:
						if parent.velocity.x > 0:
								parent.velocity.x += - (parent.DASHSPEED * 1.25)
								parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
						elif parent.velocity.x < 0:
								parent.velocity.x += (parent.DASHSPEED * 1.25)
								parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
						parent.frame()
						return states.STAND
				else:
					if parent.velocity.x < 0:
						parent.velocity.x += parent.AIR_ACCEL * 15
						parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
					elif parent.velocity.x > 0:
						parent.velocity.x += - parent.AIR_ACCEL * 15
						parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
					parent.lag_frames = 30
					parent.frame()
					return states.FREE_FALL

		states.DOWN_SPECIAL:
			parent.invis_frames = 0
			
			if AIREAL() == false:
				parent.velocity.x = 0
				if parent.frame == 1:
					parent.DOWN_SPECIAL()
			else:
				parent.fastfall = false
				
				if parent.velocity.y < parent.FALLINGSPEED:
					parent.velocity.y += parent.FALLSPEED * 8
					parent.velocity.y = clamp(parent.velocity.y, parent.velocity.y, 0)
				else:
					parent.velocity.y += - parent.FALLSPEED * 8
					parent.velocity.y = clamp(parent.velocity.y, parent.velocity.y, 0)
				if parent.velocity.x < 0:
					parent.velocity.x = 0
					parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
				elif parent.velocity.x > 0:
					parent.velocity.x = 0
					parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
				if parent.frame == 1:
					parent.DOWN_SPECIAL()
			if Input.is_action_just_pressed("jump_%s" % id):
				parent.frame()
				return states.JUMP_SQUAT
			if parent.DOWN_SPECIAL() == true:
				if AIREAL() == false:
					if Input.is_action_pressed("down_%s" % id):
						parent.cooldown = 0
						parent.frame()
						return states.CROUCH
					else:
						parent.cooldown = 0
						parent.frame()
						return states.STAND
				else:
					parent.cooldown = 30
					parent.frame()
					return states.AIR
				

		states.UP_SPECIAL:
			parent.invis_frames = 0
			var direction = Vector2(Input.get_action_strength("right_%s" % id) - Input.get_action_strength("left_%s" % id), Input.get_action_strength("down_%s" % id) - Input.get_action_strength("up_%s" % id))
			parent.velocity.x += 2 * (Input.get_action_strength("right_%s" % id) - Input.get_action_strength("left_%s" % id))
			print("Horizontal " + str((Input.get_action_strength("right_%s" % id) - Input.get_action_strength("left_%s" % id))))
			print("vertical " + str((Input.get_action_strength("up_%s" % id) - Input.get_action_strength("down_%s" % id))))
			if Input.is_action_just_pressed("shield_%s" % id):
				parent.frame()
				return states.AIR_DODGE
			if AIREAL() == false:
				if parent.frame <= 1:
					if parent.velocity.x > 0:
						if parent.velocity.x > parent.DASHSPEED:
							parent.velocity.x = parent.DASHSPEED
						
						parent.velocity.x = 0
						parent.velocity.x += 2 * (Input.get_action_strength("right_%s" % id) - Input.get_action_strength("left_%s" % id))
						parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
					elif parent.velocity.x < 0:
						if parent.velocity.x < - parent.DASHSPEED:
							parent.velocity.x = - parent.DASHSPEED
						parent.velocity.x = 0
						parent.velocity.x += 2 * (Input.get_action_strength("right_%s" % id) - Input.get_action_strength("left_%s" % id))
						
						parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
			else:
				parent.fastfall = false
				if parent.velocity.y < 0:
					parent.velocity.y += parent.FALLSPEED * 8
					parent.velocity.y = clamp(parent.velocity.y, parent.velocity.y, 0)
				if parent.velocity.y > 0:
					parent.velocity.y += - (parent.FALLSPEED * 8)
					parent.velocity.y = clamp(parent.velocity.y, 0, parent.velocity.y)
				if parent.velocity.x < 0:
					parent.velocity.x = 0
					parent.velocity.x += 10 * (Input.get_action_strength("right_%s" % id) - Input.get_action_strength("left_%s" % id))
					parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
				elif parent.velocity.x > 0:
					parent.velocity.x = 0
					parent.velocity.x += 10 * (Input.get_action_strength("right_%s" % id) - Input.get_action_strength("left_%s" % id))
					parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
			if parent.frame == 1:
				parent.UP_SPECIAL()
			if parent.frame == 39:
				direction = Vector2(Input.get_action_strength("right_%s" % id) - Input.get_action_strength("left_%s" % id), Input.get_action_strength("down_%s" % id) - Input.get_action_strength("up_%s" % id))
			if parent.UP_SPECIAL() == true:
				var deadzone = (Input.get_action_strength("right_%s" % id) - Input.get_action_strength("left_%s" % id) in range( - 0.01, 1.01) and Input.get_action_strength("up_%s" % id) - Input.get_action_strength("down_%s" % id) in range( - 0.01, 1.01))
				
				if deadzone == true and direction.x in range( - 0.01, 1.01) and direction.y in range( - 0.01, 1.01):
					direction = Vector2(0 * parent.direction(), - 1)
				if AIREAL() == true:
					parent.velocity = parent.UP_B_LAUNCHSPEED * direction.normalized()
					
					parent.spritez.rotation_degrees = ((Vector2(0, 0).angle_to_point(direction.normalized()) * 180) / PI) - 90
				if AIREAL() == false:
					parent.velocity = parent.UP_B_LAUNCHSPEED * 0.857 * direction.normalized()
				
					parent.spritez.rotation_degrees = ((Vector2(0, 0).angle_to_point(direction.normalized()) * 180) / PI) - 90
				parent.frame()
				return states.UP_SPECIAL_1

		states.UP_SPECIAL_1:
			parent.invis_frames = 0
			if parent.frame == 1:
				parent.UP_SPECIAL_1()
			if parent.UP_SPECIAL_1() == true:
				parent.frame()
				parent.fastfall = false
				if parent.velocity.y < 0:
					parent.velocity.y += parent.FALLSPEED * 5
					parent.velocity.y = clamp(parent.velocity.y, parent.velocity.y, 0)
				if parent.velocity.y > 0:
					parent.velocity.y += - (parent.FALLSPEED * 5)
					parent.velocity.y = clamp(parent.velocity.y, 0, parent.velocity.y)
				if parent.velocity.x < 0:
					parent.velocity.x += parent.AIR_ACCEL * 5
					parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
				elif parent.velocity.x > 0:
					parent.velocity.x += - parent.AIR_ACCEL * 5
					parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
				parent.lag_frames = 30
				parent.frame()
				return states.FREE_FALL

		states.AIR_ATTACK:
			parent.invis_frames = 0
			AIRMOVEMENT()
			if Input.is_action_pressed("up_%s" % id):
				parent.frame()
				return states.UAIR
			if Input.is_action_pressed("down_%s" % id):
				parent.frame()
				return states.DAIR
			match parent.direction():
				1:
					if Input.is_action_pressed("left_%s" % id):
						parent.frame()
						return states.BAIR
					if Input.is_action_pressed("right_%s" % id):
						parent.frame()
						return states.FAIR
				- 1:
					if Input.is_action_pressed("right_%s" % id):
						parent.frame()
						return states.BAIR
					if Input.is_action_pressed("left_%s" % id):
						parent.frame()
						return states.FAIR
			parent.frame()
			return states.NAIR


		states.NAIR:
			parent.invis_frames = 0
			AIRMOVEMENT()
			if parent.frame == 0:
				print("nair")
				parent.NAIR()
			if parent.NAIR() == true:
				parent.lag_frames = 0
				parent.frame()
				return states.AIR
			else:
				parent.lag_frames = 5

		states.UAIR:
			parent.invis_frames = 0
			AIRMOVEMENT()
			if parent.frame == 0:
				print("uair")
				parent.UAIR()
			if parent.UAIR() == true:
				parent.lag_frames = 0
				parent.frame()
				return states.AIR
			else:
				parent.lag_frames = 10

		states.BAIR:
			parent.invis_frames = 0
			AIRMOVEMENT()
			if parent.frame == 0:
				print("bair")
				parent.BAIR()
			if parent.BAIR() == true:
				parent.lag_frames = 0
				parent.frame()
				return states.AIR
			else:
				parent.lag_frames = 15

		states.FAIR:
			parent.invis_frames = 0
			AIRMOVEMENT()
			if Input.is_action_just_pressed("jump_%s" % id) and parent.airJump > 0:
				parent.fastfall = false
				parent.velocity.x = 0
				parent.velocity.y = - parent.DOUBLEJUMPFORCE
				parent.airJump -= 1
				sound_play($"../Air Jump")
				sound_play($"../Air_jump_2")
				if Input.is_action_pressed("left_%s" % id):
					parent.velocity.x = - parent.MAXAIRSPEED
				elif Input.is_action_pressed("right_%s" % id):
					parent.velocity.x = parent.MAXAIRSPEED
				return states.AIR
			if parent.frame == 0:
				print("fair")
				parent.FAIR()
			if parent.FAIR() == true:
				parent.lag_frames = 30
				parent.frame()
				return states.FAIR
			else:
				parent.lag_frames = 10

		states.DAIR:
			parent.invis_frames = 0
			AIRMOVEMENT()
			if parent.frame == 0:
				print("bair")
				parent.DAIR()
			if parent.DAIR() == true:
				parent.lag_frames = 0
				return states.AIR
			else:
				parent.lag_frames = 8

		states.DOWN_SMASH:
			Edge_Hog()
			parent.invis_frames = 0
			if AIREAL() == false:
					if parent.velocity.x > 0:
						parent.velocity.x += - parent.TRACTION / 7
						parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
					elif parent.velocity.x < 0:
						parent.velocity.x += parent.TRACTION / 7
						parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
					Edge_Hog()
			if AIREAL() == true:
					if parent.velocity.y < parent.FALLINGSPEED:
						parent.velocity.y += parent.FALLSPEED
					if parent.velocity.x < 0:
						parent.velocity.x += parent.AIR_ACCEL / 10
					elif parent.velocity.x > 0:
						parent.velocity.x += - parent.AIR_ACCEL / 10
			if parent.frame < 5 and not Input.is_action_pressed("attack_%s" % id):
				parent.charge = 1
				
			if parent.frame >= 5 and parent.frame <= 10 and not Input.is_action_pressed("attack_%s" % id):
				parent.charge = 1.1
				parent.frame()
				return states.DOWN_SMASH_1
			if parent.frame >= 11 and parent.frame <= 20 and not Input.is_action_pressed("attack_%s" % id):
				parent.charge = 1.1
				parent.frame()
				return states.DOWN_SMASH_1
			if parent.frame >= 21 and parent.frame <= 40 and not Input.is_action_pressed("attack_%s" % id):
				parent.charge = 1.2
				parent.frame()
				return states.DOWN_SMASH_1
			if parent.frame >= 41 and parent.frame <= 50 and not Input.is_action_pressed("attack_%s" % id):
				parent.charge = 1.2
				parent.frame()
				return states.DOWN_SMASH_1
			if parent.frame >= 51 and not Input.is_action_pressed("attack_%s" % id):
				parent.charge = 1.3
				parent.frame()
				return states.DOWN_SMASH_1
			if parent.frame == 63:
				parent.charge = 1.4
				parent.frame()
				return states.DOWN_SMASH_1
		states.DOWN_SMASH_1:
			parent.invis_frames = 0
			if AIREAL() == false:
					if parent.velocity.x > 0:
						parent.velocity.x += - parent.TRACTION / 7
						parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
					elif parent.velocity.x < 0:
						parent.velocity.x += parent.TRACTION / 7
						parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
			if AIREAL() == true:
					if parent.velocity.y < parent.FALLINGSPEED:
						parent.velocity.y += parent.FALLSPEED
					if parent.velocity.x < 0:
						parent.velocity.x += parent.AIR_ACCEL / 10
					elif parent.velocity.x > 0:
						parent.velocity.x += - parent.AIR_ACCEL / 10
			if parent.DOWN_SMASH() == true:
				Edge_Hog()
				if Input.is_action_pressed("down_%s" % id):
					parent.frame()
					return states.CROUCH
				else:
					parent.frame()
					return states.STAND

		states.UP_SMASH:
			Edge_Hog()
			parent.invis_frames = 0
			if AIREAL() == false:
					if parent.velocity.x > 0:
						parent.velocity.x += - parent.TRACTION / 7
						parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
					elif parent.velocity.x < 0:
						parent.velocity.x += parent.TRACTION / 7
						parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
					Edge_Hog()
			if AIREAL() == true:
					if parent.velocity.y < parent.FALLINGSPEED:
						parent.velocity.y += parent.FALLSPEED
					if parent.velocity.x < 0:
						parent.velocity.x += parent.AIR_ACCEL / 10
					elif parent.velocity.x > 0:
						parent.velocity.x += - parent.AIR_ACCEL / 10
			if parent.frame < 5 and not Input.is_action_pressed("down_%s" % id):
				parent.charge = 1
		
			if parent.frame >= 5 and parent.frame <= 10 and not Input.is_action_pressed("attack_%s" % id):
				parent.charge = 1.1
				parent.frame()
				return states.UP_SMASH_1
			if parent.frame >= 11 and parent.frame <= 20 and not Input.is_action_pressed("attack_%s" % id):
				parent.charge = 1.1
				parent.frame()
				return states.UP_SMASH_1
			if parent.frame >= 21 and parent.frame <= 40 and not Input.is_action_pressed("attack_%s" % id):
				parent.charge = 1.2
				parent.frame()
				return states.UP_SMASH_1
			if parent.frame >= 41 and parent.frame <= 50 and not Input.is_action_pressed("attack_%s" % id):
				parent.charge = 1.2
				parent.frame()
				return states.UP_SMASH_1
			if parent.frame >= 51 and not Input.is_action_pressed("attack_%s" % id):
				parent.charge = 1.3
				parent.frame()
				return states.UP_SMASH_1
			if parent.frame == 63:
				parent.charge = 1.4
				parent.frame()
				return states.UP_SMASH_1
		states.UP_SMASH_1:
			Edge_Hog()
			parent.invis_frames = 0
			if AIREAL() == false:
					if parent.velocity.x > 0:
						parent.velocity.x += - parent.TRACTION / 3
						parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
					elif parent.velocity.x < 0:
						parent.velocity.x += parent.TRACTION / 3
						parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
			if AIREAL() == true:
					if parent.velocity.y < parent.FALLINGSPEED:
						parent.velocity.y += parent.FALLSPEED
					if parent.velocity.x < 0:
						parent.velocity.x += parent.AIR_ACCEL / 10
					elif parent.velocity.x > 0:
						parent.velocity.x += - parent.AIR_ACCEL / 10
			if parent.UP_SMASH() == true:
				if Input.is_action_pressed("down_%s" % id):
					parent.frame()
					return states.CROUCH
				else:
					parent.frame()
					return states.STAND


		states.FORWARD_SMASH:
			Edge_Hog()
			parent.invis_frames = 0
			print(AIREAL())
			if AIREAL() == false:
					if parent.velocity.x > 0:
						parent.velocity.x += - parent.TRACTION * 10
						parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
					elif parent.velocity.x < 0:
						parent.velocity.x += parent.TRACTION * 10
						parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
					Edge_Hog()
			if AIREAL() == true:
					if parent.velocity.y < parent.FALLINGSPEED:
						parent.velocity.y += parent.FALLSPEED
					if parent.velocity.x > 0:
						parent.velocity.x += - parent.TRACTION / 3
						parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
					elif parent.velocity.x < 0:
						parent.velocity.x += parent.TRACTION / 3
						parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
			if parent.frame >= 5 and parent.frame <= 10 and not Input.is_action_pressed("attack_%s" % id):
				parent.charge = 1.1
				
			
			if parent.frame >= 11 and parent.frame <= 20 and not Input.is_action_pressed("attack_%s" % id):
				parent.charge = 1.1
				parent.frame()
				return states.FORWARD_SMASH_1
			if parent.frame >= 21 and parent.frame <= 40 and not Input.is_action_pressed("attack_%s" % id):
				parent.charge = 1.2
				parent.frame()
				return states.FORWARD_SMASH_1
			if parent.frame >= 41 and parent.frame <= 50 and not Input.is_action_pressed("attack_%s" % id):
				parent.charge = 1.2
				parent.frame()
				return states.FORWARD_SMASH_1
			if parent.frame >= 51 and not Input.is_action_pressed("attack_%s" % id):
				parent.charge = 1.3
				parent.frame()
				return states.FORWARD_SMASH_1
			if parent.frame == 63:
				parent.charge = 1.4
				parent.frame()
				return states.FORWARD_SMASH_1
				
		states.FORWARD_SMASH_1:
			Edge_Hog()
			parent.invis_frames = 0
			if AIREAL() == false:
				parent.velocity.x = parent.DASHSPEED * parent.direction() * 0.9
			if AIREAL() == true:
					if parent.velocity.y < parent.FALLINGSPEED:
						parent.velocity.y += parent.FALLSPEED
					if parent.velocity.x > 0:
						parent.velocity.x += - parent.TRACTION / 3
						parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
					elif parent.velocity.x < 0:
						parent.velocity.x += parent.TRACTION / 3
						parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
			if parent.FORWARD_SMASH() == true:
				if parent.velocity.x > 0:
					parent.velocity.x += - parent.TRACTION
					parent.velocity.x = clamp(parent.velocity.x, 0, parent.velocity.x)
				if parent.velocity.x < 0:
					parent.velocity.x += parent.TRACTION
					parent.velocity.x = clamp(parent.velocity.x, parent.velocity.x, 0)
				if Input.is_action_pressed("down_%s" % id):
					parent.frame()
					return states.CROUCH
				else:
					parent.frame()
					return states.STAND

		states.RESPAWN:
			if parent.frame == 1:
				if parent.RESPAWN() == false:
					parent.RESPAWN()
			parent.velocity = Vector2(0, 0)
			if parent.frame <= 300 and parent.frame >= 30:
				parent.hurtbox.disabled = true
				if Input.is_action_just_pressed("right_%s" % id):
					parent.frame()
					parent.DESPAWN()
					parent.invis_frames = 120
					return states.AIR
				elif Input.is_action_just_pressed("left_%s" % id):
					parent.frame()
					parent.DESPAWN()
					parent.invis_frames = 120
					return states.AIR
				elif Input.is_action_just_pressed("jump_%s" % id) and parent.airJump > 0:
					parent.fastfall = false
					parent.velocity.x = 0
					parent.velocity.y = - parent.DOUBLEJUMPFORCE
					parent.airJump -= 1
					
					
					if Input.is_action_pressed("left_%s" % id):
						parent.velocity.x = - parent.MAXAIRSPEED
					elif Input.is_action_pressed("right_%s" % id):
						parent.velocity.x = parent.MAXAIRSPEED
					parent.DESPAWN()
					parent.invis_frames = 120
					return states.AIR
				elif Input.is_action_pressed("down_%s" % id) and parent.down_buffer == 1 and parent.velocity.y > - 150 and not parent.fastfall:
					
					parent.velocity.y = parent.MAXFALLSPEED
					parent.fastfall = true
					if parent.fastfall == true:
						parent.set_collision_mask_bit(2, false)
						parent.velocity.y = parent.MAXFALLSPEED
					parent.DESPAWN()
					parent.invis_frames = 120
					return states.AIR
			elif parent.frame > 390:
				parent.frame()
				parent.DESPAWN()
				parent.invis_frames = 120
				return states.AIR

		states.DEAD:
			parent.lag_frames = 0
			parent.velocity.x = 0
			parent.velocity.y = 0


func enter_state(new_state, old_state):
	match new_state:
		states.STAND:
			parent.play_animation("STAND")
			parent.states.text = str("STAND")
		states.RUN:
			parent.play_animation("RUN")
			parent.states.text = str("RUN")
		states.WALK:
			parent.play_animation("WALK")
			parent.states.text = str("WALK")
		states.FULL_HOP:
			parent.play_animation("AIR")
			parent.states.text = str("FULL_HOP")
		states.SHORT_HOP:
			parent.play_animation("AIR")
			parent.states.text = str("SHORT_HOP")
		states.MOONWALK:
			parent.play_animation("WALK")
			parent.states.text = str("MOONWALK")
		states.DASH:
			parent.play_animation("DASH")
			parent.states.text = str("DASH")
		states.JUMP_SQUAT:
			parent.play_animation("JUMP_SQUAT")
			parent.states.text = str("JUMP_SQUAT")
		states.TURN:
			parent.play_animation("TURN")
			parent.states.text = str("TURN")
		states.CROUCH:
			parent.play_animation("CROUCH")
			parent.states.text = str("CROUCH")
		states.AIR:
			parent.play_animation("AIR")
			parent.states.text = str("AIR")
		states.FREE_FALL:
			parent.play_animation("FREE_FALL")
			parent.states.text = str("FREE_FALL")
		states.LANDING:
			parent.play_animation("LANDING")
			parent.states.text = str("LANDING")
		states.AIR_DODGE:
			parent.play_animation("AIR_DODGE")
			parent.states.text = str("AIR_DODGE")
		states.LEDGE_CATCH:
			parent.play_animation("LEDGE_CATCH")
			parent.states.text = str("LEDGE_CATCH")
			sound_play($"../Ledge")
			sound_play($"../LedgeSFX")
		states.LEDGE_HOLD:
			parent.play_animation("LEDGE_CATCH")
			parent.states.text = str("LEDGE_HOLD")
		states.LEDGE_JUMP:
			parent.play_animation("AIR")
			parent.states.text = str("LEDGE_JUMP")
		states.LEDGE_CLIMB:
			parent.play_animation("ROLL_FORWARD")
			parent.states.text = str("LEDGE_CLIMB")
		states.LEDGE_ROLL:
			parent.play_animation("ROLL_FORWARD")
			parent.states.text = str("LEDGE_ROLL")
		states.HITSTUN:
			parent.play_animation("HITSTUN")
			parent.states.text = str("HITSTUN")
		states.TUMBLE:
			parent.play_animation("TUMBLE")
			parent.states.text = str("TUMBLE")
		states.PARRY:
			parent.play_animation("PARRY")
			parent.states.text = str("PARRY")
		states.ROLL_RIGHT:
			parent.play_animation("TECH_GROUND")
			parent.states.text = str("ROLL_RIGHT")
		states.ROLL_LEFT:
			parent.play_animation("TECH_GROUND")
			parent.states.text = str("ROLL_LEFT")
		states.TECH_GROUND:
			parent.play_animation("TECH_GROUND")
			parent.states.text = str("TECH_GROUND")
		states.TECH_FORWARD:
			parent.play_animation("TECH_GROUND")
			parent.states.text = str("TECH_FORWARD")
		states.TECH_BACKWARD:
			parent.play_animation("TECH_GROUND")
			parent.states.text = str("TECH_BACKWARD")
		states.UP_TILT:
			parent.play_animation("UP_TILT")
			parent.states.text = str("UP_TILT")
		states.DOWN_TILT:
			parent.play_animation("DOWN_TILT")
			parent.states.text = str("DOWN_TILT")
		states.FORWARD_TILT:
			parent.play_animation("FORWARD_TILT")
			parent.states.text = str("FORWARD_TILT")
		states.JAB:
			parent.play_animation("JAB")
			parent.states.text = str("JAB")
		states.JAB_1:
			parent.play_animation("JAB_1")
			parent.states.text = str("JAB_1")
		states.GROUND_ATTACK:
			
			parent.states.text = str("GROUND_ATTACK")
		states.SPECIAL:
			
			parent.states.text = str("SPECIAL")
		states.FORWARD_SPECIAL:
			parent.play_animation("FORWARD_SPECIAL")
			parent.states.text = str("FORWARD_SPECIAL")
		states.NEUTRAL_SPECIAL:
			parent.play_animation("NEUTRAL_SPECIAL")
			parent.states.text = str("NEUTRAL_SPECIAL")
		states.UP_SPECIAL:
			parent.play_animation("UP_SPECIAL")
			parent.states.text = str("UP_SPECIAL")
		states.UP_SPECIAL_1:
			parent.play_animation("UP_SPECIAL_1")
			parent.states.text = str("UP_SPECIAL_1")
		states.DOWN_SPECIAL:
			parent.play_animation("DOWN_SPECIAL")
			parent.states.text = str("DOWN_SPECIAL")
			($"../DSpecial").play()
		states.NAIR:
			parent.play_animation("NAIR")
			parent.states.text = str("NAIR")
		states.UAIR:
			parent.play_animation("UAIR")
			parent.states.text = str("UAIR")
		states.BAIR:
			parent.play_animation("BAIR")
			parent.states.text = str("BAIR")
		states.FAIR:
			parent.play_animation("FAIR")
			parent.states.text = str("FAIR")
		states.DAIR:
			parent.play_animation("DAIR")
			parent.states.text = str("DAIR")
		states.DOWN_SMASH:
			parent.play_animation("DOWN_SMASH")
			parent.states.text = str("DOWN_SMASH")
		states.DOWN_SMASH_1:
			parent.play_animation("DOWN_SMASH_1")
			parent.states.text = str("DOWN_SMASH_1")
		states.UP_SMASH:
			parent.play_animation("UP_SMASHS")
			parent.states.text = str("UP_SMASH")
		states.UP_SMASH_1:
			parent.play_animation("UP_SMASHS_1")
			parent.states.text = str("UP_SMASH_1")
		states.FORWARD_SMASH:
			parent.play_animation("FORWARD_SMASHS")
			parent.states.text = str("FORWARD_SMASH")
		states.FORWARD_SMASH_1:
			parent.play_animation("FORWARD_SMASHS_1")
			parent.states.text = str("FORWARD_SMASH_1")
		states.RESPAWN:
			parent.play_animation("STAND")
			parent.states.text = str("RESPAWN")
		states.DEAD:
			parent.play_animation("STAND")
			parent.states.text = str("DEAD")
			
func exit_state(old_state, new_state):
	if old_state == states.LANDING and new_state == states.AIR:
		parent.lag_frames = 0

func AIRMOVEMENT():
	if parent.velocity.y < parent.FALLINGSPEED:
		parent.velocity.y += parent.FALLSPEED
	if Input.is_action_pressed("down_%s" % id) and parent.down_buffer == 1 and parent.velocity.y > - 150 and not parent.fastfall:
	
		parent.velocity.y = parent.MAXFALLSPEED
		parent.fastfall = true
	if parent.fastfall == true:
		parent.set_collision_mask_bit(2, false)
		parent.velocity.y = parent.MAXFALLSPEED
		
	if abs(parent.velocity.x) >= abs(parent.MAXAIRSPEED):
		if parent.velocity.x > 0:
			if Input.is_action_pressed("left_%s" % id):
				parent.velocity.x += - parent.AIR_ACCEL
			elif Input.is_action_pressed("right_%s" % id):
					parent.velocity.x = parent.velocity.x
		if parent.velocity.x < 0:
			if Input.is_action_pressed("left_%s" % id):
				parent.velocity.x = parent.velocity.x
			elif Input.is_action_pressed("right_%s" % id):
				parent.velocity.x += parent.AIR_ACCEL
					
				
	elif abs(parent.velocity.x) < abs(parent.MAXAIRSPEED):
		if Input.is_action_pressed("left_%s" % id):
			parent.velocity.x += - parent.AIR_ACCEL
		if Input.is_action_pressed("right_%s" % id):
			parent.velocity.x += parent.AIR_ACCEL
		
	if not Input.is_action_pressed("left_%s" % id) and not Input.is_action_pressed("right_%s" % id):
		
		if parent.velocity.x < 0:
			parent.velocity.x += parent.AIR_ACCEL / 5
		elif parent.velocity.x > 0:
			parent.velocity.x += - parent.AIR_ACCEL / 5

func drop_platform():
		if state_includes([states.RUN, states.WALK, states.STAND, states.CROUCH, states.DASH, states.LANDING, states.TURN, states.JUMP_SQUAT, states.MOONWALK, states.ROLL_RIGHT, states.ROLL_LEFT, states.PARRY]) and parent.down_buffer < 10:
			if Input.is_action_pressed("down_%s" % id) and parent.frame > 4:
					if parent.GroundL.is_colliding():
						var collider = parent.GroundL.get_collider()
						if collider.get_node("Label").text == "Platform":
							parent.set_collision_mask_bit(2, false)
							parent.velocity.y = parent.FALLSPEED
							return states.AIR
							
					if parent.GroundR.is_colliding():
						var collider = parent.GroundR.get_collider()
						if collider.get_node("Label").text == "Platform":
							parent.set_collision_mask_bit(2, false)
							parent.velocity.y = parent.FALLSPEED
							return states.AIR
							









func Landing():
	if state_includes([states.AIR, states.AIR_DODGE, states.FREE_FALL, states.TUMBLE, states.NAIR, states.UAIR, states.BAIR, states.FAIR, states.DAIR]):
		if (parent.GroundL.is_colliding()) and parent.velocity.y > 0:
				var collider = parent.GroundL.get_collider()
				if collider.get_node("Label").text == "Floor":
					parent.frame = 0
					if parent.velocity.y > 0:
						parent.velocity.y = 0
					parent._reset_Jumps()
					parent.reset_platform()
					parent.fastfall = false
					return true
			
				if collider.get_node("Label").text == "Platform":
					if parent.velocity.y > 0:
						parent.velocity.y = 0
					parent._reset_Jumps()
					parent.reset_platform()
					parent.fastfall = false
					return true
		elif parent.GroundR.is_colliding() and parent.velocity.y > 0:
				var collider2 = parent.GroundR.get_collider()
				if collider2.get_node("Label").text == "Floor":
					parent.frame = 0
					if parent.velocity.y > 0:
						parent.velocity.y = 0
					parent._reset_Jumps()
					parent.reset_platform()
					parent.fastfall = false
					return true
			
				if collider2.get_node("Label").text == "Platform":
					if parent.velocity.y > 0:
						parent.velocity.y = 0
					parent._reset_Jumps()
					parent.reset_platform()
					parent.fastfall = false
					return true


func Falling():
	if state_includes([states.RUN, states.WALK, states.STAND, states.CROUCH, states.DASH, states.LANDING, states.TURN, states.JUMP_SQUAT, states.MOONWALK, states.ROLL_RIGHT, states.ROLL_LEFT, states.PARRY]):
		if not parent.GroundL.is_colliding() and not parent.GroundR.is_colliding():
			return true
			
			
			
			
			
			
			

func Ledge():
	if state_includes([states.AIR, states.FREE_FALL, states.UP_SPECIAL_1, states.TUMBLE]):
		if (parent.Ledge_Grab_F.is_colliding()):
			var collider = parent.Ledge_Grab_F.get_collider()
			if collider.get_node("Label").text == "Ledge_L" and not Input.get_action_strength("down_%s" % id) > 0.6 and parent.regrab == 0 and not collider.is_grabbed:

				if state_includes([states.AIR, states.FREE_FALL, ]):
					if parent.velocity.y < 0:
						return false
				parent.frame = 0
				parent.velocity.x = 0
				parent.velocity.y = 0
				self.parent.position.x = collider.position.x - 20
				self.parent.position.y = collider.position.y - 2
				parent.turn(false)
				parent._reset_Jumps()
				parent.fastfall = false
				
				
				collider.is_grabbed = true
				parent.last_ledge = collider
				return true
				

			if collider.get_node("Label").text == "Ledge_R" and not Input.get_action_strength("down_%s" % id) > 0.6 and parent.regrab == 0 and not collider.is_grabbed:
				
				if state_includes([states.AIR, states.FREE_FALL, ]):
					if parent.velocity.y < 0:
						return false
				parent.frame = 0
				parent.velocity.x = 0
				parent.velocity.y = 0
				self.parent.position.x = collider.position.x + 20
				self.parent.position.y = collider.position.y + 1
				parent.turn(true)
				parent._reset_Jumps()
				parent.fastfall = false
				
			
				collider.is_grabbed = true
				parent.last_ledge = collider
				return true

		if (parent.Ledge_Grab_B.is_colliding()):
			var collider = parent.Ledge_Grab_B.get_collider()
			if collider.get_node("Label").text == "Ledge_L" and not Input.get_action_strength("down_%s" % id) > 0.6 and parent.regrab == 0 and not collider.is_grabbed:

				if state_includes([states.AIR, states.FREE_FALL, ]):
					if parent.velocity.y < 0:
						return false
				parent.frame = 0
				parent.velocity.x = 0
				parent.velocity.y = 0
				self.parent.position.x = collider.position.x - 20
				self.parent.position.y = collider.position.y - 1
				parent.turn(false)
				parent._reset_Jumps()
				parent.fastfall = false
				
			
				collider.is_grabbed = true
				parent.last_ledge = collider
				return true
				

			if collider.get_node("Label").text == "Ledge_R" and not Input.get_action_strength("down_%s" % id) > 0.6 and parent.regrab == 0 and not collider.is_grabbed:
				
				if state_includes([states.AIR, states.FREE_FALL, ]):
					if parent.velocity.y < 0:
						return false
				parent.frame = 0
				parent.velocity.x = 0
				parent.velocity.y = 0
				self.parent.position.x = collider.position.x + 20
				self.parent.position.y = collider.position.y + 1
				parent.turn(true)
				parent._reset_Jumps()
				parent.fastfall = false
			
			
				collider.is_grabbed = true
				parent.last_ledge = collider
				return true

				

func state_includes(state_array):
	for each_state in state_array:
		if state == each_state:
			return true
	return false

func Platform_Drop():
	if state_includes([states.RUN, states.WALK, states.STAND, states.CROUCH, states.DASH, states.LANDING, states.TURN, states.JUMP_SQUAT, states.MOONWALK, states.ROLL_RIGHT, states.ROLL_LEFT, states.PARRY]) and parent.down_buffer < 10:
		if Input.is_action_pressed("down_%s" % id) and parent.frame > 4 and (parent.GroundL.is_colliding() or parent.GroundR.is_colliding()):
				if parent.GroundL.is_colliding():
					var collider = parent.GroundL.get_collider()
					if collider.get_node("Label").text == "Platform":
						parent.velocity.y = parent.FALLSPEED
						self.parent.set_collision_mask_bit(2, false)
						return true
				elif parent.GroundR.is_colliding():
					var collider = parent.GroundR.get_collider()
					if collider.get_node("Label").text == "Platform":
						self.parent.set_collision_mask_bit(2, false)
						parent.velocity.y = parent.FALLSPEED
						return true

func right_stick():
	if Input.is_action_just_pressed("r_up_%s" % id):
		return true
	if Input.is_action_just_pressed("r_right_%s" % id):
		return true
	if Input.is_action_just_pressed("r_down_%s" % id):
		return true
	if Input.is_action_just_pressed("r_left_%s" % id):
		return true

func TILT():
	if state_includes([states.STAND, states.MOONWALK, states.DASH, states.RUN, states.WALK, states.CROUCH, states.TURN, states.JUMP_SQUAT]):
		Platform_Drop()
		return true

func AIREAL():
	if state_includes([states.UP_SPECIAL, states.DOWN_SPECIAL, states.NEUTRAL_SPECIAL, states.FORWARD_SPECIAL, states.JUMP_SQUAT, states.AIR, states.DOWN_SMASH, states.DOWN_SMASH_1, states.FORWARD_SMASH, states.FORWARD_SMASH_1, states.UP_SMASH, states.UP_SMASH_1, states.TUMBLE]):
		if not (parent.GroundL.is_colliding() and parent.GroundR.is_colliding()):
			return true
		else:
			return false

func SPECIAL():
	if state_includes([states.LANDING, states.STAND, states.WALK, states.DASH, states.RUN, states.TURN, states.MOONWALK, states.CROUCH, states.TUMBLE]):
		Platform_Drop()
		return true

func GROUND_ATTACKS():
	if Input.is_action_just_pressed("attack_%s" % id) and TILT() == true:
		parent.frame()
		return states.JAB
	if Input.is_action_just_pressed("attack_%s" % id) and Input.is_action_pressed("up_%s" % id) and TILT() == true:
		parent.frame()
		return states.UP_TILT
	if Input.is_action_just_pressed("attack_%s" % id) and Input.is_action_pressed("down_%s" % id) and TILT() == true:
		parent.frame()
		return states.DOWN_TILT
	if Input.is_action_just_pressed("attack_%s" % id) and (Input.is_action_pressed("left_%s" % id) or Input.is_action_pressed("right_%s" % id)) and TILT() == true:
		parent.frame()
		if Input.is_action_pressed("left_%s" % id):
			parent.turn(true)
			parent.frame()
			return states.FORWARD_TILT
		if Input.is_action_pressed("right_%s" % id):
			parent.turn(false)
			parent.frame()
			return states.FORWARD_TILT

func sound_play(sound):
	null
	
		

func Edge_Hog():
	if not parent.GroundL.is_colliding() and parent.direction() == - 1:
		parent.velocity.x = 0
	if not parent.GroundR.is_colliding() and parent.direction() == 1:
		parent.velocity.x = 0

func char_angle_reset():
		if not state_includes([states.UP_SPECIAL, states.UP_SPECIAL_1]):
			parent.shapez.rotation_degrees = 0
			parent.spritez.rotation_degrees = 0

func can_roll():
	if state_includes([states.STAND, states.DASH, states.MOONWALK, states.RUN, states.WALK, states.CROUCH, states.TURN]):
		Platform_Drop()
		return true

func enable_HurtBox():
	if not state_includes([states.PARRY, states.AIR_DODGE, states.ROLL_RIGHT, states.ROLL_LEFT, states.LEDGE_CATCH, states.LEDGE_HOLD, states.LEDGE_CLIMB, states.LEDGE_ROLL, states.TECH, states.TECH_GROUND, states.TECH_FORWARD, states.TECH_BACKWARD]):
		parent.hurtbox.disabled = false
		
