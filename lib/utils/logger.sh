#!/bin/bash

# ANSI 颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 无颜色

# 记录错误信息
log_error() {
    echo -e "${RED}[错误]${NC} $1" >&2
}

# 记录成功信息
log_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

# 记录警告信息
log_warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

# 记录信息
log_info() {
    echo -e "${YELLOW}[信息]${NC} $1"
}

# 记录调试信息（仅在启用DEBUG时）
log_debug() {
    if [ "${DEBUG:-false}" = true ]; then
        echo "[调试] $1"
    fi
}