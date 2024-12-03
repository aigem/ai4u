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

# aria2 下载命令
ARIA2_CMD1="aria2c "https://modelscope.cn/models/SWivid/F5-TTS_Emilia-ZH-EN/resolve/master/F5TTS_Base/model_1200000.pt" --dir=. --max-connection-per-server=16 --split=16 --min-split-size=10M --continue=true --max-concurrent-downloads=1 --file-allocation=none --console-log-level=notice --show-console-readout=true --summary-interval=3"
ARIA2_CMD2="aria2c "https://modelscope.cn/models/SWivid/E2-TTS_Emilia-ZH-EN/resolve/master/E2TTS_Base/model_1200000.pt" --dir=. --max-connection-per-server=16 --split=16 --min-split-size=10M --continue=true --max-concurrent-downloads=1 --file-allocation=none --console-log-level=notice --show-console-readout=true --summary-interval=3"