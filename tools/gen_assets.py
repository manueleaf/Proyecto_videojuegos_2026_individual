#!/usr/bin/env python3
"""Genera arte (pixel-art 16-bits) y audio para Magnet-o.

Estilo según la propuesta: fábrica de reciclaje industrial, gris oscuro + óxido,
verde fosforescente para salida/ácido, azul eléctrico y rojo carmesí saturados
para las mecánicas magnéticas.

Salidas en assets/sprites/ y assets/audio/. Reejecutable e idempotente.
Requiere: pillow, numpy (stdlib: wave).
"""
import os
import math
import wave
import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPRITES = os.path.join(ROOT, "assets", "sprites")
AUDIO = os.path.join(ROOT, "assets", "audio")
os.makedirs(SPRITES, exist_ok=True)
os.makedirs(AUDIO, exist_ok=True)
RATE = 22050

# ------------------------------------------------------------------ paleta ---
OUT      = (16, 14, 20, 255)      # contorno
METAL    = (124, 132, 146, 255)
METAL_L  = (170, 178, 190, 255)
METAL_D  = (78, 84, 96, 255)
RUST     = (132, 78, 42, 255)
RUST_D   = (92, 52, 28, 255)
VISOR    = (96, 222, 255, 255)
VISOR_HI = (210, 248, 255, 255)
BLUE     = (40, 150, 255, 255)
RED      = (255, 56, 70, 255)
GREEN    = (60, 230, 120, 255)
AMBER    = (255, 180, 64, 255)
DARK     = (30, 28, 34, 255)


def save_sprite(img, name):
    p = os.path.join(SPRITES, name)
    img.save(p)
    print("sprite ->", p, img.size)


# ---------------------------------------------------------------- Mag-Boy ----
def gen_player():
    W, H = 32, 48
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Piernas
    d.rectangle([9, 39, 13, 46], fill=METAL_D, outline=OUT)
    d.rectangle([18, 39, 22, 46], fill=METAL_D, outline=OUT)
    d.rectangle([8, 45, 14, 47], fill=DARK)            # pie
    d.rectangle([17, 45, 23, 47], fill=DARK)

    # Torso
    d.rectangle([6, 21, 25, 40], fill=METAL, outline=OUT)
    d.rectangle([8, 23, 12, 38], fill=METAL_L)          # luz lateral izq
    d.rectangle([20, 30, 24, 39], fill=METAL_D)         # sombra
    d.line([7, 35, 24, 35], fill=RUST_D)                # juntura
    d.point((22, 24)); d.rectangle([21, 24, 22, 25], fill=RUST)  # mancha óxido

    # Brazos
    d.rectangle([3, 23, 5, 36], fill=METAL_D, outline=OUT)
    d.rectangle([26, 23, 28, 36], fill=METAL_D, outline=OUT)

    # Socket del núcleo (lo cubre el Core sprite, dejarlo oscuro)
    d.ellipse([12, 26, 19, 33], fill=DARK, outline=OUT)

    # Casco
    d.rounded_rectangle([8, 5, 23, 20], radius=4, fill=METAL, outline=OUT)
    d.rectangle([9, 6, 22, 8], fill=METAL_L)            # brillo superior
    # Visor
    d.rectangle([10, 11, 21, 16], fill=VISOR, outline=OUT)
    d.rectangle([11, 11, 16, 12], fill=VISOR_HI)        # reflejo
    # Antena
    d.line([16, 5, 16, 1], fill=METAL_L)
    d.ellipse([15, 0, 17, 2], fill=RED)
    save_sprite(img, "player.png")


