# Magnet-o

Plataformero 2D hecho en **Godot 4.6** donde controlas a **Mag-Boy**, un personaje con polaridad magnética capaz de atraer y repeler cajas metálicas para resolver el nivel.

---

## Tabla de contenidos

- [Requisitos](#requisitos)
- [Instalación de Godot](#instalación-de-godot)
  - [Windows](#windows)
  - [macOS](#macos)
- [Cómo ejecutar el proyecto](#cómo-ejecutar-el-proyecto)
- [Controles](#controles)
- [Funciones actuales](#funciones-actuales)
- [Nivel 1 — puzzles](#nivel-1--puzzles)
- [Enemigos](#enemigos)
- [Coleccionables y peligros](#coleccionables-y-peligros)
- [Audio](#audio)
- [Arte temporal (sprites)](#arte-temporal-sprites)
- [Menú y flujo](#menú-y-flujo)
- [Overlay de rendimiento](#overlay-de-rendimiento-información-técnica-en-ejecución)
- [Exportar a ejecutable](#exportar-a-ejecutable)
- [Métricas técnicas (slides)](#métricas-técnicas-slides)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Estado vs la propuesta](#estado-vs-la-propuesta)
- [Hoja de ruta (entregables)](#hoja-de-ruta-entregables)

---

## Requisitos

- **Godot Engine 4.6** (o superior, rama 4.x).
- **Sistema operativo:** Windows 10/11 o macOS 11+.
- **GPU:** cualquier tarjeta compatible con OpenGL 3.3 / Direct3D 12 (el proyecto usa el renderer *GL Compatibility*).
- ~150 MB libres en disco (Godot + proyecto).

> No necesitas actualmente .NET / Mono. El proyecto está escrito en **GDScript**, así que basta con la versión estándar de Godot.

---

## Instalación de Godot

### Windows

1. Entra a la página oficial de descargas: <https://godotengine.org/download/windows/>.
2. Descarga la versión **Godot 4.6 — Standard (GDScript)**. Si tu equipo es de 64 bits (lo normal), elige el `.zip` que dice `Win64`.
3. Descomprime el `.zip` en una carpeta a tu elección, por ejemplo `C:\Godot\`.
4. Dentro encontrarás un ejecutable llamado algo como `Godot_v4.6-stable_win64.exe`. **Haz doble clic** para abrirlo. No requiere instalación.
5. (Opcional) Crea un acceso directo en el escritorio o ánclalo a la barra de tareas para abrirlo más rápido.

> Si Windows muestra un aviso de SmartScreen, haz clic en **"Más información" → "Ejecutar de todas formas"**. El binario es seguro porque proviene del sitio oficial.

### macOS

1. Entra a la página oficial de descargas: <https://godotengine.org/download/macos/>.
2. Descarga la versión **Godot 4.6 — Standard (GDScript)** (`.dmg` universal para Apple Silicon e Intel).
3. Abre el `.dmg` descargado y arrastra **Godot.app** a la carpeta **Aplicaciones**.
4. La primera vez que lo abras, macOS puede bloquear la app por venir de un desarrollador no identificado. Si ocurre:
   - Ve a **Ajustes del Sistema → Privacidad y Seguridad**.
   - Baja hasta el aviso sobre Godot y pulsa **"Abrir de todas formas"**.
5. Listo: Godot se abrirá mostrando el *Project Manager*.

---

## Cómo ejecutar el proyecto

1. **Clona el repositorio** (o descárgalo como `.zip` y descomprímelo):

   ```bash
   git clone https://github.com/<tu-usuario>/magnet-o.git
   cd magnet-o
   ```

2. **Abre Godot.** En el *Project Manager* haz clic en **Import**.
3. Navega hasta la carpeta `magnet-o/` que clonaste y selecciona el archivo `project.godot`. Luego pulsa **Import & Edit**.
4. Una vez cargado el editor, presiona **F5** (o el botón ▶ "Play" arriba a la derecha) para ejecutar el juego. La escena principal es `scenes/MainMenu.tscn` (el menú); desde **Jugar** se carga `scenes/Level1.tscn`. La escena de pruebas `scenes/TestLevel.tscn` sigue disponible como sandbox.
5. Para correr una escena específica que tengas abierta, usa **F6**.

> La primera vez Godot importará los recursos y compilará shaders; puede tardar unos segundos. La carpeta `.godot/` que aparece se genera localmente y está ignorada por git.

---

## Controles

| Acción                                | Tecla / Botón                         |
| ------------------------------------- | ------------------------------------- |
| Mover izquierda                       | `A` o `←`                             |
| Mover derecha                         | `D` o `→`                             |
| Saltar                                | `Espacio`, `W` o `↑`                  |
| Polaridad **azul** (atraer)           | `J` o **clic izquierdo** (mantener)   |
| Polaridad **roja** (repeler)          | `K` o **clic derecho** (mantener)     |
| Cambiar de caja seleccionada (mientras atraes) | `Shift`                      |
| Panel técnico completo                | **`Tab`** (o `` ` `` / `F3`)          |
| Reiniciar nivel                       | `R`                                   |
| Volver al menú principal              | `Esc`                                 |

El núcleo del personaje cambia de color según la polaridad activa: ámbar (neutro), azul (atraer), rojo (repeler).

> **Nota macOS:** la tecla principal del panel técnico es **`Tab`** (funciona en cualquier teclado). `F3` no sirve en Mac porque lo intercepta *Mission Control*, y el acento grave (`` ` ``) es tecla muerta en teclados español/latino. Además, una **lectura mini de FPS/ms/RAM está siempre visible** arriba a la derecha.

---

## Funciones actuales

### Personaje (Mag-Boy)
- Movimiento de plataforma 2D con `CharacterBody2D`: aceleración, fricción y control aéreo configurables (`air_control = 0.6`).
- Salto con detección de suelo (`is_on_floor()`).
- Velocidad base: `220 px/s`. Salto: `-420 px/s`. Gravedad heredada del proyecto (`980 px/s²`).

### Sistema magnético
- **Área de detección circular** (`MagnetArea`, radio `220`) que detecta cualquier `RigidBody2D` en rango.
- **Polaridad ATRAER (azul):** atrae **una sola caja** — la seleccionada — para permitir manipulación precisa.
  - Selección automática de la caja más cercana al activar la atracción.
  - `Shift` cicla entre todas las cajas en rango si hay varias.
  - Si la caja seleccionada sale del área, se deselecciona sola.
- **Polaridad REPELER (roja):** empuja **todas** las cajas dentro del área simultáneamente (útil para apartar varios objetos a la vez o lanzarlos).
- **Fuerza ajustada para los puzzles:** `magnet_force = 1800`, `magnet_falloff = 0.35`. Con la gravedad del proyecto (`980`) y caja `mass = 1`, esto da una fuerza neta hacia el imán de **+820** unidades al estar pegado y **+190** unidades al borde del radio — la caja se puede elevar en todo el alcance. Ambos parámetros siguen siendo `@export`, así que se afinan desde el inspector.
- **Rayos magnéticos**: mientras hay polaridad activa se dibuja un haz (azul al atraer, rojo al repeler) desde el jugador hacia cada caja afectada (`Player._draw`).
- Modo de depuración: `debug_magnetism` imprime distancias y fuerzas aplicadas en consola.

### Botones (pressure plates)
- `Area2D` que detecta cuando un cuerpo (jugador y/o caja metálica) se posa encima.
- Cambia de **rojo apagado** a **verde brillante** mientras está presionado.
- Bandera `requires_metal_box` para botones que **solo** aceptan cajas (forza al jugador a usar magnetismo en lugar de pisarlos).
- Notifica a un nodo destino (`target_path`) llamando `on_button_pressed()` / `on_button_released()`, o emite las señales `pressed` / `released` para conectarlas desde el editor.

### Puertas
- `StaticBody2D` con colisión que se activa/desactiva al instante.
- Parámetro `required_presses` (1 a 4): la puerta solo se abre cuando ese número de botones vinculados está presionado al mismo tiempo. Permite armar compuertas lógicas tipo **AND** con varios botones.
- `auto_close` controla si vuelve a cerrarse al perder presión (apagado en el Nivel 1 para que los puzzles avancen sin penalizar el regreso).
- Visual: opaca cuando está cerrada, traslúcida cuando está abierta.

### Zona de meta
- `Area2D` (`Goal`) que detecta al jugador (vía el grupo `player`, añadido automáticamente en `Player._ready`).
- Al activarse muestra una etiqueta de HUD configurable (`hud_label_path`) y emite la señal `reached` para poder encadenar lógica futura (cargar siguiente nivel, mostrar tiempo, etc.).

### Dron Centinela (vuela)
- `CharacterBody2D` **volador** (sin gravedad): flota alrededor de su altura de aparición con un leve vaivén y patrulla a izquierda/derecha hasta `patrol_distance`, rebotando en los límites o al chocar con una pared. Se inclina hacia su dirección de avance.
- Capa de física propia (`Enemy`, capa 4): no colisiona físicamente con el jugador ni con las cajas, pero sí con el suelo y paredes. La detección de impactos va por un `Area2D` (`HitArea`).
- **Condición de daño al jugador:** al entrar en contacto, llama `Player.respawn()` → el jugador vuelve a su posición inicial con velocidad y polaridad reseteadas.
- **Condición de muerte del enemigo:** muere si una `MetalBox` lo impacta con `linear_velocity.length() >= box_kill_speed` (250 por defecto). Esto se logra fácilmente con la polaridad **roja** (repulsión) — el imán convierte la caja en un proyectil.
- Modo `debug_enemy` imprime cada respawn y velocidad de impacto en consola.

### Respawn del jugador
- `Player._spawn_position` se guarda al inicio del nivel (en `_ready`).
- `Player.respawn()` reposiciona, anula `velocity` y limpia la caja seleccionada / polaridad activa. Disponible para cualquier sistema que necesite "matar" al jugador (enemigo, hazards, caídas, etc.).

### Cajas metálicas
- `RigidBody2D` (física 2D: `mass = 1`, amortiguación lineal/angular) manipulable por el imán.
- El sprite recibe un **tinte azul** (`modulate`) cuando la caja está **seleccionada** para ser atraída.
- Agregadas al grupo `metal_box` para futuras consultas globales.

### Nivel 1 (`Level1.tscn`, escena principal)
- Recorrido lineal con dos puertas que requieren resolver puzzles para abrirse.
- HUD permanente con controles + pistas por puzzle + banner "¡NIVEL COMPLETADO!" al llegar a la meta.
- Cámara que sigue al jugador con `position_smoothing` para que el scroll lateral sea suave.

### Nivel de prueba (`TestLevel.tscn`)
- Suelo, paredes laterales y 3 plataformas estáticas (`StaticBody2D`).
- 5 cajas metálicas distribuidas para experimentar con atraer/repeler.
- Se mantiene como **sandbox** para iterar mecánicas sin afectar el flujo del nivel principal.

### Configuración técnica
- Resolución base **1280×720** con stretch `canvas_items` (escala manteniendo aspecto).
- Renderer: **GL Compatibility** (compatible con hardware antiguo y web).
- Físicas 3D: **Jolt Physics** (aunque el juego es 2D actualmente).
- Capas de física: `World` (1), `MetalBox` (2), `Player` (3). Los botones detectan máscara `6` (capas 2 + 3); la meta detecta solo al jugador (máscara `4`).

---

## Nivel 1 — puzzles

El nivel se atraviesa de izquierda a derecha y combina dos retos:

### Puzzle 1 · La caja sobre el botón
1. Cerca del spawn hay una **caja metálica** y un **botón rojo** que solo acepta cajas.
2. Mantén **J** (o clic izquierdo) cerca de la caja para atraerla y arrástrala sobre el botón.
3. La puerta morada se vuelve translúcida y permite pasar a la siguiente sala.

### Puzzle 2 · Dos botones simultáneos
1. En la segunda sala hay **dos botones** conectados a la misma puerta (`required_presses = 2`).
2. Uno está en el suelo (lo activa el jugador o una caja); el otro está sobre una **plataforma elevada** y solo lo activan cajas.
3. Atrae la caja a la plataforma, suelta la atracción para que caiga sobre el botón y luego camina hasta el botón del suelo. Mientras los dos sigan presionados, la segunda puerta queda abierta.

### Meta
- Cruzar la segunda puerta y tocar el **estandarte verde** dispara el cartel "¡NIVEL COMPLETADO!".

> Hay un **enemigo rojo patrullando** la sala 2. Si te toca, vuelves al spawn (las puertas ya abiertas siguen abiertas porque `auto_close = false`). Para eliminarlo, repele una caja contra él.

---

## Enemigos

- **Dron Centinela (`Enemy.tscn`)**: robot **volador** que flota y patrulla horizontalmente alrededor de su spawn (`patrol_distance` configurable), tal como en la propuesta. No dispara; el impacto con el jugador lo respawnea. Muere si lo golpea una caja a más de `box_kill_speed` (250 px/s por defecto).
- **Capa de física `Enemy` (4)**: separada de Player (3) y MetalBox (2) para evitar enganches físicos. Toda la interacción pasa por su `HitArea`.
- Forma sencilla de derrotarlo en el Nivel 1: párate cerca de una caja, mantén **K** (repulsión) apuntando hacia el dron — la caja sale disparada y supera el umbral de velocidad. Al destruirlo hace un pequeño *pop*.

---

## Coleccionables y peligros

- **Engranajes dorados (`Collectible.tscn`)**: 3 repartidos por el nivel; el HUD muestra `Engranajes: X / N`. Suenan al recogerse y desaparecen con un pop. El contador vive en el autoload `Game`.
- **Pozo de ácido (`AcidPool.tscn`)** y **láser de seguridad (`Laser.tscn`)**: peligros que reinician al jugador al contacto (script común `Hazard.gd`). El láser **parpadea** para cruzarlo con *timing*. Forman un pequeño *gauntlet* en el tramo final antes de la salida.
- **Victoria / derrota**: al llegar a la meta aparece el panel de victoria con los engranajes recogidos; al morir, un **flash rojo + "¡REINICIANDO!"** y respawn. El autoload `Game` emite las señales y `Level.gd` actualiza el HUD.

---

## Audio

- **Autoload `Audio`** (`scripts/AudioManager.gd`): pool de reproductores para SFX, un canal para la música y otro para el zumbido del imán. Sigue sonando durante la pausa.
- **SFX:** `jump.wav` (salto) y `magnet.wav` (zumbido en bucle mientras hay polaridad activa).
- **Música:** `music.wav` en bucle; arranca en el menú y en el nivel.
- Los `.wav` son **placeholder sintetizados** (ver `tools/gen_assets.py`), pensados para reemplazarse por audio final sin tocar código: basta sustituir los archivos en `assets/audio/`.

---

## Arte temporal (sprites)

Estética **industrial 16-bits** según la propuesta (gris oscuro + óxido, verde de salida, azul/rojo saturados para el magnetismo). Todo generado por código en `assets/sprites/` con `python3 tools/gen_assets.py` (requiere `pillow` y `numpy`).

- **`player.png`** — Mag-Boy: casco, visor cian, antena con luz y un **socket** central donde brilla el núcleo.
- **`core.png`** — orbe del núcleo (`Sprite2D` superpuesto) que se **tiñe** azul/rojo/ámbar según la polaridad (`modulate`).
- **`box.png`** — caja metálica con bisel, remaches, óxido y franjas magnéticas azul/roja; al seleccionarla se resalta con un tinte.
- **`enemy.png`** — Dron Centinela con rotor y sensor rojo.
- **`bg_factory.png`** — fondo de la fábrica (2600×1000): paneles con remaches, tuberías, vigas con franjas de peligro, luces de neón de emergencia, resplandor verde de salida y pozo de metal fundido, con grano y viñeta.
- El **escenario** jugable (suelo, paredes, plataformas) usa `Polygon2D` recoloreados a metal oscuro con **borde ámbar de advertencia**; la migración a Tilemap sigue pendiente (opcional).
- Los `Sprite2D` usan **filtro Nearest** (`texture_filter`) para que el pixel-art se vea nítido. Es arte **temporal**: sustituir los PNG por el pixel-art final no requiere tocar código.

---

## Menú y flujo

- **`MainMenu.tscn`** es la escena principal: botones **Jugar** y **Salir** (`scripts/MainMenu.gd`).
- Dentro del nivel (`scripts/Level.gd`): **R** reinicia el nivel y **Esc** vuelve al menú.

---

## Overlay de rendimiento (información técnica en ejecución)

- **Autoload `PerfOverlay`** (`scripts/PerfOverlay.gd`).
- **Lectura mini siempre visible** (arriba a la derecha): **FPS · ms/frame · RAM**. Así el dato técnico está presente durante toda la partida y la demo.
- **Panel completo** con **`Tab`** (o `` ` `` / `F3`): añade **CPU (proceso) ms, física ms, VRAM, draw calls y objetos en frame** (vía la API `Performance` de Godot).
- En **macOS** usa **`Tab`**: `F3` lo captura Mission Control y el acento grave es tecla muerta en teclados español/latino.
- Es la herramienta para capturar los datos técnicos del informe del profesor (ver [`docs/SLIDES_METRICAS.md`](docs/SLIDES_METRICAS.md)).

---

## Exportar a ejecutable

Para generar el binario (MVP) que evaluará el profesor:

1. En Godot: **Editor → Manage Export Templates… → Download and Install** (solo la primera vez).
2. **Project → Export…** y añade un preset:
   - **Windows Desktop** → genera `Magnet-o.exe`.
   - **macOS** → genera `Magnet-o.app` / `.dmg` / `.zip`.
3. Pulsa **Export Project**, elige carpeta y nombre.
4. Ejecuta el archivo resultante. En macOS puede pedir *Privacidad y Seguridad → Abrir de todas formas* la primera vez.

> El ejecutable empaqueta todo (escenas, scripts y `assets/`); no necesita Godot instalado para correr.

---

## Métricas técnicas (slides)

El profesor pide un deck con **FPS, Frames/ms, tiempo de render y RAM**. El overlay (**`Tab`**) muestra esos valores en vivo; la guía para capturarlos y el guion completo de las diapositivas está en **[`docs/SLIDES_METRICAS.md`](docs/SLIDES_METRICAS.md)**.

---

## Estructura del proyecto

```
magnet-o/
├── project.godot          # Configuración del proyecto (autoloads, main_scene, capas)
├── icon.svg               # Ícono de la app
├── assets/
│   ├── sprites/           # player, core, box, enemy, gear, hazard + bg_factory
│   └── audio/             # jump, magnet, music, gear, hurt (sintetizados)
├── scenes/
│   ├── MainMenu.tscn      # Menú principal (escena de inicio)
│   ├── Level1.tscn        # Nivel principal (puzzles + dron + peligros + meta)
│   ├── TestLevel.tscn     # Sandbox de mecánicas
│   ├── Player.tscn        # Mag-Boy (CharacterBody2D + Sprite2D + área magnética)
│   ├── MetalBox.tscn      # Caja metálica (RigidBody2D + Sprite2D)
│   ├── Button.tscn        # Botón de presión (Area2D)
│   ├── Door.tscn          # Puerta vinculada a botones (StaticBody2D)
│   ├── Goal.tscn          # Zona de meta (Area2D)
│   ├── Enemy.tscn         # Dron Centinela volador (CharacterBody2D + HitArea)
│   ├── Collectible.tscn   # Engranaje dorado (Area2D)
│   ├── AcidPool.tscn      # Pozo de ácido (Area2D, Hazard)
│   └── Laser.tscn         # Láser de seguridad parpadeante (Area2D, Hazard)
├── scripts/
│   ├── Player.gd          # Movimiento, magnetismo, rayos, respawn, audio
│   ├── MetalBox.gd        # Selección de la caja (tinte)
│   ├── Button.gd          # Detección de presión y notificación al target
│   ├── Door.gd            # Lógica AND de botones (required_presses)
│   ├── Goal.gd            # Trigger de fin de nivel
│   ├── Enemy.gd           # Dron volador: patrulla + daño + muerte por caja
│   ├── Collectible.gd     # Engranaje recogible
│   ├── Hazard.gd          # Peligro (ácido/láser) que respawnea
│   ├── MainMenu.gd        # Botones del menú
│   ├── Level.gd           # Flujo del nivel (HUD, victoria/derrota, R, Esc)
│   ├── Game.gd            # Autoload de estado (engranajes, señales)
│   ├── AudioManager.gd    # Autoload de audio (SFX + música)
│   └── PerfOverlay.gd     # Autoload de métricas (mini + panel)
├── tools/
│   └── gen_assets.py      # Generador de sprites + fondo + audio
└── docs/
    ├── CODIGO.md          # Explicación del código (arquitectura, scripts, flujo)
    └── SLIDES_METRICAS.md # Guion de slides + cómo medir FPS/RAM/render
```

---

## Estado vs la propuesta

Verificación frente a `Propuesta de Videojuego` (Magnet-O: Escape de la Fábrica).

| Elemento de la propuesta | Estado | Nota |
|--------------------------|--------|------|
| Movimiento (correr/saltar) | ✅ | Con animación procedural básica. |
| Polaridad Azul (atraer) / Roja (repeler) | ✅ | Mecánica central. |
| Apilar cajas / alcanzar zonas altas | ✅ | Física de cajas. |
| Lanzar caja contra enemigo para destruirlo | ✅ | Dron muere por impacto de caja. |
| Cajas metálicas + botones de presión + puertas | ✅ | Botones con lógica AND. |
| Enemigo: Dron Centinela **volador**, patrulla, daño al contacto | ✅ | Ahora vuela (antes caminaba). |
| Meta / "Salida Segura" + reinicio al recibir daño | ✅ | Meta + respawn. |
| Estilo industrial (óxido, neón, azul/rojo saturado) | ✅ | Sprites + fondo de fábrica. Arte **temporal**, no el pixel-art final. |
| Menú principal + victoria + derrota | ✅ | Menú, panel de victoria (con engranajes) y feedback de derrota (flash + "¡REINICIANDO!"). |
| Info técnica en ejecución (FPS/ms/RAM) | ✅ | Mini siempre visible + panel completo (`Tab`). |
| Sonido básico (salto, imán, música) | ✅ | WAVs sintetizados (temporales) + pickup y daño. |
| Coleccionables (engranajes dorados) | ✅ | 3 engranajes + contador en el HUD. |
| Peligros: láseres de seguridad / ácido | ✅ | Láser parpadeante + pozo de ácido en el tramo final. |
| **Pixel art final + fondos definitivos** | ❌ | Arte actual es temporal generado por código. |
| **4 habitaciones progresivas (tutorial→final)** | ⚠️ | Hay 1 nivel que combina las mecánicas (el MVP permite "1 nivel grande o 3 habitaciones"). |
| Tilemaps para el escenario | ⚠️ | Hoy `Polygon2D`; pendiente opcional. |
| GDScript **con C#** | ⚠️ | Solo GDScript (suficiente para el MVP). |
| Ejecutable (.exe/.app) | 📋 | Pasos en este README; lo exportas desde Godot. |

---

## Hoja de ruta (entregables)

| Entregable | Estado | Contenido |
|------------|--------|-----------|
| 1 · Prototipo de mecánica | ✅ | Movimiento de plataforma + magnetismo con polaridad dual. |
| 2 · Cajas e interacción | ✅ | `MetalBox` con selección y ciclo de objetivo (`Shift`). |
| **3 · Nivel y enemigos** *(12/05/2026)* | ✅ | Botones, puertas con lógica AND, zona de meta, enemigo patrullero (daño + muerte por caja), respawn, **Nivel 1 jugable de inicio a fin**. Pendiente opcional: migrar el escenario a Tilemap (hoy usa polígonos). |
| **4 · Pulido y entrega** | 🟡 *en curso* | Hecho: **arte industrial** (sprites + fondo + escenario), **dron volador**, **animación procedural**, **rayos magnéticos**, **engranajes coleccionables**, **peligros** (láser + ácido), **victoria/derrota**, **audio**, **Menú Principal**, **info técnica en ejecución**. Pendiente: **pixel-art definitivo**, exportar el `.exe`/`.app`, y rellenar los slides con tus números. |
