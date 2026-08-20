# 🏛️ Contrato de Autoloads (Core Architecture)

Este documento define las responsabilidades, límites arquitectónicos y APIs públicas de los Autoloads (Singletons globales) del proyecto.

---

## 1. GameManager (`res://core/game_manager.gd`)

### Responsabilidades
1. **Configuración de sesión**: Almacena los parámetros de la partida seleccionados en la UI (datos de personajes P1 y P2, vidas iniciales, tiempo límite).
2. **Control global de pausa**: Administra el estado de pausa del árbol de escenas (`get_tree().paused = is_paused`) y notifica el cambio.
3. **Persistencia y transferencia de estado**: Mantiene los datos entre transiciones de pantallas (de selección de personajes a batalla, y de batalla a pantalla de victoria).
4. **Registro del resultado final**: Almacena el ID del ganador resultante para consulta de pantallas de resultados.

### Lo que NO debe hacer
* ❌ **NO** gestiona el combate en tiempo real (vidas activas durante el match, temporizador tick a tick, blast zones — eso pertenece a `BattleManager`).
* ❌ **NO** calcula daño (`%`), knockback, hitstun ni colisiones.
* ❌ **NO** procesa entradas de teclado ni mandos de los jugadores.

### API Pública Mínima
```gdscript
signal match_started
signal match_ended(winner_id: int)
signal pause_toggled(is_paused: bool)

func start_match(p1_data: Resource, p2_data: Resource, lives: int = 3, timer: float = 480.0) -> void
func end_match(winner_id: int) -> void
func toggle_pause() -> void
```

---

## 2. InputManager (`res://core/input_manager.gd`)

### Responsabilidades
1. **Mapeo unificado de controles**: Configura y registra automáticamente las acciones en el `InputMap` para Jugador 1 (`p1_...`) y Jugador 2 (`p2_...`).
2. **Consulta centralizada de entradas**: Provee métodos de consulta de estado por ID de jugador (`get_move_vector`, `is_attack_pressed`, `is_jump_pressed`, etc.).
3. **Detección de patrones temporales**: Detecta intenciones como doble toque (*double tap*) para diferenciar caminata de inicio de carrera (*dash*).

### Lo que NO debe hacer
* ❌ **NO** modifica directamente la física, velocidad o posición de los personajes (`CharacterBody3D`).
* ❌ **NO** maneja la lógica de combos, cancelaciones de ataques ni estados de personajes.
* ❌ **NO** maneja la lógica interna de menús o interfaces fuera de la consulta de inputs.

### API Pública Mínima
```gdscript
func get_move_vector(player_id: int) -> Vector2
func is_dash_pressed(player_id: int) -> bool
func is_jump_pressed(player_id: int) -> bool
func is_jump_held(player_id: int) -> bool
func is_attack_pressed(player_id: int) -> bool
func is_special_pressed(player_id: int) -> bool
func is_shield_pressed(player_id: int) -> bool
```

---

## 3. AudioManager (`res://core/audio_manager.gd`)

### Responsabilidades
1. **Reproducción centralizada de BGM**: Gestiona la música de fondo, evitando reinicios redundantes si la pista solicitada ya está activa.
2. **Pool de canales para SFX**: Administra una colección de reproductores (`AudioStreamPlayer`) reutilizables para reproducir efectos de sonido simultáneos sin cortes.
3. **Modulación de efectos**: Permite ajustar tono/velocidad (`pitch_scale`) para dar variedad a los impactos y acciones sonoras.

### Lo que NO debe hacer
* ❌ **NO** decide cuándo un personaje debe golpear o sufrir daño; solo ejecuta los streams de audio solicitados por otros sistemas.
* ❌ **NO** contiene lógica de partida, cálculos de combate ni dependencias directas de nodos de juego específicos.

### API Pública Mínima
```gdscript
func play_bgm(stream: AudioStream) -> void
func stop_bgm() -> void
func play_sfx(stream: AudioStream, pitch_scale: float = 1.0) -> void
```

---

## 4. Matriz de Responsabilidades y Límites

| Dominio / Funcionalidad | Componente Responsable | Justificación |
| :--- | :--- | :--- |
| Configuración inicial de match & Pausa | `GameManager` (Autoload) | Persiste entre cambios de escena. |
| Mapeo y lectura de inputs P1 / P2 | `InputManager` (Autoload) | Centraliza el hardware y teclado. |
| Música y SFX compartidos | `AudioManager` (Autoload) | Mantiene el audio vivo en todo el juego. |
| Vidas en match, reloj regresivo y reglas | `BattleManager` (Escena) | Árbitro que solo vive durante la partida. |
| Cálculos de Daño % y Knockback | `DamageCalculator` / `KnockbackCalculator` | Lógica pura desacoplada sin estado global. |
