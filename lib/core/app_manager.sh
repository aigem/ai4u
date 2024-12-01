#!/bin/bash

# 安装AI应用
install_app() {
    local app_name="$1"
    local app_dir="$APPS_DIR/$app_name"
    local config_file="$app_dir/config.yaml"

    log_info "开始安装 $app_name..."

    # 显示欢迎信息
    show_welcome_message "$app_name"

    # 检查安装前提条件
    if ! check_installation_prerequisites "$app_name"; then
        return 1
    fi

    # 创建临时工作目录
    local workspace=$(mktemp -d)
    trap 'cleanup_on_error "$workspace" "$app_name"' ERR
    trap 'rm -rf "$workspace"' EXIT

    # 执行安装步骤并显示进度
    local total_steps=3
    local current_step=0

    # 步骤1：配置
    ((current_step++))
    show_progress $current_step $total_steps "配置应用"
    if ! configure_application "$app_name" "$workspace"; then
        return 1
    fi

    # 步骤2：安装
    ((current_step++))
    show_progress $current_step $total_steps "安装组件"
    if ! execute_installation "$app_name" "$workspace"; then
        return 1
    fi

    # 步骤3：验证
    ((current_step++))
    show_progress $current_step $total_steps "验证安装"
    if ! verify_installation "$app_name"; then
        return 1
    fi

    show_success_message "$app_name"
    return 0
}

# 检查安装前提条件
check_installation_prerequisites() {
    local app_name="$1"
    local app_dir="$APPS_DIR/$app_name"
    local config_file="$app_dir/config.yaml"

    # 检查应用目录是否已存在
    if [ -d "$app_dir" ]; then
        log_error "应用 $app_name 已存在"
        return 1
    fi

    # 检查系统资源
    local required_disk_space=1024  # MB
    local required_memory=512       # MB

    # 检查磁盘空间
    local available_disk=$(df -m "$APPS_DIR" | awk 'NR==2 {print $4}')
    if [ "$available_disk" -lt "$required_disk_space" ]; then
        log_error "磁盘空间不足。需要: ${required_disk_space}MB, 可用: ${available_disk}MB"
        return 1
    fi

    # 检查内存
    local available_memory=$(free -m | awk 'NR==2 {print $7}')
    if [ "$available_memory" -lt "$required_memory" ]; then
        log_error "内存不足。需要: ${required_memory}MB, 可用: ${available_memory}MB"
        return 1
    fi

    return 0
}

# 列出所有已安装的应用
list_apps() {
    echo "=============================="
    echo "  已安装的AI应用"
    echo "=============================="
    
    if [ ! -d "$APPS_DIR" ] || [ -z "$(ls -A "$APPS_DIR")" ]; then
        echo "当前没有已安装的应用"
        echo "使用 'create' 命令创建新应用"
        return 0
    fi

    echo "应用列表："
    echo "----------------------------"
    for app_dir in "$APPS_DIR"/*; do
        if [ -d "$app_dir" ]; then
            local app_name=$(basename "$app_dir")
            local config_file="$app_dir/config.yaml"
            if [ -f "$config_file" ]; then
                local type=$(yaml_get_value "$config_file" "type")
                local version=$(yaml_get_value "$config_file" "version")
                printf "%-20s %-15s %s\n" "$app_name" "$type" "v$version"
            else
                printf "%-20s %-15s %s\n" "$app_name" "未知" "配置缺失"
            fi
        fi
    done
    echo "----------------------------"
    echo "使用 'status <应用名称>' 查看详细信息"
}

# 移除AI应用
remove_app() {
    local app_name="$1"
    local app_dir="$APPS_DIR/$app_name"

    log_info "开始移除 $app_name..."

    # 检查应用是否存在
    if [ ! -d "$app_dir" ]; then
        log_error "应用 $app_name 不存在"
        return 1
    fi

    # 执行卸载前的清理工作
    if [ -f "$app_dir/uninstall.sh" ]; then
        log_info "执行卸载脚本..."
        bash "$app_dir/uninstall.sh"
    fi

    # 移除应用目录
    log_info "移除应用目录..."
    rm -rf "$app_dir"

    log_info "应用 $app_name 已成功移除"
    return 0
}

# 显示欢迎信息
show_welcome_message() {
    local app_name="$1"
    echo "=============================="
    echo "  AI工具安装系统"
    echo "=============================="
    echo "准备安装：$app_name"
    echo "请确保您有足够的系统权限"
    echo "安装过程中请勿关闭终端"
    echo "=============================="
}

# 显示成功信息
show_success_message() {
    local app_name="$1"
    echo "=============================="
    echo "  安装成功"
    echo "=============================="
    echo "应用：$app_name 已成功安装"
    echo "您现在可以开始使用了"
    echo "如需帮助，请查看文档"
    echo "=============================="
}