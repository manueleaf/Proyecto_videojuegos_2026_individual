# Magnet-o — Explicación del código

Documento técnico de cómo está construido el juego: arquitectura, scripts,
escenas, señales, física y cómo extenderlo. Pensado para entender o continuar el
proyecto (y para sustentar la parte técnica del informe).

- **Motor:** Godot 4.6 · **Lenguaje:** GDScript · **Render:** GL Compatibility
- **Patrón general:** escenas pequeñas reutilizables (`Player`, `MetalBox`,
  `Button`, `Door`, `Goal`, `Enemy`, `Collectible`, peligros) instanciadas dentro
  de un nivel, más **3 autoloads** (singletons) para estado, audio y métricas.

---

## Índice
- [Mapa del proyecto](#mapa-del-proyecto)
- [Autoloads (singletons)](#autoloads-singletons)
- [Capas de física](#capas-de-física)
- [El jugador (Player.gd)](#el-jugador-playergd)
- [Cómo funciona el magnetismo](#cómo-funciona-el-magnetismo)
- [Cajas (MetalBox.gd)](#cajas-metalboxgd)
- [Botones y puertas](#botones-y-puertas)
- [Dron Centinela (Enemy.gd)](#dron-centinela-enemygd)
- [Coleccionables y peligros](#coleccionables-y-peligros)
- [Meta y flujo del nivel](#meta-y-flujo-del-nivel)
- [HUD, victoria y derrota](#hud-victoria-y-derrota)
- [Menú principal](#menú-principal)
- [Generación de arte y audio](#generación-de-arte-y-audio)
- [Cómo extender el juego](#cómo-extender-el-juego)

---

## Mapa del proyecto

```
Autoloads (siempre vivos):  Game → Audio → PerfOverlay
Escena inicial:             MainMenu.tscn ──(Jugar)──▶ Level1.tscn
Level1 instancia:           Player, MetalBox×3, Button×3, Door×2, Enemy,
                            Collectible×3, AcidPool, Laser, Goal + HUD + fondo
```

Cada objeto del juego es una **escena** (`.tscn`) con su **script** (`.gd`). El
nivel los coloca y conecta por posición y por `NodePath`/grupos/señales.

---

## Autoloads (singletons)

Declarados en `project.godot → [autoload]`. Se cargan **antes** que cualquier
escena y son accesibles globalmente por su nombre (`Game`, `Audio`, `PerfOverlay`).

### `Game` (`scripts/Game.gd`)
Estado de la partida, desacoplado del HUD mediante **señales**:
- Variables: `gears_collected`, `gears_total`, `deaths`.
- Señales: `gears_changed(collected, total)`, `player_died()`, `level_won()`.
- Métodos: `reset_level(total)`, `collect_gear()`, `notify_death()`, `notify_win()`.

Quien provoca un evento (un engranaje, un peligro, la meta) **no conoce el HUD**:
sólo llama a `Game`, y `Level.gd` —que sí tiene el HUD— escucha las señales. Esto
mantiene los objetos simples y reutilizables.

### `Audio` (`scripts/AudioManager.gd`)
Gestiona todo el sonido:
- `PATHS`: diccionario nombre → ruta del `.wav` (`jump`, `magnet`, `music`,
  `gear`, `hurt`).
- Un **pool de 6 `AudioStreamPlayer`** para efectos solapados (`play_sfx`).
- Un canal de **música** (`play_music` / `stop_music`) y otro para el **zumbido
  del imán** (`set_magnet_active`).
- `_make_loop()` activa el bucle en los `AudioStreamWAV` de música e imán
  (calcula `loop_end` a partir del tamaño de datos).
- `process_mode = ALWAYS`: sigue sonando aunque el árbol se pause.

### `PerfOverlay` (`scripts/PerfOverlay.gd`)
Información técnica en ejecución (es un `CanvasLayer`):
- **Lectura mini** (`Label`) siempre visible arriba a la derecha: FPS · ms · RAM.
- **Panel completo** (`ColorRect` + `Label`) que se muestra/oculta con **`Tab`**
  (también `` ` `` o `F3`). Añade CPU (proceso) ms, física ms, VRAM, draw calls y
  objetos en frame.
- Lee todo con `Performance.get_monitor(...)` (la misma fuente que el panel
  *Monitor* del editor de Godot).

> En macOS el toggle es **`Tab`**: `F3` lo intercepta Mission Control y el acento
> grave es tecla muerta en teclados español/latino.

---

## Capas de física

Definidas en `project.godot → [layer_names]`. El **valor** de `collision_layer` /
`collision_mask` es un bitmask (capa 1 = 1, capa 2 = 2, capa 3 = 4, capa 4 = 8).

| Capa | Nombre   | La usan |
|------|----------|---------|
| 1    | World    | Suelo, paredes, plataformas, puertas |
| 2    | MetalBox | Cajas metálicas |
| 3    | Player   | Mag-Boy |
| 4    | Enemy    | Dron |

| Nodo | `layer` | `mask` | Detecta / colisiona con |
|------|---------|--------|--------------------------|
| Player (`CharacterBody2D`) | 4 (Player) | 3 (World+MetalBox) | Camina sobre el mundo y empuja cajas |
| MetalBox (`RigidBody2D`)   | 2 (MetalBox) | 7 (World+MetalBox+Player) | Choca con todo |
| Player → `MagnetArea` (`Area2D`) | — | 2 (MetalBox) | Detecta cajas en rango |
| Enemy cuerpo | 8 (Enemy) | 1 (World) | Sólo choca con paredes (vuela) |
| Enemy → `HitArea` | 0 | 6 (Player+MetalBox) | Detecta al jugador y a las cajas |
| Button / Goal / Collectible / Hazard | 0 | 4 (Player) o 6 | Detectan al jugador (y cajas en botones) |

La idea clave: el dron **no choca físicamente** con el jugador ni las cajas (capas
separadas); todo el contacto se resuelve por su `HitArea` (un `Area2D`). Así el
jugador "atraviesa" visualmente y el daño se decide por código.

---

## El jugador (Player.gd)

`Player.tscn` = `CharacterBody2D` con: `CollisionShape2D` (cápsula 28×44),
`Sprite` (cuerpo), `Core` (orbe que brilla según polaridad), `MagnetArea`
(círculo radio 220) y `Camera2D` (con suavizado y límites).

Cada `_physics_process(delta)` ejecuta, en orden:
1. `_handle_gravity` — aplica gravedad si no toca suelo.
2. `_handle_jump` — salta si está en suelo (+ SFX).
3. `_handle_horizontal_movement` — acelera/frena con `move_toward`; en el aire usa
   `air_control`.
4. `_handle_polarity_input` — fija la polaridad (ATTRACT/REPEL/NONE) según las
   teclas y arranca/para el zumbido del imán.
5. `_update_target_selection` — elige a qué caja atraer (ver abajo).
6. `_apply_magnetism` — aplica la fuerza y guarda la lista `_affected`.
7. `_update_visual_feedback` — colorea el núcleo (azul/rojo/ámbar).
8. `move_and_slide()` — mueve el cuerpo.
9. `_update_sprite_anim` — animación procedural (vaivén, inclinación, squash).
10. `queue_redraw()` — repinta los rayos del imán (`_draw`).

**Selección de objetivo (atraer):** sólo al atraer. Toma la caja más cercana en
rango; si la actual sale del rango se deselecciona; **`Shift`** cambia a la
siguiente caja en rango (cycle). Al seleccionar, llama `set_selected()` en la caja
para resaltarla.

**Respawn:** `respawn()` reubica al jugador en `_spawn_position`, limpia velocidad
y polaridad, suena `hurt` y llama `Game.notify_death()`. Lo invocan el dron y los
peligros.

**Rayos del imán (`_draw`):** mientras hay polaridad, dibuja una línea desde el
jugador a cada caja de `_affected` (azul al atraer, rojo al repeler), con un trazo
ancho translúcido + uno fino brillante + un círculo en la caja.

---

## Cómo funciona el magnetismo

En `_apply_magnet_force(body, is_attract)`:

```gdscript
var to_box   = body.global_position - global_position
var distance = to_box.length()
var dir      = to_box / distance
# falloff = 1 cuando magnet_falloff=0 (fuerza constante);
# decae linealmente con la distancia cuando magnet_falloff=1.
var falloff  = lerp(1.0, clamp(1.0 - distance / radio, 0.0, 1.0), magnet_falloff)
var fuerza   = magnet_force * falloff
body.apply_central_force((-dir if is_attract else dir) * fuerza)
```

Parámetros (exportados, editables en el inspector):
`magnet_force = 1800`, `magnet_falloff = 0.35`, radio del `MagnetArea = 220`.

**Por qué esos números:** con gravedad del proyecto `980` y caja `mass = 1`, la
fuerza neta hacia el imán es **+820** pegado y **+190** en el borde del radio →
la caja se puede **elevar en todo el alcance** (con 1500/0.4 anteriores, en el
borde la gravedad ganaba y el puzzle se sentía inconsistente).

- **Atraer:** sólo a la caja seleccionada (control preciso).
- **Repeler:** a **todas** las cajas en rango (sirve para lanzar una caja contra
  el dron y destruirlo).

---

## Cajas (MetalBox.gd)

`RigidBody2D` (masa 1, amortiguación lineal/angular) con `Sprite`. Está en el grupo
`metal_box`. `set_selected(true/false)` tiñe el sprite de azul (`modulate`) para
indicar que es el objetivo de atracción.

---

## Botones y puertas

**Button (`Button.gd`, `Area2D`):** detecta cuerpos encima. Bandera
`requires_metal_box` para aceptar **sólo cajas** (obliga a usar el imán). Cuando
cambia de estado avisa a `target_path` llamando `on_button_pressed()` /
`on_button_released()`, y emite las señales `pressed`/`released`. Cuenta cuántos
cuerpos válidos hay encima (`_bodies_on`).

**Door (`Door.gd`, `StaticBody2D`):** se abre cuando hay
`required_presses` botones pulsados a la vez (lógica **AND**, 1–4). Abrir/cerrar =
activar/desactivar su `CollisionShape2D` (con `set_deferred` para no chocar con el
flush de física) y cambiar la opacidad. `auto_close` decide si vuelve a cerrarse al
perder presión (apagado en el Nivel 1 para no penalizar el regreso).

Conexión en el nivel: cada botón apunta a su puerta por `target_path`
(p. ej. `../Door2`), y `Door2` tiene `required_presses = 2`.

---

## Dron Centinela (Enemy.gd)

`CharacterBody2D` **volador** (sin gravedad). En cada frame:
- Patrulla en X entre `spawn_x ± patrol_distance`; rebota en los límites o al
  chocar con una pared (`is_on_wall()`).
- Flota: `velocity.y` persigue `spawn_y + sin(t)·amplitud` (vaivén suave).
- Se inclina hacia su dirección de avance (`sprite.rotation`).

Su `HitArea` (`body_entered`) decide:
- **Jugador** → `body.respawn()` (daño al contacto).
- **Caja** con `linear_velocity.length() >= box_kill_speed` (250) → `_die()`.

`_die()` desactiva la física y el `HitArea`, hace un **pop** (escala + desvanecido
con `create_tween()`) y luego `queue_free()`.

---

## Coleccionables y peligros

**Collectible (`Collectible.gd`, `Area2D`)** — engranaje dorado. Está en el grupo
`gear`, gira lentamente y, al tocar el jugador: suma con `Game.collect_gear()`,
suena `gear`, y desaparece con un pop. `Level.gd` cuenta cuántos hay al iniciar
(`get_nodes_in_group("gear")`) para el total.

**Hazard (`Hazard.gd`, `Area2D`)** — script común de los peligros:
- Al tocar el jugador llama `respawn()`.
- Si `blink = true` (el láser) alterna activo/inactivo (`on_time`/`off_time`),
  oculta el nodo hijo `Beam` mientras está inactivo y, al reactivarse, comprueba si
  el jugador ya estaba dentro para alcanzarlo igual.
- Escenas: `AcidPool.tscn` (pozo verde, no parpadea) y `Laser.tscn` (haz rojo
  vertical que parpadea, con emisores arriba/abajo).

---

## Meta y flujo del nivel

**Goal (`Goal.gd`, `Area2D`)** — "Salida Segura". Al entrar el jugador, emite
`reached` y llama `Game.notify_win()` (una sola vez).

**Level (`Level.gd`, raíz de `Level1`)** — orquesta el nivel:
- En `_ready`: arranca la música, cuenta los engranajes y llama
  `Game.reset_level(total)`, y se **conecta a las señales** de `Game`.
- `_unhandled_input`: **R** recarga la escena (reiniciar), **Esc** vuelve al menú.

---

## HUD, victoria y derrota

`Level1` tiene un `CanvasLayer` (HUD) con: controles, pistas, contador de
engranajes, panel de victoria y un `DefeatFlash`. `Level.gd` reacciona a `Game`:

```
Game.gears_changed  → actualiza "Engranajes: X / N"
Game.player_died    → DefeatFlash visible + tween de alpha (flash rojo + "¡REINICIANDO!")
Game.level_won      → muestra "¡NIVEL COMPLETADO!" + subtítulo con engranajes y R/Esc
```

El flash de derrota es un `ColorRect` rojo semitransparente cuyo `modulate.a` se
anima de 1 → 0 con un `Tween`; su `Label` hijo se desvanece con él.

---

## Menú principal

`MainMenu.tscn` (`Control`) + `MainMenu.gd`: botones **Jugar**
(`change_scene_to_file` a `Level1.tscn`) y **Salir** (`get_tree().quit()`), y
arranca la música. Es la `main_scene` del proyecto.

---

## Generación de arte y audio

Todo el arte y el audio son **placeholder generados por código** con
`tools/gen_assets.py` (Python + Pillow + NumPy):
- Sprites pixel-art (jugador, núcleo, caja, dron, engranaje, franja) y el fondo
  `bg_factory.png`.
- WAVs sintetizados (salto, zumbido del imán, música en bucle, recoger, daño).

Reejecutar: `python3 tools/gen_assets.py`. Es **idempotente**: sobrescribe los
mismos archivos, así que para arte final basta **reemplazar los PNG/WAV** sin tocar
código ni escenas. Los `Sprite2D` usan `texture_filter = Nearest` para que el
pixel-art se vea nítido al escalar.

---

## Cómo extender el juego

- **Nuevo nivel:** duplica `Level1.tscn`, recoloca las piezas y añade el archivo a
  `MainMenu` (o encadena con `Game.level_won` para cargar el siguiente).
- **Nuevo enemigo:** crea una escena con `CharacterBody2D` + `HitArea`; reutiliza
  el patrón de `Enemy.gd` (patrulla + `respawn` al jugador).
- **Nuevo peligro:** instancia `AcidPool`/`Laser` o crea una `Area2D` con
  `Hazard.gd`.
- **Nuevo sonido:** añade el `.wav` a `assets/audio/`, regístralo en `PATHS` de
  `AudioManager.gd` y llama `Audio.play_sfx("nombre")`.
- **Arte final:** reemplaza los archivos en `assets/sprites/` (mismos nombres y
  tamaños aproximados); al abrir Godot se reimportan solos.
- **Ajustar dificultad:** propiedades exportadas en el inspector — `magnet_force`,
  `magnet_falloff`, `speed`, `jump_velocity` (Player); `speed`, `patrol_distance`,
  `box_kill_speed` (Enemy); `required_presses`, `auto_close` (Door); `on_time`,
  `off_time` (Laser).
