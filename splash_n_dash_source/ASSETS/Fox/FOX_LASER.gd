extends Area2D


export var LASER_SPEED = 1500
onready var parent = get_parent()
var frame = 0
export var duration = 60
export var cooldown = 8
var dir_x = 1
var dir_y = 0
export var damage = 3
var player_list = []
func dir(directionx, directiony):
	dir_x = directionx
	dir_y = directiony

func done():
	return true
func _ready():
	player_list.append(parent)
	set_process(true)


func _process(delta):
	frame += 1
	if frame == duration:
		done()
		queue_free()
	var motion = (Vector2(dir_x, dir_y)).normalized() * LASER_SPEED
	set_position(get_position() + motion * delta)
	position.direction_to(motion)
	
	set_rotation_degrees(rad2deg(Vector2(dir_x, dir_y).angle()))





func _on_FOX_LASER_body_entered(body):
	if not (body in player_list):
		print("hit")
		body.percentage += damage
		queue_free()


func _on_FOX_LASER_area_entered(area):
	var body = area.get_parent()
	if not (body in player_list):
		print("hit")
		body.percentage += damage
		queue_free()

