from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


ROOT_DIR = Path(__file__).resolve().parent.parent
SEED_VC_DIR = ROOT_DIR / "external" / "seed-vc"


@dataclass(frozen=True)
class Replacement:
    old: str
    new: str
    label: str


PATCHES: dict[str, list[Replacement]] = {
    "app.py": [
        Replacement(
            old="dtype = torch.float16\n",
            new='dtype = torch.float16 if device.type == "cuda" else torch.float32\n',
            label="CPU-safe default dtype",
        ),
    ],
    "app_svc.py": [
        Replacement(
            old='        whisper_model = WhisperModel.from_pretrained(whisper_name, torch_dtype=torch.float16).to(device)\n',
            new='        whisper_dtype = torch.float16 if device.type == "cuda" and fp16 else torch.float32\n'
            '        whisper_model = WhisperModel.from_pretrained(whisper_name, torch_dtype=whisper_dtype).to(device)\n',
            label="CPU-safe Whisper dtype",
        ),
    ],
    "seed_vc_wrapper.py": [
        Replacement(
            old='        self.whisper_model = WhisperModel.from_pretrained(whisper_name, torch_dtype=torch.float16).to(self.device)\n',
            new='        whisper_dtype = torch.float16 if self.device.type == "cuda" else torch.float32\n'
            '        self.whisper_model = WhisperModel.from_pretrained(whisper_name, torch_dtype=whisper_dtype).to(self.device)\n',
            label="Wrapper Whisper dtype",
        ),
        Replacement(
            old='            with torch.autocast(device_type=self.device.type, dtype=torch.float16):\n',
            new='            autocast_dtype = torch.float16 if self.device.type == "cuda" else torch.float32\n'
            '            with torch.autocast(device_type=self.device.type, dtype=autocast_dtype):\n',
            label="CPU-safe autocast dtype",
        ),
    ],
}


def apply_replacement(text: str, replacement: Replacement, file_path: Path) -> tuple[str, bool]:
    if replacement.new in text:
        return text, False
    if replacement.old not in text:
        raise RuntimeError(f"{file_path}: expected snippet not found for {replacement.label}")
    return text.replace(replacement.old, replacement.new, 1), True


def patch_file(file_path: Path, replacements: list[Replacement]) -> None:
    if not file_path.exists():
        raise FileNotFoundError(f"Missing seed-vc file: {file_path}")

    text = file_path.read_text(encoding="utf-8")
    patched = False
    for replacement in replacements:
        text, changed = apply_replacement(text, replacement, file_path)
        patched = patched or changed

    if patched:
        file_path.write_text(text, encoding="utf-8")
        print(f"[PATCHED] {file_path.relative_to(ROOT_DIR)}")
    else:
        print(f"[OK] {file_path.relative_to(ROOT_DIR)} already patched")


def main() -> int:
    if not SEED_VC_DIR.exists():
        raise FileNotFoundError(f"seed-vc submodule directory not found: {SEED_VC_DIR}")

    for relative_path, replacements in PATCHES.items():
        patch_file(SEED_VC_DIR / relative_path, replacements)

    print("[OK] seed-vc patches are ready.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
