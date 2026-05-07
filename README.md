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
- [Estructura del proyecto](#estructura-del-proyecto)

---

## Requisitos

- **Godot Engine 4.6** (o superior, rama 4.x).
- **Sistema operativo:** Windows 10/11 o macOS 11+.
- **GPU:** cualquier tarjeta compatible con OpenGL 3.3 / Direct3D 12 (el proyecto usa el renderer *GL Compatibility*).
- ~150 MB libres en disco (Godot + proyecto).

> No necesitas .NET / Mono. El proyecto está escrito en **GDScript**, así que basta con la versión estándar de Godot.

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
4. Una vez cargado el editor, presiona **F5** (o el botón ▶ "Play" arriba a la derecha) para ejecutar el juego. La escena principal `scenes/TestLevel.tscn` ya está configurada como entry point.
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
- **Fuerza configurable** (`magnet_force = 1500`) con curva de caída opcional según distancia (`magnet_falloff`, lerp entre fuerza constante y decaimiento lineal).
- Modo de depuración: `debug_magnetism` imprime distancias y fuerzas aplicadas en consola.

### Cajas metálicas
- `RigidBody2D` con física Jolt habilitada.
- Estado visual: la marca interior se ilumina en azul claro cuando la caja está **seleccionada** para ser atraída.
- Agregadas al grupo `metal_box` para futuras consultas globales.

### Nivel de prueba (`TestLevel.tscn`)
- Suelo, paredes laterales y 3 plataformas estáticas (`StaticBody2D`).
- 5 cajas metálicas distribuidas para experimentar con atraer/repeler.
- HUD superior con la lista de controles siempre visible.
- Resolución base **1280×720** con stretch `canvas_items` (escala manteniendo aspecto).

### Configuración técnica
- Renderer: **GL Compatibility** (compatible con hardware antiguo y web).
- Físicas 3D: **Jolt Physics** (aunque el juego es 2D actualmente).
- Capas de física: `World` (1), `MetalBox` (2), `Player` (3).

---

## Estructura del proyecto

```
magnet-o/
├── project.godot          # Configuración del proyecto Godot
├── icon.svg               # Ícono de la app
├── scenes/
│   ├── TestLevel.tscn     # Escena principal (nivel de prueba)
│   ├── Player.tscn        # Mag-Boy (CharacterBody2D + área magnética)
│   └── MetalBox.tscn      # Caja metálica (RigidBody2D)
└── scripts/
    ├── Player.gd          # Lógica de movimiento y magnetismo
    └── MetalBox.gd        # Estado visual y selección de caja
```
