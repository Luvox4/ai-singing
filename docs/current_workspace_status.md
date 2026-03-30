# Current Workspace Status

Updated: 2026-03-31

## Summary

This repo now uses a local `uv`-managed `.venv` as the primary Windows workflow.

For the longer-lived architectural decisions behind that workflow, see [docs/decisions.md](/D:/Project/ai-singing/docs/decisions.md).

The current setup was validated on:

- Windows
- Python 3.10.11
- `uv 0.11.2`
- NVIDIA GeForce RTX 5070 Ti
- PyTorch `2.7.1+cu128`

## What Changed

- [pyproject.toml](/D:/Project/ai-singing/pyproject.toml)
  Added project-level `uv` dependency metadata for the local runtime.
- [uv.lock](/D:/Project/ai-singing/uv.lock)
  Added a locked dependency set for reproducible `uv sync`.
- [setup.bat](/D:/Project/ai-singing/setup.bat)
  Reworked to build the environment with `uv`, sync from `uv.lock`, install filtered `seed-vc` dependencies, and apply the Windows torch DLL fix.
- [scripts/resolve_python.bat](/D:/Project/ai-singing/scripts/resolve_python.bat)
  Now supports both bootstrap mode and strict project-venv mode.
- [scripts/start_webui.bat](/D:/Project/ai-singing/scripts/start_webui.bat)
  Now requires the project venv and launches through `uv run --no-sync`.
- [scripts/start_svc.bat](/D:/Project/ai-singing/scripts/start_svc.bat)
  Same runtime change as the main Web UI launcher.
- [scripts/train.bat](/D:/Project/ai-singing/scripts/train.bat)
  Same runtime change for training.
- [scripts/infer.bat](/D:/Project/ai-singing/scripts/infer.bat)
  Same runtime change for inference.
- [tools/prepare_seed_vc_requirements.py](/D:/Project/ai-singing/tools/prepare_seed_vc_requirements.py)
  Generates filtered install inputs so the local PyTorch build is not overwritten and `webrtcvad` can be excluded in favor of `webrtcvad-wheels`.
- [tools/fix_torch_windows.py](/D:/Project/ai-singing/tools/fix_torch_windows.py)
  Applies the local Windows DLL shim needed by this torch build when required.
- [.gitignore](/D:/Project/ai-singing/.gitignore)
  Ignores `.uv-cache/` and `.tmp/`.

## Runtime Patch Strategy

The `external/seed-vc` submodule is currently pinned to commit `51383ef`:

- `fixe dataloader build bug when fine-tuning v1 model`

That version still needs a small local compatibility patch for CPU-safe dtype handling in the Windows workflow.

The patch is carried by:

- [tools/patch_seed_vc.py](/D:/Project/ai-singing/tools/patch_seed_vc.py)
- [tools/restore_seed_vc.py](/D:/Project/ai-singing/tools/restore_seed_vc.py)

The main repo does not carry a forked `seed-vc` revision. Instead:

- setup installs dependencies only
- Windows launch scripts apply the compatibility patch before running `seed-vc`
- Windows launch scripts restore the original `seed-vc` files afterwards

Patched files:

- [app.py](/D:/Project/ai-singing/external/seed-vc/app.py)
- [app_svc.py](/D:/Project/ai-singing/external/seed-vc/app_svc.py)
- [seed_vc_wrapper.py](/D:/Project/ai-singing/external/seed-vc/seed_vc_wrapper.py)

## Verified State

- `torch.cuda.is_available()` returned `True`
- `torch.version.cuda` returned `12.8`
- allocating a tensor on `cuda:0` succeeded
- importing `external/seed-vc/train.py` in the local env succeeded
- Demucs vocal separation completed for one FLAC test input with both `fast` and `best`

Generated vocal separation outputs exist at:

- [vocals.wav](/D:/Project/ai-singing/vocal_separation/output/mdx_extra/%E6%9E%97%E4%BF%8A%E6%9D%B0%20-%20Always%20Online/vocals.wav)
- [no_vocals.wav](/D:/Project/ai-singing/vocal_separation/output/mdx_extra/%E6%9E%97%E4%BF%8A%E6%9D%B0%20-%20Always%20Online/no_vocals.wav)
- [vocals.wav](/D:/Project/ai-singing/vocal_separation/output/htdemucs_ft/%E6%9E%97%E4%BF%8A%E6%9D%B0%20-%20Always%20Online/vocals.wav)
- [no_vocals.wav](/D:/Project/ai-singing/vocal_separation/output/htdemucs_ft/%E6%9E%97%E4%BF%8A%E6%9D%B0%20-%20Always%20Online/no_vocals.wav)

## Current Commands

Initial setup:

```powershell
.\setup.bat
```

Training:

```powershell
.\scripts\train.bat
```

Web UI:

```powershell
.\scripts\start_webui.bat
```

SVC UI:

```powershell
.\scripts\start_svc.bat
```

Manual vocal separation:

```powershell
uv run --no-sync --cache-dir .uv-cache --python .venv\Scripts\python.exe python .\vocal_separation\separate.py .\vocal_separation\input\song.flac --preset best --device cuda
```

## Local-Only Files Not Included In This Cleanup

These root files are still local and were intentionally left out of the repo cleanup:

- [README.md](/D:/Project/ai-singing/README.md)
- [main.py](/D:/Project/ai-singing/main.py)
- [.python-version](/D:/Project/ai-singing/.python-version)
