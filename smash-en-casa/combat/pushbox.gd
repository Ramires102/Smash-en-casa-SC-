# ==============================================================================
# Pushbox — Separación Física Suave entre Luchadores (Capa 16)
# ==============================================================================
# En los juegos de pelea, los personajes pueden cruzarse al correr o saltar,
# pero no deben quedarse superpuestos en el mismo punto X. Pushbox separa
# suavemente a dos luchadores cercanos sin alterar su vector velocity.
# ==============================================================================
class_name Pushbox
extends Area2D

@export var owner_character: Character
@export var push_radius: float = 14.5
@export var push_force: float = 14.0
@export var debug_draw_pushbox: bool = false

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

func _ready() -> void:
	if owner_character == null:
		owner_character = get_parent() as Character

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

	# Solo empujar si ambos personajes están a una altura similar (~50 px)
	if absf(self_pos.y - other_pos.y) > 49.0:
		return

	var dx: float = self_pos.x - other_pos.x
	var total_radius: float = push_radius + other_pushbox.push_radius
	var dist_x: float = absf(dx)

	if dist_x < total_radius:
		var overlap: float = total_radius - dist_x
		var push_dir: float = signf(dx) if dist_x > 0.3 else (1.0 if owner_character.player_id == 1 else -1.0)
		var separation_step: float = (overlap * 0.5) * minf(push_force * delta, 1.0)
		owner_character.global_position.x += push_dir * separation_step

func _draw() -> void:
	if not debug_draw_pushbox or collision_shape == null or collision_shape.shape == null:
		return
	if collision_shape.shape is CircleShape2D:
		draw_circle(Vector2.ZERO, (collision_shape.shape as CircleShape2D).radius, Color(0.3, 0.4, 1.0, 0.12))
	elif collision_shape.shape is CapsuleShape2D:
		var cap := collision_shape.shape as CapsuleShape2D
		draw_rect(Rect2(-cap.radius, -cap.height * 0.5, cap.radius * 2.0, cap.height), Color(0.3, 0.4, 1.0, 0.12))
