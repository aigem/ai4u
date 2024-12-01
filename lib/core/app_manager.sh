#!/bin/bash

# 安装AI应用
install_app() {
    local app_name="$1"
    local app_dir="$APPS_DIR/$app_name"
    local config_file="$app_dir/config.yaml"

    log_info "开始安装 $app_name..."

    # 显示欢迎信息
    show_welcome_message "$app_name"

    # 安装前检查
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