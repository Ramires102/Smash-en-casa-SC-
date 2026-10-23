class_name PlayerInput
extends RefCounted

var movement: Vector2 = Vector2.ZERO
var is_dash: bool = false
var jump_pressed: bool = false
var jump_held: bool = false
var attack_pressed: bool = false
var special_pressed: bool = false
var shield_pressed: bool = false
var shield_just_pressed: bool = false

func has_movement() -> bool:
	return movement.length_squared() > 0.01

func is_moving_horizontal() -> bool:
	return absf(movement.x) > 0.12

func is_crouch_intent() -> bool:
	return movement.y < -0.55

func has_attack_intent() -> bool:
	return attack_pressed or special_pressed
