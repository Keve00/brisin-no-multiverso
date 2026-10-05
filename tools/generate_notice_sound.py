#!/usr/bin/env python3
"""Original two-note attention chime; bounded, click-free and without noise."""
from pathlib import Path
import wave
import numpy as np
SR = 22050
mix = np.zeros(round(SR * .64))
for start, frequency, duration in [(0, 659.255, .25), (.18, 987.767, .42)]:
    t = np.arange(round(SR * duration)) / SR
    envelope = np.minimum(1, t / .008) * np.minimum(1, (duration-t) / .04) * np.exp(-t*6)
    tone = (np.sin(2*np.pi*frequency*t) + .22*np.sin(2*np.pi*frequency*2*t)) * envelope
    index = round(start*SR)
    mix[index:index+len(tone)] += tone
mix *= .48 / max(abs(mix))
output = Path(__file__).resolve().parents[1] / 'godot/assets/audio/notice.wav'
with wave.open(str(output), 'wb') as f:
    f.setnchannels(1); f.setsampwidth(2); f.setframerate(SR)
    f.writeframes(np.round(mix*32767).astype('<i2').tobytes())
assert abs(mix[0]) < 1e-9 and abs(mix[-1]) < 1e-9
print(f'Attention chime: {len(mix)/SR:.2f}s, peak {20*np.log10(max(abs(mix))):.2f} dBFS, no clipping.')
