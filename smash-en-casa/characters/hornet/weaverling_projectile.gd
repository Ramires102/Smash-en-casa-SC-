class_name WeaverlingProjectile
extends Projectile

@onready var silk_line: Line2D = get_node_or_null("SilkLine")

func _ready() -> void:
	super._ready()
	if silk_line:
		silk_line.top_level = true
		silk_line.width = 2.0
		silk_line.default_color = Color(1.0, 1.0, 1.0, 0.90)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_time_frozen:
		return
	
	_update_silk_line()

func _sync_visual() -> void:
	if visual_3d == null:
		return

	# Posición sincronizada en el espacio 3D
	visual_3d.position = Vector3(
		global_position.x / Constants.UNIT_SIZE,
		-global_position.y / Constants.UNIT_SIZE,
		0.05
	)

	# Orientación frontal del Weaverling en 2.5D
	# El modelo tiene ojos en +X y cuernos en +Y
	if velocity.x >= 0.0:
		# Volando hacia la derecha
		var pitch: float = atan2(-velocity.y, velocity.x) if velocity.length_squared() > 1.0 else 0.0
		visual_3d.rotation = Vector3(0.0, 0.22, pitch)
	else:
		# Volando hacia la izquierda: rotar 180° en Y para mirar a la izquierda sin quedar boca abajo
		var pitch: float = atan2(-velocity.y, -velocity.x) if velocity.length_squared() > 1.0 else 0.0
		visual_3d.rotation = Vector3(0.0, PI - 0.22, -pitch)

func _update_silk_line() -> void:
	if silk_line == null:
		return

	silk_line.clear_points()
	var needle_pos: Vector2 = global_position - velocity.normalized() * 32.0

	if is_instance_valid(owner_character) and owner_character is Node2D:
		var facing: float = owner_character.get_facing_direction() if owner_character.has_method("get_facing_direction") else 1.0
		# Posición exacta de la punta de la aguja de Hornet en Fair
		needle_pos = owner_character.global_position + Vector2(facing * 18.0, -2.0)

	var mid_pos: Vector2 = (needle_pos + global_position) * 0.5
	# Efecto de cuerda elástica: ligera catenaria/ondulación
	var sag: float = sin(_time_alive * 20.0) * 2.5 + 3.0
	mid_pos.y += sag

	silk_line.add_point(needle_pos)
	silk_line.add_point(mid_pos)
	silk_line.add_point(global_position)

	# Brillo pulsante de seda pura
	var pulse: float = 0.82 + 0.18 * sin(_time_alive * 24.0)
	silk_line.modulate = Color(1.0, 1.0, 1.0, pulse)

func _exit_tree() -> void:
	super._exit_tree()
	if silk_line and is_instance_valid(silk_line):
		silk_line.queue_free()