# ------------------------------------------------ Mag-Boy animado (spritesheet)
def _mb_torso_head(d, dy, arm_dy):
    """Dibuja torso + cabeza + brazos de Mag-Boy desplazados verticalmente `dy`."""
    # Torso
    d.rectangle([6, 21 + dy, 25, 40 + dy], fill=METAL, outline=OUT)
    d.rectangle([8, 23 + dy, 12, 38 + dy], fill=METAL_L)          # luz lateral izq
    d.rectangle([20, 30 + dy, 24, 39 + dy], fill=METAL_D)         # sombra
    d.line([7, 35 + dy, 24, 35 + dy], fill=RUST_D)                # juntura
    d.rectangle([21, 24 + dy, 22, 25 + dy], fill=RUST)            # óxido
    # Brazos (pueden subir/bajar con arm_dy)
    d.rectangle([3, 23 + dy + arm_dy, 5, 36 + dy + arm_dy], fill=METAL_D, outline=OUT)
    d.rectangle([26, 23 + dy + arm_dy, 28, 36 + dy + arm_dy], fill=METAL_D, outline=OUT)
    # Socket del núcleo (lo cubre el Core sprite)
    d.ellipse([12, 26 + dy, 19, 33 + dy], fill=DARK, outline=OUT)
    # Casco
    d.rounded_rectangle([8, 5 + dy, 23, 20 + dy], radius=4, fill=METAL, outline=OUT)
    d.rectangle([9, 6 + dy, 22, 8 + dy], fill=METAL_L)            # brillo superior
    # Visor
    d.rectangle([10, 11 + dy, 21, 16 + dy], fill=VISOR, outline=OUT)
    d.rectangle([11, 11 + dy, 16, 12 + dy], fill=VISOR_HI)        # reflejo
    # Antena
    d.line([16, 5 + dy, 16, 1 + dy], fill=METAL_L)
    d.ellipse([15, 0 + dy, 17, 2 + dy], fill=RED)


def _mb_leg(d, x, top, bottom):
    d.rectangle([x, top, x + 4, bottom], fill=METAL_D, outline=OUT)
    d.rectangle([x - 1, bottom - 1, x + 5, bottom + 1], fill=DARK)  # pie


def _mb_frame(p, mode):
    """Un frame de 32x48 de Mag-Boy. `p` en [0,1) para ciclos; `mode` define la pose."""
    W, H = 32, 48
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    s = math.sin(2 * math.pi * p)
    c = math.cos(2 * math.pi * p)

    if mode == "idle":
        dy = -1 if s > 0.5 else 0                 # respiración sutil
        ll_dx = rl_dx = 0
        ll_lift = rl_lift = 0
        arm_dy = -1 if s > 0.5 else 0
    elif mode == "walk":
        dy = -1 if abs(s) > 0.7 else 0            # rebote al pisar
        ll_dx = int(round(c * 2)); rl_dx = -int(round(c * 2))
        ll_lift = max(0, int(round(s * 3))); rl_lift = max(0, int(round(-s * 3)))
        arm_dy = 0
    elif mode == "jump_up":
        dy = -1; ll_dx = 1; rl_dx = -1; ll_lift = 3; rl_lift = 2; arm_dy = -2
    else:  # fall
        dy = 0; ll_dx = -2; rl_dx = 2; ll_lift = 0; rl_lift = 0; arm_dy = 1

    # Piernas primero (quedan detrás del torso)
    _mb_leg(d, 9 + ll_dx, 39 + dy, 46 + dy - ll_lift)
    _mb_leg(d, 18 + rl_dx, 39 + dy, 46 + dy - rl_lift)
    _mb_torso_head(d, dy, arm_dy)
    return img


