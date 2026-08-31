extends KinematicBody2D
export var id: int
export var percentage = 0
export var stocks = 3
export var weight = 110
var velocity = Vector2(0, 0)
onready var publicDelta = get_process_delta_time()
export (float) var time_scale = 1


const UP = Vector2(0, - 1)
export var hitbox: PackedScene
export var grabbox: PackedScene
export var projectile: PackedScene
export var explosion: PackedScene
export var angel_platform: PackedScene


















export (float) var RUNSPEED = 249
export (float) var DASHSPEED = 361
export (float) var WALKSPEED = 152
export (float) var GRAVITY = 1800
export (float) var JUMPFORCE = 430
export (float) var MAX_JUMPFORCE = 550
export (float) var DOUBLEJUMPFORCE = 700
export (float) var MAXAIRSPEED = 300
export (float) var AIR_ACCEL = 28
export (float) var FALLSPEED = 33
export (float) var FALLINGSPEED = 743
export (float) var MAXFALLSPEED = 743
export (float) var TRACTION = 35
export (float) var ROLL_DISTANCE = 350
export (float) var air_dodge_speed = 500
export (float) var UP_B_LAUNCHSPEED = 500

export var landing_frames = 0
onready var shapez = $Collisionbox
onready var spritez = $Sprite
onready var anim = $Sprite / AnimationPlayer
onready var raycasts = $Raycasts
onready var states = $State
onready var hurtbox = get_node("HurtBox/Hurtbox")
onready var last_ledge = false

onready var Ledge_Grab_F: = $Raycasts / Ledge_Grab_F
onready var gun_pos = get_node("gun_pos")
onready var Ledge_Grab_B = get_node("Raycasts/Ledge_Grab_B")
onready var GroundL = get_node("Raycasts/GroundL")
onready var GroundR = get_node("Raycasts/GroundR")
onready var state_machine = $StateMachine
var is_attacking = false;
var fastfall = false
var last_platform = false
var regrab = 30
var down_buffer = 0
var up_buffer = 0
var right_buffer = 0
var left_buffer = 0
var shield_buffer = 0
var invis_frames = 0
var tech_frames = 0
var cooldown = 0
var lag_frames = 0
var buffer_dodge = false
var buffering_dodge
var grabbing = false
func grabbing(value):
	grabbing = value

export var perfect_wavedash_modifier = 1
export var dash_duration = 10
export var jump_squat_duration = 3

var moonwalk = false

var selfState
var in_air
var catch = false

export var airJump = 0
export var airJumpMax = 1

func reset_sprite():
	yield(get_tree().create_timer(0.05), "timeout")
	spritez.position = Vector2(0, - 8)

func _ready():
	set_physics_process(true)
	pass

func _reset_Jumps():
	airJump = airJumpMax

func parry():
	if frame == 4:
		pass
		
	if frame == 20:
		
		pass

func rolling():
	if frame == 4:
		pass
		
	if frame == 20:
		
		pass

func reset_platform():
	last_platform = false
	self.set_collision_mask_bit(2, true)

func reset_ledge():

	last_ledge = false

func direction():
	if Ledge_Grab_F.get_cast_to().x > 0:
		return 1
	else:
		return - 1

func invis_frames():
	invis_frames -= 1
	invis_frames = clamp(invis_frames, 0, invis_frames)

func down_buffer():
	if not Input.is_action_pressed("down_%s" % id):
		down_buffer = 0
	elif Input.is_action_pressed("down_%s" % id):
		down_buffer += 1

func up_buffer():
	if not Input.is_action_pressed("up_%s" % id):
		up_buffer = 0
	elif Input.is_action_pressed("up_%s" % id):
		up_buffer += 1

func right_buffer():
	if not Input.is_action_pressed("right_%s" % id):
		right_buffer = 0
	elif Input.is_action_pressed("right_%s" % id):
		right_buffer += 1

func left_buffer():
	if not Input.is_action_pressed("left_%s" % id):
		left_buffer = 0
	elif Input.is_action_pressed("left_%s" % id):
		left_buffer += 1

func shield_buffer():
	if not Input.is_action_pressed("shield_%s" % id):
		shield_buffer = 0
	elif Input.is_action_pressed("shield_%s" % id):
		shield_buffer += 1

func techwindow():
		tech_frames += 1
		clamp(tech_frames, 0, 20)
func tech():
		tech_frames = 0
		
func cooldown():
	
	cooldown -= 1
	cooldown = clamp(cooldown, 0, cooldown)
	
	
var frame = 0
var lagframes = 0
var hitstun = 0
var knockback = 0
var charge = 1

var hdecay = 0
var vdecay = 0
var hdecay_1 = 0
var vdecay_1 = 0

func turn(direction):
	var dir = 0
	if direction:
		dir = - 1
	else:
		dir = 1
	$Sprite.set_flip_h(direction)
	gun_pos.position = Vector2(dir * abs(gun_pos.position.x), gun_pos.position.y)
	Ledge_Grab_F.set_cast_to(Vector2(dir * abs(Ledge_Grab_F.get_cast_to().x), Ledge_Grab_F.get_cast_to().y))
	Ledge_Grab_B.set_cast_to(Vector2( - dir * abs(Ledge_Grab_F.get_cast_to().x), Ledge_Grab_F.get_cast_to().y))

	pass
	
	
	
