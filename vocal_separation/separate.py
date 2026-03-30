from __future__ import annotations

import argparse
import subprocess
import sys
import tempfile
from pathlib import Path

from common import BIN_DIR, OUTPUT_DIR, PRESETS, prepare_runtime_env, resolve_model_name


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Separate vocals from songs with local Demucs models.")
    parser.add_argument("tracks", nargs="+", help="Audio file(s) to separate.")
    parser.add_argument("--preset", choices=sorted(PRESETS.keys()), default="best", help="Named model preset to use.")
    parser.add_argument("--model", help="Exact Demucs model name. Overrides --preset.")
    parser.add_argument(
        "--device",
        choices=["auto", "cpu", "cuda"],
        default="auto",
        help="Device for separation. 'auto' uses CUDA when available, else CPU.",
    )
    parser.add_argument("--out", default=str(OUTPUT_DIR), help="Output directory. Default is vocal_separation/output.")
    parser.add_argument("--jobs", type=int, default=2, help="Parallel job count for track processing.")
    parser.add_argument("--shifts", type=int, default=1, help="Quality stabilization shifts. Higher is slower.")
    parser.add_argument("--overlap", type=float, default=0.25, help="Chunk overlap.")
    parser.add_argument("--segment", type=int, help="Chunk size in seconds. Useful when GPU memory is tight.")
    parser.add_argument("--filename", default="{track}/{stem}.{ext}", help="Demucs output filename template.")
    parser.add_argument("--mp3", action="store_true", help="Also encode outputs as mp3.")
    parser.add_argument("--float32", action="store_true", help="Write float32 WAV output.")
    return parser.parse_args()


def resolve_device(choice: str) -> str:
    if choice != "auto":
        return choice
    try:
        import torch

        return "cuda" if torch.cuda.is_available() else "cpu"
    except Exception:
        return "cpu"


def normalize_tracks(tracks: list[str], env: dict[str, str]) -> tuple[list[str], tempfile.TemporaryDirectory[str]]:
    temp_dir = tempfile.TemporaryDirectory(prefix="demucs_inputs_")
    normalized_dir = Path(temp_dir.name)
    ffmpeg_exe = BIN_DIR / "ffmpeg.exe"

    used_names: set[str] = set()
    normalized_tracks: list[str] = []

    for index, raw_track in enumerate(tracks, start=1):
        source = Path(raw_track).resolve()
        if not source.exists():
            temp_dir.cleanup()
            raise FileNotFoundError(f"Input file not found: {source}")

        base_name = source.stem
        target_name = f"{base_name}.wav"
        if target_name.lower() in used_names:
            target_name = f"{base_name}_{index:02d}.wav"
        used_names.add(target_name.lower())

        target = normalized_dir / target_name
        ffmpeg_command = [
            str(ffmpeg_exe),
            "-y",
            "-i",
            str(source),
            "-vn",
            "-ac",
            "2",
            "-ar",
            "44100",
            "-c:a",
            "pcm_s16le",
            str(target),
        ]
        subprocess.run(ffmpeg_command, check=True, env=env, stdout=subprocess.DEVNULL)
        normalized_tracks.append(str(target))

    return normalized_tracks, temp_dir


def main() -> int:
    args = parse_args()
    env = prepare_runtime_env()

    model_name = resolve_model_name(args.preset, args.model)
    out_dir = Path(args.out).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    normalized_tracks, temp_dir = normalize_tracks(args.tracks, env)

    command = [
        sys.executable,
        "-m",
        "demucs.separate",
        "-n",
        model_name,
        "-o",
        str(out_dir),
        "--two-stems",
        "vocals",
        "-d",
        resolve_device(args.device),
        "-j",
        str(args.jobs),
        "--shifts",
        str(args.shifts),
        "--overlap",
        str(args.overlap),
        "--filename",
        args.filename,
    ]

    if args.segment:
        command.extend(["--segment", str(args.segment)])
    if args.mp3:
        command.append("--mp3")
    if args.float32:
        command.append("--float32")

    command.extend(normalized_tracks)

    print(f"[INFO] Preset: {args.preset}")
    print(f"[INFO] Model: {model_name}")
    print(f"[INFO] Device: {resolve_device(args.device)}")
    print(f"[INFO] Output: {out_dir}")
    print("[INFO] Input normalization: ffmpeg -> 44.1kHz stereo WAV")
    print("[INFO] Running Demucs...")

    try:
        subprocess.run(command, check=True, env=env)
    finally:
        temp_dir.cleanup()
    print("[OK] Separation complete.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
