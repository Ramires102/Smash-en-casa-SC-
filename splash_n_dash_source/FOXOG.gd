extends KinematicBody2D
export var id: int
export var percentage = 0
export var stocks = 3
export var weight = 100
var velocity = Vector2(0, 0)


const UP = Vector2(0, - 1)
export var hitbox: PackedScene
export var grabbox: PackedScene
export var projectile: PackedScene
export var angel_platform: PackedScene



































var audioFiles = []

export (float) var RUNSPEED = 340
export (float) var DASHSPEED = 390
export (float) var WALKSPEED = 200
export (float) var GRAVITY = 1800
export (float) var JUMPFORCE = 500
export (float) var MAX_JUMPFORCE = 800
export (float) var DOUBLEJUMPFORCE = 1000
export (float) var MAXAIRSPEED = 300
export (float) var AIR_ACCEL = 25
export (float) var FALLSPEED = 60
export (float) var FALLINGSPEED = 900
export (float) var MAXFALLSPEED = 900
export (float) var TRACTION = 40
export (float) var ROLL_DISTANCE = 350
export (float) var air_dodge_speed = 500
export (float) var UP_B_LAUNCHSPEED = 700

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
	if angel_plat:
		angel_plat.queue_free()
	else:
		pass
	return true

func UP_TILT():
	if frame == 5:
		
		create_hitbox(48, 68, 6, 76, 8, 140, 4, "normal", Vector2( - 22, - 15), 0, 0.6)
	if frame >= 12:
		return true

func DOWN_TILT():
	if frame == 5:
	
		create_hitbox(40, 20, 8, 90, 3, 120, 3, "normal", Vector2(64, 32), 0, 0.5)
	if frame >= 10:
		return true

func FORWARD_TILT():
	if frame == 3:
		
		create_hitbox(52, 20, 7, 120, 13, 100, 3, "normal", Vector2(22, 8), 0, 1)
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
	if frame == 14:
		create_hitbox(40, 20, 8, 90, 250, 0, 5, "normal", Vector2(48, 8), 0, 1)
	if frame == 26:
		create_projectile(0, - 1, Vector2(34.089, - 70.645))
	if frame == 32:
		create_projectile(0, - 1, Vector2(34.089, - 70.645))
	if frame == 39:
		create_projectile(0, - 1, Vector2(34.089, - 70.645))
	if frame == 43:
		return true

func NEUTRAL_SPECIAL():
	if frame == 4:
		create_projectile(1, 0, Vector2(42.82, 1.692))
	if frame == 14:
		return true

func FORWARD_SPECIAL():
	if frame == 11:
		create_hitbox(60, 40, 8, 90, 15, 148, 5, "normal", Vector2(6, - 19), 0, 1)
	if frame == 20:
		return true

func DOWN_SPECIAL():
	if frame == 2:
		
		
		create_hitbox(30, 66, 4, 0, 190, 0, 3, "normal", Vector2(30, 0), 6, 0.3)
		create_hitbox(30, 66, 4, 180, 190, 0, 3, "normal", Vector2( - 30, 0), 6, 0.3)
	if frame == 8:
		return true

func UP_SPECIAL():
	if frame == 2:
		create_hitbox(60, 66, 3, 290, 50, 0, 3, "normal", Vector2(0, 0), 2, 0.5)
	if frame == 8:
		create_hitbox(60, 66, 3, 290, 50, 0, 3, "normal", Vector2(0, 0), 2, 0.5)
	if frame == 16:
		create_hitbox(60, 66, 3, 290, 50, 0, 3, "normal", Vector2(0, 0), 2, 0.5)
	if frame == 24:
		create_hitbox(60, 66, 3, 290, 50, 0, 3, "normal", Vector2(0, 0), 1, 0.5)
	if frame == 32:
		create_hitbox(60, 66, 3, 290, 50, 0, 3, "normal", Vector2(0, 0), 1, 0.5)
	if frame == 40:
		return true
func UP_SPECIAL_1():
	if frame == 2:
		create_hitbox(60, 66, 10, 45, 10, 110, 12, "normal", Vector2(0, 0), 6, 0.5)
	if frame > 1:
		if connected == true:
			
			if frame == 21:
				connected = false
				return true
		else:
			if frame == 14:
				create_hitbox(40, 46, 5, 361, 180, 0, 6, "normal", Vector2(0, 0), 1, 0.5)
			if frame == 21:
				return true

