extends Node








func _ready():
	pass


func goto_scene(path, current_scene):
	var loader = ResourceLoader.load_interactive(path)
	var loading_bar = load("res://ASSETS/UI Features/ProgressBar.tscn").instance()
	get_tree().get_root().call_deferred("add_child", loading_bar)
	while true:
		var err = loader.poll()
		if err == ERR_FILE_EOF:
			
			var resource = loader.get_resource()
			call_deferred("_deferred_goto_scene", resource, current_scene)
			loading_bar.queue_free()
			break
		if err == OK:
			
			var progress = float(loader.get_stage()) / loader.get_stage_count()
			loading_bar.get_node("AnimationPlayer").get_node("ProgressBar").value = progress * 100
			print(progress)
		yield(get_tree(), "idle_frame")

func _deferred_goto_scene(loader, current_scene):
	
	current_scene.free()

	
	current_scene = loader.instance()

	
	get_tree().get_root().add_child(current_scene)
	
	get_tree().set_current_scene(current_scene)
	print(get_tree().get_current_scene().name)
