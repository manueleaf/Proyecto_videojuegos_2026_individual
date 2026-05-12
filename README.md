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
- [Estructura del proyecto](#estructura-del-proyecto)
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
4. Una vez cargado el editor, presiona **F5** (o el botón ▶ "Play" arriba a la derecha) para ejecutar el juego. La escena principal `scenes/Level1.tscn` ya está configurada como entry point. La escena de pruebas `scenes/TestLevel.tscn` sigue disponible como sandbox.
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

El núcleo del personaje cambia de color según la polaridad activa: amarillo (neutro), azul (atraer), rojo (repeler).

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

### Cajas metálicas
- `RigidBody2D` con física Jolt habilitada.
- Estado visual: la marca interior se ilumina en azul claro cuando la caja está **seleccionada** para ser atraída.
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

---

## Estructura del proyecto

```
magnet-o/
├── project.godot          # Configuración del proyecto Godot
├── icon.svg               # Ícono de la app
├── scenes/
│   ├── Level1.tscn        # Nivel principal (puzzles de botones + meta)
│   ├── TestLevel.tscn     # Sandbox de mecánicas
│   ├── Player.tscn        # Mag-Boy (CharacterBody2D + área magnética)
│   ├── MetalBox.tscn      # Caja metálica (RigidBody2D)
│   ├── Button.tscn        # Botón de presión (Area2D)
│   ├── Door.tscn          # Puerta vinculada a botones (StaticBody2D)
│   └── Goal.tscn          # Zona de meta (Area2D)
└── scripts/
    ├── Player.gd          # Movimiento, magnetismo y selección de cajas
    ├── MetalBox.gd        # Estado visual y selección de la caja
    ├── Button.gd          # Detección de presión y notificación al target
    ├── Door.gd            # Lógica AND de botones (required_presses)
    └── Goal.gd            # Trigger de fin de nivel
```

---

## Hoja de ruta (entregables)

| Entregable | Estado | Contenido |
|------------|--------|-----------|
| 1 · Prototipo de mecánica | ✅ | Movimiento de plataforma + magnetismo con polaridad dual. |
| 2 · Cajas e interacción | ✅ | `MetalBox` con selección y ciclo de objetivo (`Shift`). |
| **3 · Nivel y enemigos** *(12/05/2026)* | 🟡 *en curso* | Hecho: botones, puertas con lógica AND, zona de meta, Nivel 1 jugable de principio a fin con 2 puzzles encadenados. Pendiente: enemigo básico con patrullaje + daño y migración del escenario a Tilemap. |
| 4 · Arte final + audio | 🔜 | Sustituir polígonos por sprites, añadir SFX y música. |
