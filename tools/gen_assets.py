#!/usr/bin/env python3
"""Genera arte temporal (pixel-art) y audio sintetizado para Magnet-o.

Salidas:
  assets/sprites/player.png   (32x48)
  assets/sprites/box.png      (40x40)
  assets/sprites/enemy.png    (32x40)
  assets/audio/jump.wav       (~0.18 s)
  assets/audio/magnet.wav     (~0.80 s, loop seamless)
  assets/audio/music.wav      (~4.0 s, loop)

Requiere: pillow, numpy (stdlib: wave). Reejecutable de forma idempotente.
"""
import os
import wave
import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPRITES = os.path.join(ROOT, "assets", "sprites")
AUDIO = os.path.join(ROOT, "assets", "audio")
os.makedirs(SPRITES, exist_ok=True)
os.makedirs(AUDIO, exist_ok=True)

RATE = 22050


# ----------------------------------------------------------------------------
# Helpers de pixel-art
# ----------------------------------------------------------------------------
def new_img(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def rect(px, x0, y0, x1, y1, color):
    """Rellena un rectángulo inclusivo [x0,x1] x [y0,y1]."""
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            px[x, y] = color


def save(img, name):
    path = os.path.join(SPRITES, name)
    img.save(path)
    print("sprite ->", path)


# ----------------------------------------------------------------------------
# Player (Mag-Boy) 32x48
# ----------------------------------------------------------------------------
def gen_player():
    W, H = 32, 48
    img = new_img(W, H)
    px = img.load()
    body = (96, 120, 170, 255)
    body_d = (62, 80, 120, 255)
    helmet = (54, 66, 104, 255)
    visor = (110, 220, 240, 255)
    metal = (180, 188, 200, 255)
    boot = (40, 44, 60, 255)

    # Piernas
    rect(px, 9, 40, 14, 46, body_d)
    rect(px, 17, 40, 22, 46, body_d)
    rect(px, 9, 45, 14, 46, boot)
    rect(px, 17, 45, 22, 46, boot)
    # Torso
    rect(px, 7, 22, 24, 41, body)
    rect(px, 7, 22, 8, 41, body_d)
    rect(px, 23, 22, 24, 41, body_d)
    # Cinturón / placa magnética
    rect(px, 7, 33, 24, 35, metal)
    # Brazos
    rect(px, 4, 24, 6, 37, body_d)
    rect(px, 25, 24, 27, 37, body_d)
    # Casco
    rect(px, 8, 6, 23, 21, helmet)
    rect(px, 8, 6, 23, 7, body_d)
    # Visor
    rect(px, 10, 11, 21, 16, visor)
    rect(px, 10, 11, 21, 11, (200, 245, 255, 255))
    # Antena
    rect(px, 15, 2, 16, 5, metal)
    px[15, 1] = (255, 90, 90, 255)
    save(img, "player.png")


# ----------------------------------------------------------------------------
# Caja metálica 40x40
# ----------------------------------------------------------------------------
def gen_box():
    W, H = 40, 40
    img = new_img(W, H)
    px = img.load()
    fill = (150, 158, 168, 255)
    hi = (196, 204, 214, 255)
    lo = (96, 104, 116, 255)
    edge = (54, 60, 70, 255)
    rivet = (70, 76, 88, 255)
    # Cuerpo
    rect(px, 1, 1, 38, 38, fill)
    # Bordes
    rect(px, 0, 0, 39, 1, edge)
    rect(px, 0, 38, 39, 39, edge)
    rect(px, 0, 0, 1, 39, edge)
    rect(px, 38, 0, 39, 39, edge)
    # Bisel
    rect(px, 2, 2, 37, 3, hi)
    rect(px, 2, 2, 3, 37, hi)
    rect(px, 2, 36, 37, 37, lo)
    rect(px, 36, 2, 37, 37, lo)
    # Remaches en esquinas
    for (rx, ry) in [(5, 5), (33, 5), (5, 33), (33, 33)]:
        rect(px, rx, ry, rx + 1, ry + 1, rivet)
    # Franja magnética (mitad roja / mitad azul) en los laterales,
    # dejando el centro libre para el marcador de selección.
    rect(px, 4, 18, 9, 21, (210, 80, 80, 255))
    rect(px, 30, 18, 35, 21, (80, 120, 210, 255))
    save(img, "box.png")


# ----------------------------------------------------------------------------
# Enemigo 32x40 (cara incluida)
# ----------------------------------------------------------------------------
def gen_enemy():
    W, H = 32, 40
    img = new_img(W, H)
    px = img.load()
    body = (196, 58, 58, 255)
    body_d = (140, 36, 36, 255)
    foot = (90, 22, 22, 255)
    white = (245, 240, 226, 255)
    pupil = (30, 16, 16, 255)
    mouth = (40, 10, 10, 255)
    brow = (110, 26, 26, 255)
    # Cuerpo redondeado
    rect(px, 4, 6, 27, 34, body)
    rect(px, 6, 4, 25, 5, body)
    rect(px, 4, 6, 5, 34, body_d)
    rect(px, 26, 6, 27, 34, body_d)
    rect(px, 4, 33, 27, 34, body_d)
    # Patas
    rect(px, 7, 35, 13, 38, foot)
    rect(px, 18, 35, 24, 38, foot)
    # Cejas enojadas
    rect(px, 7, 12, 14, 13, brow)
    rect(px, 17, 12, 24, 13, brow)
    # Ojos
    rect(px, 8, 14, 13, 19, white)
    rect(px, 18, 14, 23, 19, white)
    rect(px, 11, 16, 13, 18, pupil)
    rect(px, 18, 16, 20, 18, pupil)
    # Boca
    rect(px, 10, 25, 21, 27, mouth)
    rect(px, 12, 24, 13, 24, mouth)
    rect(px, 18, 24, 19, 24, mouth)
    save(img, "enemy.png")


# ----------------------------------------------------------------------------
# Audio
# ----------------------------------------------------------------------------
def write_wav(name, samples):
    samples = np.clip(samples, -1.0, 1.0)
    data = (samples * 32767.0).astype("<i2").tobytes()
    path = os.path.join(AUDIO, name)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data)
    print("audio  ->", path, "(%d frames)" % len(samples))


