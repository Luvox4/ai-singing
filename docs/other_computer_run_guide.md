# Run On Another PC

Updated: 2026-03-31

Use this when you want to bring the current repo state onto another Windows machine.

## Prerequisites

Install these first:

- Git
- Python 3.10.x
- `uv`
- NVIDIA driver if you want GPU acceleration

## Fresh Setup

```powershell
git clone --recurse-submodules https://github.com/Luvox4/ai-singing.git
cd ai-singing
.\setup.bat
```

Then edit `.env` and add:

```text
HUGGING_FACE_HUB_TOKEN=hf_your_token_here
```

## Update An Existing Checkout

```powershell
git pull origin main
git submodule update --init --recursive
.\setup.bat
```

Do not copy `.venv` from another machine. Rebuild it locally with `.\setup.bat`.

## Common Commands

Launch the main UI:

```powershell
.\scripts\start_webui.bat
```

Launch the SVC UI:

```powershell
.\scripts\start_svc.bat
```

Start training:

```powershell
.\scripts\train.bat
```

Run vocal separation:

```powershell
uv run --no-sync --cache-dir .uv-cache --python .venv\Scripts\python.exe python .\vocal_separation\separate.py .\vocal_separation\input\song.flac --preset best --device cuda
```

## Important Notes

- The project now uses `uv` as the primary dependency manager on Windows.
- The Windows setup installs the local torch runtime from [uv.lock](/D:/Project/ai-singing/uv.lock).
- `seed-vc` compatibility patches are applied by repo tooling at runtime and restored afterwards. They are not meant to be edited manually.
- The current `seed-vc` submodule base revision is `51383ef`.
- If GPU training fails on a new Windows machine, verify the NVIDIA driver first, then rerun `.\setup.bat`.