def gen_player_sheet():
    """Spritesheet 1 fila: idle(2) + walk(6) + jump_up(1) + fall(1) = 10 frames de 32x48."""
    W, H = 32, 48
    frames = [_mb_frame(0.0, "idle"), _mb_frame(0.5, "idle")]
    for k in range(6):
        frames.append(_mb_frame(k / 6.0, "walk"))
    frames.append(_mb_frame(0.0, "jump_up"))
    frames.append(_mb_frame(0.0, "fall"))
    sheet = Image.new("RGBA", (W * len(frames), H), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.paste(f, (i * W, 0))
    save_sprite(sheet, "player_sheet.png")


# ------------------------------------------------------------ caja metálica --
def gen_box():
    W = H = 40
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([1, 1, 38, 38], fill=METAL, outline=OUT)
    # bisel
    d.rectangle([2, 2, 37, 4], fill=METAL_L)
    d.rectangle([2, 2, 4, 37], fill=METAL_L)
    d.rectangle([2, 35, 37, 37], fill=METAL_D)
    d.rectangle([35, 2, 37, 37], fill=METAL_D)
    # marco interior
    d.rectangle([7, 7, 32, 32], outline=METAL_D)
    # óxido
    d.rectangle([5, 28, 11, 34], fill=RUST_D)
    d.rectangle([6, 29, 9, 31], fill=RUST)
    d.point((30, 9)); d.rectangle([29, 9, 31, 11], fill=RUST)
    # remaches
    for (x, y) in [(5, 5), (34, 5), (5, 34), (34, 34)]:
        d.ellipse([x - 1, y - 1, x + 1, y + 1], fill=METAL_D)
    # franjas magnéticas (azul/rojo) a los lados
    d.rectangle([3, 17, 9, 22], fill=RED)
    d.rectangle([30, 17, 36, 22], fill=BLUE)
    save_sprite(img, "box.png")


# ----------------------------------------------------- dron centinela (vuela)
def gen_drone():
    W, H = 44, 30
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Rotor superior
    d.line([10, 4, 34, 4], fill=METAL_L, width=2)
    d.rectangle([21, 2, 23, 8], fill=METAL_D)            # eje
    # Cuerpo (cápsula)
    d.rounded_rectangle([10, 7, 34, 24], radius=8, fill=METAL, outline=OUT)
    d.rounded_rectangle([10, 7, 34, 12], radius=6, fill=METAL_L)  # brillo
    d.rectangle([12, 20, 32, 24], fill=METAL_D)          # sombra inferior
    # Carcasa roja (es enemigo)
    d.arc([10, 7, 34, 24], 200, 340, fill=RED, width=2)
    # Ojo/sensor rojo brillante
    d.ellipse([18, 12, 26, 20], fill=RED, outline=OUT)
    d.ellipse([20, 13, 23, 16], fill=(255, 200, 200, 255))  # reflejo
    # Patas/garras
    d.line([15, 24, 12, 28], fill=METAL_D, width=2)
    d.line([29, 24, 32, 28], fill=METAL_D, width=2)
    save_sprite(img, "enemy.png")


# ----------------------------------------------------- núcleo (orbe glow) ----
def gen_core():
    # Blanco/claro para teñirlo por código según polaridad (modulate).
    W = H = 16
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([1, 1, 14, 14], fill=(120, 140, 170, 90))   # halo
    d.ellipse([3, 3, 12, 12], fill=(220, 230, 245, 200))
    d.ellipse([5, 5, 10, 10], fill=(255, 255, 255, 255))  # núcleo
    d.ellipse([6, 6, 8, 8], fill=(255, 255, 255, 255))
    save_sprite(img, "core.png")


# ----------------------------------------------------- franja de peligro -----
def gen_hazard():
    W, H = 32, 10
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, W - 1, H - 1], fill=(28, 26, 22, 255))
    for x in range(-H, W, 10):
        d.polygon([(x, H), (x + 5, H), (x + 5 + H, 0), (x + H, 0)], fill=AMBER)
    d.rectangle([0, 0, W - 1, 1], fill=(60, 55, 45, 255))
    save_sprite(img, "hazard.png")


# --------------------------------------------- engranaje (coleccionable) ----
def gen_gear():
    W = H = 24
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = 12, 12
    GOLD = (255, 205, 70, 255)
    GOLD_D = (190, 135, 30, 255)
    GOLD_L = (255, 240, 160, 255)
    HOLE = (120, 80, 20, 255)
    # Dientes
    for k in range(8):
        a = math.pi * 2 * k / 8
        tx = cx + math.cos(a) * 9
        ty = cy + math.sin(a) * 9
        d.rectangle([tx - 2, ty - 2, tx + 2, ty + 2], fill=GOLD_D)
    # Cuerpo
    d.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=GOLD, outline=OUT)
    d.ellipse([cx - 7, cy - 7, cx + 1, cy - 1], fill=GOLD_L)   # brillo
    # Agujero central
    d.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=HOLE, outline=GOLD_D)
    save_sprite(img, "gear.png")


# ------------------------------------------------- texturas para VFX (particulas)
def gen_fx():
    # Chispa / punto suave (blanco, para teñir por codigo con modulate).
    s = 16
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    for y in range(s):
        for x in range(s):
            dx = x - s / 2 + 0.5
            dy = y - s / 2 + 0.5
            dist = math.hypot(dx, dy) / (s / 2)
            a = max(0.0, 1.0 - dist)
            img.putpixel((x, y), (255, 255, 255, int(255 * a * a)))
    save_sprite(img, "fx_spark.png")

    # Pieza de metal (metralla del robot al explotar).
    c = 8
    img = Image.new("RGBA", (c, c), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, c - 1, c - 1], fill=METAL, outline=OUT)
    d.rectangle([1, 1, 3, 3], fill=METAL_L)          # brillo
    d.rectangle([c - 3, c - 3, c - 1, c - 1], fill=METAL_D)  # sombra
    save_sprite(img, "fx_chunk.png")

    # Gota (líquido; blanca para teñir de verde en el ácido / derretido).
    w, h = 10, 14
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([1, 5, 8, 13], fill=(255, 255, 255, 255))     # cuerpo
    d.polygon([(4, 0), (1, 6), (8, 6)], fill=(255, 255, 255, 255))  # punta
    d.ellipse([3, 7, 5, 9], fill=(255, 255, 255, 255))
    save_sprite(img, "fx_drop.png")


