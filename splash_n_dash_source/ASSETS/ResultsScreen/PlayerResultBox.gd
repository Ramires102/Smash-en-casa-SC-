extends MarginContainer

onready var playerPos = get_node("PlayerPos/PlayerPos")
onready var background = get_node("Background")
onready var playerIcon = get_node("PlayerIcon/Icon and Text/Icon")
onready var playerName = get_node("PlayerIcon/Icon and Text/Name")
onready var playerNo = get_node("MarginContainer2/PlayerNo")

export var FOX: Texture
export var WOLF: Texture
export var MARIO: Texture

export (int) var id


func _ready():
	set_playerPos()


func set_playerPos():
	if id == 1:
		playerPos.text = "1ST"
		match Globals.winner:
			"Player_1":
				background.self_modulate = Color("fb615d")
				playerNo.text = "P1"
				char_data_1()
			"Player_2":
				background.self_modulate = Color("655dfb")
				playerNo.text = "P2"
				char_data_2()
	if id == 2:
			playerPos.text = "2ND"
			match Globals.winner:
				"Player_1":
					background.self_modulate = Color("655dfb")
					playerNo.text = "P2"
					char_data_2()
				"Player_2":
					background.self_modulate = Color("fb615d")
					playerNo.text = "P1"
					char_data_1()

func char_data_1():
	match Globals.css["char_1"]:
		"FOX":
			playerIcon.set_texture(FOX)
			playerName.text = "FOX"
		"WOLF":
			playerIcon.set_texture(WOLF)
			playerName.text = "WOLF"
		"MARIO":
			playerIcon.set_texture(MARIO)
			playerName.text = "MARIO"

func char_data_2():
	match Globals.css["char_2"]:
		"FOX":
			playerIcon.set_texture(FOX)
			playerName.text = "FOX"
		"WOLF":
			playerIcon.set_texture(WOLF)
			playerName.text = "WOLF"
		"MARIO":
			playerIcon.set_texture(MARIO)
			playerName.text = "MARIO"
