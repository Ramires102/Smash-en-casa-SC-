extends Node2D

var velocity: Vector2
var speed = 1000
var picking = false
export var id: int

onready var HandSprite = get_node("HandSprite")
onready var Detector = get_node("HandArea")

func _process(delta):

	var input: = Vector2.ZERO
	
	
	
	input = Vector2(Input.get_action_strength("right_%s" % id) - Input.get_action_strength("left_%s" % id), Input.get_action_strength("down_%s" % id) - Input.get_action_strength("up_%s" % id))
	
	
	
		
	global_position += (input * speed * delta)
	
	var dec = Detector.get_overlapping_areas()
	for b in dec:
		if b.name == "ArrowArea2D":
			HandSprite.play("HandPoint")
	if Input.is_action_just_pressed("ui_select_%s" % id):
		print("yoooooooooooo")
	
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
				
				
					get_tree().change_scene("res://ASSETS/StageSelect/StageSelecteScreen.tscn")
			else:
				pass
	else:
		pass

func _on_HandArea_area_entered(area):
	print("")
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