# ---------------------------------------------- fondo industrial (grande) ----
def _vgrad(w, h, top, bottom):
    ys = np.linspace(0, 1, h)
    rows = np.outer(1 - ys, np.array(top)) + np.outer(ys, np.array(bottom))
    arr = np.repeat(rows[:, None, :], w, axis=1).astype("uint8")
    return Image.fromarray(arr, "RGB").convert("RGBA")


def _glow(img, cx, cy, r, color):
    layers = [(r, 26), (int(r * 0.7), 55), (int(r * 0.45), 110), (int(r * 0.25), 220)]
    ov = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    for rr, a in layers:
        d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=(color[0], color[1], color[2], a))
    img.alpha_composite(ov)


def gen_background():
    W, H = 2600, 1000
    img = _vgrad(W, H, (30, 27, 33), (44, 34, 28))
    d = ImageDraw.Draw(img, "RGBA")

    # Gears/máquinas lejanas (siluetas)
    for gx, gy, gr in [(300, 250, 120), (900, 180, 90), (1500, 280, 140),
                       (2100, 200, 100), (700, 700, 110), (1900, 720, 130)]:
        d.ellipse([gx - gr, gy - gr, gx + gr, gy + gr], fill=(38, 34, 38, 255))
        d.ellipse([gx - gr // 2, gy - gr // 2, gx + gr // 2, gy + gr // 2], fill=(30, 27, 31, 255))

    # Paneles de pared (rejilla con óxido y remaches)
    pw, ph = 200, 160
    for yy in range(0, H, ph):
        for xx in range(0, W, pw):
            base = (50, 45, 41) if (xx // pw + yy // ph) % 2 == 0 else (44, 39, 36)
            d.rectangle([xx + 3, yy + 3, xx + pw - 4, yy + ph - 4], fill=base + (255,),
                        outline=(28, 25, 23, 255))
            # remaches
            for rx in (xx + 12, xx + pw - 12):
                for ry in (yy + 12, yy + ph - 12):
                    d.ellipse([rx - 2, ry - 2, rx + 2, ry + 2], fill=(70, 63, 57, 255))
            # mancha de óxido ocasional
            if (xx * 7 + yy * 13) % 5 == 0:
                d.ellipse([xx + 40, yy + 60, xx + 90, yy + 110], fill=(96, 56, 30, 70))

    # Tuberías
    for py in [120, 520, 880]:
        d.rectangle([0, py, W, py + 22], fill=(70, 74, 82, 255), outline=(40, 43, 49, 255))
        d.rectangle([0, py + 3, W, py + 8], fill=(110, 116, 126, 255))
        for jx in range(80, W, 320):
            d.rectangle([jx, py - 4, jx + 16, py + 26], fill=(54, 58, 66, 255), outline=(30, 32, 37, 255))
    for px in [360, 1180, 2000]:
        d.rectangle([px, 0, px + 18, H], fill=(66, 70, 78, 255), outline=(38, 41, 47, 255))

    # Vigas con franjas de peligro
    for bx in [640, 1500, 2240]:
        d.rectangle([bx, 0, bx + 26, 150], fill=(58, 52, 46, 255), outline=(30, 27, 24, 255))
        for s in range(0, 150, 28):
            d.polygon([(bx, s), (bx + 26, s + 14), (bx + 26, s + 28), (bx, s + 14)], fill=(210, 170, 40, 90))

    # Luces de emergencia (neón con glow)
    for (lx, ly, col) in [(200, 90, RED), (1100, 120, AMBER), (1750, 90, VISOR),
                          (2400, 140, RED), (560, 600, VISOR), (1400, 640, AMBER)]:
        _glow(img, lx, ly, 70, col[:3])
        d.ellipse([lx - 6, ly - 6, lx + 6, ly + 6], fill=(255, 255, 255, 230))

    # Resplandor verde de la salida (derecha) y pozo de metal fundido abajo-der
    _glow(img, 2480, 560, 220, GREEN[:3])
    _glow(img, 2300, 980, 260, (255, 120, 40))

    # Grano/suciedad
    rng = np.random.default_rng(7)
    noise = rng.integers(0, 22, (H, W, 1), dtype="int16")
    arr = np.asarray(img).astype("int16")
    arr[:, :, :3] = np.clip(arr[:, :, :3] - noise, 0, 255)
    img = Image.fromarray(arr.astype("uint8"), "RGBA")

    # Viñeta (oscurecer bordes)
    vig = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    vd = ImageDraw.Draw(vig)
    for i in range(60):
        a = int(2.2 * i)
        vd.rectangle([i * 6, i * 4, W - i * 6, H - i * 4], outline=(0, 0, 0, max(0, 60 - i)))
    img.alpha_composite(vig)

    p = os.path.join(SPRITES, "bg_factory.png")
    img.convert("RGBA").save(p)
    print("sprite ->", p, img.size)


# ------------------------------------------------------------------- audio ---
def write_wav(name, samples):
    samples = np.clip(samples, -1.0, 1.0)
    data = (samples * 32767.0).astype("<i2").tobytes()
    p = os.path.join(AUDIO, name)
    with wave.open(p, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
        w.writeframes(data)
    print("audio  ->", p, "(%d frames)" % len(samples))


def gen_jump():
    dur = 0.18
    t = np.linspace(0, dur, int(RATE * dur), endpoint=False)
    freq = np.linspace(330, 880, t.size)
    phase = 2 * np.pi * np.cumsum(freq) / RATE
    write_wav("jump.wav", 0.5 * np.sin(phase) * np.exp(-t * 9.0))


def gen_magnet():
    dur = 0.8
    t = np.linspace(0, dur, int(RATE * dur), endpoint=False)
    sig = (0.30 * np.sin(2 * np.pi * 110.0 * t) + 0.20 * np.sin(2 * np.pi * 112.5 * t)
           + 0.12 * np.sin(2 * np.pi * 220.0 * t))
    write_wav("magnet.wav", sig * 0.7)


def gen_music():
    total = 4.0
    n = int(RATE * total)
    out = np.zeros(n)
    notes = [220.00, 261.63, 329.63, 392.00, 329.63, 261.63, 246.94, 196.00]
    step = total / len(notes)
    for i, f in enumerate(notes):
        start = int(i * step * RATE)
        length = int(step * RATE)
        tt = np.linspace(0, step, length, endpoint=False)
        env = np.sin(np.pi * tt / step) ** 1.2
        out[start:start + length] += (0.16 * np.sin(2 * np.pi * f * tt)
                                      + 0.05 * np.sin(2 * np.pi * 2 * f * tt)) * env
    t = np.linspace(0, total, n, endpoint=False)
    out += 0.06 * np.sin(2 * np.pi * 110.0 * t) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.5 * t))
    write_wav("music.wav", out * 0.9)


def gen_gear_wav():
    dur = 0.16
    t = np.linspace(0, dur, int(RATE * dur), endpoint=False)
    half = t.size // 2
    sig = np.zeros(t.size)
    for i, ff in enumerate([1047.0, 1319.0]):  # C6 -> E6
        seg = slice(i * half, (i + 1) * half)
        tt = t[seg] - t[seg][0]
        sig[seg] = 0.4 * np.sin(2 * np.pi * ff * tt) * np.exp(-tt * 12.0)
    write_wav("gear.wav", sig)


def gen_hurt_wav():
    dur = 0.3
    t = np.linspace(0, dur, int(RATE * dur), endpoint=False)
    freq = np.linspace(420, 90, t.size)
    phase = 2 * np.pi * np.cumsum(freq) / RATE
    env = np.exp(-t * 5.0)
    sig = 0.35 * np.sign(np.sin(phase)) * env + 0.25 * np.sin(phase) * env
    write_wav("hurt.wav", sig)


if __name__ == "__main__":
    gen_player()
    gen_player_sheet()
    gen_fx()
    gen_box()
    gen_drone()
    gen_core()
    gen_hazard()
    gen_gear()
    gen_background()
    gen_jump()
    gen_magnet()
    gen_music()
    gen_gear_wav()
    gen_hurt_wav()
    print("Listo.")
