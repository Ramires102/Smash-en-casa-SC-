# Explicación de `characters/animation_controller.gd` y Módulos Procedurales

## Resumen
El sistema de animación 3D está modularizado en **4 clases con responsabilidad única** para mantener el código limpio y legible:

1. **`AnimationController` (`animation_controller.gd`)**: Fachada (`Node`) que coordina el ciclo de vida de animaciones de un personaje, escuchando cambios de estado de la `StateMachine` y eventos de ataque.
2. **`ProceduralPoseSolver` (`procedural_pose_solver.gd`)**: Resuelve frame a frame las rotaciones de huesos (`Skeleton3D`) para poses procedurales fluidas (respiración en *Idle*, inclinación en *Run*, saltos, escudo, *hitstun* y ataques).
3. **`CombatVFXController` (`combat_vfx_controller.gd`)**: Genera efectos visuales 3D en combate (estelas de corte/golpe, destellos de impacto, aura de especial, etc.).
4. **`ProceduralMovesetBuilder` (`procedural_moveset_builder.gd`)**: Construye pistas de animación procedurales en `AnimationPlayer` para maniquíes articulados cuando un modelo no usa esqueleto `.glb`.

## Comunicación e Interacciones
- **Gobernado por**: `Character`, `StateMachine` y `AttackController`.
- **Opera sobre**: El nodo 3D `Humanoid` / `ModelRoot` administrado por `VisualController`.
