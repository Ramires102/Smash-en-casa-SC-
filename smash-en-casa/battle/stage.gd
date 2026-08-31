class_name Stage
extends Node3D

signal blast_zone_entered(body: Node)

@export var stage_name: String = "Santuario Astral"
@export var blast_left: float = -780.0
@export var blast_right: float = 780.0
@export var blast_top: float = -650.0
@export var blast_bottom: float = 550.0
@onready var blast_zone_2d: Area2D = get_node_or_null("BlastZone2D")

@onready var celestial_ring: Node3D = get_node_or_null("BackgroundDeco/CelestialRing")
@onready var core_crystal: Node3D = get_node_or_null("MainPlatform/CoreCrystal")
@onready var island_left: Node3D = get_node_or_null("BackgroundDeco/FloatingIslandLeft")
@onready var island_right: Node3D = get_node_or_null("BackgroundDeco/FloatingIslandRight")

var _anim_time: float = 0.0

func _ready() -> void:
	if blast_zone_2d:
		blast_zone_2d.body_entered.connect(_on_blast_zone_body_entered)

func _process(delta: float) -> void:
	_anim_time += delta
	if celestial_ring:
		celestial_ring.rotate_z(delta * 0.04)
	if core_crystal:
		core_crystal.rotate_y(delta * 0.5)
		core_crystal.position.y = -2.3 + sin(_anim_time * 1.2) * 0.08

func _on_blast_zone_body_entered(body: Node) -> void:
	if body is Character:
		blast_zone_entered.emit(body)

func _physics_process(_delta: float) -> void:
	var parent_node := get_parent()
	if parent_node:
		for child in parent_node.get_children():
			if child is Character and child.visible and child.is_inside_tree():
				if child.global_position.y > blast_bottom or child.global_position.y < blast_top or child.global_position.x < blast_left or child.global_position.x > blast_right:
					blast_zone_entered.emit(child)

func get_spawn_position(player_id: int) -> Vector2:
	if player_id == 1:
		return Vector2(-140.0, -80.0)
	elif player_id == 2:
		return Vector2(140.0, -80.0)
	return Vector2(0.0, -80.0)
