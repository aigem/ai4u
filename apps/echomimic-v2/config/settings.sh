#!/bin/bash

# echomimic-v2 应用配置
APP_NAME="echomimic-v2"
APP_TYPE="cli"
APP_VERSION="1.0.0"

# 用于哪个平台的安装
PLATFORM_NAME="良心云"

# 应用特定配置

# 虚拟环境名称
VENV_NAME="ai_echomimic-v2"
# 虚拟环境目录(良心云的默认路径，其他环境请自行修改)
VENV_DIR="/root/miniconda3/envs/"
# python版本
PYTHON_VERSION="3.10"
# 工作目录: 用于存放下载的Ai应用
WORKSPACE_DIR="/workspace"
# 应用端口
APP_PORT="7860"
# 启动命令-请自行修改,必填项
run_cmd="cd /workspace/echomimic-v2 && python app.py"

# 应用git地址
APP_GIT_URL="https://openi.pcl.ac.cn/aipc/echomimic_v2.git"
