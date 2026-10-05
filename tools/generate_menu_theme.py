#!/usr/bin/env python3
"""Brisin — Brisa de Partida. Original deterministic 16-bar chiptune loop.

No samples, external assets or melodies. Python 3 + numpy + ffmpeg, output Vorbis.
All note/percussion tails wrap onto the start; no whole-track fade is used.
"""
from pathlib import Path
import json
import wave
import subprocess
import tempfile
import numpy as np

SR = 44100
BPM = 128
BEAT = 60 / BPM
BARS = 16
COUNT = int(round(BARS * 4 * BEAT * SR))
DURATION = COUNT / SR
rng = np.random.default_rng(817203)
mix = np.zeros(COUNT, dtype=np.float64)


def add(signal, beat, gain=1):
    start = int(round(beat * BEAT * SR))
    np.add.at(mix, (start + np.arange(len(signal))) % COUNT, signal * gain)


def hz(note):
    return 440 * 2 ** ((note - 69) / 12)


def env(length, attack=.004, release=.025, decay=1.3):
    t = np.arange(length) / SR
    total = length / SR
    envelope = np.exp(-decay * t / max(total, .001))
    envelope *= np.minimum(1, t / attack)
    envelope *= np.minimum(1, np.maximum(0, (total - t) / release))
    envelope[0] = envelope[-1] = 0
    return envelope


def pulse(phase, duty=.5, harmonics=15):
    """Bandlimited pulse; no aliased raw square discontinuities."""
    out = np.zeros_like(phase)
    for h in range(1, harmonics + 1):
        out += (2 * np.sin(np.pi * h * duty) / (np.pi * h)) * np.cos(h * phase - np.pi * h * duty)
    return out


