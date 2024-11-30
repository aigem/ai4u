#!/bin/bash

# AI Tools 安装管理系统主入口脚本

# 引入必要的库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/error_handler.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/ui.sh"

# 版本信息
VERSION="1.0.0"

# 显示帮助信息
show_help() {
    cat << EOF
AI Tools 安装管理系统 v$VERSION

用法: $(basename "$0") [选项] [命令] [参数]

命令:
    list                    列出可用的应用
    install <app>           安装指定的应用
    create-app <name>       创建新的应用模板
    update <app>            更新指定的应用
    remove <app>           删除指定的应用
    status [app]           显示应用状态
    help                   显示此帮助信息

选项:
    -v, --version          显示版本信息
    -h, --help            显示帮助信息
    -d, --debug           启用调试模式
    -q, --quiet           静默模式
    --no-color            禁用彩色输出

示例:
    $0 list               # 列出所有可用应用
    $0 install comfyui    # 安装ComfyUI
    $0 create-app myapp   # 创建新应用

更多信息请访问: https://github.com/yourusername/aitools
EOF
}

# 列出可用的应用
list_apps() {
    log_info "正在扫描可用应用..."
    
    local apps_dir="$SCRIPT_DIR/apps"
    local setup_dir="$SCRIPT_DIR/setup"
    local available_apps=()
    
    # 扫描应用目录
    for app_dir in "$apps_dir"/*; do
        if [ -d "$app_dir" ]; then
            local app_name=$(basename "$app_dir")
            available_apps+=("$app_name" "$(get_app_description "$app_name")" "OFF")
        fi
    done
    
    if [ ${#available_apps[@]} -eq 0 ]; then
        show_message "可用应用" "当前没有可用的应用。"
        return 0
    fi
    
    # 显示应用列表
    show_checklist "可用应用" "选择要安装的应用：" "${available_apps[@]}"
}

# 获取应用描述
get_app_description() {
    local app_name="$1"
    local desc_file="$SCRIPT_DIR/apps/$app_name/description.txt"
    
    if [ -f "$desc_file" ]; then
        cat "$desc_file"
    else
        case "$app_name" in
            "comfyui")
                echo "强大的 Stable Diffusion 图像生成工具"
                ;;
            "openwebui")
                echo "开源的 Web UI 框架"
                ;;
            *)
                echo "无描述"
                ;;
        esac
    fi
}

# 安装应用
install_app() {
    local app_name="$1"
    local app_dir="$SCRIPT_DIR/apps/$app_name"
    local install_script="$app_dir/install.sh"
    
    # 检查应用是否存在
    if [ ! -d "$app_dir" ]; then
        show_message "错误" "应用 '$app_name' 不存在"
        return 1
    fi
    
    # 检查安装脚本
    if [ ! -f "$install_script" ]; then
        show_message "错误" "找不到应用 '$app_name' 的安装脚本"
        return 1
    fi
    
    # 执行安装
    log_info "开始安装 $app_name..."
    
    # 显示安装进度
    (
        bash "$install_script" 2>&1 | while IFS= read -r line; do
            log_info "$line"
            echo "$line" >> "$LOG_FILE"
        done
    )
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        show_message "成功" "$app_name 安装完成"
        return 0
    else
        show_message "错误" "$app_name 安装失败，请查看日志了解详情"
        return 1
    fi
}

# 创建新应用
create_app() {
    local app_name="$1"
    local app_dir="$SCRIPT_DIR/apps/$app_name"
    
    # 检查应用名称是否已存在
    if [ -d "$app_dir" ]; then
        show_message "错误" "应用 '$app_name' 已存在"
        return 1
    fi
    
    # 创建应用目录结构
    log_info "创建应用 $app_name..."
    
    # 使用模板工具生成应用骨架
    source "$SCRIPT_DIR/utils/template_utils.sh"
    generate_app_skeleton "$app_name" "$app_dir" || {
        log_error "生成应用骨架失败"
        return 1
    }
    
    # 创建入口脚本
    local setup_script="$SCRIPT_DIR/setup/${app_name}_setup.sh"
    local vars=(
        "APP_NAME=$app_name"
        "APP_VERSION=1.0.0"
        "TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')"
    )
    replace_template_vars "$SCRIPT_DIR/templates/setup_template.sh" "$setup_script" "${vars[@]}" || {
        log_error "生成入口脚本失败"
        return 1
    }
    chmod +x "$setup_script" || return 1
    
    show_message "成功" "应用 '$app_name' 创建完成"
    return 0
}

# 更新应用
update_app() {
    local app_name="$1"
    local app_dir="$SCRIPT_DIR/apps/$app_name"
    
    # 检查应用是否存在
    if [ ! -d "$app_dir" ]; then
        show_message "错误" "应用 '$app_name' 不存在"
        return 1
    fi
    
    # TODO: 实现更新逻辑
    show_message "提示" "更新功能尚未实现"
    return 0
}

# 删除应用
remove_app() {
    local app_name="$1"
    local app_dir="$SCRIPT_DIR/apps/$app_name"
    
    # 检查应用是否存在
    if [ ! -d "$app_dir" ]; then
        show_message "错误" "应用 '$app_name' 不存在"
        return 1
    fi
    
    # 确认删除
    if show_yesno "确认" "确定要删除应用 '$app_name' 吗？"; then
        rm -rf "$app_dir" || return 1
        show_message "成功" "应用 '$app_name' 已删除"
    fi
    
    return 0
}

# 显示应用状态
show_status() {
    local app_name="$1"
    
    if [ -n "$app_name" ]; then
        # 显示特定应用状态
        local app_dir="$SCRIPT_DIR/apps/$app_name"
        if [ ! -d "$app_dir" ]; then
            show_message "错误" "应用 '$app_name' 不存在"
            return 1
        fi
        
        # TODO: 实现状态检查逻辑
        show_message "状态" "应用 '$app_name' 状态检查功能尚未实现"
    else
        # 显示所有应用状态
        list_apps
    fi
    
    return 0
}

# 主函数
main() {
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                return 0
                ;;
            -v|--version)
                echo "AI Tools v$VERSION"
                return 0
                ;;
            -d|--debug)
                set_log_level "debug"
                shift
                ;;
            -q|--quiet)
                set_log_level "error"
                shift
                ;;
            --no-color)
                # TODO: 实现禁用彩色输出
                shift
                ;;
            list)
                list_apps
                return $?
                ;;
            install)
                shift
                install_app "$1"
                return $?
                ;;
            create-app)
                shift
                create_app "$1"
                return $?
                ;;
            update)
                shift
                update_app "$1"
                return $?
                ;;
            remove)
                shift
                remove_app "$1"
                return $?
                ;;
            status)
                shift
                show_status "$1"
                return $?
                ;;
            *)
                echo "未知选项: $1"
                show_help
                return 1
                ;;
        esac
    done
    
    # 如果没有参数，显示帮助信息
    show_help
    return 0
}

# 启动程序
main "$@"
