#!/bin/bash

# 配置文件模板生成器

generate_config() {
    local app_name="$1"
    local install_dir="$2"
    local version="$3"
    
    cat << EOF
# $app_name 配置文件
# 由安装脚本自动生成

# 基本配置
APP_NAME="$app_name"
APP_VERSION="$version"
INSTALL_DIR="$install_dir"

# 目录配置
DATA_DIR="\${INSTALL_DIR}/data"
CONFIG_DIR="\${INSTALL_DIR}/config"
LOG_DIR="\${INSTALL_DIR}/logs"

# 运行时配置
PORT="8080"         # 默认端口
DEBUG_MODE="false"  # 调试模式

# 日志配置
LOG_LEVEL="info"    # 日志级别：debug, info, warn, error

# 自定义配置
# 在此处添加应用特定的配置项
EOF
}

# 使用示例
# generate_config "myapp" "/opt/myapp" "1.0.0" > config.sh
