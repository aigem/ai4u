#!/bin/bash

# 日志工具

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 日志目录和文件
LOG_DIR="$ROOT_DIR/logs"
LOG_FILE="$LOG_DIR/aitools.log"

# 确保日志目录存在
mkdir -p "$LOG_DIR" || {
    echo "错误: 无法创建日志目录 $LOG_DIR"
    exit 1
}

# 日志级别
LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_WARN=2
LOG_LEVEL_ERROR=3

# 当前日志级别
CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO

# 日志颜色
COLOR_DEBUG="\033[36m"  # 青色
COLOR_INFO="\033[32m"   # 绿色
COLOR_WARN="\033[33m"   # 黄色
COLOR_ERROR="\033[31m"  # 红色
COLOR_RESET="\033[0m"   # 重置

# 日志格式化
_log() {
    local level="$1"
    local color="$2"
    local message="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 输出到控制台（带颜色）
    echo -e "[$timestamp] [${color}${level}${COLOR_RESET}] $message"
    
    # 输出到文件（不带颜色）
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# 调试日志
log_debug() {
    if [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_DEBUG ]; then
        _log "DEBUG" "$COLOR_DEBUG" "$1"
    fi
}

# 信息日志
log_info() {
    if [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_INFO ]; then
        _log "INFO" "$COLOR_INFO" "$1"
    fi
}

# 警告日志
log_warn() {
    if [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_WARN ]; then
        _log "WARN" "$COLOR_WARN" "$1"
    fi
}

# 错误日志
log_error() {
    if [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_ERROR ]; then
        _log "ERROR" "$COLOR_ERROR" "$1"
    fi
}

# 设置日志级别
set_log_level() {
    local level="$1"
    case "$level" in
        debug) CURRENT_LOG_LEVEL=$LOG_LEVEL_DEBUG ;;
        info)  CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO ;;
        warn)  CURRENT_LOG_LEVEL=$LOG_LEVEL_WARN ;;
        error) CURRENT_LOG_LEVEL=$LOG_LEVEL_ERROR ;;
        *)     log_error "无效的日志级别: $level" ;;
    esac
}

# 清理旧日志
clean_old_logs() {
    local days="${1:-30}"
    find "$LOG_DIR" -type f -name "*.log" -mtime +"$days" -delete
}

# 获取日志文件路径
get_log_file() {
    echo "$LOG_FILE"
}

# 查看最新日志
view_latest_logs() {
    local lines="${1:-50}"
    tail -n "$lines" "$LOG_FILE"
}

# 初始化日志
_init_logger() {
    # 输出日志系统初始化信息
    log_info "=== 日志系统初始化 ==="
    log_info "日志文件: $LOG_FILE"
    
    # 检查日志文件权限
    if [ ! -w "$LOG_FILE" ]; then
        touch "$LOG_FILE" 2>/dev/null || {
            echo "错误: 无法创建日志文件 $LOG_FILE"
            exit 1
        }
    fi
}

# 初始化日志系统
_init_logger