var connected = false

func create_hitbox(width, height, damage, angle, base_kb, kb_scaling, duration, type, points, angle_flipper, hitlag = 1):
	
	var hitbox_instance = hitbox.instance()
	self.add_child(hitbox_instance)
	
	if direction() == 1:
		hitbox_instance.set_parameters(width, height, damage, angle, base_kb, kb_scaling, duration, type, points, angle_flipper, hitlag)
		
	else:
		
		
		
		var flip_x_points = Vector2( - points.x, points.y)
		hitbox_instance.set_parameters(width, height, damage, - angle + 180, base_kb, kb_scaling, duration, type, flip_x_points, angle_flipper, hitlag)
		
	return hitbox_instance

func create_grabbox(width, height, damage, duration, points):
	var grabbox_instance = grabbox.instance()
	self.add_child(grabbox_instance)
	
	if direction() == 1:
		grabbox_instance.set_parameters(width, height, damage, duration, points)
		
	else:
		var flip_x_points = Vector2( - points.x, points.y)
		grabbox_instance.set_parameters(width, height, damage, duration, flip_x_points)
		
	return grabbox_instance

func create_projectile(dir_x, dir_y, point):
	var projectile_instance = projectile.instance()
	projectile_instance.player_list.append(self)

	
	gun_pos.set_position(point)
	
	if direction() == 1:
		projectile_instance.dir(dir_x, dir_y)
		get_parent().add_child(projectile_instance)
		projectile_instance.set_position(gun_pos.get_global_position())
		
	else:
		gun_pos.position.x = - gun_pos.position.x
		projectile_instance.dir( - (dir_x), dir_y)
		get_parent().add_child(projectile_instance)
		projectile_instance.set_position(gun_pos.get_global_position())
		
	return projectile_instance

func PARRY():
	if frame == 2:
		
		create_hitbox(48, 68, 6, 76, 18, 140, 4, "normal", Vector2( - 22, - 15), 0, 0.6)
	if frame == 30:
		return true

func RESPAWN():
	var angel_plat = angel_platform.instance()
	self.add_child(angel_plat)
	return true
	
func DESPAWN():
	var angel_plat = get_node("FOX_ANGEL_PLAT")
	angel_plat.queue_free()
	return true

func UP_TILT():
	if frame == 5:
		
		create_hitbox(30, 50, 5, 80, 8, 145, 2, "normal", Vector2(55, 3), 0, 0.6)
	if frame == 8:
		create_hitbox(45, 50, 5.5, 80, 28, 130, 2, "normal", Vector2(9, - 58), 0, 0.6)
	if frame >= 18:
		return true

func DOWN_TILT():
	if frame == 4:
	
		create_hitbox(40, 20, 7, 75, 3, 120, 3, "normal", Vector2(44, 32), 0, 0.5)
	if frame >= 25:
		return true

func FORWARD_TILT():
	if frame == 4:
		
		create_hitbox(52, 20, 9, 361, 4, 140, 10, "slash", Vector2(32, 8), 0, 1)
	if frame >= 8:
		return true
		
func JAB():
	if frame == 2:
			create_grabbox(30, 40, 0, 3, Vector2(64, 0))
	if frame == 5:
			if grabbing == true:
				return false
				
	if frame >= 20:
		return true

func JAB_1():
	if frame == 1:
		grabbing = false
		create_grabbox(30, 40, 0, 13, Vector2(64, 0))
	if frame == 12:
		create_hitbox(40, 20, 8, 90, 11, 150, 9, "normal", Vector2(48, 8), 0, 1)
	
	




	if frame == 32:
		return true

func NEUTRAL_SPECIAL():
	if frame == 14:
		create_projectile(1, 1, Vector2(42.82, 1.692))
	if frame == 43:
		return true

func FORWARD_SPECIAL():
	if frame == 11:
		create_hitbox(71, 54, 10, 90, 0, 0, 6, "Flip", Vector2(26, - 2), 0, 1)
	if frame == 32:
		return true

func DOWN_SPECIAL():
	if frame == 5:
		create_hitbox(60, 66, 2, 120, 160, 0, 2, "normal", Vector2(0, 0), 7, 1)
	if frame == 9:
		create_hitbox(60, 66, 2, 120, 160, 0, 2, "normal", Vector2(0, 0), 7, 1)
	if frame == 12:
		create_hitbox(60, 66, 2, 120, 160, 0, 2, "normal", Vector2(0, 0), 7, 1)
	if frame == 15:
		create_hitbox(60, 66, 2, 120, 160, 0, 2, "normal", Vector2(0, 0), 7, 1)
	if frame == 18:
		create_hitbox(60, 66, 2, 120, 160, 0, 2, "normal", Vector2(0, 0), 7, 1)
	if frame == 21:
		create_hitbox(60, 66, 2, 90, 160, 0, 3, "normal", Vector2(0, 0), 7, 1)
	if frame == 41:
		create_hitbox(60, 66, 5, 90, 10, 150, 10, "normal", Vector2(0, 0), 0, 1)
	if frame == 65:
		return true

