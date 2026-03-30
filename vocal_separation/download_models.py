from __future__ import annotations

import argparse
import os

from common import PRESETS, prepare_runtime_env, resolve_model_name


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Pre-download Demucs vocal separation models into the local project cache.")
    parser.add_argument(
        "--preset",
        action="append",
        choices=sorted(PRESETS.keys()),
        help="Preset(s) to download. Can be repeated. Defaults to best if omitted.",
    )
    parser.add_argument(
        "--all-presets",
        action="store_true",
        help="Download all built-in presets.",
    )
    parser.add_argument(
        "--model",
        action="append",
        help="Download an exact Demucs model name. Can be repeated.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    env = prepare_runtime_env()
    os.environ.update(env)

    from demucs.pretrained import get_model

    targets: list[str] = []
    if args.all_presets:
        targets.extend([data["model"] for data in PRESETS.values()])
    elif args.preset:
        targets.extend([resolve_model_name(preset=name) for name in args.preset])
    else:
        targets.append(resolve_model_name(preset="best"))

    if args.model:
        targets.extend(args.model)

    # Keep order while de-duplicating.
    unique_targets = list(dict.fromkeys(targets))
    for name in unique_targets:
        print(f"[INFO] Downloading model: {name}")
        get_model(name)
        print(f"[OK] Model ready: {name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
