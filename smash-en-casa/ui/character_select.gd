class_name CharacterSelect
extends Control

@export var miyabi_data: CharacterData = preload("res://resources/instances/miyabi_data.tres")
@export var gogeta_data: CharacterData = preload("res://resources/instances/gogeta_data.tres")
@export var sakuya_data: CharacterData = preload("res://resources/instances/sakuya_data.tres")
@export var john_data: CharacterData = preload("res://resources/instances/john_placeholder_data.tres")
@export var nekomiya_data: CharacterData = preload("res://resources/instances/nekomiya_data.tres")

var p1_selected: CharacterData = null
var p2_selected: CharacterData = null

@onready var p1_status: Label = $VBoxContainer/HBoxContainer/P1Selection/P1Status
@onready var p2_status: Label = $VBoxContainer/HBoxContainer/P2Selection/P2Status
@onready var start_battle_button: Button = $VBoxContainer/CenterContainer/StartBattleButton

func _ready() -> void:
	if start_battle_button:
		start_battle_button.disabled = true
		start_battle_button.text = "Seleccionen Personajes para Iniciar"
	
	var first_btn: Button = get_node_or_null("VBoxContainer/HBoxContainer/P1Selection/BtnMiyabiP1")
	if first_btn:
		first_btn.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()

# --- Selección de P1 ---


func _on_p1_miyabi_pressed() -> void:
	p1_selected = miyabi_data
	p1_status.text = "P1 Seleccionó: Miyabi"
	_check_ready()

func _on_p1_gogeta_pressed() -> void:
	p1_selected = gogeta_data
	p1_status.text = "P1 Seleccionó: Gogeta"
	_check_ready()

func _on_p1_sakuya_pressed() -> void:
	p1_selected = sakuya_data
	p1_status.text = "P1 Seleccionó: Sakuya"
	_check_ready()

func _on_p1_john_pressed() -> void:
	p1_selected = john_data
	p1_status.text = "P1 Seleccionó: John Placeholder"
	_check_ready()

func _on_p1_nekomiya_pressed() -> void:
	p1_selected = nekomiya_data
	p1_status.text = "P1 Seleccionó: Nekomiya Mana"
	_check_ready()

# --- Selección de P2 ---


func _on_p2_miyabi_pressed() -> void:
	p2_selected = miyabi_data
	p2_status.text = "P2 Seleccionó: Miyabi"
	_check_ready()

func _on_p2_gogeta_pressed() -> void:
	p2_selected = gogeta_data
	p2_status.text = "P2 Seleccionó: Gogeta"
	_check_ready()

func _on_p2_sakuya_pressed() -> void:
	p2_selected = sakuya_data
	p2_status.text = "P2 Seleccionó: Sakuya"
	_check_ready()

func _on_p2_john_pressed() -> void:
	p2_selected = john_data
	p2_status.text = "P2 Seleccionó: John Placeholder"
	_check_ready()

func _on_p2_nekomiya_pressed() -> void:
	p2_selected = nekomiya_data
	p2_status.text = "P2 Seleccionó: Nekomiya Mana"
	_check_ready()

# --- Verificación ---
func _check_ready() -> void:
	if p1_selected and p2_selected:
		if start_battle_button:
			start_battle_button.disabled = false
			start_battle_button.text = "¡INICIAR BATALLA!"

func _on_start_battle_button_pressed() -> void:
	if p1_selected and p2_selected:
		GameManager.start_match(p1_selected, p2_selected)
		get_tree().change_scene_to_file("res://battle/battle.tscn")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
