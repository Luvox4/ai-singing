from __future__ import annotations

import re
from pathlib import Path


ROOT_DIR = Path(__file__).resolve().parent.parent
TMP_DIR = ROOT_DIR / ".tmp"
SOURCE_REQUIREMENTS = ROOT_DIR / "external" / "seed-vc" / "requirements.txt"
FILTERED_REQUIREMENTS = TMP_DIR / "seed-vc.requirements.filtered.txt"
EXCLUDES_FILE = TMP_DIR / "seed-vc.exclude.txt"
SKIP_PACKAGES = {"torch", "torchvision", "torchaudio"}
EXCLUDE_PACKAGES = ["webrtcvad"]


def extract_name(line: str) -> str | None:
    candidate = line.strip()
    if not candidate or candidate.startswith("#"):
        return None

    match = re.match(r"([A-Za-z0-9_.-]+)", candidate)
    if not match:
        return None
    return match.group(1).lower().replace("_", "-")


def main() -> int:
    if not SOURCE_REQUIREMENTS.exists():
        raise FileNotFoundError(f"Missing requirements file: {SOURCE_REQUIREMENTS}")

    TMP_DIR.mkdir(parents=True, exist_ok=True)

    filtered_lines: list[str] = []
    for raw_line in SOURCE_REQUIREMENTS.read_text(encoding="utf-8").splitlines():
        package_name = extract_name(raw_line)
        if package_name in SKIP_PACKAGES:
            continue
        filtered_lines.append(raw_line)

    FILTERED_REQUIREMENTS.write_text("\n".join(filtered_lines).rstrip() + "\n", encoding="utf-8")
    EXCLUDES_FILE.write_text("\n".join(EXCLUDE_PACKAGES) + "\n", encoding="utf-8")

    print(f"[OK] Wrote {FILTERED_REQUIREMENTS.relative_to(ROOT_DIR)}")
    print(f"[OK] Wrote {EXCLUDES_FILE.relative_to(ROOT_DIR)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
