#!/bin/bash

# 全局配置文件
AITOOLS_VERSION="1.0.0"

# 基础目录配置
BASE_INSTALL_DIR="/opt/aitools"
BASE_DATA_DIR="/var/lib/aitools"
BASE_CACHE_DIR="/var/cache/aitools"
BASE_LOG_DIR="/var/log/aitools"

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