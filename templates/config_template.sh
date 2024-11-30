#!/bin/bash

# {{APP_NAME}} 配置文件
# 创建时间: {{TIMESTAMP}}

# 应用信息
APP_NAME="{{APP_NAME}}"
APP_VERSION="{{APP_VERSION}}"

# 应用配置继承全局设置
INSTALL_DIR="${BASE_INSTALL_DIR}/${APP_NAME}"
DATA_DIR="${BASE_DATA_DIR}/${APP_NAME}"
CACHE_DIR="${BASE_CACHE_DIR}/${APP_NAME}"
LOG_DIR="${BASE_LOG_DIR}/${APP_NAME}"

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
