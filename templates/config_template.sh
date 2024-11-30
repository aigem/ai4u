#!/bin/bash

# {{APP_NAME}} 配置文件
# 创建时间: {{TIMESTAMP}}

# 应用信息
APP_NAME="{{APP_NAME}}"
APP_VERSION="{{APP_VERSION}}"

# 安装配置
INSTALL_DIR="$HOME/.local/share/aitools/{{APP_NAME}}"
DATA_DIR="$HOME/.local/share/aitools/{{APP_NAME}}/data"
CACHE_DIR="$HOME/.cache/aitools/{{APP_NAME}}"
LOG_DIR="$HOME/.local/share/aitools/{{APP_NAME}}/logs"

# 依赖配置
DEPENDENCIES=(
    "python3"
    "pip3"
    "git"
)

# Python包依赖
PYTHON_PACKAGES=(
    "requests"
    "pyyaml"
)
