extends SceneTree

func _init():
	var sakuya_data = load("res://resources/instances/sakuya_data.tres")
	var root := Node3D.new()
	root.name = "CharacterRoot"
	
	var humanoid := Node3D.new()
	humanoid.name = "Humanoid"
	root.add_child(humanoid)
	
	var model = sakuya_data.model_scene.instantiate()
	model.name = "ModelRoot"
	humanoid.add_child(model)
	
	var ap := AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	ap.root_node = NodePath("..")
	ap.add_animation_library("", sakuya_data.animation_library)
	root.add_child(ap)
	
	# Add to tree
	get_root().add_child(root)
	
	print("Resolving track target: ", root.get_node_or_null("Humanoid/ModelRoot/Sakuya_Root/Skeleton3D"))
	print("Has Idle? ", ap.has_animation("Idle"))
	ap.play("Idle")
	print("Playing: ", ap.current_animation)
	
	# Advance 1 frame to see if any warnings fire
	root.queue_free()
	quit()
