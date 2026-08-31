class_name Pushbox
extends Area2D

## Componente de colisión y separación suave entre luchadores estilo Super Smash Bros.
## Evita solapamientos, atravesamientos físicos y montajes glitchy entre personajes.

@export var owner_character: Character
@export var push_radius: float = 14.5  ## Radio de empuje en px (≈ 0.52m * 28px)
@export var push_force: float = 14.0   ## Velocidad de separación suave
@export var debug_draw_pushbox: bool = true

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

func _ready() -> void:
	if owner_character == null:
		owner_character = get_parent() as Character
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if owner_character == null or not owner_character.visible:
		return
		
	for area in get_overlapping_areas():
		if area is Pushbox and area != self:
			_resolve_push(area, delta)

func _resolve_push(other_pushbox: Pushbox, delta: float) -> void:
	var other_char: Character = other_pushbox.owner_character
	if other_char == null or not other_char.visible:
		return
		
	var self_pos: Vector2 = owner_character.global_position
	var other_pos: Vector2 = other_char.global_position
	
	# Verificar si están en un rango vertical que deba empujar (~50px de altura)
	var dy: float = absf(self_pos.y - other_pos.y)
	if dy > 49.0:
		return
		
	var dx: float = self_pos.x - other_pos.x
	var total_radius: float = push_radius + other_pushbox.push_radius
	var dist_x: float = absf(dx)
	
	if dist_x < total_radius:
		var overlap: float = total_radius - dist_x
		var push_dir: float = 1.0
		
		if dist_x > 0.3:
			push_dir = signf(dx)
		else:
			# Si están exactamente en el mismo punto X, desempatar por ID del jugador
			var self_id: int = owner_character.player_id if "player_id" in owner_character else 1
			push_dir = 1.0 if self_id == 1 else -1.0
			
		# Separación suave basada en posición (sin generar velocidad residual / sliding)
		var separation_step: float = (overlap * 0.5) * minf(push_force * delta, 1.0)
		owner_character.global_position.x += push_dir * separation_step

func _on_area_entered(_area: Area2D) -> void:
	pass

func _draw() -> void:
	if not debug_draw_pushbox or collision_shape == null or collision_shape.shape == null:
		return
	if collision_shape.shape is CircleShape2D:
		var r: float = (collision_shape.shape as CircleShape2D).radius
		draw_circle(Vector2.ZERO, r, Color(0.3, 0.4, 1.0, 0.12))
	elif collision_shape.shape is CapsuleShape2D:
		var cap := collision_shape.shape as CapsuleShape2D
		draw_rect(Rect2(-cap.radius, -cap.height * 0.5, cap.radius * 2.0, cap.height), Color(0.3, 0.4, 1.0, 0.12))
