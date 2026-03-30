# Project Decisions

Updated: 2026-03-31

This document records the durable technical decisions behind the current local workflow.

## 1. Scope: Local-Only Workflow

Decision:

- This repo is maintained for local Windows use only.
- Server deployment, SSH tunnel forwarding, and remote training helpers were removed from the main workflow.

Why:

- The actual use case is local training, local inference, and local vocal separation.
- Keeping remote-only scripts created maintenance overhead and mixed two different operating models in one repo.

Result:

- `scripts/` only keeps local Windows entry points.
- `GUIDE.md` describes local usage only.

## 2. Package Management: `uv` Is The Source Of Truth

Decision:

- The project uses a local `uv`-managed `.venv`.
- The main dependency baseline is tracked in [pyproject.toml](/D:/Project/ai-singing/pyproject.toml) and [uv.lock](/D:/Project/ai-singing/uv.lock).

Why:

- The previous mixed `venv + pip + ad-hoc installs` flow was harder to reproduce.
- `uv` gives a stable local environment and a lockfile that documents the exact runtime set.

Result:

- [setup.bat](/D:/Project/ai-singing/setup.bat) now bootstraps the local environment with `uv`.
- Windows launch scripts assume the project `.venv` exists.

## 3. GPU Compatibility: Use `torch 2.7.1+cu128`

Decision:

- The validated local GPU stack is:
  - `torch==2.7.1+cu128`
  - `torchvision==0.22.1+cu128`
  - `torchaudio==2.7.1+cu128`

Why:

- This machine uses an RTX 5070 Ti.
- The earlier `torch 2.4.0 + cu121` stack was not the correct fit for the current GPU architecture.

Result:

- The lockfile and local setup are aligned with the validated CUDA 12.8 stack.
- The project is documented against that local baseline.

## 4. Submodule Strategy: Keep `seed-vc` Upstream, Patch At Runtime

Decision:

- The repo keeps `external/seed-vc` at its checked-out upstream submodule revision.
- The current local baseline is `51383ef`:
  - `fixe dataloader build bug when fine-tuning v1 model`
- Compatibility changes are applied at runtime and restored afterwards.

Why:

- Forking the submodule in-place would make updates and provenance harder to reason about.
- The local compatibility change is narrow and operational, not a project-level reimplementation.

Result:

- Runtime patching is implemented in [tools/patch_seed_vc.py](/D:/Project/ai-singing/tools/patch_seed_vc.py).
- Restoration is implemented in [tools/restore_seed_vc.py](/D:/Project/ai-singing/tools/restore_seed_vc.py).
- Launch scripts patch before running and restore afterwards.

## 5. Compatibility Patch Policy

Decision:

- The compatibility patch only changes runtime dtype handling in `seed-vc`.

Patched files:

- [app.py](/D:/Project/ai-singing/external/seed-vc/app.py)
- [app_svc.py](/D:/Project/ai-singing/external/seed-vc/app_svc.py)
- [seed_vc_wrapper.py](/D:/Project/ai-singing/external/seed-vc/seed_vc_wrapper.py)

Why:

- The local workflow needs CPU-safe fallback behavior in code paths that otherwise assume `float16`.
- The goal is compatibility, not behavioral redesign.

Result:

- The patch is intentionally small.
- The submodule should not stay permanently modified after local runs.

## 6. Dependency Filtering For `seed-vc`

Decision:

- `seed-vc` dependencies are not installed from its raw `requirements.txt` without filtering.

Why:

- The upstream file includes torch-related requirements that conflict with the validated local PyTorch stack.
- `webrtcvad` is also problematic on this Windows setup and is replaced operationally by `webrtcvad-wheels`.

Result:

- [tools/prepare_seed_vc_requirements.py](/D:/Project/ai-singing/tools/prepare_seed_vc_requirements.py) generates the filtered input used by setup.

## 7. Windows Torch DLL Fix Stays Local To The Venv

Decision:

- The Windows torch DLL compatibility fix is applied inside the project `.venv`, not at the system level.

Why:

- The issue is local to this runtime stack.
- Keeping the fix local reduces blast radius and keeps the workaround explicit.

Result:

- [tools/fix_torch_windows.py](/D:/Project/ai-singing/tools/fix_torch_windows.py) manages the local shim.

## 8. Documentation Structure

Decision:

- Project state is split across a few focused documents.

Roles:

- [GUIDE.md](/D:/Project/ai-singing/GUIDE.md)
  Current local operator guide.
- [docs/current_workspace_status.md](/D:/Project/ai-singing/docs/current_workspace_status.md)
  Current validated machine and repo state.
- [docs/new_computer_setup.md](/D:/Project/ai-singing/docs/new_computer_setup.md)
  Fresh machine setup steps.
- [docs/other_computer_run_guide.md](/D:/Project/ai-singing/docs/other_computer_run_guide.md)
  Existing checkout / another-machine run flow.
- [docs/decisions.md](/D:/Project/ai-singing/docs/decisions.md)
  Why the repo is structured this way.

## 9. What Should Not Be Assumed

- Do not assume remote/server scripts still exist.
- Do not assume `setup.bat` leaves `seed-vc` permanently patched.
- Do not assume the submodule revision changed just because local patch tooling exists.
- Do not assume root-level local files such as [README.md](/D:/Project/ai-singing/README.md), [main.py](/D:/Project/ai-singing/main.py), or [.python-version](/D:/Project/ai-singing/.python-version) are part of the tracked project state.
