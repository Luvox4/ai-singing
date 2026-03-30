from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

from patch_seed_vc import PATCHES, ROOT_DIR, SEED_VC_DIR, Replacement


def locate_git() -> str | None:
    candidate = shutil.which("git")
    if candidate:
        return candidate

    known_paths = [
        Path("D:/Program Files/Git/cmd/git.exe"),
        Path("C:/Program Files/Git/cmd/git.exe"),
    ]
    for path in known_paths:
        if path.exists():
            return str(path)
    return None


def restore_with_git(relative_paths: list[str]) -> bool:
    git_executable = locate_git()
    if not git_executable:
        return False

    command = [
        git_executable,
        "-c",
        f"safe.directory={SEED_VC_DIR.as_posix()}",
        "-C",
        str(SEED_VC_DIR),
        "restore",
        "--source=HEAD",
        "--worktree",
        "--",
        *relative_paths,
    ]
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode != 0:
        return False

    for relative_path in relative_paths:
        print(f"[RESTORED] external/seed-vc/{relative_path}")
    return True


def reverse_replacement(text: str, replacement: Replacement, file_path: Path) -> tuple[str, bool]:
    if replacement.new not in text:
        if replacement.old in text:
            return text, False
        raise RuntimeError(f"{file_path}: expected snippet not found for {replacement.label}")
    return text.replace(replacement.new, replacement.old, 1), True


def restore_file(file_path: Path, replacements: list[Replacement]) -> None:
    if not file_path.exists():
        raise FileNotFoundError(f"Missing seed-vc file: {file_path}")

    text = file_path.read_text(encoding="utf-8")
    restored = False
    for replacement in replacements:
        text, changed = reverse_replacement(text, replacement, file_path)
        restored = restored or changed

    if restored:
        file_path.write_text(text, encoding="utf-8")
        print(f"[RESTORED] {file_path.relative_to(ROOT_DIR)}")
    else:
        print(f"[OK] {file_path.relative_to(ROOT_DIR)} already clean")


def main() -> int:
    if not SEED_VC_DIR.exists():
        raise FileNotFoundError(f"seed-vc submodule directory not found: {SEED_VC_DIR}")

    relative_paths = list(PATCHES.keys())
    if restore_with_git(relative_paths):
        print("[OK] seed-vc files restored from git.")
        return 0

    for relative_path, replacements in PATCHES.items():
        restore_file(SEED_VC_DIR / relative_path, replacements)

    print("[OK] seed-vc files restored without git.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
