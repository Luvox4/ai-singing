from __future__ import annotations

import os
import shutil
from pathlib import Path

import imageio_ffmpeg


ROOT_DIR = Path(__file__).resolve().parent
INPUT_DIR = ROOT_DIR / "input"
OUTPUT_DIR = ROOT_DIR / "output"
MODELS_DIR = ROOT_DIR / "models"
BIN_DIR = ROOT_DIR / "bin"
TORCH_HOME_DIR = MODELS_DIR / "torch_home"

PRESETS = {
    "best": {
        "model": "htdemucs_ft",
        "description": "Official Demucs highest-quality vocal separation preset. Slowest but best default choice.",
    },
    "balanced": {
        "model": "htdemucs",
        "description": "Official Demucs balanced preset. Good quality with lower runtime than best.",
    },
    "fast": {
        "model": "mdx_extra",
        "description": "Official Demucs quick preview preset. Lower quality than htdemucs but easier to deploy than the quantized variant.",
    },
    "alt": {
        "model": "hdemucs_mmi",
        "description": "Official alternative Demucs preset. Useful as a second opinion on difficult mixes.",
    },
}


def ensure_layout() -> None:
    for path in [INPUT_DIR, OUTPUT_DIR, MODELS_DIR, BIN_DIR, TORCH_HOME_DIR]:
        path.mkdir(parents=True, exist_ok=True)


def ensure_ffmpeg_shim() -> Path:
    ensure_layout()
    source = Path(imageio_ffmpeg.get_ffmpeg_exe())
    target = BIN_DIR / "ffmpeg.exe"
    if not target.exists() or source.stat().st_mtime > target.stat().st_mtime:
        shutil.copy2(source, target)
    return target


def prepare_runtime_env() -> dict[str, str]:
    ffmpeg_path = ensure_ffmpeg_shim()
    env = os.environ.copy()
    env["TORCH_HOME"] = str(TORCH_HOME_DIR)
    env["PATH"] = str(ffmpeg_path.parent) + os.pathsep + env.get("PATH", "")
    return env


def resolve_model_name(preset: str | None = None, model: str | None = None) -> str:
    if model:
        return model
    if preset is None:
        preset = "best"
    try:
        return PRESETS[preset]["model"]
    except KeyError as exc:
        raise ValueError(f"Unknown preset: {preset}") from exc
