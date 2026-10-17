# Guía de Animación y Poses para Juegos de Lucha (Fighting Games)

## 1. Regla de Oro: Claridad de Silueta
En un juego de plataformas/peleas como *Smash en Casa*, la acción transcurre en un plano 2D/2.5D a gran velocidad.
- **Evitar solapamientos:** Los brazos, piernas y armas deben extenderse fuera de la masa central del torso en los fotogramas activos.
- **Línea de acción:** Toda pose debe tener una curva dominante clara (en "C", en "S" o diagonal rígida).
- **Asimetría dinámica:** No colocar las extremidades en posiciones idénticas a menos que sea un ataque deliberadamente simétrico.

---

## 2. Los 3 Bloques Clave de un Ataque

```
[ Antagonismo / Startup ]  ──►  [ Impacto / Active ]  ──►  [ Recuperación / Recovery ]
    - Comprime el cuerpo            - Máxima extensión           - Retorno al centro
    - Muestra la intención           - Hitbox activa              - Inercia secundaria
    - Squash                         - Stretch + Hitlag           - Settle
```

---

## 3. Hitlag y Congelación de Fotograma (Hitstop)
Cuando un golpe conecta:
- **Pose estática (Hold):** El personaje atacante y el receptor se congelan en la pose extrema durante varios fotogramas (ej. 4 a 12 frames según el daño).
- **Sacudida (Camera Shake & Shiver):** Pequeño temblor procedural en el eje local del atacante y víctima para transmitir potencia cinética.

---

## 4. Reacciones de Daño (Hitstun)
- **Impacto Ligero (Light Hit):** Retracción rápida del torso hacia atrás (5-10°), recuperación instantánea.
- **Impacto Fuerte (Heavy Hit):** Espina dorsal arqueada hacia atrás (-25°), cabeza retrasada por inercia, brazos hacia afuera.
- **Lanzamiento / Knockback:** Poses de tumbling o espiral en el aire según el ángulo de lanzamiento (Knockback Angle).
