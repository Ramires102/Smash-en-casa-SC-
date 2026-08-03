# Explicación de `ui/character_select.gd`

## Resumen
Pantalla de Selección de Personajes actualizada. Permite elegir las instancias de `CharacterData` para P1 y P2 (Miyabi, Gogeta, Sakuya), muestra etiquetas de estado para saber qué eligió cada jugador, habilita el botón "¡INICIAR BATALLA!" y permite volver al menú principal en todo momento con el botón "← Volver al Menú Principal".

## Explicación Línea por Línea
```gdscript
1: class_name CharacterSelect
2: extends Control

# Selección de P1 y P2 mediante señales de botones
17: func _on_p1_miyabi_pressed() -> void:
18: 	p1_selected = miyabi_data
19: 	p1_status.text = "P1 Seleccionó: Miyabi"
20: 	_check_ready()

# Verificación de inicio
45: func _check_ready() -> void:
46: 	if p1_selected and p2_selected:
47: 		start_battle_button.disabled = false
48: 		start_battle_button.text = "¡INICIAR BATALLA!"

# Botón Volver
55: func _on_back_button_pressed() -> void:
56: 	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
```

## Comunicación e Interacciones
- **Comunica con**: `GameManager.gd` (al iniciar batalla) y las escenas `res://battle/battle.tscn` y `res://ui/main_menu.tscn`.
