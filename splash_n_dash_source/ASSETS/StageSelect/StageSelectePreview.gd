extends MarginContainer


export var Smashville: Texture

onready var thumbnail = get_node("VBoxContainer/MarginContainer/TextureRect/MarginContainer/Stage Thumbnail")
onready var stagename = get_node("VBoxContainer/MarginContainer2/Stage Name")

func _ready():
	pass


var selection = false

func _on_TextureRect_stage_selected(stage, child):
	match stage:
		"Smashville":
			thumbnail.set_texture(Smashville)
			thumbnail.self_modulate = Color(1, 1, 1, 1)
			stagename.text = "Smashville"
			Globals.css["stage"] = "Smashville"
			selection = true
	
	yield(get_tree().create_timer(1.0), "timeout")


func _on_TextureRect_stage_hovered(stage, child):
	if selection == false:
		match stage:
			"Smashville":
				thumbnail.set_texture(Smashville)
				thumbnail.self_modulate = Color(1, 1, 1, 0.5)
				stagename.text = "Smashville"
