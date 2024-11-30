#!/bin/bash

# 错误处理增强
set -o errexit
set -o pipefail
set -o nounset

# 错误栈跟踪
error_trace() {
    local frame=0
    while caller $frame; do
        ((frame++))
    done
}

# 统一错误处理
handle_error() {
    local exit_code=$?
    local line_no=$1
    local command="$2"
    
    log_error "错误发生在第 $line_no 行"
    log_error "执行命令: $command"
    log_error "错误代码: $exit_code"
    error_trace
    
    # 清理临时文件
    cleanup_temp_files
    
    # 发送错误报告
    send_error_report "$exit_code" "$line_no" "$command"
    
    exit $exit_code
}

trap 'handle_error ${LINENO} "${BASH_COMMAND}"' ERR
