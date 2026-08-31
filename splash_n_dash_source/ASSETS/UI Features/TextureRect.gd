extends TextureButton

export var path = ""
export (bool) var fade

func _on_TextureRect_pressed():
	if not fade:
		MusicController.fade_out()
	Transitions.fade_out()
	yield(Transitions.anim, "animation_finished")


	if (path != ""):
		
		get_tree().change_scene(path)
