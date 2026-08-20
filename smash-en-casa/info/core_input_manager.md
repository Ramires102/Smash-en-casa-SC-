# Explicación de `core/input_manager.gd`

## Resumen
Autoload (Singleton) que gestiona y registra automáticamente en tiempo de ejecución las acciones del `InputMap` para el Jugador 1 (`p1_...`) y Jugador 2 (`p2_...`), incluyendo la detección precisa de doble toque (*Double Tap*) diferenciando entre mantener presionado (*Walk*) y toques rápidos (*Dash/Run*), tanto para **Teclado** como para **Mandos / Joysticks**.

---

## 🎮 Mapa de Acciones Normalizado por Jugador

Todas las acciones siguen la convención estándar `p{player_id}_{action}`:

| Acción Normalizada | Jugador 1 (P1) - Teclado | Jugador 1 (P1) - Joystick (Dev 0) | Jugador 2 (P2) - Teclado | Jugador 2 (P2) - Joystick (Dev 1) |
| :--- | :--- | :--- | :--- | :--- |
| `p{id}_left` | `A` | Stick Izq (←) / D-Pad Left | `Flecha Izquierda` | Stick Izq (←) / D-Pad Left |
| `p{id}_right` | `D` | Stick Izq (→) / D-Pad Right | `Flecha Derecha` | Stick Izq (→) / D-Pad Right |
| `p{id}_up` | `W` | Stick Izq (↑) / D-Pad Up | `Flecha Arriba` | Stick Izq (↑) / D-Pad Up |
| `p{id}_down` | `S` (Agacharse) | Stick Izq (↓) / D-Pad Down | `Flecha Abajo` | Stick Izq (↓) / D-Pad Down |
| `p{id}_jump` | `Espacio` | Botón `X` / `Y` | `B` / `Numpad 0` | Botón `X` / `Y` |
| `p{id}_attack` | `J` (Normal / Jab) | Botón `A` (Xbox) / `Cross` (PS) | `N` / `Numpad 1` | Botón `A` (Xbox) / `Cross` (PS) |
| `p{id}_special` | `K` (Especial) | Botón `B` (Xbox) / `Circle` (PS) | `M` / `Numpad 2` | Botón `B` (Xbox) / `Circle` (PS) |
| `p{id}_shield` | `L` (Burbuja Escudo) | `LB` / `RB` / `LT` / `RT` | `V` / `Numpad 3` | `LB` / `RB` / `LT` / `RT` |

---

## 🕹️ Funcionalidades del Script

1. **Mapeo Automático**: En `_setup_default_input_map()`, crea dinámicamente en el `InputMap` todas las acciones `p1_` y `p2_` vinculando los eventos `InputEventKey`, `InputEventJoypadButton` e `InputEventJoypadMotion`.
2. **Buffer / Detección de Dash**: Registra la diferencia temporal de toques (`dt`) para activar la bandera `is_dash_intent[player_id] = true` si ocurre un doble toque en menos de 0.28s.
3. **Consulta Desacoplada**: Expone métodos de lectura (`get_move_vector(id)`, `is_jump_pressed(id)`, `is_attack_pressed(id)`, etc.) consumidos por los componentes de los luchadores sin acoplarse al hardware.

## Comunicación e Interacciones
- **Consumido por**: `CharacterController.gd`, `Character.gd`, `IdleState`, `WalkState`, `DashState`, `RunState`, `RunBrakeState`, `PivotState`, `SquatState`, `ShieldState`.
