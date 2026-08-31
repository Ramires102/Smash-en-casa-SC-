extends Button

onready var label = get_node("Label")

func _on_Control_pressed():
		if get_parent().get_parent().Paused == false:
			get_tree().paused = true
			get_parent().get_parent().Paused = true
			get_parent().get_parent().visible = true

		if get_parent().get_parent().Paused == true:
			get_tree().paused = false
			get_parent().get_parent().Paused = false
			get_parent().get_parent().visible = false


func _on_Resume_focus_entered():
	label.add_color_override("font_color_shadow", Color(1, 0.33, 0.2, 1))


func _on_Resume_focus_exited():
	label.add_color_override("font_color_shadow", Color(0.639216, 0, 1))


func _on_RESUME_area_entered(area):
	emit_signal("focus_entered")


func _on_RESUME_area_exited(area):
	emit_signal("focus_exited")
