# 人声分离工作区

这个目录专门用来做人声分离，基于官方 `Demucs` 模型部署。

## 目录说明

- `input/`
  放待分离的歌曲文件
- `output/`
  放分离后的结果
- `models/`
  放本地模型缓存
- `bin/`
  放本地 `ffmpeg.exe` shim
- `download_models.py`
  预下载模型
- `separate.py`
  统一的人声分离入口

## 推荐模型

- `best` -> `htdemucs_ft`
  官方 Demucs 里最推荐的高质量预设，适合正式分离
- `balanced` -> `htdemucs`
  质量和速度更平衡
- `fast` -> `mdx_extra`
  适合快速预览
- `alt` -> `hdemucs_mmi`
  可在某些难分离歌曲上做二次对比

## 常用命令

先下载推荐模型：

```powershell
.\.venv\Scripts\python.exe .\vocal_separation\download_models.py --preset best --preset balanced --preset fast
```

高质量分离：

```powershell
.\.venv\Scripts\python.exe .\vocal_separation\separate.py .\vocal_separation\input\song.mp3 --preset best --device auto
```

快速预览：

```powershell
.\.venv\Scripts\python.exe .\vocal_separation\separate.py .\vocal_separation\input\song.mp3 --preset fast --device auto
```

结果会输出到：

```text
vocal_separation/output/<模型名>/<歌曲名>/
```

其中你最关心的是：

- `vocals.wav`
- `no_vocals.wav`

## 运行细节

- `separate.py` 会先用本地 `ffmpeg` 把输入统一转成临时 `44.1kHz` 双声道 WAV
- 这样可以规避单声道、采样率不一致、部分容器格式带来的兼容问题
- 正式分离默认就用 `best`

## 建议

- 正式做 AI 翻唱时，优先用 `best`
- 先试听可以用 `fast`
- 如果某首歌分离不干净，可以再试 `balanced` 或 `alt`
