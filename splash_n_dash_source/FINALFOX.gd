extends KinematicBody2D

const WALL = "Wall"
const FLOOR = "Floor"
const PLATFORM = "Platform"

onready var anim = $Sprite / AnimationPlayer
onready var sprite = $Sprite.flip_h == true
onready var rayL = get_node_and_resource("Raycasts/GroundL")
onready var rayM = get_node("Raycasts/GroundM")
onready var rayR = get_node("Raycasts/GroundR")
onready var ledge_grabF = get_node("Raycasts/Ledge_Grab_F")
onready var ledge_grabB = get_node("Raycasts/Ledge_Grab_B")
onready var raycasts = get_node("Raycasts/GroundM")


const STAND = "stand"
const DASH = "dash"
const RUN = "run"
const CROUCH = "crouch"
const LANDING = "landing"
const JUMP_SQUAT = "jump_squat"
const SHORT_HOP = "short_hop"
const FULL_HOP = "full_hop"
const SKID = "skid"
const AIR = "air"
const AIR_DODGE = "air_dodge"
const FREE_FALL = "free_fall"
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
var weight = 73
var percentage = 0

var velocity = Vector2(0, 0)
var char_name = "Test"
var state = AIR
var run_speed = 400
var dash_speed = 480
var max_air_speed = 250
var fall_speed = 40
var max_fall_speed = 900
var air_accel = 21
var traction = 20
var jump_speed = 430
var short_hop_speed
var second_jump_speed = 800
var next_jump = 0
var max_air_jumps = 1
var jumps = 0
var fast_fall = false
var landing_frames = 4
var lag_frames = 0
var last_ledge = false
onready var health = get_node("Percentage")


var perfect_wavedash_modifier = 1.11
var dash_duration = 16
var jump_squat_duration = 3
var air_dodge_speed = 730


var damage = 0
var timer = 0
var collision = false
var last_platform = false
var buffer_dodge = false
var regrab = 0
var down_buffer = 0



const UP = Vector2(0, - 1)
const SPEED = 480
const DASHSPEED = 700
const GRAVITY = 30
const JUMPFORCE = - 600

func _ready():
	set_physics_process(true)
	pass
	

func refresh_jumps():
	jumps = 0
	
func reset_ledge():
	last_ledge.is_grabbed = false
	last_ledge = false


func reset_platform():
	last_platform = false
	self.set_collision_mask_bit(2, true)


func turn(direction):
	var dir = 0
	if direction:
		dir = - 1
	else:
		dir = 1
	sprite.set_flip_h(direction)
	ledge_grabF.set_cast_to(Vector2(dir * abs(ledge_grabF.get_cast_to().x), ledge_grabF.get_cast_to().y))
	ledge_grabB.set_cast_to(Vector2(dir * abs(ledge_grabB.get_cast_to().x), ledge_grabB.get_cast_to().y))
	pass


func get_collision():
	for node in get_children():
		if node is CollisionShape2D:
			if node.disabled == false:
				
				return node

func update_rays_positions():
	
	ledge_grabF.position.x = get_collision().position.x
	ledge_grabF.position.y = get_collision().position.y

	
	rayL.position.x = get_collision().position.x - get_collision().shape.get_extents().x
	rayL.position.y = get_collision().position.y + get_collision().shape.get_extents().y - 2
	
	rayR.position.x = get_collision().position.x + get_collision().shape.get_extents().x
	rayR.position.y = get_collision().position.y + get_collision().shape.get_extents().y - 2





var is_attacking = false;



func _physics_process(delta):
	if Input.is_action_pressed("left") and Input.is_action_pressed("right") and is_attacking == false:
		velocity.x = lerp(velocity.x, 0, 0.005)
		if is_on_floor() == true:
			anim.play("idle")
		else:
			anim.play("jump")
	elif Input.is_action_pressed("right") and is_attacking == false:
		velocity.x = DASHSPEED
		$Sprite.flip_h = false
		if is_on_floor() == true:
			anim.play("dash")
		else:
			anim.play("jump")
	elif Input.is_action_pressed("left") and is_attacking == false:
		velocity.x = - DASHSPEED
		$Sprite.flip_h = true
		if is_on_floor() == true:
			anim.play("dash")
		else:
			anim.play("jump")
	elif Input.is_action_pressed("down"):
		if is_on_floor() == true:
			velocity.x = lerp(velocity.x, 0, 0.001)
			anim.play("DownSmash")
			is_attacking = true;
		else:
			anim.play("jump")
	elif is_on_floor() == true and is_attacking == false:
		anim.play("idle")
	if not is_on_floor():
		anim.play("jump")
	if Input.is_action_just_pressed("jump1") and is_on_floor():
		velocity.y = JUMPFORCE
		
	if Input.is_action_just_released("jump1") and (velocity.y < 0):
		velocity.y = - 200
		
	velocity.y += GRAVITY
	health.text = str(percentage)
	

	velocity = move_and_slide(velocity, Vector2.UP)

	velocity.x = lerp(velocity.x, 0, 0.08)



func _on_AnimationPlayer_animation_finished(anim_name):
	print(anim_name)
	if anim_name == "DownSmash":
		is_attacking = false;
