class_name WeaverlingProjectile
extends Projectile

@onready var silk_line: Line2D = get_node_or_null("SilkLine")
var _trail_points: Array[Vector2] = []

func _ready() -> void:
	super._ready()
	if silk_line:
		silk_line.top_level = true
		silk_line.width = 2.5
		silk_line.default_color = Color(1.0, 1.0, 1.0, 0.85)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_time_frozen:
		return
	
	# Trailing silk cord connected to Hornet's needle
	if silk_line:
		silk_line.clear_points()
		if is_instance_valid(owner_character) and owner_character is Node2D:
			var facing: float = owner_character.get_facing_direction() if owner_character.has_method("get_facing_direction") else 1.0
			var needle_pos: Vector2 = owner_character.global_position + Vector2(facing * 32.0, -12.0)
			silk_line.add_point(needle_pos)
		else:
			silk_line.add_point(global_position - velocity.normalized() * 48.0)
		silk_line.add_point(global_position)
		
		# Pulsing silk glow
		var pulse: float = 0.85 + 0.15 * sin(_time_alive * 16.0)
		silk_line.modulate = Color(1.0, 1.0, 1.0, pulse)

func _exit_tree() -> void:
	super._exit_tree()
	if silk_line and is_instance_valid(silk_line):
		silk_line.queue_free()