func UP_SPECIAL():
	if frame == 6:
		create_hitbox(40, 28, 2, 80, 130, 0, 5, "normal", Vector2(26, 10), 0, 0.5)
	if frame == 9:
		create_hitbox(36, 45, 2, 80, 130, 0, 9, "normal", Vector2(19, - 12), 0, 0.5)
	if frame == 12:
		create_hitbox(22, 30, 10, 95, 20, 150, 1, "normal", Vector2(19, - 12), 0, 0.1)
	if frame == 29:
		return true

func NAIR():
	if frame == 1:
		create_hitbox(56, 56, 8, 361, 5, 100, 3, "normal", Vector2(0, 0), 0, 1)
	if frame > 1:
		if connected == true:
			
			if frame == 40:
				connected = false
				return true
		else:
			if frame == 5:
				create_hitbox(46, 56, 5, 361, 5, 100, 20, "normal", Vector2(0, 0), 0, 1)
			if frame == 40:
				connected = false
				return true

func UAIR():
	if frame == 4:
		create_hitbox(37, 38, 7, 80, 10, 135, 2, "slash", Vector2(36, 3), 0, 1)
	if frame == 8:
		create_hitbox(45, 42, 7, 90, 10, 135, 4, "slash", Vector2( - 13, - 57), 0, 1)
	if frame == 10:
		create_hitbox(40, 37, 7, 75, 10, 135, 3, "slash", Vector2( - 21, 2), 0, 1)
	if frame == 28:
		return true

func BAIR():
	if frame == 8:
		create_hitbox(35, 32, 8, 140, 8, 140, 20, "normal", Vector2( - 32, 9), 0, 1)
	if frame == 40:
		return true

func FAIR():
	if frame == 15:
		create_hitbox(34, 28, 14, 270, 6, 130, 3, "normal", Vector2(26, - 33), 6, 0.1)
	if frame > 15:
		if connected == true:
			if frame == 44:
				print("sweetspot")
				connected = false
				return true
		else:
			if frame == 17:
				create_hitbox(30, 45, 14, 270, 6, 130, 3, "normal", Vector2(27, - 14), 0, 0.2)
			if frame > 17:
				if connected == true:
					if frame == 44:
						print("sweetspot")
						connected = false
						return true
				else:
					if frame == 18:
						create_hitbox(21, 20, 14, 270, 6, 130, 3, "normal", Vector2(15, 34), 6, 0.2)
					if frame == 44:
						connected = false
						return true

func DAIR():
	if frame == 13:
		create_hitbox(36, 58, 2, 40, 3, 110, 6, "normal", Vector2(28, 17), 0, 0.5)
	if frame == 17:
		create_hitbox(36, 58, 2, 40, 1, 110, 2, "normal", Vector2(28, 17), 0, 1)
	if frame == 22:
		create_hitbox(36, 58, 2, 40, 1, 110, 2, "normal", Vector2(28, 17), 0, 1)
	if frame == 27:
		create_hitbox(36, 58, 2, 40, 1, 110, 2, "normal", Vector2(28, 17), 0, 1)
	if frame == 32:
		create_hitbox(36, 58, 2, 40, 3, 120, 2, "normal", Vector2(28, 17), 0, 0.5)
	if frame == 60:
		return true

func DOWN_SMASH():
	if frame == 1:
		create_hitbox(51, 24, 11 * charge, 45, 8, 170, 5, "normal", Vector2(51, 44), 0, 0.7)
	if frame == 6:
		create_hitbox(51, 24, 11 * charge, 130, 8, 170, 3, "normal", Vector2( - 52, 44), 0, 0.7)
	if frame == 30:
		return true

func UP_SMASH():
	if frame == 1:
		create_hitbox(60, 32, 7 * charge, 100, 140, 0, 3, "normal", Vector2(6, 3), 0, 1)
	if frame == 6:
		create_hitbox(55, 80, 12 * charge, 83, 6, 120, 3, "normal", Vector2(9, - 34), 0, 1)
	if frame == 22:
		return true

func FORWARD_SMASH():
	if frame == 14:
		create_hitbox(71, 54, 15 * charge, 45, 8, 110, 5, "none", Vector2(26, - 2), 0, 0.4)
	if frame == 11:
		var explosion_instance = explosion.instance()
		explosion_instance.set_position(gun_pos.get_global_position())
		explosion_instance.number = 1
		get_parent().add_child(explosion_instance)
	if frame == 38:
		return true


func updateframes():
	frame += 1
	$Frames.text = str(frame)
	$Health.text = str(percentage) + " %"
func frame():
	frame = 0



func play_animation(animation_name):
	$Sprite / AnimationPlayer.play(animation_name)
	


var movement
func _physics_process(delta):
	selfState = states.text
	
	
	

	match id:
		1:
			Globals.player_1["percentage"] = percentage
			Globals.player_1["stocks"] = stocks
		2:
			Globals.player_2["percentage"] = percentage
			Globals.player_2["stocks"] = stocks




