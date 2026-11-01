# Explicación de `core/input_manager.gd`

## Resumen
Autoload (Singleton) que registra y sincroniza dinámicamente las acciones del `InputMap` para hasta **4 jugadores** (`p1_...` a `p4_...`), integrándose con `ProfileManager` para soportar perfiles personalizados de teclado y mandos tipo Xbox, zonas muertas (*deadzones*) y detección de doble toque (*Double Tap*).

---

## 🎮 Acciones Normalizadas por Jugador (`p{id}_{action}`)

| Acción | Descripción | Teclado P1 (Default) | Teclado P2 (Default) | Mando Xbox |
| :--- | :--- | :--- | :--- | :--- |
| `left` / `right` | Movimiento horizontal | `A` / `D` | `←` / `→` | Stick Izq / D-Pad |
| `up` / `down` | Apuntado vertical / Fast-Fall | `W` / `S` | `↑` / `↓` | Stick Izq / D-Pad |
| `jump` | Salto (Short Hop / Full Hop) | `Espacio` | `Enter` / `KP 0` | `A` / `Y` |
| `attack` | Ataque normal (Jab / Tilt / Aerial) | `J` | `K` / `KP 1` | `X` |
| `special` | Ataque especial (`B`) | `K` | `L` / `KP 2` | `B` |
| `shield` | Escudo / Parry / Esquiva | `L` | `;` / `KP 3` | `LB` / `RB` / `LT` / `RT` |
| `c_left`..`c_down` | C-Stick (Ataques direccionales rápidos) | — | — | Stick Derecho |

---

## 🕹️ Funcionalidades Clave
1. **Sincronización con Perfiles**: Reconstruye el `InputMap` cuando el usuario cambia un botón o perfil en `controls_config.tscn`.
2. **Construcción de `PlayerInput`**: Empaqueta en cada frame físico todas las lecturas de un jugador en un objeto `PlayerInput` limpio mediante `get_player_input(player_id)`.
3. **Consumido por**: `Character`, `CharacterController`, `AttackController`, `StateMachine` y pantallas de UI multijugador (`character_select.gd`, `controls_config.gd`).
