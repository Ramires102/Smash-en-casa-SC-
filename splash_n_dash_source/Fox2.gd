extends KinematicBody2D

const UP = Vector2(0, - 1)
const SLOPE_STOP = 64

var velocity = Vector2()
var move_speed = 480
var gravity = 1000
var jump_velocity = - 400
var is_grounded


onready var raycasts = $Raycasts
onready var sprites = $Body / CharacterRig / Sprite
func _physics_process(delta):
	_get_input()
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, UP, SLOPE_STOP)
	
	is_grounded = _check_is_grounded()
	
	
func _input(event):
	if event.is_action_pressed("jump1") and is_grounded:
		velocity.y = jump_velocity
		_assign_animation()


func _get_input():
	var move_direction = - int(Input.is_action_pressed("left")) + int(Input.is_action_pressed("right"))
	velocity.x = lerp(velocity.x, move_speed * move_direction, _get_h_weight())
	_assign_animation()
	if move_direction != 0:
		$Body.scale.x = move_direction
		_assign_animation()

func _get_h_weight():
	return 0.8 if is_grounded else 0.5

func _check_is_grounded():
	for raycast in raycasts.get_children():
		if raycast.is_colliding():
			return true
	
	return false
		
func _assign_animation():
	sprites.play("idle")
	
	if not is_grounded:
		sprites.play("jump")
	elif velocity.x != 0:
		sprites.play("walk")

