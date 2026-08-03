# Explicación de `core/input_manager.gd`

## Resumen
Autoload (Singleton) que gestiona y registra automáticamente en tiempo de ejecución las acciones del `InputMap` para el Jugador 1 (`p1_...`) y Jugador 2 (`p2_...`).

## Mapeo de Teclado Configurado

### Jugador 1 (P1):
- **Movimiento**: `W` (Arriba), `A` (Izquierda), `S` (Abajo), `D` (Derecha)
- **Salto**: `Espacio`
- **Ataque Normal**: `J`
- **Ataque Especial**: `K`
- **Escudo**: `L`

### Jugador 2 (P2):
- **Movimiento**: `Flechas Direccionales` (Arriba, Izquierda, Abajo, Derecha)
- **Salto**: `B` / `Numpad 0`
- **Ataque Normal**: `N` / `Numpad 1`
- **Ataque Especial**: `M` / `Numpad 2`
- **Escudo**: `V` / `Numpad 3`

## Explicación Línea por Línea
```gdscript
5: func _setup_default_input_map() -> void:
6: 	# Registra automáticamente en tiempo de ejecución las teclas sin necesidad de configurarlas manualmente en el editor
```

## Comunicación e Interacciones
- **Consumido por**: `CharacterController.gd` y `Character.gd` durante la partida.
