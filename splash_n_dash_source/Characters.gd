extends Node

var char_id



func deselect_buttons(character_selected = null):
	var other_character = get_children()
	
	if character_selected:
		other_character.erase(character_selected)
	for child in other_character:
		if child.is_pressed():
			child.set_pressed(false)

