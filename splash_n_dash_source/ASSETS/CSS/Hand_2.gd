extends Node2D

var velocity: Vector2
var speed = 1000
var picking = false
export var id: int

onready var HandSprite = get_node("HandSprite")
onready var Detector = get_node("HandArea")

func _process(delta):
	var input: = Vector2.ZERO
	
	input.x = Input.get_action_strength("right_2") - Input.get_action_strength("left_2")
	input.y = Input.get_action_strength("down_2") - Input.get_action_strength("up_2")
	input = input.normalized()
	
	if input != Vector2.ZERO:
		global_position += (input * speed * delta)
	
	
	
	
	
	
	
	
	
	
	
	
	var dec = Detector.get_overlapping_areas()
	for b in dec:
		if b.name == "ArrowArea2D":
			HandSprite.play("HandPoint")


func _unhandled_input(event):
	if Input.is_action_just_pressed("ui_select_2"):
		var dec = Detector.get_overlapping_areas()
		for b in dec:
			if b.name == "CoinArea" and (b.get_parent().id == id):
				if self.picking == false:
					HandSprite.play("HandGrab")
					b.get_parent().picked = true
					self.picking = true
				else:

					HandSprite.play("HandOpen")
					b.get_parent().picked = false
					b.get_parent().rest_point = b.get_parent().global_position
					b.get_parent().auto_snap()
					self.picking = false
				
				
			elif b.name == "ArrowArea2D":
				b.get_parent().emit_signal("pressed")
			elif b.name == "ReadyToFight":
				if HandSprite.animation == "HandPoint":
					get_tree().change_scene("res://TitleScreen.tscn")
			else:
				pass
	else:
		pass



func _on_HandArea_area_entered(area):
	if area.name == "ArrowArea2D":
		HandSprite.play("HandPoint")
		var dec = Detector.get_overlapping_areas()
		for b in dec:
			if b.name == "CoinArea" and (b.get_parent().id == id) and b.get_parent().picked == true:
				b.get_parent().picked = false
				b.get_parent().rest_point = b.get_parent().global_position
				b.get_parent().auto_snap()
				picking = false
	elif area.name == "ReadyToFight":
		if not HandSprite.animation == "HandGrab":
			HandSprite.play("HandPoint")
			var dec = Detector.get_overlapping_areas()
			for b in dec:
				if b.name == "CoinArea" and (b.get_parent().id == id) and b.get_parent().picked == true:
					b.get_parent().picked = false
					b.get_parent().rest_point = b.get_parent().global_position
					b.get_parent().auto_snap()
					picking = false


func _on_HandArea_area_exited(area):
	if area.name == "ArrowArea2D":
		HandSprite.play("HandOpen")
	elif area.name == "ReadyToFight":
		if not HandSprite.animation == "HandGrab":
			HandSprite.play("HandOpen")

