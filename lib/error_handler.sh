#!/bin/bash

# 引入日志模块
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"

# 错误代码定义
declare -A ERROR_CODES=(
    ["SUCCESS"]=0
    ["GENERAL_ERROR"]=1
    ["PERMISSION_ERROR"]=2
    ["DEPENDENCY_ERROR"]=3
    ["NETWORK_ERROR"]=4
    ["CONFIG_ERROR"]=5
    ["INSTALLATION_ERROR"]=6
)

# 错误处理栈
declare -a ERROR_STACK=()

# 初始化错误处理
init_error_handler() {
    set -o errexit  # 遇到错误时退出
    set -o pipefail # 管道中的错误也会导致退出
    trap 'error_trap ${LINENO} $?' ERR
}

# 错误捕获函数
error_trap() {
    local line_no=$1
    local error_code=$2
    local error_msg="Error on line $line_no (Exit code: $error_code)"
    
    log_error "$error_msg"
    ERROR_STACK+=("$error_msg")
}

# 推送错误到错误栈
push_error() {
    local error_msg="$1"
    ERROR_STACK+=("$error_msg")
    log_error "$error_msg"
}

# 获取最后一个错误
get_last_error() {
    local stack_size=${#ERROR_STACK[@]}
    if [ $stack_size -gt 0 ]; then
        echo "${ERROR_STACK[$stack_size-1]}"
    fi
}

# 清空错误栈
clear_errors() {
    ERROR_STACK=()
}

# 检查是否有错误
has_errors() {
    [ ${#ERROR_STACK[@]} -gt 0 ]
}

# 打印所有错误
print_errors() {
    if has_errors; then
        echo "Encountered the following errors:"
        for error in "${ERROR_STACK[@]}"; do
            echo " - $error"
        done
        return 1
    fi
    return 0
}

# 错误恢复函数
rollback_changes() {
    local component="$1"
    log_warn "Rolling back changes for component: $component"
    # 在这里实现具体的回滚逻辑
    return 0
}

# 安全执行命令
safe_execute() {
    local cmd="$1"
    local error_msg="${2:-Command execution failed}"
    
    if ! eval "$cmd"; then
        push_error "$error_msg"
        return 1
    fi
    return 0
}

# 初始化错误处理系统
init_error_handler
