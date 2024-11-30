#!/bin/bash

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
UTILS_DIR="$SCRIPT_DIR/utils"

# 设置默认语言环境
export LANG=C
export LC_ALL=C

# 引入必要的库
source "$LIB_DIR/logger.sh" || {
    echo "错误: 无法加载日志模块"
    exit 1
}
source "$LIB_DIR/utils.sh" || {
    log_error "无法加载工具模块"
    exit 1
}
source "$LIB_DIR/error_handler.sh" || {
    log_error "无法加载错误处理模块"
    exit 1
}
source "$LIB_DIR/ui.sh" || {
    log_error "无法加载界面模块"
    exit 1
}

# 版本信息
VERSION="1.0.0"

# 显示帮助信息
show_help() {
    cat << EOF
AI Tools 安装管理系统 v$VERSION

用法: $(basename "$0") <命令> [参数]

可用命令:
  list                 列出可用的 AI 工具
  install <app>        安装指定的 AI 工具
  remove <app>         删除指定的 AI 工具
  update <app>         更新指定的 AI 工具
  status <app>         查看指定 AI 工具的状态
  create-app <name>    创建新的 AI 工具模板
  help                 显示此帮助信息

示例:
  $(basename "$0") list
  $(basename "$0") install comfyui
  $(basename "$0") create-app myapp
EOF
}

# 列出可用的应用
list_apps() {
    local apps_dir="$SCRIPT_DIR/apps"
    local available_apps=()
    
    # 检查应用目录是否存在
    if [ ! -d "$apps_dir" ]; then
        show_message "错误" "应用目录不存在"
        return 1
    fi
    
    # 获取所有应用
    while IFS= read -r app_dir; do
        if [ -f "$app_dir/install.sh" ]; then
            local app_name=$(basename "$app_dir")
            local description=""
            if [ -f "$app_dir/README.md" ]; then
                description=$(head -n 1 "$app_dir/README.md" | sed 's/^#\s*//')
            fi
            available_apps+=("$app_name" "$description")
        fi
    done < <(find "$apps_dir" -mindepth 1 -maxdepth 1 -type d)
    
    if [ ${#available_apps[@]} -eq 0 ]; then
        show_message "提示" "目前没有可用的应用。\n\n您可以使用 'create-app' 命令创建新应用。\n\n操作提示：\n - 使用方向键选择选项\n - 按 Enter 键确认\n - 按 Tab 键切换按钮"
        return 0
    fi
    
    show_menu "可用的 AI 工具" "使用方向键选择应用，Enter 键确认，Tab 键切换按钮" "${available_apps[@]}"
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
        log_error "应用 '$app_name' 已存在"
        return 1
    }
    
    log_info "创建应用 $app_name..."
    
    # 加载模板工具
    source "$UTILS_DIR/template_utils.sh" || {
        log_error "加载模板工具失败"
        return 1
    }
    
    # 创建应用目录
    mkdir -p "$app_dir" || {
        log_error "创建应用目录失败"
        return 1
    }
    
    # 创建应用结构
    create_app_structure "$app_name" "$app_dir" || {
        log_error "创建应用结构失败"
        return 1
    }
    
    log_info "应用 $app_name 创建成功"
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
    local setup_script="$SCRIPT_DIR/setup/${app_name}_setup.sh"
    
    # 检查应用是否存在
    if [ ! -d "$app_dir" ]; then
        show_message "错误" "应用 '$app_name' 不存在"
        return 1
    fi
    
    # 确认删除
    if show_yesno "确认" "确定要删除应用 '$app_name' 吗？\n这将同时删除:\n1. 应用目录\n2. 安装入口脚本"; then
        # 删除应用目录
        rm -rf "$app_dir" || {
            show_message "错误" "删除应用目录失败"
            return 1
        }
        
        # 删除安装入口脚本
        if [ -f "$setup_script" ]; then
            rm -f "$setup_script" || {
                show_message "警告" "应用目录已删除，但删除安装入口脚本失败"
                return 1
            }
        fi
        
        show_message "成功" "应用 '$app_name' 已完全删除"
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
    local command="$1"
    shift || true
    
    case "$command" in
        "list"|"")
            list_apps
            ;;
        "install")
            install_app "$@"
            ;;
        "remove")
            remove_app "$@"
            ;;
        "update")
            update_app "$@"
            ;;
        "status")
            show_status "$@"
            ;;
        "create-app")
            create_app "$@"
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            show_message "错误" "未知命令: $command\n\n运行 '$(basename "$0") help' 获取帮助。"
            return 1
            ;;
    esac
}

# 启动程序
main "$@"
