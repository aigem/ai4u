#!/bin/bash

# F5TTS 应用配置
APP_NAME="f5tts"
APP_TYPE="cli"
APP_VERSION="1.0.0"

# 用于哪个平台的安装
PLATFORM_NAME="良心云"

# 应用特定配置
# 虚拟环境名称
VENV_NAME="ai_$APP_NAME"
# 虚拟环境目录(良心云的默认路径，其他环境请自行修改)
VENV_DIR="/root/miniconda3/envs/"
# python版本
PYTHON_VERSION="3.11"
# 工作目录: 用于存放下载的Ai应用
WORKSPACE_DIR="/workspace"
# 应用端口
APP_PORT="7860" 

# ================================================
# 以下内容不要修改
# ================================================

# 设置模型缓存路径
export HF_HOME="$WORKSPACE_DIR/cache"
# export TRANSFORMERS_CACHE="$WORKSPACE_DIR/cache"

# 设置下载目标目录
F5TTS_TARGET_DIR="$WORKSPACE_DIR/cache/huggingface/hub/models--SWivid--F5-TTS/snapshots/4dcc16f297f2ff98a17b3726b16f5de5a5e45672/F5TTS_Base"
E2TTS_TARGET_DIR="$WORKSPACE_DIR/cache/huggingface/hub/models--SWivid--E2-TTS/snapshots/98016df3e24487aad803aff506335caba8414195/E2TTS_Base"
WHISPER_TARGET_DIR="$WORKSPACE_DIR/cache/huggingface/hub/models--openai--whisper-large-v3-turbo/snapshots/41f01f3fe87f28c78e2fbf8b568835947dd65ed9/"

# 创建目录（如果不存在）
mkdir -p "$F5TTS_TARGET_DIR"
mkdir -p "$E2TTS_TARGET_DIR"
mkdir -p "$WHISPER_TARGET_DIR"
# aria2 下载命令
ARIA2_CMD1="aria2c -c -x 16 -s 16 -k 50M --max-download-limit=50M \
  -d \"$F5TTS_TARGET_DIR\" \
  -o \"model_1200000.safetensors\" \
  https://modelscope.cn/models/SWivid/F5-TTS_Emilia-ZH-EN/resolve/master/F5TTS_Base/model_1200000.safetensors"
ARIA2_CMD2="aria2c -c -x 16 -s 16 -k 50M --max-download-limit=50M \
  -d \"$E2TTS_TARGET_DIR\" \
  -o \"model_1200000.safetensors\" \
  https://modelscope.cn/models/SWivid/E2-TTS_Emilia-ZH-EN/resolve/master/E2TTS_Base/model_1200000.safetensors"

MODELSCOPE_CMD="modelscope download --model AI-ModelScope/whisper-large-v3-turbo --local_dir \"$WHISPER_TARGET_DIR\""


# 测试语音生成命令：
只需在命令行中输入以下命令即可生成语音

```bash
f5-tts_infer-cli \
--model "F5-TTS" \
--ref_audio "gemini.mp3" \
--ref_text "Gemini 1.5 Pro的主要特点包括突破性的长上下文理解能力能够处理高达100万个Token的上下文信息是上一代模型的30倍以上可以更好地理解复杂的概念和任务. " \
--gen_text "帮我写一篇关于Gemini 1.5 Pro的文章，并理解Gemini 1.5 Pro的主要特点"
```
