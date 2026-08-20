# Issue Breakdown Granular (para backlog)

Este documento divide las epicas actuales (issues #1-#16) en issues mas chicos y ejecutables.

## Epic #1 - Core Autoload Contract

- [ ] GameManager: contrato de responsabilidades y API minima.
- [ ] InputManager: contrato de responsabilidades y API minima.
- [ ] AudioManager: contrato de responsabilidades y API minima.

## Epic #2 - Input Map and Player Actions

- [ ] Auditar acciones actuales P1/P2 y limpiar duplicados.
- [ ] Normalizar nombres de acciones (convencion unica).
- [ ] Validar paridad teclado/joystick en ambos jugadores.

## Epic #3 - PlayerInput Abstraction

- [ ] Definir estructura PlayerInput (move/jump/attack/special/shield).
- [ ] Crear adapter InputManager -> PlayerInput por jugador.
- [ ] Migrar Character/FSM para consumir solo PlayerInput.

## Epic #4 - Character Scene Contract

- [ ] Checklist de nodos obligatorios de Character.
- [ ] Implementar/validar configure(data).
- [ ] Eliminar referencias hardcodeadas a personajes puntuales.

## Epic #5 - FSM Core State Set

- [ ] Transiciones base Idle/Run/Jump/Fall.
- [ ] Transiciones Attack/Hit/Death.
- [ ] Verificacion de estados muertos y loops invalidos.

## Epic #6 - Attack State and Frame Windows

- [ ] Logica de startup/active/recovery.
- [ ] Activacion de hitbox solo en active frames.
- [ ] Reglas de salida de AttackState.

## Epic #7 - Hitbox/Hurtbox Impact Contract

- [ ] Definir payload de impacto estandar.
- [ ] Lockout de multi-hit accidental por swing/objetivo.
- [ ] Emision de senal hit_received con contrato estable.

## Epic #8 - Damage and Percentage Application

- [ ] Pipeline de aplicacion de dano en DamageCalculator.
- [ ] Emision de evento percentage_changed para HUD.

## Epic #9 - Knockback and Hit Reaction

- [ ] Implementar interfaz de KnockbackCalculator.
- [ ] Aplicar velocidad de lanzamiento y transicionar a HitState.

## Epic #10 - Stage BlastZones and Spawns

- [ ] Configurar blast zones (top/bottom/left/right).
- [ ] Configurar spawn points de inicio y respawn.

## Epic #11 - BattleManager Stocks Timer Winner

- [ ] Logica stock-- y decision respawn/game over.
- [ ] Resolucion de winner por timer/stock.
- [ ] Integracion de salida a pantalla Victory.

## Epic #12 - Data Model Character/MoveSet/Attack

- [ ] Cerrar campos finales de CharacterData.
- [ ] Cerrar slots finales de MoveSet.
- [ ] Cerrar campos finales de AttackData.

## Epic #13 - Character Instances and Selection Pipeline

- [ ] Guardar seleccion P1/P2 en GameManager.
- [ ] Cargar CharacterData en Battle y configurar ambos players.

## Epic #14 - UI Main Loop HUD Pause Victory

- [ ] Navegacion MainMenu -> CharacterSelect -> Battle.
- [ ] HUD conectado a porcentaje/stocks/timer reales.
- [ ] Comportamiento de Pause y Victory.

## Epic #15 - Integration Smoke Tests and Hardening

- [ ] Ejecutar checklist smoke test completo.
- [ ] Corregir bloqueantes criticos detectados.

## Epic #16 - Post-MVP Gacha Boundary

- [ ] Marcar gacha como Post-MVP en docs/flujo.
- [ ] Definir interfaz futura sin acoplar al core de combate.

## Regla obligatoria

Todo issue granular debe incluir Architecture Check y respetar 00-architecture-guardrails.md.
