#!/bin/bash

# {{APP_NAME}} 配置文件
# 版本: {{APP_VERSION}}
# 创建时间: {{TIMESTAMP}}

# 应用基本信息
APP_NAME="{{APP_NAME}}"
APP_VERSION="{{APP_VERSION}}"

# 安装目录
INSTALL_DIR="/opt/$APP_NAME"
DATA_DIR="/var/lib/$APP_NAME"
CACHE_DIR="/var/cache/$APP_NAME"
LOG_DIR="/var/log/$APP_NAME"

# 系统依赖
DEPENDENCIES=(
    "curl"
    "git"
    "python3"
    "python3-pip"
)

# Python包依赖
PYTHON_PACKAGES=(
    "numpy>=1.20.0"
    "pandas>=1.3.0"
    "requests>=2.26.0"
)

# 应用配置
APP_PORT=8080
APP_HOST="localhost"
APP_LOG_LEVEL="INFO"

# 检查系统要求
check_system_requirements() {
    # 检查Python版本
    python3 --version >/dev/null 2>&1 || return 1
    
    # 检查pip
    python3 -m pip --version >/dev/null 2>&1 || return 1
    
    # 检查git
    git --version >/dev/null 2>&1 || return 1
    
    return 0
}
