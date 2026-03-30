from __future__ import annotations

import shutil
import sys
from pathlib import Path


def main() -> int:
    if sys.platform != "win32":
        print("[SKIP] Windows-only torch DLL compatibility fix is not needed on this platform.")
        return 0

    import torch

    lib_dir = Path(torch.__file__).resolve().parent / "lib"
    source = lib_dir / "libiomp5md.dll"
    target = lib_dir / "libomp140.x86_64.dll"

    if target.exists():
        print(f"[OK] {target.name} already present.")
        return 0

    if not source.exists():
        raise FileNotFoundError(f"Missing source DLL: {source}")

    shutil.copy2(source, target)
    print(f"[PATCHED] Copied {source.name} -> {target.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
