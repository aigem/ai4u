#!/bin/bash

# 加载工具函数
source "$ROOT_DIR/lib/utils/progress.sh"

# 安装AI应用
install_app() {
    local app_name="$1"
    local app_dir="$APPS_DIR/$app_name"
    local config_file="$app_dir/config.yaml"
    local install_script="$app_dir/scripts/install.sh"

    log_info "开始安装 $app_name..."

    # 显示欢迎信息
    show_welcome_message "$app_name"

    # 检查应用是否存在
    if [ ! -d "$app_dir" ]; then
        log_error "应用 $app_name 不存在，请先创建应用"
        return 1
    fi

    # 检查是否已安装
    if [ -f "$app_dir/.installed" ]; then
        log_error "应用 $app_name 已经安装"
        # 询问是否重新安装，如果选择否则返回,否则继续
        read -p "确定要重新安装吗?(y/n) " confirm
        if [[ $confirm != "y" ]]; then
            log_info "取消重新安装"
            return 0
        fi
        rm -f "$app_dir/.installed"
    fi

    # 检查安装前提条件
    if ! check_installation_prerequisites "$app_name"; then
        return 1
    fi

    # 执行安装步骤并显示进度
    local total_steps=4
    local current_step=0

    # 步骤1：安装依赖
    ((current_step++))
    show_progress $current_step $total_steps "安装依赖项"
    if ! install_dependencies "$app_name"; then
        return 1
    fi

    # 步骤2：配置环境
    ((current_step++))
    show_progress $current_step $total_steps "配置环境"
    if ! configure_environment "$app_name"; then
        return 1
    fi

    # 步骤3：执行安装脚本
    ((current_step++))
    show_progress $current_step $total_steps "执行安装脚本"
    if [ -f "$install_script" ]; then
        if ! bash "$install_script"; then
            log_error "安装脚本执行失败"
            return 1
        fi
    fi

    # 步骤4：标记为已安装
    ((current_step++))
    show_progress $current_step $total_steps "完成安装"
    touch "$app_dir/.installed"
    
    # 更新应用状态
    update_yaml "$config_file" "status" "installed"

    show_success_message "$app_name"
    return 0
}

# 安装依赖项
install_dependencies() {
    local app_name="$1"
    local config_file="$APPS_DIR/$app_name/config.yaml"
    
    # 读取依赖项列表
    local deps=($(yaml_get_array "$config_file" "dependencies"))
    
    if [ ${#deps[@]} -eq 0 ]; then
        log_info "无需安装依赖项"
        return 0
    fi

    log_info "安装依赖项：${deps[*]}"
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            if ! apt-get install -y "$dep"; then
                log_error "安装依赖项失败：$dep"
                return 1
            fi
        fi
    done

    return 0
}

# 配置环境变量
configure_environment() {
    local app_name="$1"
    local config_file="$APPS_DIR/$app_name/config.yaml"
    local env_file="$APPS_DIR/$app_name/.env"
    
    # 读取环境变量配置
    local env_vars=($(yaml_get_array "$config_file" "environment"))
    
    if [ ${#env_vars[@]} -eq 0 ]; then
        log_info "无需配置环境变量"
        return 0
    fi

    # 创建环境变量文件
    echo "# $app_name 环境变量配置" > "$env_file"
    for env in "${env_vars[@]}"; do
        echo "export $env" >> "$env_file"
    done
    
    # 设置权限
    chmod 600 "$env_file"

    return 0
}

# 检查安装前提条件
check_installation_prerequisites() {
    local app_name="$1"
    local app_dir="$APPS_DIR/$app_name"
    local config_file="$app_dir/config.yaml"

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

    #询问是否确认移除
    read -p "确定要移除 $app_name 吗?(y/n) " confirm
    if [[ $confirm != "y" ]]; then
        log_info "取消移除 $app_name"
        return 0
    fi

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

# 显示应用状态
show_status() {
    local app_name="$1"
    local app_dir="$APPS_DIR/$app_name"

    # 检查应用是否存在
    if [ ! -d "$app_dir" ]; then
        log_error "应用 $app_name 不存在"
        return 1
    fi

    # 检查配置文件
    local config_file="$app_dir/config.yaml"
    if [ ! -f "$config_file" ]; then
        log_error "应用 $app_name 的配置文件不存在"
        return 1
    fi

    # 读取配置信息
    local app_type=$(yaml_get_value "$config_file" "type")
    local app_version=$(yaml_get_value "$config_file" "version")
    local app_command=$(yaml_get_value "$config_file" "command")

    # 检查安装状态
    local installed=false
    if [ -f "$app_dir/.installed" ]; then
        installed=true
    fi

    # 显示状态信息
    echo "应用名称: $app_name"
    echo "类型: $app_type"
    echo "版本: $app_version"
    echo "安装状态: $([ "$installed" = true ] && echo "已安装" || echo "未安装")"
    
    # 如果已安装，检查运行状态
    if [ "$installed" = true ] && [ -n "$app_command" ]; then
        if pgrep -f "$app_command" > /dev/null; then
            echo "运行状态: 运行中"
        else
            echo "运行状态: 未运行"
        fi
    fi

    return 0
}