#!/usr/bin/env python3
"""Yer tutucu SFX üretici (C-66, resource §9) — deterministik, yalnız standart kütüphane.

ADR-0008 §5: 16-bit mono 44.1 kHz. Çıktılar `game/assets/audio/sfx/` altına yazılır;
aynı girdi her çalıştırmada byte-eşit dosya üretir (gürültü sabit tohumlu).

    python3 tools/asset-pipeline/generate_sfx.py
"""

import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
OUT_DIR = Path(__file__).resolve().parents[2] / "game" / "assets" / "audio" / "sfx"


def _write(name: str, samples: list[float]) -> None:
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = 0.8 / peak  # -2 dBFS civarı tepe; seviye SFX bus'ında ayarlanır
    frames = b"".join(struct.pack("<h", int(round(s * scale * 32767))) for s in samples)
    path = OUT_DIR / name
    with wave.open(str(path), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(frames)
    print(f"{path} ({len(samples) / RATE:.3f} s)")


def drum() -> list[float]:
    """Üretim onayı: kısa, tok davul vuruşu — 110→55 Hz düşen gövde + vuruş gürültüsü."""
    rng = random.Random(66)
    length = int(RATE * 0.22)
    phase = 0.0
    samples = []
    for i in range(length):
        t = i / RATE
        freq = 55.0 + 55.0 * math.exp(-t * 30.0)
        phase += 2.0 * math.pi * freq / RATE
        body = math.sin(phase) * math.exp(-t * 14.0)
        hit = (rng.random() * 2.0 - 1.0) * math.exp(-t * 90.0) * 0.35
        samples.append(body + hit)
    return samples


def coin() -> list[float]:
    """Gelir: iki notalı parlak sikke şıngırtısı (B6 → E7), metalik üst harmonikli."""
    length = int(RATE * 0.32)
    notes = [(0.0, 1975.5), (0.07, 2637.0)]
    samples = []
    for i in range(length):
        t = i / RATE
        value = 0.0
        for start, freq in notes:
            if t < start:
                continue
            local = t - start
            env = math.exp(-local * 12.0) * min(1.0, local * RATE / 64.0)
            value += env * (math.sin(2.0 * math.pi * freq * local)
                            + 0.35 * math.sin(2.0 * math.pi * freq * 2.76 * local))
        samples.append(value)
    return samples


if __name__ == "__main__":
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    _write("sfx_economy_recruit_drum.wav", drum())
    _write("sfx_economy_income_coin.wav", coin())
