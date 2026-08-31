extends Control

export var id: int
onready var hover_texture = get_node("HoverTexture")
onready var full_texture = get_node("TextureRect")
onready var text = get_node("Control/Label")

signal char_ready(character, id)
signal char_unready(character, id)

export var FOX: Texture
export var WOLF: Texture
export var MARIO: Texture

var newtexture

func _ready():
	pass

func _on_Character_mouse_entered():
	hover_texture
	pass





func _on_Character_character_hovered(character, child, id):
	if self.id == id:
		match character:
			"FOX":
				character = FOX
				hover_texture.set_texture(FOX)
				full_texture.set_visible(false)
				full_texture.set_texture(FOX)
				text.text = "FOX"
			"WOLF":
				character = WOLF
				hover_texture.set_texture(WOLF)
				full_texture.set_visible(false)
				full_texture.set_texture(WOLF)
				text.text = "WOLF"
			"MARIO":
				character = MARIO
				hover_texture.set_texture(MARIO)
				full_texture.set_visible(false)
				full_texture.set_texture(MARIO)
				text.text = "MARIO"

func _on_Character_character_selected(character, child, id):
	
	if self.id == id:
		
		match character:
			"FOX":
				character = FOX
				hover_texture.set_visible(false)
				full_texture.set_visible(true)
				emit_signal("char_ready", "FOX", id)
			"WOLF":
				character = WOLF
				hover_texture.set_visible(false)
				full_texture.set_visible(true)
				emit_signal("char_ready", "WOLF", id)
			"MARIO":
				character = MARIO
				hover_texture.set_visible(false)
				full_texture.set_visible(true)
				emit_signal("char_ready", "MARIO", id)
				

func _on_Character_character_deselected(character, child, id):
	if self.id == id:
		match character:
			"FOX":
				character = FOX
				hover_texture.set_visible(true)
				full_texture.set_visible(false)
				emit_signal("char_unready", "FOX", id)
			"WOLF":
				character = WOLF
				hover_texture.set_visible(true)
				full_texture.set_visible(false)
				emit_signal("char_unready", "WOLF", id)
			"MARIO":
				character = MARIO
				hover_texture.set_visible(true)
				full_texture.set_visible(false)
				emit_signal("char_unready", "MARIO", id)



