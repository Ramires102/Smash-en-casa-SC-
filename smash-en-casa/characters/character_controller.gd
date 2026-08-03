class_name CharacterController
extends Node

@export var character: CharacterBody3D
@export var move_speed: float = 8.0
@export var jump_velocity: float = 14.0

var facing_direction: float = 1.0

func setup(data: CharacterData) -> void:
	if data:
		move_speed = data.move_speed
		jump_velocity = data.jump_velocity

func get_input_vector(player_id: int) -> Vector2:
	return InputManager.get_move_vector(player_id)

func apply_horizontal_movement(input_x: float) -> void:
	if character:
		character.velocity.x = input_x * move_speed
		if input_x != 0.0:
			facing_direction = sign(input_x)
			character.rotation_degrees.y = 0.0 if facing_direction > 0 else 180.0

func apply_jump() -> void:
	if character:
		character.velocity.y = jump_velocity
