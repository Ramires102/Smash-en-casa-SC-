# Explicación de `core/input_manager.gd`

## Resumen
Autoload (Singleton) que gestiona y registra automáticamente en tiempo de ejecución las acciones del `InputMap` para el Jugador 1 (`p1_...`) y Jugador 2 (`p2_...`), incluyendo la detección precisa de doble toque (*Double Tap*) diferenciando entre mantener presionado (*Walk*) y toques rápidos (*Dash/Run*).

## Mapeo de Teclado Configurado

### Jugador 1 (P1):
- **Caminar**: Presionar y mantener `A` (Izquierda) / `D` (Derecha) (Velocidad de caminata 1.375 Smash / 8.25 Godot)
- **Correr (Dash/Run)**: Doble toque rápido (*Short Tap* < 0.18s + re-presión < 0.22s) en `A` o `D` (Velocidad de carrera 3.85 Smash / 23.1 Godot)
- **Agacharse**: Mantener `S` (Abajo)
- **Salto**: `Espacio`
- **Ataque Normal**: `J`
- **Ataque Especial**: `K`
- **Escudo**: `L`

### Jugador 2 (P2):
- **Caminar**: Presionar y mantener `Flechas Direccionales`
- **Correr (Dash/Run)**: Doble toque rápido en `Flecha Izquierda` o `Flecha Derecha`
- **Agacharse**: Mantener `Flecha Abajo`
- **Salto**: `B` / `Numpad 0`
- **Ataque Normal**: `N` / `Numpad 1`
- **Ataque Especial**: `M` / `Numpad 2`
- **Escudo**: `V` / `Numpad 3`

## Explicación Línea por Línea
```gdscript
60: # Requiere que el primer toque haya sido un Short Tap (< 0.18s) y la repetición ocurra en < 0.22s
61: if was_short_tap[p_id]["right"] and dt < 0.22:
62: 	is_dash_intent[p_id] = true
```

## Comunicación e Interacciones
- **Consumido por**: `CharacterController.gd`, `Character.gd`, `IdleState`, `WalkState`, `DashState`, `RunState`, `RunBrakeState`, `PivotState`, `SquatState`.
