class_name Stage
extends Node3D

signal blast_zone_entered(body: Node)

@export var stage_name: String = "Santuario Astral"
@export var blast_left: float = -780.0
@export var blast_right: float = 780.0
@export var blast_top: float = -650.0
@export var blast_bottom: float = 550.0
@onready var blast_zone_2d: Area2D = get_node_or_null("StageColliders2D/BlastZone2D")

@onready var celestial_ring: Node3D = get_node_or_null("BackgroundDeco/CelestialRing")
@onready var core_crystal: Node3D = get_node_or_null("MainPlatform/CoreCrystal")
@onready var island_left: Node3D = get_node_or_null("BackgroundDeco/FloatingIslandLeft")
@onready var island_right: Node3D = get_node_or_null("BackgroundDeco/FloatingIslandRight")

var _anim_time: float = 0.0

func _ready() -> void:
	if blast_zone_2d == null:
		blast_zone_2d = get_node_or_null("BlastZone2D")
	if blast_zone_2d and not blast_zone_2d.body_entered.is_connected(_on_blast_zone_body_entered):
		blast_zone_2d.body_entered.connect(_on_blast_zone_body_entered)


func _process(delta: float) -> void:
	_anim_time += delta
	if celestial_ring:
		celestial_ring.rotate_z(delta * 0.04)
	if core_crystal:
		core_crystal.rotate_y(delta * 0.5)
		core_crystal.position.y = -2.3 + sin(_anim_time * 1.2) * 0.08

func _on_blast_zone_body_entered(body: Node) -> void:
	if body is Character and body.is_inside_tree() and body.visible:
		if body.state_machine and body.state_machine.current_state:
			if body.state_machine.current_state.name.to_lower() == "death":
				return
		blast_zone_entered.emit(body)

func is_position_out_of_bounds(pos: Vector2) -> bool:
	return pos.y > blast_bottom or pos.y < blast_top or pos.x < blast_left or pos.x > blast_right

func get_spawn_position(player_id: int) -> Vector2:
	match player_id:
		1:
			return Vector2(-170.0, -80.0)
		2:
			return Vector2(170.0, -80.0)
		3:
			return Vector2(-65.0, -80.0)
		4:
			return Vector2(65.0, -80.0)
	return Vector2(0.0, -80.0)
