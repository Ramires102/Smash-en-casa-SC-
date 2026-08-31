extends Node2D

var picked = false
export var id: int

var rest_point
var rest_positions
var is_colliding = false
var min_dist = 100

func player_pos():
	var vect
	match id:
		1:
			vect = Globals.css["Token_1_pos"]
			return vect
		2:
			vect = Globals.css["Token_2_pos"]
			return vect

func _ready():
	
	rest_positions = get_tree().get_nodes_in_group("Char_Select")
	rest_point = player_pos()
	print("rest point is " + str(rest_point))
	

func _physics_process(delta):
	Globals.css["Token_%s_pos" % id] = self.global_position
	if picked == true:
		global_position = get_node("../Hand_%s/Position2D" % id).global_position
	else:
		
		global_position = lerp(global_position, rest_point, 5 * delta)


func auto_snap():
	for child in rest_positions:
		var distance = self.global_position.distance_to(child.get_node("point").global_position)
		if distance < min_dist:
			rest_point = child.get_node("point").global_position
	if picked == false:
		var dec = $CoinArea.get_overlapping_areas()
		for b in dec:
			if b.name == "CharacterArea":
				b.get_parent().emit_signal("button_down")



