# 新电脑初始化

这份文档只说明一件事：把当前仓库拉到另一台电脑后，怎样最快恢复成可用状态。

## 前提

- Windows 10/11
- 已安装 `Git`
- 已安装 `Python 3.10.x`
- 如需 GPU 推理或训练，已装对应 NVIDIA 驱动和 CUDA 运行环境

## 推荐步骤

1. 克隆仓库

```powershell
git clone https://github.com/Luvox4/ai-singing.git
cd ai-singing
```

2. 运行初始化脚本

```powershell
.\setup.bat
```

`setup.bat` 现在会自动做这些事：

- 初始化 `external/seed-vc` 子模块
- 创建 `.venv`
- 用清华镜像安装依赖
- 给 `seed-vc` 自动打上当前仓库依赖的兼容补丁
- 安装本项目附加工具，包括人声分离依赖
- 自动复制 `.env.example` 为 `.env`

3. 编辑 `.env`

至少补上：

```text
HUGGING_FACE_HUB_TOKEN=你的 token
```

## 初始化完成后怎么用

- 启动 Web UI：

```powershell
.\scripts\start_webui.bat
```

- 启动歌声转换 Web UI：

```powershell
.\scripts\start_svc.bat
```

- 使用人声分离：

```powershell
.\.venv\Scripts\python.exe .\vocal_separation\download_models.py --preset best --preset balanced --preset fast
.\.venv\Scripts\python.exe .\vocal_separation\separate.py "D:\你的歌曲.flac" --preset best --device auto
```

## 注意

- 不是“只 clone 就能直接运行”，因为模型和 Python 环境本来就不进 Git
- 现在的目标是“`clone + setup.bat` 后可用”
- `external/seed-vc` 仍然是子模块，但仓库已经把必须的本地兼容修复自动化了
