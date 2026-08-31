extends Node

class_name State


onready var player: KinematicBody2D
onready var states: Dictionary = {}


var dir: float
var dirV: float
var jump

var frame: float
var RUNSPEED: float
var DASHSPEED: float
var GRAVITY: float
var JUMPFORCE: float
var MAX_JUMPFORCE: float
var DOUBLEJUMPFORCE: float
var MAXAIRSPEED: float
var AIR_ACCEL: float
var FALLSPEED: float
var FALLINGSPEED: float
var MAXFALLSPEED: float
var TRACTION: float
var LANDFRAMES: float
var next_state: State

func enter() -> void :
	next_state = null
	player.animation(name)


func logic() -> void :
	get_input()
	player.move_player()
	frame += 1


func stats() -> void :
	RUNSPEED = player.RUNSPEED
	DASHSPEED = player.DASHSPEED
	GRAVITY = player.GRAVITY
	JUMPFORCE = player.JUMPFORCE
	MAX_JUMPFORCE = player.MAX_JUMPFORCE
	DOUBLEJUMPFORCE = player.DOUBLEJUMPFORCE
	MAXAIRSPEED = player.MAXAIRSPEED
	AIR_ACCEL = player.AIR_ACCEL
	FALLSPEED = player.FALLSPEED
	FALLINGSPEED = player.FALLINGSPEED
	MAXFALLSPEED = player.MAXFALLSPEED
	LANDFRAMES = player.LANDFRAMES

func get_input() -> void :
	jump = Input.is_action_just_pressed("jump1")
	dir = Input.get_action_strength("right") - Input.get_action_strength("left")
	dirV = Input.get_action_strength("up") - Input.get_action_strength("down")


func get_transition() -> State:
	return next_state

