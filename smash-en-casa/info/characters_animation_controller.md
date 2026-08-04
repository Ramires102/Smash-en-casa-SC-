# Explicación de `characters/animation_controller.gd`

## Resumen
Abstracción limpia sobre el nodo `AnimationPlayer` de Godot para reproducir animaciones 3D por nombre de forma segura. Genera automáticamente animaciones procedimentales por fotogramas (*Keyframed Procedural Animations*) con poses ultra-exageradas estilo JoJo / MUGEN meme para John Placeholder y todos los luchadores que utilicen la jerarquía `Humanoid`. Incluye una pista de animación `RESET` para asegurar que las extremidades del personaje (piernas, brazos, torso) vuelvan instantáneamente a su pose inicial de reposo al pasar de agachado (`Squat`) u otras acciones hacia `Idle`.

## Funciones Principales

```gdscript
func play_animation(anim_name: String) -> void:
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
```
- `_ready()`: Inicializa y construye la `AnimationLibrary` en tiempo de ejecución.
- `_create_reset_animation()`: Registra la pista `RESET` restaurando posiciones y rotaciones relativas predeterminadas de todos los miembros del cuerpo.
- `_create_idle_animation()`: Pose de combate estilo JoJo (*Menacing Stance*) con reseteo de posiciones de piernas y torso.
- **Animaciones soportadas**: `Idle`, `Walk`, `Run`, `RunBrake`, `Pivot`, `Squat`, `JumpSquat`, `Jump`, `Fall`, `FastFall`, `Attack`, `Hit`, `Shield`, `Roll`, `Spotdodge`.

## Comunicación e Interacciones
- **Consumido por**: Todos los estados de la máquina de estados FSM (`IdleState`, `WalkState`, `DashState`, `RunState`, `RunBrakeState`, `PivotState`, `SquatState`, `JumpSquatState`, `JumpState`, `FallState`, `AttackState`, `HitState`, `ShieldState`, `RollState`, `SpotDodgeState`).
