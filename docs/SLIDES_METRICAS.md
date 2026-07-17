# Slides técnicos — Magnet-o (Entregable 4)

Guion para los slides que pidió el profesor: **demo en ejecución + información
técnica** (FPS, Frames/ms, tiempo de render, RAM). Este documento te da la
estructura del deck y, sobre todo, **cómo capturar los números en tu máquina**
(los valores dependen de tu hardware, así que hay que medirlos, no inventarlos).

---

## 1. Cómo capturar las métricas

El juego trae un **overlay de rendimiento**: ejecuta el juego y pulsa **Tab**.
Muestra en vivo:

- **FPS** — cuadros por segundo.
- **Frame (ms)** — milisegundos por cuadro (1000 / FPS).
- **CPU (proceso, ms)** — tiempo de CPU del hilo principal por cuadro.
- **Física (ms)** — tiempo del paso de física por cuadro.
- **RAM estática (MB)** — memoria reservada por el juego.
- **VRAM (MB)** — memoria de video usada.
- **Draw calls / Objetos en frame** — carga de render.

> Internamente usa la API `Performance` de Godot (`Performance.get_monitor(...)`),
> que es la misma fuente que el panel *Monitor* del editor.

### Procedimiento sugerido
1. Ejecuta el **ejecutable exportado** (no el editor) para números realistas, o
   en su defecto corre con F5 en modo *Release/Fast*.
2. Ve a un momento representativo: **Level4** (paredes magnéticas + torreta +
   2 drones + partículas) o la sala más cargada de Level1. Es donde hay más carga.
3. Pulsa **Tab** y observa ~30 segundos jugando normal.
4. Anota **mínimo / promedio / máximo** de FPS y frame-time.
5. Toma una **captura de pantalla** con el overlay visible (sirve como evidencia
   en el slide).

### Datos de tu sistema (para el slide de especificaciones)
- **Windows:** `Win + R` → `dxdiag` (CPU, RAM, GPU); Administrador de tareas →
  pestaña *Rendimiento* (uso de RAM).
- **macOS:**  → *Acerca de esta Mac* (chip, memoria); *Monitor de Actividad* →
  pestaña *Memoria* (RAM usada por el proceso Magnet-o).

---

## 2. Estructura del deck (8 slides)

### Slide 1 — Portada
- Título: **MAGNET-O — Prototipo / MVP**
- Integrantes, curso, fecha.
- Captura del menú principal o del Nivel 1.

### Slide 2 — Concepto
- Plataformero 2D donde controlas a **Mag-Boy**, con **polaridad magnética**
  (atrae / repele cajas metálicas) para resolver puzzles y enfrentar enemigos.
- 1 frase de "fantasía de jugador".

### Slide 3 — Mecánicas implementadas
- Movimiento de plataforma (acel./fricción/control aéreo + coyote time / jump buffer).
- Imán dual: **atraer** (caja seleccionada) / **repeler** (todas en rango).
- **Paredes magnéticas**: dash/rebote en el aire (foco de Level4).
- **Botones** (pressure plates) + **puertas** con lógica AND.
- **Enemigos**: dron volador (contacto) y **torreta** (dispara proyectiles).
- Coleccionables (engranajes), peligros (ácido/láser), meta y reinicio.
- **4 niveles** encadenados + créditos, con guardado y menú de pausa.

### Slide 4 — Arquitectura técnica
- **Motor:** Godot 4.7 · **Lenguaje:** GDScript · **Render:** GL Compatibility.
- **Física:** 2D integrada (gravedad 980, capas World/MetalBox/Player/Enemy).
- **Autoloads (6):** `Audio`, `PerfOverlay`, `Game` (estado/progresión/guardado),
  `Fx` (juice/transiciones), `Pause`, `Vfx`.
- Flujo de escenas: `MainMenu → Level1 → 2 → 3 → 4 → Créditos`.

### Slide 5 — Metodología de medición
- Herramienta: overlay propio (Tab) basado en `Performance` API.
- Escena medida: **Level4** (la de mayor carga) o la sala más pesada de Level1.
- Build: exportado (Release) / resolución 1280×720.
- Ventana de muestreo: ~30 s de juego normal.

### Slide 6 — Resultados de rendimiento (RELLENAR)

| Métrica                     | Mín | Promedio | Máx |
|-----------------------------|-----|----------|-----|
| FPS                         |     |          |     |
| Frame (ms)                  |     |          |     |
| CPU proceso (ms)            |     |          |     |
| Física (ms)                 |     |          |     |
| RAM estática (MB)           |     |          |     |
| VRAM (MB)                   |     |          |     |
| Draw calls                  |     |          |     |
| Objetos en frame            |     |          |     |

> Pega aquí la captura del overlay (Tab) como evidencia.

### Slide 7 — Sistema de prueba (RELLENAR)

| Componente        | Especificación |
|-------------------|----------------|
| CPU               |                |
| GPU               |                |
| RAM total         |                |
| Sistema operativo |                |
| Resolución        | 1280×720       |
| Versión de Godot  | 4.7            |
| Tipo de build     | Exportado / Editor |

### Slide 8 — Conclusiones y próximos pasos
- Estado: MVP jugable de inicio a fin con todas las mecánicas.
- Observaciones de rendimiento (¿estable a 60 FPS?, ¿cuellos de botella?).
- Próximos pasos: arte final, migración a Tilemap, más niveles, audio definitivo.

---

## 3. Checklist de la demo en vivo
- [ ] Abrir el **ejecutable** (no el editor).
- [ ] Mostrar el **Menú Principal** → Jugar.
- [ ] Resolver **Puzzle 1** (caja sobre botón).
- [ ] Mostrar **enemigo**: morir una vez (respawn) y luego **eliminarlo con una caja**.
- [ ] Resolver **Puzzle 2** (dos botones) y llegar a la **meta**.
- [ ] Pulsar **Tab** y comentar las métricas en pantalla.
- [ ] Mostrar **R** (reiniciar) y **Esc** (volver al menú).
