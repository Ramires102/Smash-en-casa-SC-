extends KinematicBody2D

var velocity = Vector2(0, 0)


const UP = Vector2(0, - 1)
const SPEED = 300
const GRAVITY = 800
const JUMPFORCE = - 900
var weight = 100
var percentage = 0
onready var health = get_node("Percentage")
var isGrabable: bool


func _physics_process(delta):
	if is_on_floor() == true:
		isGrabable = true
	else:
		isGrabable = false
	if Input.is_action_pressed("left_arrow") and Input.is_action_pressed("right_arrow"):
		velocity.x = lerp(velocity.x, 0, 0.005)
		$Sprite.play("idle")
	elif Input.is_action_pressed("right_arrow"):
		velocity.x = SPEED
		$Sprite.play("walk")
		$Sprite.flip_h = false
	elif Input.is_action_pressed("left_arrow"):
		velocity.x = - SPEED
		$Sprite.play("walk")
		$Sprite.flip_h = true
	else:
		$Sprite.play("idle")
	if not is_on_floor():
		$Sprite.play("jump1")
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMPFORCE
	health.text = str(percentage)
	velocity.y += GRAVITY * delta
	

	velocity = move_and_slide(velocity, Vector2.UP)

	velocity.x = lerp(velocity.x, 0, 0.08)






















