class_name AnimationController
extends Node

@export var animation_player: AnimationPlayer

func play_animation(anim_name: String) -> void:
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

func stop() -> void:
	if animation_player:
		animation_player.stop()
