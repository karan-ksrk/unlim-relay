"""Synthesizes the launch sound (assets/sounds/launch.wav) from scratch.

Standard library only, fully deterministic. Timed to the launch animation
in lib/features/launch/launch_intro.dart:
  0.00-0.60 s  a filtered-noise whoosh rises while the loop draws
  0.82 s       first chime note as the light completes the loop
  0.92 s       second note a fifth above, with a short sparkle
then a small room reverb tail. Run from the project root:

  python tool/generate_launch_sound.py
"""

import math
import random
import struct
import wave

SR = 44100
DURATION = 2.0
N = int(SR * DURATION)
OUT_PATH = "assets/sounds/launch.wav"


def whoosh(out):
    """Band-passed noise whose centre sweeps 250 Hz -> 2.5 kHz."""
    rng = random.Random(7)
    low = band = 0.0
    rise, release = 0.60, 0.15
    for i in range(int(SR * (rise + release))):
        t = i / SR
        centre = 250 * 10 ** min(t / rise, 1.0)
        f = 2 * math.sin(math.pi * centre / SR)
        high = rng.uniform(-1, 1) - low - 0.45 * band
        band += f * high
        low += f * band
        env = (t / rise) ** 2.4 if t < rise else 1 - (t - rise) / release
        out[i] += band * env * 0.30


def sub_swell(out):
    """A quiet low sine gliding up under the whoosh, for weight."""
    phase = 0.0
    length = 0.85
    for i in range(int(SR * length)):
        t = i / SR
        phase += 2 * math.pi * (55 + 45 * t / length) / SR
        env = math.sin(math.pi * t / length) ** 2
        out[i] += math.sin(phase) * env * 0.18


def bell(out, start, freq, amp, decay):
    """Two-operator FM bell: bright attack that mellows as it decays."""
    first = int(SR * start)
    for i in range(N - first):
        t = i / SR
        env = min(1.0, t / 0.004) * math.exp(-t / decay)
        if t > 0.01 and env < 1e-4:
            break
        index = 2.0 * math.exp(-t / 0.22)
        modulator = math.sin(2 * math.pi * freq * 1.4 * t)
        tone = math.sin(2 * math.pi * freq * t + index * modulator)
        overtone = 0.25 * math.sin(2 * math.pi * freq * 2.0 * t) * math.exp(-t / 0.18)
        out[first + i] += (tone + overtone) * env * amp


def reverb(dry):
    """Small Schroeder reverb: four damped combs, two all-passes."""
    def comb(signal, delay, feedback, damp):
        buf = [0.0] * delay
        out, store, idx = [0.0] * len(signal), 0.0, 0
        for i, x in enumerate(signal):
            y = buf[idx]
            store = y * (1 - damp) + store * damp
            buf[idx] = x + store * feedback
            out[i] = y
            idx = (idx + 1) % delay
        return out

    def allpass(signal, delay, gain):
        buf = [0.0] * delay
        out, idx = [0.0] * len(signal), 0
        for i, x in enumerate(signal):
            y = buf[idx]
            buf[idx] = x + y * gain
            out[i] = y - x * gain
            idx = (idx + 1) % delay
        return out

    wet = [0.0] * len(dry)
    for delay in (1557, 1617, 1491, 1422):
        for i, y in enumerate(comb(dry, delay, 0.80, 0.3)):
            wet[i] += y * 0.25
    for delay in (225, 556):
        wet = allpass(wet, delay, 0.5)
    return [d * 0.8 + w * 0.28 for d, w in zip(dry, wet)]


def layer(build, peak):
    """Renders one layer and levels it to [peak], so layers mix by ear
    rather than by their raw filter gain."""
    buf = [0.0] * N
    build(buf)
    top = max(abs(s) for s in buf) or 1.0
    return [s * peak / top for s in buf]


def chime(out):
    bell(out, 0.82, 554.37, 0.10, 0.50)   # C#5, warmth under the first note
    bell(out, 0.82, 880.00, 0.32, 0.55)   # A5
    bell(out, 0.92, 1318.51, 0.26, 0.60)  # E6
    bell(out, 0.92, 2637.02, 0.06, 0.12)  # sparkle


def main():
    layers = (
        layer(whoosh, 0.35),
        layer(sub_swell, 0.22),
        layer(chime, 0.80),
    )
    mixed = reverb([sum(samples) for samples in zip(*layers)])

    fade = int(SR * 0.25)
    for i in range(fade):
        mixed[N - fade + i] *= 1 - i / fade
    peak = max(abs(s) for s in mixed)
    scale = 0.70 / peak  # about -3 dBFS
    frames = b"".join(
        struct.pack("<h", int(max(-1.0, min(1.0, s * scale)) * 32767))
        for s in mixed
    )
    with wave.open(OUT_PATH, "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SR)
        wav.writeframes(frames)
    print(f"wrote {OUT_PATH}: {DURATION}s, {len(frames)} bytes")


if __name__ == "__main__":
    main()
