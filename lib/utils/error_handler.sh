#!/bin/bash

# 错误代码
declare -r E_INVALID_ARG=1
declare -r E_MISSING_DEP=2
declare -r E_CONFIG_ERROR=3
declare -r E_INSTALL_ERROR=4
declare -r E_PERMISSION_ERROR=5
declare -r E_NETWORK_ERROR=6

# 处理带有上下文的错误
handle_error() {
    local error_code="$1"
    local context="$2"
    local suggestion="$3"

    case $error_code in
        $E_INVALID_ARG)
            log_error "无效参数：$context"
            ;;
        $E_MISSING_DEP)
            log_error "缺少依赖项：$context"
            ;;
        $E_CONFIG_ERROR)
            log_error "配置错误：$context"
            ;;
        $E_INSTALL_ERROR)
            log_error "安装错误：$context"
            ;;
        $E_PERMISSION_ERROR)
            log_error "权限错误：$context"
            ;;
        $E_NETWORK_ERROR)
            log_error "网络错误：$context"
            ;;
        *)
            log_error "未知错误：$context"
            ;;
    esac

    if [ -n "$suggestion" ]; then
        log_info "建议：$suggestion"
    fi

    return $error_code
}

# 错误时清理
cleanup_on_error() {
    local workspace="$1"
    local app_name="$2"

    log_info "正在清理错误..."
    
    # 删除临时文件
    if [ -d "$workspace" ]; then
        rm -rf "$workspace"
    fi

    # 如果存在备份则恢复
    if [ -f "$APPS_DIR/$app_name.backup" ]; then
        mv "$APPS_DIR/$app_name.backup" "$APPS_DIR/$app_name"
    fi
}

# 设置错误陷阱
set_error_trap() {
    trap 'handle_error $? "发生意外错误"' ERR
}