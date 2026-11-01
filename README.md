# Smash en Casa (`Smash-en-casa-SC-`)

**Autores:** Rodrigo Espinoza Squef y Pablo Chiavetta Chavez  
**Asignatura:** Programación 4  
**Motor:** Godot Engine 4.7

---

## Descripción General

Videojuego de combate en plataformas **2.5D** (*Platform Fighter* inspirado en *Super Smash Bros.* y *Dragon Ball FighterZ*) para **2 a 4 jugadores locales en simultáneo**, con física determinista en 2D a 60 FPS y renderizado 3D en tiempo real.

### Características Principales
- **6 Luchadores Jugables Orientados a Datos (`.tres`)**: Lego Batman, Sakuya Izayoi (*Time Stop*), Gogeta SSJ, Miyabi Hoshimi, Hornet (*Sistema de Carretes de Seda*) y John Placeholder / Sans, más selección Aleatoria (`?`).
- **3 Escenarios Dinámicos**: *Santuario Astral*, *Cámara Cibernética* y *Caldera Ardiente*.
- **Multijugador de 2 a 4 Jugadores**: Soporte completo para hasta 4 mandos de Xbox / Gamepads y teclado compartido.
- **Configuración de Controles Estilo Yuzu**: Remapeo interactivo por jugador, vista previa vectorial en vivo del mando de Xbox, ajuste de *Deadzone* / *Range*, prueba de vibración, mezclador de 4 canales de audio y gestión de perfiles.
- **Leaderboard Persistente por Perfiles**: Tabla de clasificación automática con podio, victorias, derrotas, *Win Rate %* y luchador favorito.

---

## Controles Predeterminados Rápidos

| Acción | Mando Xbox (P1–P4) | Teclado P1 | Teclado P2 |
| :--- | :--- | :--- | :--- |
| **Moverse / Apuntar** | Stick Izquierdo / D-Pad | `W` `A` `S` `D` | Flechas Direccionales |
| **Saltar / Doble Salto** | `A` (o `Y` alt.) | `Espacio` | `Numpad 0` / `B` |
| **Ataque Normal / Aéreo** | `X` | `J` | `N` / `Numpad 1` |
| **Ataque Especial** | `B` | `K` | `M` / `Numpad 2` |
| **Escudo / Esquive (Dodge)** | `LB` / `RB` / `LT` / `RT` | `L` / `Shift` | `Numpad 3` |
| **Pausa** | `Start` (`Menu`) | `Escape` | `Enter` |

*(Todos los controles pueden personalizarse y guardarse por perfil desde **Opciones -> Controles**).*

---

## Documentación para Estudio y Presentación

- **[Guía de Estudio y Defensa Oral (`Analisis.md`)](./Analisis.md)**: Explicación pedagógica de los patrones de diseño (Singleton, Observer, State/FSM, Facade + Composición, Data-Driven), orden sugerido de lectura del código y preguntas típicas de presentación.
- **[Arquitectura Técnica Detallada (`smash-en-casa/ARCHITECTURE.md`)](./smash-en-casa/ARCHITECTURE.md)**: Mapa completo de carpetas y scripts, arquitectura híbrida 2.5D y diagramas de secuencia del motor de combate.

---

## Ejecución del Proyecto

1. Abrir **Godot Engine 4.7**.
2. Importar el archivo `smash-en-casa/project.godot`.
3. Presionar **F5** (escena principal: `res://ui/main_menu.tscn`).
