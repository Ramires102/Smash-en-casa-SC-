# Explicación y Arquitectura de `characters/character.gd`

## Resumen
`Character` es la fachada raíz reutilizable (`CharacterBody2D`) para cualquier luchador del juego dentro de una arquitectura **2.5D Híbrida y Data-Driven**:
- **Simulación y colisiones en 2D**: físicas exactas en el plano XY (`CharacterBody2D`, `Hitbox`, `Hurtbox`, `Pushbox`).
- **Representación visual en 3D**: el componente `VisualController` proyecta cada frame la posición 2D (`100 px = 1.0 m`) a un proxy `Humanoid` (`Node3D`) en el escenario 3D.

Un único `character.tscn` sirve para los 7 personajes simplemente inyectándole su recurso `CharacterData` (`.tres`).

---

## 🏛️ 1. Jerarquía de Componentes de `Character`

```text
Character (CharacterBody2D) [character.gd]
├── Controller (Node) [character_controller.gd]
├── Stats (Node) [character_stats.gd]
├── AttackController (Node) [attack_controller.gd]
├── ShieldController (Node) [shield_controller.gd]
├── VisualController (Node) [visual_controller.gd] ──▶ gestiona Humanoid (Node3D) en el mundo 3D
├── AnimationController (Node) [animation_controller.gd]
│   ├── ProceduralPoseSolver (RefCounted) [procedural_pose_solver.gd]
│   ├── CombatVFXController (RefCounted) [combat_vfx_controller.gd]
│   └── ProceduralMovesetBuilder (RefCounted) [procedural_moveset_builder.gd]
├── Hitbox (Area2D) [hitbox.gd]
├── Hurtbox (Area2D) [hurtbox.gd]
├── Pushbox (Area2D) [pushbox.gd]
└── StateMachine (Node) [state_machine.gd]
    └── 15 estados activos (Idle, Run, JumpSquat, Jump, Fall, Attack, Hit,
        Shield, Roll, SpotDodge, AirDodge, Daze, Ledge, LedgeGetup, Death)
```

---

## ⚙️ 2. Configuración Data-Driven (`configure(data: CharacterData)`)
Al iniciar la partida, `SpawnManager` invoca `character.configure(data)`, que delega la configuración a cada subsistema:
1. **`controller.setup(data)`**: Velocidad de carrera, aceleración, gravedad, fuerza de salto y peso.
2. **`stats.setup(data)`**: Peso para knockback y porcentaje de daño inicial (`0.0%`).
3. **`attack_controller.setup(data)`**: Carga el `Moveset` (Jabs, Tilts, Aerials y Especiales).
4. **`visual_controller.setup_3d_visuals(data)`**: Instancia el modelo `.glb` (`ModelRoot`), configura escala/offset y la malla de escudo 3D.
5. **`animation_controller.setup_character_rig(...)`**: Vincula huesos humanoides (`Skeleton3D`) y genera/conecta las animaciones de combate.
