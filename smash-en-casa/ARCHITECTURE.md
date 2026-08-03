# 🎮 Arquitectura General: Smash en Casa (Platform Fighter 2.5D)

Este documento detalla la **arquitectura técnica actual** del proyecto en Godot 4 y la **planificación proyectada** para la versión final.

---

## 🏛️ 1. Arquitectura Actual Implementada

El proyecto sigue una arquitectura **desacoplada, modular y orientada a datos (Data-Driven)** estructurada en los siguientes módulos:

```text
smash-en-casa/
├── core/                  # Autoloads / Singletons globales
│   ├── events.gd          # EventBus desacoplado (Señales de combate, UI y cámara)
│   ├── game_manager.gd    # Configuración global de partida, pausa y estado
│   ├── audio_manager.gd   # Pool de audio centralizado para BGM y SFX
│   └── input_manager.gd   # Mapeo automático de teclas y mandos (P1 y P2)
│
├── resources/             # Sistema Data-Driven (Creación de personajes sin tocar código)
│   ├── character_data.gd  # Resource: Nombre, Velocidad, Peso, Color, Icono, Moveset
│   ├── moveset.gd         # Resource: Agrupa los AttackData por dirección y tipo
│   ├── attack_data.gd     # Resource: Frame Data, Daño %, Base & Scaling Knockback, Ángulo
│   └── instances/         # Instancias .tres (Miyabi, Gogeta, Sakuya, default_moveset, etc.)
│
├── characters/            # Arquitectura basada en Componentes de Personaje
│   ├── character.gd       # Raíz contenedora CharacterBody3D
│   ├── character_controller.gd  # Componente: Movimiento físico horizontal y salto
│   ├── character_stats.gd       # Componente: Gestión del porcentaje de daño % y peso
│   ├── attack_controller.gd     # Componente: Selección de AttackData e interfaz con Hitbox
│   ├── animation_controller.gd  # Componente: Reproductor abstracto de animaciones
│   └── state_machine/           # FSM (Máquina de Estados Finita)
│       ├── state_machine.gd     # FSM Genérica
│       ├── state.gd             # Clase base abstracta State
│       ├── idle_state.gd        # Estado de reposo
│       ├── run_state.gd         # Estado de carrera
│       ├── jump_state.gd        # Estado de salto
│       ├── fall_state.gd        # Estado de caída
│       ├── attack_state.gd      # Estado de ataque activo
│       ├── hit_state.gd         # Estado de recepción de golpe (Aturdimiento por knockback)
│       ├── death_state.gd       # Estado de KO
│       └── shield_state.gd      # Estado de escudo (Burbuja 3D)
│
├── combat/                # Colisiones de Ataque y Daño
│   ├── hitbox.gd          # Area3D ofensiva (Activa la ventana de colisión)
│   ├── hurtbox.gd         # Area3D defensiva (Recibe el golpe y notifica al dueño)
│   └── damage_calculator.gd # Calculadora de porcentaje acumulativo
│
├── physics/               # Cálculos de Física Pura
│   └── knockback_calculator.gd # Ecuación matemática de lanzamiento estilo Smash Bros
│
├── battle/                # Reglas y Escenario 2.5D
│   ├── stage.gd           # Escenario 3D con plataformas y BlastZone (Area3D)
│   ├── spawn_manager.gd   # Spawns iniciales y reaparición de luchadores (Respawns)
│   ├── battle_manager.gd  # Árbitro: Vidas (stocks), Reloj regresivo, KOs y Ganador
│   └── battle.gd          # Ensamblador de la escena principal de batalla
│
├── systems/               # Sistemas Auxiliares
│   ├── camera_controller.gd # Cámara 2.5D dinámica (Seguimiento de centro y zoom Z)
│   ├── screen_shake.gd      # Sacudida de cámara por impactos
│   └── input_buffer.gd      # Buffer de comandos
│
├── ui/                    # Pantallas de Interfaz de Usuario
│   ├── main_menu.gd / .tscn        # Menú Principal
│   ├── character_select.gd / .tscn # Selección de Luchadores con status e inicio
│   ├── hud.gd / .tscn              # HUD desacoplado (escucha EventBus)
│   ├── pause.gd / .tscn            # Menú de Pausa
│   ├── gacha.gd / .tscn            # Pantalla de Gacha
│   └── victory.gd / .tscn          # Pantalla de Victoria / Resultados
│
└── shared/                # Constantes y Helpers
    ├── constants.gd       # Constantes de combate y Z plane 2.5D
    ├── utils.gd           # Formateo de tiempo `MM:SS` y porcentaje `%`
    └── helpers.gd         # Restricción de posición en el plano $Z=0$
```

---

## 🎨 2. Componentes Visuales Actuales

- **Maniquí Humanoide 3D Placeholder**: La escena del personaje (`character.tscn`) cuenta con un modelo 3D articulado (Cabeza, Torso, Brazos, Piernas y Burbuja de Escudo). Se colorea automáticamente según el `CharacterData` (Miyabi en Rojo, Gogeta en Azul, Sakuya en Blanco).
- **Controles de Teclado Mapeados**:
  - **P1**: `WASD` (Movimiento), `Espacio` (Salto), `J` (Jab Normal), `K` (Especial), `L` (Escudo).
  - **P2**: `Flechas` (Movimiento), `B` (Salto), `N` (Jab Normal), `M` (Especial), `V` (Escudo).

---

## 🚀 3. Arquitectura Planificada para la Versión Final (Roadmap)

Conforme el proyecto avance hacia su versión final, se desarrollarán los siguientes hitos sobre la misma estructura desacoplada:

1. **Modelos 3D e Rigging Final de Personajes**:
   - Sustitución de los maniquíes placeholder por modelos 3D finales riggeados en Blender (Miyabi, Gogeta, Sakuya).
   - Animaciones 3D personalizadas para cada estado de la FSM (Idle, Run, Jump, Attack, Hit, Victory).
2. **Eventos de Animación (Animation-Driven Events)**:
   - Emisión de señales desde pistas de animación para la apertura/cierre exacto de Hitboxes y disparo de partículas visuales.
3. **Efectos Visuales (VFX) e Impactos**:
   - Instanciación de efectos de partículas (`GPUParticles3D`) y ráfagas de golpe al conectar `hitbox` con `hurtbox`.
4. **Escenarios 3D Complejos (`Stages`)**:
   - Modelado de escenarios 2.5D temáticos con materiales PBR, mapas de sombras dinámicos y plataformas móviles.
5. **Ampliación del Roster de Personajes**:
   - Inclusión de nuevos luchadores simplemente creando sus correspondientes `CharacterData`, `MoveSet` y `AttackData` recursos `.tres` sin tocar una sola línea de código del motor.
6. **Sistema de Audio y Música Completo**:
   - Asignación de SFX de impacto y voces únicas por ataque y BGM dinámico por escenario.
7. **Modo Gacha y Persistencia de Guardado**:
   - Integración de `SaveManager` para persistir desbloqueos de luchadores y preferencias del jugador.
