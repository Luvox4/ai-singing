# AI Singing Local Guide

Updated: 2026-03-31

This project is now organized for local use only.

Removed scope:

- remote server deployment
- SSH tunnel forwarding
- server-side training helpers

## Requirements

- Windows 10/11
- Git
- Python 3.10.x
- `uv`
- NVIDIA GPU if you want GPU training

## Initial Setup

```powershell
git clone --recurse-submodules https://github.com/Luvox4/ai-singing.git
cd ai-singing
.\setup.bat
```

`setup.bat` now builds the local `.venv` with `uv`, syncs from [uv.lock](/D:/Project/ai-singing/uv.lock), installs the filtered `seed-vc` dependencies, and applies the Windows torch compatibility fix.

If `.env` is missing, setup creates it from `.env.example`. Add your Hugging Face token:

```text
HUGGING_FACE_HUB_TOKEN=hf_your_token_here
```

## Local Commands

Main Web UI:

```powershell
.\scripts\start_webui.bat
```

SVC Web UI:

```powershell
.\scripts\start_svc.bat
```

Training:

```powershell
.\scripts\train.bat
```

Inference:

```powershell
.\scripts\infer.bat
```

Manual vocal separation:

```powershell
uv run --no-sync --cache-dir .uv-cache --python .venv\Scripts\python.exe python .\vocal_separation\download_models.py --preset best
uv run --no-sync --cache-dir .uv-cache --python .venv\Scripts\python.exe python .\vocal_separation\separate.py .\vocal_separation\input\song.flac --preset best --device cuda
```

## Training Notes

- Put training audio under `data/raw/`
- The validated GPU stack in this workspace is `torch 2.7.1+cu128`
- The current `external/seed-vc` base commit is `51383ef` (`fixe dataloader build bug when fine-tuning v1 model`)
- `external/seed-vc` compatibility fixes are applied locally by [tools/patch_seed_vc.py](/D:/Project/ai-singing/tools/patch_seed_vc.py)
- Local launch scripts restore those patched files afterwards through [tools/restore_seed_vc.py](/D:/Project/ai-singing/tools/restore_seed_vc.py), so the submodule does not need to stay permanently modified

## Compatibility Notes

- The local compatibility patch only changes runtime dtype handling in `seed-vc`
- The patch targets:
  - `app.py`
  - `app_svc.py`
  - `seed_vc_wrapper.py`
- Purpose:
  - fall back to `float32` when running on CPU paths
  - keep the validated local Windows workflow stable with the current `uv` environment
- The patch is not a version fork; it is applied on top of the checked-out `51383ef` submodule revision and then restored

## Related Docs

- [docs/new_computer_setup.md](/D:/Project/ai-singing/docs/new_computer_setup.md)
- [docs/other_computer_run_guide.md](/D:/Project/ai-singing/docs/other_computer_run_guide.md)
- [docs/current_workspace_status.md](/D:/Project/ai-singing/docs/current_workspace_status.md)
- [docs/decisions.md](/D:/Project/ai-singing/docs/decisions.md)
