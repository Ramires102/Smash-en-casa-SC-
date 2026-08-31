extends Node








func _ready():

	MusicController.fade_in()
	MusicController.play_music(MusicController.airport_music)

var input: = Vector2.ZERO

func _process(delta):
	if (Input.is_action_just_pressed("ui_select_1") or Input.is_action_just_pressed("ui_select_2")):



		get_tree().change_scene("res://TitleScreen.tscn")
	if Input.get_action_strength("right_1") or Input.get_action_strength("right_2"):
		$HSlider.set_value($HSlider.get_value() + $HSlider.step)
	if (Input.get_action_strength("left_1") + Input.get_action_strength("left_2")):
		$HSlider.set_value($HSlider.get_value() - $HSlider.step)


func _on_HSlider_value_changed(value) -> void :
	AudioServer.set_bus_volume_db(0, linear2db(value))
	$"volume percent".text = "%d%%" % (value * 100)


func set_bus_volume(bus_index: int, value: float):
	AudioServer.set_bus_volume_db(bus_index, linear2db(value))
	
	
