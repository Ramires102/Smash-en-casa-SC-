extends KinematicBody2D


var velocity = Vector2(0, 0)
var UP = Vector2(0, - 1)
export var RUNSPEED = 760
export var DASHSPEED = 700
export var GRAVITY = 1800
export var JUMPFORCE = 600
export var MAX_JUMPFORCE = 800
export var DOUBLEJUMPFORCE = 800
export var MAXAIRSPEED = 400
export var AIR_ACCEL = 20
export var FALLSPEED = 40
export var FALLINGSPEED = 560
export var MAXFALLSPEED = 900
export var TRACTION = 20
export var LANDFRAMES = 3

var fastfall = false
var frame = 0
var lagframes = 0



var perfect_wavedash_modifier = 1.11
export var dash_duration = 10
export var jump_squat_duration = 6
var air_dodge_speed = 1000


export var airJump = 0
export var airJumpMax = 1


func ready():
	set_physics_process(true)
	pass
func reset_Jumps():
	if is_on_floor() == true:
		airJump = airJumpMax
		

onready var anim = $Sprite / AnimationPlayer
onready var statename = $State
onready var frames = $Frames

func physics_process(delta):
	frame += 1
	frames.text = str(frame)

func animation(name: String):
	anim.play(name)
	statename.text = str(name)
	frames.text = str(frame)

func move_player():
	velocity = Vector2(0, 0)
	UP = Vector2(0, - 1)

func calc_physics(dir):
	velocity.x = dir
	
	if velocity.x < 0:
		velocity.x = - RUNSPEED
		$Sprite.flip_h = true
	elif velocity.x > 0:
		velocity.x = RUNSPEED
		$Sprite.flip_h = false
