# New Computer Setup

Updated: 2026-03-31

## Windows Workflow

This repo now expects a local `uv`-managed `.venv`.

Install these first:

- Git
- Python 3.10.x
- `uv`
- NVIDIA driver and CUDA-capable GPU if you want GPU training

Clone the repo and submodules:

```powershell
git clone --recurse-submodules https://github.com/Luvox4/ai-singing.git
cd ai-singing
```

Run the project setup:

```powershell
.\setup.bat
```

`setup.bat` now does the following:

- creates `.venv` with `uv`
- syncs the main project dependencies from [uv.lock](/D:/Project/ai-singing/uv.lock)
- installs filtered `seed-vc` dependencies without overwriting the local torch build
- applies the Windows torch DLL compatibility fix when needed
- applies the local `seed-vc` compatibility patch
- creates `.env` from `.env.example` if missing

Add your Hugging Face token to `.env`:

```text
HUGGING_FACE_HUB_TOKEN=hf_your_token_here
```

## Common Commands

Launch the combined Web UI:

```powershell
.\scripts\start_webui.bat
```

Launch the SVC UI:

```powershell
.\scripts\start_svc.bat
```

Run training:

```powershell
.\scripts\train.bat
```

Run vocal separation manually:

```powershell
uv run --no-sync --cache-dir .uv-cache --python .venv\Scripts\python.exe python .\vocal_separation\download_models.py --preset best
uv run --no-sync --cache-dir .uv-cache --python .venv\Scripts\python.exe python .\vocal_separation\separate.py .\vocal_separation\input\song.flac --preset best --device cuda
```

## Notes

- The validated Windows GPU stack in this workspace is `torch 2.7.1+cu128`.
- `external/seed-vc` is patched locally by the repo tooling; you do not need to edit it by hand.
- Do not copy `.venv` from another machine. Run `.\setup.bat` on each machine instead.
