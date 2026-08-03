# Explicación de `ui/pause.gd`, `ui/gacha.gd` y `ui/victory.gd`

## 1. `ui/pause.gd`
- **Función**: Maneja el menú emergente de pausa durante la pelea.
- **Líneas clave**:
  - `process_mode = PROCESS_MODE_ALWAYS`: Le permite capturar entradas cuando el árbol de la escena está congelado/pausado.
  - `_unhandled_input(event)`: Si se presiona la tecla Cancelar/Escape, invoca `GameManager.toggle_pause()`.

---

## 2. `ui/gacha.gd`
- **Función**: Menú de gacha/desbloqueables.
- **Líneas clave**:
  - `_on_back_button_pressed()`: Regresa al Menú Principal con `get_tree().change_scene_to_file("res://ui/main_menu.tscn")`.

---

## 3. `ui/victory.gd`
- **Función**: Pantalla de fin de partida.
- **Líneas clave**:
  - `_ready()`: Lee `GameManager.winner_player_id` y actualiza la etiqueta de texto (ej. `"¡JUGADOR 1 GANA!"` o `"¡EMPATE!"`).
  - Permite reiniciar la revancha inmediatamente o regresar a la selección de personajes.

## Comunicación e Interacciones
- **Comunican con**: `GameManager.gd` y el árbol de escenas de Godot 4.
