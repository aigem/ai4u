#!/bin/bash

# 日志工具

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 日志目录和文件
LOG_DIR="$ROOT_DIR/logs"
LOG_FILE="$LOG_DIR/aitools.log"

# 确保日志目录存在
mkdir -p "$LOG_DIR"

# 日志级别
LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_WARN=2
LOG_LEVEL_ERROR=3

# 当前日志级别
CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO

# 日志格式化
_log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# 调试日志
log_debug() {
    if [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_DEBUG ]; then
        _log "DEBUG" "$1"
    fi
}

# 信息日志
log_info() {
    if [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_INFO ]; then
        _log "INFO" "$1"
    fi
}

# 警告日志
log_warn() {
    if [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_WARN ]; then
        _log "WARN" "$1"
    fi
}

# 错误日志
log_error() {
    if [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_ERROR ]; then
        _log "ERROR" "$1"
    fi
}

# 设置日志级别
set_log_level() {
    case "$1" in
        "debug") CURRENT_LOG_LEVEL=$LOG_LEVEL_DEBUG ;;
        "info")  CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO ;;
        "warn")  CURRENT_LOG_LEVEL=$LOG_LEVEL_WARN ;;
        "error") CURRENT_LOG_LEVEL=$LOG_LEVEL_ERROR ;;
        *) echo "无效的日志级别: $1" >&2; return 1 ;;
    esac
}

# 清理旧日志
clean_old_logs() {
    local days="$1"
    find "$LOG_DIR" -name "*.log" -type f -mtime +$days -delete
}

# 获取日志文件路径
get_log_file() {
    echo "$LOG_FILE"
}

# 查看最新日志
view_latest_logs() {
    local lines="${1:-50}"  # 默认显示最后50行
    tail -n "$lines" "$LOG_FILE"
}

# 初始化日志
_init_logger() {
    # 如果日志文件不存在，创建它
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
    fi
    
    # 记录启动信息
    log_info "=== 日志系统初始化 ==="
    log_info "日志文件: $LOG_FILE"
}

# 初始化日志系统
_init_logger
