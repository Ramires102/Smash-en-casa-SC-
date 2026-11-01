# ==============================================================================
# PlayerInput — Instantánea de Entrada por Frame (DTO)
# ==============================================================================
# Estructura liviana que encapsula qué botones y ejes está pulsando un jugador
# en el frame físico actual. InputManager construye un objeto de este tipo en
# cada frame y Character lo consume sin acoplarse a teclas ni mandos físicos.
# ==============================================================================
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