def gen_jump():
    dur = 0.18
    t = np.linspace(0, dur, int(RATE * dur), endpoint=False)
    freq = np.linspace(330, 880, t.size)
    phase = 2 * np.pi * np.cumsum(freq) / RATE
    env = np.exp(-t * 9.0)
    sig = 0.5 * np.sin(phase) * env
    write_wav("jump.wav", sig)


def gen_magnet():
    # Duración múltiplo de 1/1.25 s para loop sin clic (110, 112.5, 220 Hz).
    dur = 0.8
    t = np.linspace(0, dur, int(RATE * dur), endpoint=False)
    sig = (0.30 * np.sin(2 * np.pi * 110.0 * t)
           + 0.20 * np.sin(2 * np.pi * 112.5 * t)
           + 0.12 * np.sin(2 * np.pi * 220.0 * t))
    sig *= 0.7
    write_wav("magnet.wav", sig)


def gen_music():
    # Loop de 4 s: arpegio + pad. Cada nota con envolvente que cierra en 0
    # para que el límite del loop no produzca clic.
    total = 4.0
    n = int(RATE * total)
    out = np.zeros(n)
    notes = [220.00, 261.63, 329.63, 392.00, 329.63, 261.63, 246.94, 196.00]
    step = total / len(notes)
    for i, f in enumerate(notes):
        start = int(i * step * RATE)
        length = int(step * RATE)
        tt = np.linspace(0, step, length, endpoint=False)
        env = np.sin(np.pi * tt / step) ** 1.2  # sube y baja a 0
        tone = 0.16 * np.sin(2 * np.pi * f * tt) * env
        tone += 0.05 * np.sin(2 * np.pi * 2 * f * tt) * env
        out[start:start + length] += tone
    # Pad grave continuo (frecuencia múltiplo de 0.25 Hz -> loop limpio)
    t = np.linspace(0, total, n, endpoint=False)
    pad = 0.06 * np.sin(2 * np.pi * 110.0 * t) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.5 * t))
    out += pad
    out *= 0.9
    write_wav("music.wav", out)


if __name__ == "__main__":
    gen_player()
    gen_box()
    gen_enemy()
    gen_jump()
    gen_magnet()
    gen_music()
    print("Listo.")
