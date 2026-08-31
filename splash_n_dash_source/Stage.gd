extends Node2D

export (PackedScene) var FOX
export (PackedScene) var WOLF
export (PackedScene) var MARIO


func _ready():
	MusicController.play_music(MusicController.sss_music)
	MusicController.fade_in()
	Transitions.fade_in()
	match Globals.css["char_1"]:
		"FOX":
			var instance = FOX.instance()
			instance.id = 1
			instance.stocks = Globals.css["stocks"]
			instance.global_position = get_node("SpawnPoint1").global_position
			self.add_child(instance)
			instance.turn(false)
			$Camera2D.add_target(instance)
		"WOLF":
			var instance = WOLF.instance()
			instance.id = 1
			instance.stocks = Globals.css["stocks"]
			instance.global_position = get_node("SpawnPoint1").global_position
			self.add_child(instance)
			instance.turn(false)
			$Camera2D.add_target(instance)
		"MARIO":
			var instance = MARIO.instance()
			instance.id = 1
			instance.stocks = Globals.css["stocks"]
			instance.global_position = get_node("SpawnPoint1").global_position
			self.add_child(instance)
			instance.turn(false)
			$Camera2D.add_target(instance)
	match Globals.css["char_2"]:
		"FOX":
			var instance = FOX.instance()
			instance.id = 2
			instance.stocks = Globals.css["stocks"]
			instance.global_position = get_node("SpawnPoint2").global_position
			self.add_child(instance)
			instance.turn(true)
			$Camera2D.add_target(instance)
		"WOLF":
			var instance = WOLF.instance()
			instance.id = 2
			instance.stocks = Globals.css["stocks"]
			instance.global_position = get_node("SpawnPoint2").global_position
			self.add_child(instance)
			instance.turn(true)
			$Camera2D.add_target(instance)
		"MARIO":
			var instance = MARIO.instance()
			instance.id = 2
			instance.stocks = Globals.css["stocks"]
			instance.global_position = get_node("SpawnPoint2").global_position
			self.add_child(instance)
			instance.turn(true)
			$Camera2D.add_target(instance)

	
	
	
	pass




