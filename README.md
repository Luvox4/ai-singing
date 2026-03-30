# AI Singing

Local-first AI singing workflow built around `seed-vc`, `uv`, and a Windows GPU setup.

This repo is now maintained for:

- local training
- local inference
- local vocal separation

It is not maintained for server deployment or SSH tunnel workflows.

## Quick Start

Requirements:

- Windows 10/11
- Git
- Python 3.10.x
- `uv`
- NVIDIA GPU for GPU training

Setup:

```powershell
git clone --recurse-submodules https://github.com/Luvox4/ai-singing.git
cd ai-singing
.\setup.bat
```

Then add your Hugging Face token to `.env`:

```text
HUGGING_FACE_HUB_TOKEN=hf_your_token_here
```

## Main Commands

Web UI:

```powershell
.\scripts\start_webui.bat
```

SVC UI:

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
uv run --no-sync --cache-dir .uv-cache --python .venv\Scripts\python.exe python .\vocal_separation\separate.py .\vocal_separation\input\song.flac --preset best --device cuda
```

## Current Baseline

- Python: `3.10`
- Package manager: `uv`
- Validated torch stack: `2.7.1+cu128`
- `seed-vc` submodule base: `51383ef`

## Docs

- [GUIDE.md](/D:/Project/ai-singing/GUIDE.md)
  Local operator guide.
- [docs/current_workspace_status.md](/D:/Project/ai-singing/docs/current_workspace_status.md)
  Current validated repo and machine state.
- [docs/decisions.md](/D:/Project/ai-singing/docs/decisions.md)
  Durable technical decisions behind the current structure.
- [docs/new_computer_setup.md](/D:/Project/ai-singing/docs/new_computer_setup.md)
  Fresh machine setup.
- [docs/other_computer_run_guide.md](/D:/Project/ai-singing/docs/other_computer_run_guide.md)
  Existing checkout / another-machine flow.
