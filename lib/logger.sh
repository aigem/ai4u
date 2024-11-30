#!/bin/bash

# 日志级别定义
LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_WARN=2
LOG_LEVEL_ERROR=3

# 默认日志级别
CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO

# 日志文件路径
LOG_DIR="/var/log/aitools"
LOG_FILE="$LOG_DIR/install.log"

# 确保日志目录存在
init_logger() {
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR" 2>/dev/null || {
            echo "Error: Failed to create log directory: $LOG_DIR"
            return 1
        }
    fi
    touch "$LOG_FILE" 2>/dev/null || {
        echo "Error: Failed to create log file: $LOG_FILE"
        return 1
    }
}

# 设置日志级别
set_log_level() {
    case "${1,,}" in
        "debug") CURRENT_LOG_LEVEL=$LOG_LEVEL_DEBUG ;;
        "info")  CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO ;;
        "warn")  CURRENT_LOG_LEVEL=$LOG_LEVEL_WARN ;;
        "error") CURRENT_LOG_LEVEL=$LOG_LEVEL_ERROR ;;
        *) echo "Invalid log level: $1" >&2; return 1 ;;
    esac
}

# 格式化日志消息
format_log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message"
}

# 写入日志到文件
write_log() {
    local level="$1"
    local message="$2"
    local formatted_message=$(format_log_message "$level" "$message")
    echo "$formatted_message" >> "$LOG_FILE"
}

# 日志函数
log_debug() {
    [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_DEBUG ] && write_log "DEBUG" "$1"
}

log_info() {
    [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_INFO ] && write_log "INFO" "$1"
}

log_warn() {
    [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_WARN ] && write_log "WARN" "$1"
}

log_error() {
    [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_ERROR ] && write_log "ERROR" "$1"
}

# 错误处理函数
handle_error() {
    local error_message="$1"
    local error_code="${2:-1}"
    log_error "$error_message"
    echo "Error: $error_message" >&2
    return $error_code
}

# 初始化日志系统
init_logger || {
    echo "Failed to initialize logger" >&2
    exit 1
}
