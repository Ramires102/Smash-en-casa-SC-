# 🏛️ Contrato de Autoloads (`core/`)

Este documento resume las responsabilidades, límites arquitectónicos y APIs públicas de los **5 Autoloads (Singletons)** registrados en `project.godot`.

---

## 1. `Events` (`res://core/events.gd`)
Bus global de señales (**Patrón Observer / EventBus**) para comunicar eventos de combate, KO, escudo, pausa y sacudida/zoom de cámara sin acoplar nodos entre sí.

---

## 2. `GameManager` (`res://core/game_manager.gd`)
- **Responsabilidades**: Almacena la configuración de la partida actual hasta **4 jugadores** (`active_players`, `player_datas`, `player_profiles`, `selected_stage_id`, `starting_lives`, `match_timer`), gestiona el estado global de pausa (`toggle_pause`) y registra victorias/partidas en el leaderboard al concluir un combate (`end_match`).
- **No hace**: No ejecuta físicas ni colisiones en tiempo real (eso pertenece a `BattleManager` y `Character`).

---

## 3. `ProfileManager` (`res://core/profile_manager.gd`)
- **Responsabilidades**: Gestiona perfiles personalizados de controles por jugador (al estilo Yuzu), asignación de dispositivos de entrada (teclado o mando Xbox 0–3) y persistencia en JSON (`user://controls_v2.json` y `user://leaderboard.json`).

---

## 4. `InputManager` (`res://core/input_manager.gd`)
- **Responsabilidades**: Registra y sincroniza dinámicamente las acciones del `InputMap` para los 4 jugadores (`p1_` a `p4_`), detecta doble toque (*dash*) y construye objetos `PlayerInput` desacoplados del hardware físico.
- **No hace**: No modifica directamente la velocidad o posición del `CharacterBody2D`.

---

## 5. `AudioManager` (`res://core/audio_manager.gd`)
- **Responsabilidades**: Reproduce música de fondo (`play_menu_bgm`, `play_battle_bgm`, `play_bgm`) evitando reinicios redundantes de pista y gestiona un *Object Pool* de reproductores `AudioStreamPlayer` para efectos de sonido simultáneos (`play_sfx`).

---

## Matriz de Responsabilidades

| Dominio / Funcionalidad | Componente Responsable | Justificación |
| :--- | :--- | :--- |
| Bus de señales desacoplado | `Events` (Autoload) | Evita referencias circulares UI ↔ Combate. |
| Sesión de partida (1–4P) y Pausa | `GameManager` (Autoload) | Persiste entre escenas de menú, batalla y victoria. |
| Perfiles de mando y Leaderboard | `ProfileManager` (Autoload) | Centraliza lectura/escritura JSON en `user://`. |
| Mapeo y lectura de inputs P1–P4 | `InputManager` (Autoload) | Abstrae teclado y gamepads en `PlayerInput`. |
| Música y pool de SFX | `AudioManager` (Autoload) | Mantiene el audio continuo entre cambios de escena. |
| Vidas activas, reloj y blast zones | `BattleManager` (Escena) | Árbitro que solo vive durante la partida. |