def note(midi, beat, beats, gain, voice="lead"):
    length = int(round(beats * BEAT * SR))
    t = np.arange(length) / SR
    freq = hz(midi)
    phase = 2 * np.pi * freq * t
    if voice == "bass":
        osc = np.zeros_like(t)
        for h in [1, 3, 5, 7]:
            osc += ((-1) ** ((h - 1) // 2)) * np.sin(h * phase) / (h * h)
        envelope = env(length, .005, .022, .55)
    elif voice == "arp":
        osc = pulse(phase, .25, min(9, int(SR / (2 * freq)) - 1))
        envelope = env(length, .0025, .025, 3.8)
    else:
        # Gentle delayed 5 Hz vibrato; fundamental plus NES-like 50% pulse.
        phase += .012 * np.sin(2 * np.pi * 5 * t) * np.minimum(1, t / .09)
        osc = .7 * pulse(phase, .5, min(13, int(SR / (2 * freq)) - 1)) + .3 * np.sin(phase)
        envelope = env(length, .004, .032, .75)
    add(osc * envelope, beat, gain)


def kick(beat, gain=.14):
    t = np.arange(int(.16 * SR)) / SR
    phase = 2 * np.pi * (47 * t + 4.7 * (1 - np.exp(-t * 38)))
    add(np.sin(phase) * np.exp(-t * 29) * env(len(t), .001, .02, 0), beat, gain)


def snare(beat, gain=.055):
    t = np.arange(int(.105 * SR)) / SR
    noise = rng.uniform(-1, 1, len(t))
    noise = noise - np.convolve(noise, np.ones(9) / 9, mode="same")
    signal = .75 * noise + .25 * np.sin(2 * np.pi * 175 * t)
    add(signal * np.exp(-t * 32) * env(len(t), .001, .015, 0), beat, gain)


def hat(beat, gain=.019):
    t = np.arange(int(.052 * SR)) / SR
    noise = rng.uniform(-1, 1, len(t))
    noise = noise - np.convolve(noise, np.ones(5) / 5, mode="same")
    add(noise * np.exp(-t * 70) * env(len(t), .001, .008, 0), beat, gain)


# Four bars form a question, four answer, then a variation/cadence returns to C.
chords = [
    (48, [60, 64, 67, 72]), (55, [59, 62, 67, 71]),
    (57, [60, 64, 69, 72]), (53, [60, 65, 69, 72]),
    (48, [60, 64, 67, 72]), (55, [59, 62, 67, 71]),
    (53, [60, 65, 69, 72]), (55, [59, 62, 67, 71]),
] * 2

# (start in beats, MIDI pitch, duration); composed for this project.
melody = [
    [(0,72,.42),(.5,76,.42),(1,79,.85),(2,76,.42),(2.5,81,.42),(3,79,.82)],
    [(0,74,.42),(.5,79,.42),(1,83,.8),(2,81,.42),(2.5,79,.42),(3,74,.8)],
    [(0,76,.7),(1,72,.42),(1.5,76,.42),(2,81,.85),(3,79,.42),(3.5,76,.42)],
    [(0,77,.85),(1,76,.42),(1.5,72,.42),(2,74,.42),(2.5,77,.42),(3,76,.8)],
    [(0,79,.42),(.5,84,.42),(1,83,.42),(1.5,79,.42),(2,76,.85),(3,72,.8)],
    [(0,74,.42),(.5,76,.42),(1,79,.85),(2,83,.42),(2.5,81,.42),(3,79,.8)],
    [(0,81,.85),(1,79,.42),(1.5,77,.42),(2,76,.42),(2.5,74,.42),(3,72,.85)],
    [(0,74,.42),(.5,79,.42),(1,77,.42),(1.5,74,.42),(2,71,.8),(3,74,.42),(3.5,71,.42)],
    [(0,72,.42),(.5,76,.42),(1,79,.42),(1.5,84,.42),(2,83,.42),(2.5,79,.42),(3,81,.8)],
    [(0,83,.7),(1,79,.42),(1.5,74,.42),(2,76,.42),(2.5,79,.42),(3,74,.8)],
    [(0,81,.85),(1,79,.42),(1.5,76,.42),(2,72,.42),(2.5,76,.42),(3,79,.8)],
    [(0,77,.42),(.5,81,.42),(1,84,.8),(2,81,.42),(2.5,79,.42),(3,77,.8)],
    [(0,76,.42),(.5,79,.42),(1,84,.85),(2,83,.42),(2.5,79,.42),(3,76,.8)],
    [(0,79,.7),(1,74,.42),(1.5,71,.42),(2,74,.42),(2.5,79,.42),(3,83,.8)],
    [(0,81,.42),(.5,79,.42),(1,77,.85),(2,76,.42),(2.5,74,.42),(3,72,.8)],
    [(0,74,.42),(.5,71,.42),(1,67,.7),(2,71,.42),(2.5,74,.42),(3,79,.42),(3.5,71,.42)],
]

for bar, (root, chord) in enumerate(chords):
    base = bar * 4
    # Syncopated roots/fifths keep the pulse jaunty without heavy drums.
    for at, pitch, length in [(0, root - 12, .62), (1, root, .38), (1.5, root - 5, .36), (2, root - 12, .65), (3, root - 5, .38), (3.5, root, .35)]:
        note(pitch, base + at, length, .108, "bass")
    order = [0, 1, 2, 1, 3, 2, 1, 2] if bar < 8 else [0, 2, 1, 3, 2, 1, 2, 3]
    for step, chord_index in enumerate(order):
        at = step * .5 + (.035 if step % 2 else 0)
        note(chord[chord_index], base + at, .43, .038, "arp")
    for at, midi, length in melody[bar]:
        note(midi, base + at + (.025 if at % 1 else 0), length, .13, "lead")
        # Quiet one-tap echo wraps naturally, including the final turnaround.
        note(midi, base + at + .3, length * .82, .021, "lead")
    kick(base)
    kick(base + 2, .125)
    snare(base + 1)
    snare(base + 3)
    for eighth in range(8):
        hat(base + eighth / 2 + (.035 if eighth % 2 else 0), .016 if eighth % 2 == 0 else .023)
    if bar in [3, 7, 11, 15]:
        snare(base + 3.5, .032)

# Fixed headroom; a 2.5 ms seam taper removes codec start/end ringing without
# fading the musical phrase. This is shorter than one note's normal attack.
mix -= mix.mean()
seam = int(.0025 * SR)
taper = np.sin(np.linspace(0, np.pi / 2, seam)) ** 2
mix[:seam] *= taper
mix[-seam:] *= taper[::-1]
mix *= .72 / np.max(np.abs(mix))
pcm = np.round(mix * 32767).astype("<i2")
root = Path(__file__).resolve().parents[1]
output = root / 'godot/assets/audio'
with tempfile.TemporaryDirectory(prefix='brisin-music-') as temporary:
    wav_path = Path(temporary) / 'menu_theme.wav'
    with wave.open(str(wav_path), 'wb') as wav:
        wav.setparams((1, 2, SR, COUNT, 'NONE', 'not compressed'))
        wav.writeframes(pcm.tobytes())
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', str(wav_path),
                    '-c:a', 'libvorbis', '-q:a', '5', str(output / 'menu_theme.ogg')], check=True)
differences = np.diff(pcm.astype(np.int32))
stats = {
    "title": "Brisa de Partida", "original_composition": True,
    "bpm": BPM, "key": "C major", "meter": "4/4", "bars": BARS,
    "duration_seconds": DURATION, "sample_rate": SR, "samples": COUNT,
    "channels": 1, "bits": 16,
    "peak": float(np.max(np.abs(pcm.astype(np.int32))) / 32768),
    "peak_dbfs": float(20 * np.log10(np.max(np.abs(pcm.astype(np.int32))) / 32768)),
    "rms_dbfs": float(20 * np.log10(np.sqrt(np.mean((pcm.astype(float) / 32768) ** 2)))),
    "dc": float(pcm.mean() / 32768), "clipped_samples": int(np.count_nonzero(np.abs(pcm.astype(np.int32)) >= 32767)),
    "loop_boundary_step_pcm": int(pcm[0]) - int(pcm[-1]),
    "loop_boundary_step_dbfs": float(20 * np.log10(max(1, abs(int(pcm[0]) - int(pcm[-1]))) / 32768)),
    "largest_internal_step_pcm": int(np.max(np.abs(differences))),
    "loop_no_long_global_fade": True, "seam_taper_ms": 2.5, "rng_seed": 817203,
}
assert stats["clipped_samples"] == 0
assert abs(stats["loop_boundary_step_pcm"]) < 80
(root / 'godot/docs/menu_music_metrics.json').write_text(json.dumps(stats, indent=2) + "\n")
print(json.dumps(stats, indent=2))
