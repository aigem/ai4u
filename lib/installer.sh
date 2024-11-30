#!/bin/bash

# 安装器核心库

# 引入其他库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"
source "$SCRIPT_DIR/error_handler.sh"
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/ui.sh"

# 安装状态管理
declare -A INSTALL_STATUS
INSTALL_STATUS_FILE="/var/lib/aitools/install_status.json"

# 初始化安装器
init_installer() {
    # 确保状态目录存在
    mkdir -p "$(dirname "$INSTALL_STATUS_FILE")" 2>/dev/null || true
    
    # 加载已有的安装状态
    if [ -f "$INSTALL_STATUS_FILE" ]; then
        source "$INSTALL_STATUS_FILE"
    fi
}

# 保存安装状态
save_install_status() {
    local app="$1"
    local status="$2"
    local version="$3"
    local install_time="$(date '+%Y-%m-%d %H:%M:%S')"
    
    INSTALL_STATUS["$app"]="$status"
    INSTALL_STATUS["${app}_version"]="$version"
    INSTALL_STATUS["${app}_install_time"]="$install_time"
    
    # 保存到文件
    {
        echo "# AI Tools 安装状态文件"
        echo "# 最后更新: $install_time"
        echo
        for key in "${!INSTALL_STATUS[@]}"; do
            echo "INSTALL_STATUS[$key]=\"${INSTALL_STATUS[$key]}\""
        done
    } > "$INSTALL_STATUS_FILE"
}

# 获取安装状态
get_install_status() {
    local app="$1"
    echo "${INSTALL_STATUS[$app]:-not_installed}"
}

# 检查是否已安装
is_installed() {
    local app="$1"
    [ "${INSTALL_STATUS[$app]:-not_installed}" = "installed" ]
}

# 依赖管理
declare -A APP_DEPENDENCIES

# 注册应用依赖
register_dependency() {
    local app="$1"
    shift
    APP_DEPENDENCIES["$app"]="$*"
}

# 检查依赖
check_dependencies() {
    local app="$1"
    local deps="${APP_DEPENDENCIES[$app]}"
    
    if [ -n "$deps" ]; then
        for dep in $deps; do
            if ! is_installed "$dep"; then
                log_error "依赖 '$dep' 未安装"
                return 1
            fi
        done
    fi
    return 0
}

# 环境变量管理
declare -A ENV_VARS

# 注册环境变量
register_env_var() {
    local app="$1"
    local var_name="$2"
    local var_value="$3"
    
    ENV_VARS["${app}_${var_name}"]="$var_value"
    export "$var_name"="$var_value"
}

# 保存环境变量
save_env_vars() {
    local app="$1"
    local env_file="/etc/profile.d/aitools_${app}.sh"
    
    {
        echo "# AI Tools 环境变量 - $app"
        echo "# 自动生成于 $(date '+%Y-%m-%d %H:%M:%S')"
        echo
        for key in "${!ENV_VARS[@]}"; do
            if [[ $key == ${app}_* ]]; then
                echo "export ${key#${app}_}=\"${ENV_VARS[$key]}\""
            fi
        done
    } > "$env_file"
}

# 并行安装支持
declare -A INSTALL_PIDS

# 启动并行安装
start_parallel_install() {
    local app="$1"
    local install_script="$2"
    
    bash "$install_script" &
    INSTALL_PIDS["$app"]=$!
}

# 等待并行安装完成
wait_parallel_installs() {
    local failed=0
    
    for app in "${!INSTALL_PIDS[@]}"; do
        if ! wait "${INSTALL_PIDS[$app]}"; then
            log_error "应用 '$app' 安装失败"
            failed=1
        fi
    done
    
    return $failed
}

# 断点续传支持
RESUME_FILE="/var/lib/aitools/resume.json"

# 保存安装进度
save_progress() {
    local app="$1"
    local step="$2"
    local data="$3"
    
    echo "{\"app\":\"$app\",\"step\":\"$step\",\"data\":\"$data\"}" > "$RESUME_FILE"
}

# 恢复安装进度
resume_install() {
    local app="$1"
    
    if [ -f "$RESUME_FILE" ]; then
        local saved_app=$(jq -r .app "$RESUME_FILE")
        local saved_step=$(jq -r .step "$RESUME_FILE")
        local saved_data=$(jq -r .data "$RESUME_FILE")
        
        if [ "$saved_app" = "$app" ]; then
            echo "$saved_step:$saved_data"
            return 0
        fi
    fi
    
    echo "start:"
    return 1
}

# 清理恢复点
clear_resume() {
    rm -f "$RESUME_FILE"
}

# 初始化安装器
init_installer
