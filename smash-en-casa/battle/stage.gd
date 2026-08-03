class_name Stage
extends Node3D

signal blast_zone_entered(body: Node3D)

@export var stage_name: String = "Escenario Principal"
@onready var spawn_p1: Node3D = $SpawnP1
@onready var spawn_p2: Node3D = $SpawnP2
@onready var blast_zone: Area3D = $BlastZone

func _ready() -> void:
	if blast_zone:
		blast_zone.body_entered.connect(_on_blast_zone_body_entered)

func _on_blast_zone_body_entered(body: Node3D) -> void:
	if body is Character:
		blast_zone_entered.emit(body)

func get_spawn_position(player_id: int) -> Vector3:
	if player_id == 1 and spawn_p1:
		return spawn_p1.global_position
	elif player_id == 2 and spawn_p2:
		return spawn_p2.global_position
	return Vector3(0, 5, 0)
