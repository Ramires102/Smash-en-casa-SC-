# Explicación y Estándar de `characters/character.gd`

## Resumen
`Character` es el contenedor raíz reutilizable (`CharacterBody3D`) para cualquier luchador del juego. Sigue una arquitectura **100% Data-Driven**, desacoplada por componentes, donde un único `character.tscn` puede representar a cualquier personaje simplemente aplicando su `CharacterData`.

---

## 🏛️ 1. Nodos Obligatorios de `Character` (Estructura Mínima)

Cualquier escena o instancia de `Character` debe contar obligatoriamente con la siguiente jerarquía de nodos:

```text
Character (CharacterBody3D) [Script: character.gd]
├── Controller (Node) [Script: character_controller.gd]
├── Stats (Node) [Script: character_stats.gd]
├── AttackController (Node) [Script: attack_controller.gd]
├── CollisionShape3D (CapsuleShape3D principal)
├── Humanoid (Node3D - Raíz de modelo visual 3D)
│   ├── ModelRoot (Instancia dinámica del modelo 3D)
│   └── ShieldMesh (MeshInstance3D - Burbuja de escudo 3D)
├── Hitbox (Area3D) [Script: hitbox.gd]
│   └── CollisionShape3D (BoxShape3D ofensivo)
├── Hurtbox (Area3D) [Script: hurtbox.gd]
│   └── CollisionShape3D (CapsuleShape3D defensivo)
├── AnimationController (Node) [Script: animation_controller.gd]
├── AnimationPlayer (AnimationPlayer)
└── StateMachine (Node) [Script: state_machine.gd]
    ├── Idle, Walk, Dash, Run, RunBrake, Pivot, Squat
    ├── JumpSquat, Jump, Fall
    ├── Attack, Hit, Death, Shield, Daze, Spotdodge, Roll
```

---

## ⚙️ 2. Contrato de Configuración Data-Driven (`configure`)

El método estándar para inicializar o cambiar el luchador es:

```gdscript
func configure(data: CharacterData) -> void
```

### Acciones ejecutadas por `configure(data)`:
1. Asigna la referencia `character_data = data`.
2. **Físicas y Movimiento**: Llama a `controller.setup(data)` aplicando velocidades de carrera/caminata, tracción, salto y gravedad.
3. **Estadísticas de Combate**: Llama a `stats.setup(data)` configurando peso y reseteando porcentaje (`0.0%`).
4. **Moveset y Ataques**: Llama a `attack_controller.setup(data)` vinculando los recursos `AttackData` para ataques neutrales, aéreos, tilts y especiales.
5. **Representación Visual 3D**:
   - Si `data.model_scene` está presente: Instancia el modelo 3D final (`ModelRoot`), aplica `data.model_offset` y escala `data.model_scale`.
   - Si no está presente (Fallback): Aplica `data.character_color` en los materiales del maniquí articulado placeholder.

---

## 🚫 3. Cero Hardcode por Personaje

* **Sin condicionales por nombre**: No existen comprobaciones del tipo `if data.character_name == "..."`.
* **Extensibilidad**: Crear un nuevo personaje solo requiere crear un nuevo recurso `.tres` (`CharacterData`) en la carpeta `resources/instances/` sin modificar código de motor.

---

## 📡 Comunicación e Interacciones
* **Entradas**: Lee intenciones de control desacopladas mediante `current_input: PlayerInput`.
* **Señales**: Emite `percentage_changed(new_percentage)` y `character_ko(player_id)`.
* **Consumido por**: `SpawnManager`, `BattleManager`, `CameraController`, `HUD`.
