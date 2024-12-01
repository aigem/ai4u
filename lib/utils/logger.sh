#!/bin/bash

# 定义颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 信息日志
log_info() {
    echo -e "[信息] $1"
}

# 成功日志
log_success() {
    echo -e "${GREEN}[成功] $1${NC}"
}

# 警告日志
log_warn() {
    echo -e "${YELLOW}[警告] $1${NC}"
}

# 错误日志
log_error() {
    echo -e "${RED}[错误] $1${NC}" >&2
}

# 调试日志
log_debug() {
    if [ "$DEBUG" = "true" ]; then
        echo -e "${BLUE}[调试] $1${NC}"
    fi
}