# Explicación de `ui/main_menu.gd`

## Resumen
Script del Menú Principal. Conecta los botones de la interfaz para navegar hacia la Selección de Personajes, el Gacha o Salir del juego.

## Explicación Línea por Línea
```gdscript
1: class_name MainMenu
2: extends Control

4: func _on_start_button_pressed() -> void:
5: 	get_tree().change_scene_to_file("res://ui/character_select.tscn")

7: func _on_gacha_button_pressed() -> void:
8: 	get_tree().change_scene_to_file("res://ui/gacha.tscn")

10: func _on_quit_button_pressed() -> void:
11: 	get_tree().quit()
```
- Cambia a las escenas correspondientes con `change_scene_to_file()`.

## Comunicación e Interacciones
- **Carga las escenas**: `res://ui/character_select.tscn` y `res://ui/gacha.tscn`.
