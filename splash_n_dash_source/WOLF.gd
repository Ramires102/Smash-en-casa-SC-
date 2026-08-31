extends KinematicBody2D
export var id: int
export var percentage = 0
export var stocks = 3
export var weight = 119
var velocity = Vector2(0, 0)
onready var publicDelta = get_process_delta_time()
export (float) var time_scale = 1


const UP = Vector2(0, - 1)
export var hitbox: PackedScene
export var grabbox: PackedScene
export var projectile: PackedScene
export var angel_platform: PackedScene


















export (float) var RUNSPEED = 310
export (float) var DASHSPEED = 350
export (float) var WALKSPEED = 159
export (float) var GRAVITY = 1800
export (float) var JUMPFORCE = 469
export (float) var MAX_JUMPFORCE = 732
export (float) var DOUBLEJUMPFORCE = 830
export (float) var MAXAIRSPEED = 300
export (float) var AIR_ACCEL = 30
export (float) var FALLSPEED = 51
export (float) var FALLINGSPEED = 857
export (float) var MAXFALLSPEED = 857
export (float) var TRACTION = 38
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
	get_parent().add_child(projectile_instance)
	
	gun_pos.set_position(point)
	
	if direction() == 1:
		projectile_instance.dir(dir_x, dir_y)
		projectile_instance.set_position(gun_pos.get_global_position())
		
	else:
		gun_pos.position.x = - gun_pos.position.x
		projectile_instance.dir( - (dir_x), dir_y)
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
	if frame == 4:
		
		create_hitbox(50, 71, 5, 76, 6, 145, 2, "normal", Vector2(6, - 13), 0, 0.6)
	if frame >= 12:
		return true

func DOWN_TILT():
	if frame == 5:
	
		create_hitbox(40, 20, 7, 30, 9, 120, 3, "normal", Vector2(64, 32), 0, 0.5)
	if frame >= 10:
		return true

func FORWARD_TILT():
	if frame == 3:
		
		create_hitbox(52, 20, 7, 40, 13, 130, 3, "slash", Vector2(22, 8), 0, 1)
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
	if frame == 11:
		create_projectile(1, 0, Vector2(42.82, 1.692))
	if frame == 22:
		create_hitbox(52, 20, 5, 70, 5, 120, 3, "normal", Vector2(22, 8), 0, 1)
	if frame == 43:
		return true

func FORWARD_SPECIAL():
	if frame == 10:
		create_hitbox(61, 41, 6, 35, 7, 130, 5, "normal", Vector2(27, - 6), 0, 1)
	if frame == 18:
		create_hitbox(61, 41, 18, 280, 2, 110, 2, "slash", Vector2(27, - 6), 0, 1)
	if frame == 20:
		return true

func DOWN_SPECIAL():
	if frame == 2:
		
		
	
	
		create_hitbox(30, 66, 4, 45, 140, 0, 3, "normal", Vector2(30, 0), 6, 0.3)
		create_hitbox(30, 66, 4, 135, 140, 0, 3, "normal", Vector2( - 30, 0), 6, 0.3)
	if frame == 8:
		return true

func UP_SPECIAL():
	if frame == 2:
		create_hitbox(60, 66, 2, 290, 50, 0, 3, "normal", Vector2(0, 0), 2, 0.5)
	if frame == 8:
		create_hitbox(60, 66, 2, 290, 50, 0, 3, "normal", Vector2(0, 0), 2, 0.5)
	if frame == 16:
		create_hitbox(60, 66, 2, 290, 50, 0, 3, "normal", Vector2(0, 0), 2, 0.5)
	if frame == 24:
		create_hitbox(60, 66, 2, 290, 50, 0, 3, "normal", Vector2(0, 0), 1, 0.5)
	if frame == 32:
		create_hitbox(60, 66, 3, 290, 50, 0, 3, "normal", Vector2(0, 0), 1, 0.5)
	if frame == 40:
		return true
func UP_SPECIAL_1():
	if frame == 2:
		create_hitbox(60, 66, 2, 90, 120, 0, 3, "normal", Vector2(0, 0), 7, 1)
	if frame == 6:
		create_hitbox(60, 66, 2, 90, 120, 0, 3, "normal", Vector2(0, 0), 7, 1)
	if frame == 14:
	
	
		create_hitbox(66, 66, 7, 90, 20, 120, 12, "slash", Vector2(0, 0), 6, 0.5)
	if frame == 24:
		return true

func NAIR():
	if frame == 1:
		create_hitbox(56, 56, 8, 361, 5, 100, 3, "normal", Vector2(0, 0), 0, 1)
	if frame > 1:
		if connected == true:
			
			if frame == 16:
				connected = false
				return true
		else:
			if frame == 5:
				create_hitbox(46, 56, 5, 361, 5, 100, 10, "normal", Vector2(0, 0), 0, 1)
			if frame == 16:
				return true

func UAIR():
	if frame == 7:
		create_hitbox(56, 46, 16, 85, 5, 100, 4, "slash", Vector2(0, - 48), 0, 1)
	if frame == 19:
		return true

func BAIR():
	if frame == 2:
		create_hitbox(52, 55, 15, 45, 5, 100, 5, "normal", Vector2( - 47, 7), 6, 1)
	if frame > 1:
		if connected == true:
			
			if frame == 18:
				connected = false
				return true
		else:
			if frame == 7:
				create_hitbox(52, 55, 5, 45, 5, 140, 10, "normal", Vector2( - 47, 7), 6, 1)
			if frame == 18:
				return true

func FAIR():
	if frame == 10:
		create_hitbox(59, 80, 9, 45, 45, 180, 3, "slash", Vector2(53, - 34), 0, 0.9)
	if frame == 23:
		return true

func DAIR():
	if frame == 7:
		create_hitbox(80, 45, 15, 270, 6, 190, 5, "normal", Vector2( - 2, 44), 0, 0.1)
	if frame == 20:
		return true

func DOWN_SMASH():
	if frame == 1:
		create_hitbox(51, 24, 19 * charge, 45, 4, 110, 5, "normal", Vector2(51, 44), 0, 0.7)
	if frame == 6:
		create_hitbox(51, 24, 19 * charge, 135, 4, 110, 3, "normal", Vector2( - 52, 44), 0, 0.7)
	if frame == 20:
		return true

func UP_SMASH():
	if frame == 1:
		create_hitbox(60, 32, 7 * charge, 100, 140, 0, 3, "normal", Vector2(6, 3), 0, 1)
	if frame == 6:
		create_hitbox(55, 80, 12 * charge, 90, 12, 120, 3, "normal", Vector2(9, - 34), 0, 1)
	if frame == 22:
		return true

func FORWARD_SMASH():
	if frame == 1:
		create_hitbox(71, 54, 15 * charge, 45, 8, 110, 5, "normal", Vector2(26, - 2), 0, 0.4)
	if frame == 21:
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




