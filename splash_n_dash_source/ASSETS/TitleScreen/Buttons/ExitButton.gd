extends Button

onready var label = get_node("Label")


func _on_QuitButton_focus_entered():
	label.add_color_override("font_color_shadow", Color(0.2, 0.88, 1, 1))

func _on_QuitButton_focus_exited():
	label.add_color_override("font_color_shadow", Color(1, 0.33, 0.2, 1))

func _on_QuitButton_mouse_entered():
	label.add_color_override("font_color_shadow", Color(0.2, 0.88, 1, 1))

func _on_QuitButton_mouse_exited():
	label.add_color_override("font_color_shadow", Color(1, 0.33, 0.2, 1))


func _on_QuitButton_pressed():
	get_tree().quit()
	pass




func _on_Area2D_area_entered(area):
	emit_signal("focus_entered")

func _on_Area2D_area_exited(area):
	emit_signal("focus_exited")
