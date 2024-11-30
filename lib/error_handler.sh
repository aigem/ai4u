#!/bin/bash

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
    # 设置错误捕获
    trap error_trap ERR
    # 清空错误栈
    ERROR_STACK=()
}

# 错误捕获函数
error_trap() {
    local err_code=$?
    local line_no=$1
    
    # 记录错误
    push_error "错误发生在第 $line_no 行，错误代码: $err_code"
    return $err_code
}

# 推送错误到错误栈
push_error() {
    local error_msg="$1"
    ERROR_STACK+=("$error_msg")
    echo "$error_msg" >&2
}

# 获取最后一个错误
get_last_error() {
    if [ ${#ERROR_STACK[@]} -gt 0 ]; then
        echo "${ERROR_STACK[-1]}"
        return 0
    fi
    return 1
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
        echo "错误列表:"
        local i=1
        for error in "${ERROR_STACK[@]}"; do
            echo "$i. $error"
            ((i++))
        done
        return 1
    fi
    return 0
}

# 错误恢复函数
rollback_changes() {
    if has_errors; then
        echo "正在回滚更改..."
        # 在这里添加回滚逻辑
    fi
}

# 安全执行命令
safe_execute() {
    local cmd="$1"
    local error_msg="${2:-执行命令失败: $cmd}"
    
    if ! eval "$cmd"; then
        push_error "$error_msg"
        return 1
    fi
    return 0
}

# 初始化错误处理系统
init_error_handler