func NAIR():
	if frame == 1:
		create_hitbox(56, 56, 12, 361, 0, 100, 3, "normal", Vector2(0, 0), 0, 1)
	if frame > 1:
		if connected == true:
			
			if frame == 16:
				connected = false
				return true
		else:
			if frame == 5:
				create_hitbox(46, 56, 9, 361, 0, 100, 10, "normal", Vector2(0, 0), 0, 1)
			if frame == 16:
				return true

func UAIR():
	if frame == 2:
		create_hitbox(32, 36, 5, 90, 130, 0, 2, "normal", Vector2(0, - 45), 0, 0.5)
	if frame == 6:
		create_hitbox(56, 46, 10, 90, 20, 108, 3, "normal", Vector2(0, - 48), 0, 0.05)
	if frame == 15:
		return true

func BAIR():
	if frame == 2:
		create_hitbox(52, 55, 15, 45, 1, 100, 5, "normal", Vector2( - 47, 7), 6, 0.7)
	if frame > 1:
		if connected == true:
			
			if frame == 18:
				connected = false
				return true
		else:
			if frame == 7:
				create_hitbox(52, 55, 5, 45, 3, 140, 10, "normal", Vector2( - 47, 7), 6, 0.7)
			if frame == 18:
				return true

func FAIR():
	if frame == 2:
		create_hitbox(35, 47, 3, 76, 10, 150, 3, "normal", Vector2(60, - 7), 0, 0.9)
	if frame == 11:
		create_hitbox(35, 47, 3, 76, 10, 150, 3, "normal", Vector2(60, - 7), 0, 0.9)
	if frame == 18:
		return true

func DAIR():
	if frame == 2:
		create_hitbox(36, 58, 2, 290, 140, 0, 2, "normal", Vector2(28, 17), 0, 0.5)
	if frame == 3:
		create_hitbox(36, 58, 2, 290, 140, 0, 2, "normal", Vector2(28, 17), 0, 0.5)
	if frame == 5:
		create_hitbox(36, 58, 2, 290, 140, 0, 2, "normal", Vector2(28, 17), 0, 0.5)
	if frame == 7:
		create_hitbox(36, 58, 2, 290, 140, 0, 2, "normal", Vector2(28, 17), 0, 0.5)
	if frame == 9:
		create_hitbox(36, 58, 2, 290, 140, 0, 2, "normal", Vector2(28, 17), 0, 0.5)
	if frame == 11:
		create_hitbox(36, 58, 2, 290, 140, 0, 2, "normal", Vector2(28, 17), 0, 0.5)
	if frame == 14:
		create_hitbox(36, 58, 4, 45, 12, 120, 2, "normal", Vector2(28, 17), 0, 0.5)
	if frame == 17:
		return true

func DOWN_SMASH():
	if frame == 1:
		create_hitbox(62, 27, 15 * charge, 30, 4, 130, 5, "normal", Vector2(0, 26), 6, 0.7)
	if frame == 21:
		return true

func UP_SMASH():
	if frame == 4:
		create_hitbox(59, 80, 14 * charge, 90, 4, 120, 3, "normal", Vector2(53, - 34), 0, 0.2)
	if frame == 22:
		return true

func FORWARD_SMASH():
	if frame == 1:
		create_hitbox(71, 54, 15 * charge, 45, 4, 120, 5, "normal", Vector2(26, - 2), 6, 0.4)
	if frame == 21:
		return true

	
	
	
	
	
	
	
	
	
		
														
														
		
		
		
	
	
	
	
	
	
	
	
				
		
	
	
			



var state = STAND
func updateframes(delta):
	frame += 1
	$Frames.text = str(frame)
	$Health.text = str(percentage) + " %"
func frame():
	frame = 0

const STAND = "stand"
const DASH = "dash"
const RUN = "run"
const CROUCH = "crouch"
const LANDING = "landing"
const JUMP_SQUAT = "jump_squat"
const SHORT_HOP = "short_hop"
const FULL_HOP = "full_hop"
const TURN = "turn"
const AIR = "air"
const AIR_DODGE = "air_dodge"
const FREEFALL = "freefall"
const WALLJUMPLEFT = "wall_jump_left"
const WALLJUMPRIGHT = "wall_jump_right"
const LEDGE_CATCH = "ledge_catch"
const LEDGE_HOLD = "ledge_hold"
const LEDGE_ROLL = "ledge_roll"
const LEDGE_CLIMB = "ledge_climb"
const LEDGE_JUMP = "ledge_jump"
const NAIR = "nair"
const FAIR = "fair"
const UAIR = "uair"
const BAIR = "bair"
const DAIR = "dair"
const TUMBLE = "tumble"



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







