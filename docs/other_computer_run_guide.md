# 另一台电脑运行指南

这份文档面向一个目标：

- 在另一台 Windows 电脑上，把这个项目拉下来并跑起来

当前项目已经整理成：

- `git clone` 后
- 再执行一次 `setup.bat`
- 就能进入可用状态

不是“只 clone 不初始化就能直接运行”。

## 1. 前提条件

建议环境：

- Windows 10 或 Windows 11
- `Git`
- `Python 3.10.x`
- 可正常联网

如果你要用 GPU：

- NVIDIA 显卡
- 正常安装显卡驱动
- CUDA 运行环境兼容 `torch 2.4.0 + cu121`

如果你只是先测试：

- 没有 GPU 也能跑
- 但推理和人声分离会明显更慢

## 2. 第一次在新电脑上拉项目

打开 PowerShell，执行：

```powershell
git clone https://github.com/Luvox4/ai-singing.git
cd ai-singing
```

然后执行初始化脚本：

```powershell
.\setup.bat
```

这个脚本会自动完成：

- 初始化 `external/seed-vc` 子模块
- 创建 `.venv`
- 用清华镜像安装 Python 依赖
- 安装 `torch 2.4.0 / torchvision 0.19.0 / torchaudio 2.4.0`
- 自动给 `seed-vc` 应用本项目依赖的兼容补丁
- 安装本项目附加工具
- 自动创建 `.env`

## 3. 初始化完成后必须做的事

打开项目根目录下的 `.env`，至少填这个：

```text
HUGGING_FACE_HUB_TOKEN=你的token
```

如果你没有 token：

- 去 Hugging Face 注册账号
- 在 `https://huggingface.co/settings/tokens` 创建一个 token

## 4. 新电脑上最常用的运行方式

### 4.1 启动主 Web UI

```powershell
.\scripts\start_webui.bat
```

### 4.2 启动歌声转换 Web UI

```powershell
.\scripts\start_svc.bat
```

如果启动成功，通常在浏览器打开：

- `http://127.0.0.1:7860`
- 或者脚本输出里显示的本地地址

## 5. 新电脑上做人声分离

第一次使用前，先下载推荐模型：

```powershell
.\.venv\Scripts\python.exe .\vocal_separation\download_models.py --preset best --preset balanced --preset fast
```

正式分离：

```powershell
.\.venv\Scripts\python.exe .\vocal_separation\separate.py "D:\你的歌曲.flac" --preset best --device auto
```

快速试听：

```powershell
.\.venv\Scripts\python.exe .\vocal_separation\separate.py "D:\你的歌曲.flac" --preset fast --device auto
```

输出目录默认是：

```text
vocal_separation/output/<模型名>/<歌曲名>/
```

你最关心的是：

- `vocals.wav`
- `no_vocals.wav`

## 6. 新电脑上训练

先准备你自己的训练音频，放进项目数据目录。

然后直接运行：

```powershell
.\scripts\train.bat
```

如果你只是想先验证训练流程能不能跑：

- 先用少量数据
- 先跑少量步数
- 不要一上来就长时间训练

## 7. 新电脑上更新项目

以后如果你在主电脑上已经推送了更新，另一台电脑这样同步：

```powershell
git pull origin main
git submodule update --init --recursive
.\setup.bat
```

这样做的原因是：

- 主仓库代码会更新
- 子模块会同步到主仓库记录的版本
- `setup.bat` 会重新应用当前项目要求的兼容补丁

## 8. 如果另一台电脑拉下来后不能运行，先查这几项

### 8.1 Python 版本不对

确认：

```powershell
python --version
```

应该是：

- `Python 3.10.x`

### 8.2 子模块没初始化

执行：

```powershell
git submodule update --init --recursive
```

### 8.3 `.env` 没配

检查项目根目录下有没有：

- `.env`

并确认 `HUGGING_FACE_HUB_TOKEN` 已填。

### 8.4 没有 GPU

没有 GPU 也能跑，但会慢很多：

- 人声分离慢
- 推理慢
- 训练更慢

### 8.5 模型还没下载

人声分离模型和部分推理模型第一次运行时需要下载。

## 9. 推荐的最小工作流

如果你只是想在另一台电脑先跑通整条链路，按这个顺序：

1. `git clone`
2. `.\setup.bat`
3. 配 `.env`
4. 下载人声分离模型
5. 分离一首歌，拿到 `vocals.wav`
6. 启动 `start_svc.bat`
7. 做一次转换测试

## 10. 当前这份文档的定位

如果你只想看最短步骤，读：

- [new_computer_setup.md](D:\Project\Pycharm Project\ai-singing\docs\new_computer_setup.md)

如果你要完整上手流程，就看这份文档。
