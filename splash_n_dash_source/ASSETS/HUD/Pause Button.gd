extends Button

export var path = ""

onready var label = get_node("Label")

func _on_Button_pressed():
	MusicController.fade_out()
	yield(MusicController.tween, "tween_completed")
	if (path != ""):
		get_tree().paused = false
		get_tree().change_scene(path)

func _on_CHAR_area_entered(area):
	emit_signal("focus_entered")


func _on_CHAR_area_exited(area):
	emit_signal("focus_exited")


func _on_Char_Select_focus_entered():
	label.add_color_override("font_color_shadow", Color(1, 0.33, 0.2, 1))


func _on_Char_Select_focus_exited():
	label.add_color_override("font_color_shadow", Color(0.639216, 0, 1))
