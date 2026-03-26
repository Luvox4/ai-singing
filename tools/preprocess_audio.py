"""
Audio Preprocessing Tool
========================
将录制的原始声音数据预处理为训练所需格式：
- 转换为 wav 格式
- 重采样到目标采样率
- 自动切割超长音频（>30s）
- 去除静音段
- 规范化音量

用法:
    python tools/preprocess_audio.py --input data/raw_recordings --output data/raw --target-sr 44100
"""

import argparse
import os
import sys
from pathlib import Path

try:
    import librosa
    import soundfile as sf
    import numpy as np
except ImportError:
    print("[ERROR] Missing dependencies. Run: pip install librosa soundfile numpy")
    sys.exit(1)


def trim_silence(audio, sr, top_db=30):
    """去除开头和结尾的静音"""
    trimmed, _ = librosa.effects.trim(audio, top_db=top_db)
    return trimmed


def split_long_audio(audio, sr, max_duration=28.0, min_duration=1.0):
    """将超长音频切割为多个片段（每段最长 max_duration 秒）"""
    max_samples = int(max_duration * sr)
    min_samples = int(min_duration * sr)

    if len(audio) <= max_samples:
        return [audio] if len(audio) >= min_samples else []

    # 按静音点切割
    intervals = librosa.effects.split(audio, top_db=35, frame_length=2048, hop_length=512)

    segments = []
    current_segment = np.array([])

    for start, end in intervals:
        chunk = audio[start:end]
        if len(current_segment) + len(chunk) <= max_samples:
            current_segment = np.concatenate([current_segment, audio[start:end]])
        else:
            if len(current_segment) >= min_samples:
                segments.append(current_segment)
            current_segment = chunk

    if len(current_segment) >= min_samples:
        segments.append(current_segment)

    return segments


def normalize_audio(audio, target_db=-20.0):
    """规范化音量到目标分贝"""
    rms = np.sqrt(np.mean(audio ** 2))
    if rms == 0:
        return audio
    target_rms = 10 ** (target_db / 20)
    gain = target_rms / rms
    return np.clip(audio * gain, -1.0, 1.0)


def process_file(input_path: Path, output_dir: Path, target_sr: int, file_idx: int):
    """处理单个音频文件"""
    print(f"  Processing: {input_path.name}")

    try:
        audio, sr = librosa.load(str(input_path), sr=target_sr, mono=True)
    except Exception as e:
        print(f"  [SKIP] Cannot load {input_path.name}: {e}")
        return 0

    # 去除静音
    audio = trim_silence(audio, target_sr)

    # 规范化音量
    audio = normalize_audio(audio)

    # 切割长音频
    duration = len(audio) / target_sr
    if duration < 1.0:
        print(f"  [SKIP] Too short ({duration:.1f}s)")
        return 0

    segments = split_long_audio(audio, target_sr)

    saved = 0
    for i, segment in enumerate(segments):
        out_name = f"{input_path.stem}_{file_idx:04d}_{i:02d}.wav"
        out_path = output_dir / out_name
        sf.write(str(out_path), segment, target_sr)
        dur = len(segment) / target_sr
        print(f"    -> Saved: {out_name} ({dur:.1f}s)")
        saved += 1

    return saved


def main():
    parser = argparse.ArgumentParser(description="Preprocess audio for AI singing model training")
    parser.add_argument("--input", required=True, help="Input directory with raw recordings")
    parser.add_argument("--output", required=True, help="Output directory for processed audio")
    parser.add_argument("--target-sr", type=int, default=44100, help="Target sample rate (default: 44100 for SVC)")
    args = parser.parse_args()

    input_dir = Path(args.input)
    output_dir = Path(args.output)
    output_dir.mkdir(parents=True, exist_ok=True)

    if not input_dir.exists():
        print(f"[ERROR] Input directory not found: {input_dir}")
        sys.exit(1)

    supported_formats = {".wav", ".flac", ".mp3", ".m4a", ".opus", ".ogg"}
    audio_files = [f for f in input_dir.rglob("*") if f.suffix.lower() in supported_formats]

    if not audio_files:
        print(f"[ERROR] No audio files found in: {input_dir}")
        sys.exit(1)

    print(f"\n[INFO] Found {len(audio_files)} audio files")
    print(f"[INFO] Output directory: {output_dir}")
    print(f"[INFO] Target sample rate: {args.target_sr}Hz\n")

    total_saved = 0
    for i, f in enumerate(sorted(audio_files)):
        count = process_file(f, output_dir, args.target_sr, i)
        total_saved += count

    print(f"\n[DONE] Processed {len(audio_files)} files -> {total_saved} training segments")
    print(f"[INFO] Training data ready in: {output_dir}")


if __name__ == "__main__":
    main()
