# AI 演唱模型 - 完整使用指南

> 基于 [Seed-VC](https://github.com/Plachtaa/seed-vc)，使用你自己的声音进行歌声转换与克隆

---

## 目录

1. [项目概述](#1-项目概述)
2. [环境要求](#2-环境要求)
3. [本地安装](#3-本地安装)
4. [声音数据采集指南](#4-声音数据采集指南)
5. [数据预处理](#5-数据预处理)
6. [模型选择说明](#6-模型选择说明)
7. [零样本使用（无需训练）](#7-零样本使用无需训练)
8. [微调训练（本地）](#8-微调训练本地)
9. [服务器训练部署](#9-服务器训练部署)
10. [推理与歌声转换](#10-推理与歌声转换)
11. [常见问题](#11-常见问题)

---

## 1. 项目概述

本项目使用 **Seed-VC** 作为核心模型，实现以下功能：

| 功能 | 说明 |
|------|------|
| **零样本歌声转换** | 只需 1~30 秒参考录音，无需训练即可将任意歌曲转为你的声音 |
| **微调模型** | 用更多数据训练，让声音克隆更精准 |
| **实时语音转换** | 约 300ms 延迟，适合直播/会议 |

**推荐工作流：**
```
采集声音 -> 预处理数据 -> 零样本测试 -> 微调训练 -> 高质量推理
```

---

## 2. 环境要求

### 本地（推理 + 微调）
- **操作系统**：Windows 10/11 或 Linux
- **Python**：3.10（严格要求，其他版本可能兼容性差）
- **内存**：16GB RAM 以上
- **显卡**（推荐）：NVIDIA GPU，显存 ≥ 6GB（CUDA 11.8 或 12.1）
- **硬盘**：至少 10GB 可用空间（模型文件约 2-4GB）

> **无 GPU 也可运行**，但推理速度会很慢（约 3-5 分钟/首歌）

### 服务器（推荐用于训练）
- **GPU**：NVIDIA A100/V100/3090/4090（显存 16GB+）
- **CUDA**：12.1+
- **系统**：Ubuntu 20.04+

---

## 3. 本地安装

### 第一步：克隆项目

```bash
git clone --recurse-submodules https://github.com/Luvox4/ai-singing.git
cd ai-singing
```

如果已克隆但子模块为空：
```bash
git submodule update --init --recursive
```

### 第二步：运行安装脚本（Windows）

双击运行：
```
setup.bat
```

或手动安装：
```bash
# 创建虚拟环境
python -m venv .venv
.venv\Scripts\activate

# 安装 PyTorch（CUDA 12.1）
pip install torch==2.4.0 torchvision==0.19.0 torchaudio==2.4.0 --index-url https://download.pytorch.org/whl/cu121

# 安装依赖
cd external/seed-vc
pip install -r requirements.txt
cd ../..
```

### 第三步：配置环境变量

```bash
cp .env.example .env
```

编辑 `.env` 文件：
```
HUGGING_FACE_HUB_TOKEN=hf_xxxxxxxxxxxxxxxx
```

> 从 https://huggingface.co/settings/tokens 免费获取 Token（需注册账号）
> 如果访问 HuggingFace 困难，在 .env 中取消注释：`HF_ENDPOINT=https://hf-mirror.com`

### 第四步：验证安装

```bash
.venv\Scripts\activate
python -c "import torch; print('CUDA:', torch.cuda.is_available(), '| Device:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'CPU')"
```

---

## 4. 声音数据采集指南

> 数据质量比数量更重要！

### 录音要求

| 要求 | 说明 |
|------|------|
| **时长** | 每条 1~30 秒，总时长建议 5~30 分钟 |
| **格式** | .wav / .flac / .mp3 / .m4a |
| **采样率** | 44100Hz（歌声）或 22050Hz（语音）|
| **环境** | 安静房间，无回声，无背景音乐 |
| **设备** | 手机录音机 / 专业麦克风（建模效果更好）|

### 推荐录音内容

**方案 A：唱歌录音（推荐用于歌声转换）**
- 用原唱伴奏或无伴奏清唱 10~20 首歌曲片段
- 每段 15~30 秒，覆盖不同音调（高中低音）
- 包含真声和假声（如果你会用的话）

**方案 B：朗读录音（基础方案）**
- 朗读中文/英文文章段落
- 覆盖丰富的音素和语调变化
- 每条 5~20 秒

**方案 C：混合录音（最佳效果）**
- 唱歌 + 朗读 + 日常口语
- 总计 15~30 分钟音频

### 录音步骤

1. **准备安静环境**：关窗、关空调，尽量减少噪音
2. **设备测试**：先录一段回放，确认音质清晰
3. **保持一致距离**：嘴巴到麦克风距离保持 10~20cm
4. **多种内容**：
   ```
   # 推荐录音内容示例（中文）：
   - 歌曲片段：《晴天》《稻香》《青花瓷》等，每首唱 2~3 段
   - 朗读：任意书籍/文章片段
   - 对话：模拟日常说话
   ```
5. **保存文件**：统一放入 `data/raw_recordings/` 目录

### 目录结构

```
data/
├── raw_recordings/     # 你的原始录音（未处理）
│   ├── song_001.wav
│   ├── song_002.wav
│   └── reading_001.mp3
└── raw/                # 预处理后的训练数据（自动生成）
```

---

## 5. 数据预处理

将原始录音预处理为训练格式：

```bash
.venv\Scripts\activate

python tools/preprocess_audio.py \
    --input data/raw_recordings \
    --output data/raw \
    --target-sr 44100
```

该脚本自动完成：
- 格式统一转换为 WAV
- 重采样到 44100Hz
- 去除开头/结尾静音
- 自动切割超长片段（>30s）
- 音量规范化

---

## 6. 模型选择说明

本项目使用 **Seed-VC 的歌声转换模型（SVC）**：

| 模型 | 用途 | 参数量 | 推荐场景 |
|------|------|--------|----------|
| `seed-uvit-whisper-base` | **歌声转换** ⭐ | 200M | 高质量歌唱转换（推荐） |
| `seed-uvit-whisper-small-wavenet` | 语音转换 | 98M | 日常说话声音克隆 |
| `seed-uvit-tat-xlsr-tiny` | 实时语音转换 | 25M | 实时变声（直播/会议） |

**本项目选用 `seed-uvit-whisper-base`（歌声转换）**，理由：
- 专为歌唱设计，支持 F0 音高控制
- 44100Hz 高品质输出
- 零样本效果最强

---

## 7. 零样本使用（无需训练）

**最快方式**：只需一段你的声音录音作为参考，直接转换歌曲。

### 方法 A：Web UI（推荐新手）

```bash
# Windows
scripts\start_svc.bat

# 或手动
.venv\Scripts\activate
cd external/seed-vc
python app_svc.py
```

打开浏览器：http://localhost:7860

操作步骤：
1. 上传**源音频**（你想转换的歌曲，人声部分）
2. 上传**参考音频**（你的声音录音，5~30 秒）
3. 点击 Convert
4. 下载结果

### 方法 B：命令行

```bash
.venv\Scripts\activate
cd external/seed-vc

python inference.py \
    --source "你的歌曲.wav" \
    --target "你的声音参考.wav" \
    --output "output/" \
    --diffusion-steps 30 \
    --f0-condition True \
    --semi-tone-shift 0
```

参数说明：
- `--diffusion-steps 30`：质量步数，越高越好但越慢（推荐 30-50）
- `--f0-condition True`：歌声转换必须开启
- `--semi-tone-shift`：音高调整（正数升调，负数降调，单位：半音）

---

## 8. 微调训练（本地）

微调后声音相似度会显著提升。

### 准备数据

确保 `data/raw/` 中有处理好的 WAV 文件（至少 1 条，推荐 50+ 条）

### 开始训练（Windows）

双击运行：
```
scripts\train.bat
```

或命令行：
```bash
.venv\Scripts\activate
cd external/seed-vc

python train.py \
    --config configs/presets/config_dit_mel_seed_uvit_whisper_base_f0_44k.yml \
    --dataset-dir ../../data/raw \
    --run-name my_voice_model \
    --batch-size 2 \
    --max-steps 1000 \
    --max-epochs 1000 \
    --save-every 200 \
    --num-workers 0
```

### 训练参数建议

| 数据量 | 推荐步数 | 时间（RTX 3060） |
|--------|----------|-----------------|
| < 5 分钟 | 500~1000 步 | ~10~20 分钟 |
| 5~15 分钟 | 1000~2000 步 | ~20~40 分钟 |
| > 15 分钟 | 2000~5000 步 | ~1~2 小时 |

### 训练完成后

模型保存在：`external/seed-vc/runs/my_voice_model/`

使用微调模型推理：
```bash
python inference.py \
    --source "歌曲.wav" \
    --target "参考声音.wav" \
    --output "output/" \
    --checkpoint "runs/my_voice_model/model_500.pth" \
    --config "configs/presets/config_dit_mel_seed_uvit_whisper_base_f0_44k.yml" \
    --diffusion-steps 30 \
    --f0-condition True
```

---

## 9. 服务器训练部署

适合需要大量数据和更多训练步数的场景。

### 9.1 准备服务器

推荐云服务商：
- **AutoDL**（国内，性价比高，RTX 3090 约 1.8¥/小时）
- **RunPod / Vast.ai**（海外，支持 A100）
- **阿里云/腾讯云 GPU 实例**

推荐实例：
- RTX 3090 (24GB) 或 A100 (40GB)
- Ubuntu 20.04，CUDA 12.1，Python 3.10

### 9.2 服务器部署步骤

```bash
# 1. 克隆项目（在服务器上）
git clone --recurse-submodules https://github.com/Luvox4/ai-singing.git
cd ai-singing

# 2. 运行服务器安装脚本
bash scripts/setup_server.sh

# 3. 上传你的声音数据到服务器
# 方式1：使用 scp
scp -r data/raw/ user@server_ip:~/ai-singing/data/

# 方式2：使用 rsync（断点续传）
rsync -avz data/raw/ user@server_ip:~/ai-singing/data/raw/

# 方式3：如果服务器在国内，可以通过 OSS/对象存储中转

# 4. 开始训练
bash scripts/train_server.sh
```

### 9.3 使用 tmux 保持训练不中断

```bash
# 服务器上
tmux new -s train
bash scripts/train_server.sh

# 断开 SSH 后，重新连接：
tmux attach -t train
```

### 9.4 将训练好的模型下载到本地

```bash
# 在本地执行
scp -r user@server_ip:~/ai-singing/external/seed-vc/runs/my_voice_model/ models/checkpoints/
```

### 9.5 使用服务器模型在本地推理

```bash
# 修改 scripts/infer.bat 中的 CHECKPOINT 路径
set CHECKPOINT=../../models/checkpoints/my_voice_model/model_final.pth
set CONFIG=../../external/seed-vc/configs/presets/config_dit_mel_seed_uvit_whisper_base_f0_44k.yml
```

---

## 10. 推理与歌声转换

### 最佳实践

1. **源音频处理**：
   - 推荐使用**人声分离工具**（如 UVR5、Demucs）提取干净人声
   - 去除背景音乐，让声音转换更精准
   - 工具：https://github.com/Anjok07/ultimatevocalremovergui

2. **参考音频选择**：
   - 选择你录音中音调最清晰的片段
   - 长度 10~30 秒效果最佳
   - 音调应与源歌曲接近

3. **参数调整**：
   - `diffusion-steps`：30 质量，50 高质量，10 快速预览
   - `semi-tone-shift`：转调，+12 升八度，-12 降八度
   - `inference-cfg-rate`：0.7 默认，0.0 更快但相似度降低

### 完整工作流示例

```bash
# 步骤1：用 UVR5 分离歌曲人声
# 输入：原曲.mp3 -> 输出：vocals.wav + instrumental.wav

# 步骤2：转换人声（用你的声音）
python inference.py \
    --source "vocals.wav" \
    --target "my_voice_reference.wav" \
    --output "output/" \
    --diffusion-steps 40 \
    --f0-condition True

# 步骤3：用音频编辑软件合并人声和伴奏
# 推荐工具：Audacity（免费）或 Adobe Audition
```

---

## 11. 常见问题

**Q: 第一次运行需要下载什么？**
A: 首次运行会自动从 HuggingFace 下载模型（约 1-2GB），需要 HF Token 和网络。国内用户设置 `HF_ENDPOINT=https://hf-mirror.com`。

**Q: 没有 GPU 能运行吗？**
A: 可以，但推理一首歌可能需要 5~10 分钟。训练会非常慢，建议用服务器。

**Q: 效果不好怎么办？**
A: 检查以下：1）参考音频是否足够清晰干净；2）是否开启了 `--f0-condition True`；3）增加 `--diffusion-steps` 到 50；4）提供更多训练数据做微调。

**Q: 训练出现 CUDA OOM 错误？**
A: 减小 `--batch-size` 到 1，同时确保没有其他程序占用 GPU 显存。

**Q: 转换后音调不对？**
A: 使用 `--semi-tone-shift` 参数调整，或尝试 `--auto-f0-adjust True`（不推荐用于歌声）。

**Q: 如何提升训练效果？**
A: 1）增加训练数据量（建议 15 分钟+）；2）增加训练步数；3）确保录音环境干净无噪音。

---

## 项目结构

```
ai-singing/
├── data/
│   ├── raw_recordings/     # 你的原始录音（放这里）
│   ├── raw/                # 预处理后的训练数据
│   └── processed/          # 推理输出结果
├── models/
│   └── checkpoints/        # 训练好的模型存放处
├── external/
│   └── seed-vc/            # Seed-VC 核心（git submodule）
│       ├── train.py        # 训练脚本
│       ├── inference.py    # 推理脚本
│       ├── app_svc.py      # 歌声转换 Web UI
│       └── configs/        # 模型配置文件
├── scripts/
│   ├── setup.bat           # Windows 安装
│   ├── train.bat           # Windows 训练
│   ├── start_svc.bat       # 启动歌声转换 UI
│   ├── infer.bat           # 命令行推理
│   ├── setup_server.sh     # 服务器安装
│   └── train_server.sh     # 服务器训练
├── tools/
│   └── preprocess_audio.py # 音频预处理工具
├── setup.bat               # 快速安装入口
├── .env.example            # 环境变量模板
└── GUIDE.md                # 本文档
```

---

*由 Claude Code 生成 | 基于 Seed-VC (MIT License)*
