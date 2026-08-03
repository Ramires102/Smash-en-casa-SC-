# Explicación de `ui/hud.gd`

## Resumen
Controlador de la interfaz de usuario en combate (`HUD.tscn`). Totalmente desacoplado: **no calcula daño ni vidas**, simplemente recibe señales y actualiza las etiquetas de texto de P1, P2 y el temporizador.

## Explicación Línea por Línea
```gdscript
1: class_name HUD
2: extends Control

4: @onready var p1_percent_label: Label = $MarginContainer/VBoxContainer/TopRow/P1Box/PercentLabel
5: @onready var p1_lives_label: Label = $MarginContainer/VBoxContainer/TopRow/P1Box/LivesLabel
6: @onready var p2_percent_label: Label = $MarginContainer/VBoxContainer/TopRow/P2Box/PercentLabel
7: @onready var p2_lives_label: Label = $MarginContainer/VBoxContainer/TopRow/P2Box/LivesLabel
8: @onready var timer_label: Label = $MarginContainer/VBoxContainer/TopRow/TimerBox/TimerLabel
```
- Referencias `@onready` a las etiquetas del árbol de nodos UI.

```gdscript
10: func update_player_percentage(player_id: int, percentage: float) -> void:
11: 	var text: String = Utils.format_percentage(percentage)
12: 	if player_id == 1 and p1_percent_label: p1_percent_label.text = text
13: 	elif player_id == 2 and p2_percent_label: p2_percent_label.text = text
```
- Formatea con `Utils.format_percentage()` y actualiza el valor visual de porcentaje (ej. `"142%"`).

```gdscript
15: func update_lives(player_id: int, lives: int) -> void:
16: 	var text: String = "Vidas: %d" % lives
17: 	if player_id == 1 and p1_lives_label: p1_lives_label.text = text
18: 	elif player_id == 2 and p2_lives_label: p2_lives_label.text = text
```
- Muestra el stock de vidas restante.

```gdscript
20: func update_timer(time_seconds: float) -> void:
21: 	if timer_label: timer_label.text = Utils.format_time(time_seconds)
```
- Muestra el reloj regresivo en formato `MM:SS`.

## Comunicación e Interacciones
- **Escucha señales de**: `Character.gd` (`percentage_changed`) y `BattleManager.gd` (`lives_updated`, `timer_updated`).
