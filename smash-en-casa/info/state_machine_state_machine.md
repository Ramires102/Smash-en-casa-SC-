# Explicación de `characters/state_machine/state_machine.gd`

## Resumen
Máquina de Estados Finita (**Patrón State / FSM**) desacoplada. Registra automáticamente todos sus nodos hijos que heredan de `State`, delega la actualización física (`physics_update`) únicamente al estado activo y gestiona transiciones seguras mediante `transition_to()`.

## Flujo Principal
```gdscript
class_name StateMachine
extends Node

signal state_changed(current_state_name: String)

@export var initial_state: State
var current_state: State
var states: Dictionary = {}
```

1. **Inicialización (`_ready`)**:
   - Espera a que el `Character` raíz (`CharacterBody2D`) esté listo (`await owner.ready`).
   - Recorre sus hijos de tipo `State`, los registra en `states[child.name.to_lower()]` e inyecta las referencias `child.state_machine = self` y `child.character = owner as Character`.
2. **Actualización por Frame (`_physics_process`)**:
   - Si el personaje no está congelado en *Hitstop* (`hitlag`), delega el frame a `current_state.physics_update(delta)`.
3. **Transición (`transition_to(target_state_name, msg)`)**:
   - Resuelve alias de estados estilo Smash (`ACMD_ALIASES`), ejecuta `current_state.exit()`, activa el nuevo estado ejecutando `enter(msg)` y emite `state_changed`.

## Comunicación e Interacciones
- **Gobernador de**: Los 15 estados activos del luchador (`IdleState`, `RunState`, `JumpSquatState`, `JumpState`, `FallState`, `AttackState`, `HitState`, `ShieldState`, `RollState`, `SpotDodgeState`, `AirDodgeState`, `DazeState`, `LedgeState`, `LedgeGetupState`, `DeathState`).
