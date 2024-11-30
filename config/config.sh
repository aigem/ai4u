#!/bin/bash

# 全局配置文件
AITOOLS_VERSION="1.0.0"

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 基础目录配置 - 使用当前文件夹
BASE_INSTALL_DIR="$ROOT_DIR/installed"    # 应用安装目录
BASE_DATA_DIR="$ROOT_DIR/data"           # 数据存储目录
BASE_CACHE_DIR="$ROOT_DIR/cache"         # 缓存目录
BASE_LOG_DIR="$ROOT_DIR/logs"            # 日志目录

# 日志配置
LOG_LEVEL="INFO"
MAX_LOG_SIZE="100M"
MAX_LOG_FILES="10"

# 下载配置
DOWNLOAD_TIMEOUT=300
DOWNLOAD_RETRIES=3
DOWNLOAD_MIRRORS=(
    "https://mirror1.example.com"
    "https://mirror2.example.com"
)

# 系统配置
MIN_DISK_SPACE=5120  # MB
MIN_MEMORY=2048      # MB
MIN_CPU_CORES=2 