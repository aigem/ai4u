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

# 检查必要目录
required_dirs=(
    "$SCRIPT_DIR/templates"
    "$SCRIPT_DIR/templates/app_template"
    "$SCRIPT_DIR/apps"
    "$SCRIPT_DIR/lib"
    "$SCRIPT_DIR/utils"
    "$SCRIPT_DIR/logs"
    "$SCRIPT_DIR/config"
    "$SCRIPT_DIR/plugins"
)

for dir in "${required_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" || {
            log_error "无法创建必要目录: $dir"
            exit 1
        }
    fi
done

# 初始化模板文件
init_templates() {
    log_info "正在初始化模板文件..."
    
    # 创建模板目录
    mkdir -p "$SCRIPT_DIR/templates/app_template" || {
        log_error "无法创建模板目录"
        return 1
    }
    
    # 创建安装脚本模板
    cat > "$SCRIPT_DIR/templates/app_template/install.sh" << 'EOF'
#!/bin/bash

# {{APP_NAME}} 安装脚本
# 版本: {{APP_VERSION}}
# 创建时间: {{TIMESTAMP}}

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 引入配置文件
source "$SCRIPT_DIR/config/config.sh" || {
    echo "错误: 无法加载配置文件"
    exit 1
}

# 创建必要的目录
create_directories() {
    mkdir -p \
        "$INSTALL_DIR" \
        "$DATA_DIR" \
        "$CACHE_DIR" \
        "$LOG_DIR" || return 1
    
    return 0
}

# 安装系统依赖
install_dependencies() {
    for dep in "${DEPENDENCIES[@]}"; do
        echo "安装系统依赖: $dep"
        if command -v apt-get >/dev/null; then
            apt-get install -y "$dep" || return 1
        elif command -v yum >/dev/null; then
            yum install -y "$dep" || return 1
        else
            echo "错误: 不支持的包管理器"
            return 1
        fi
    done
    
    return 0
}

# 安装Python包
install_python_packages() {
    for pkg in "${PYTHON_PACKAGES[@]}"; do
        echo "安装Python包: $pkg"
        python3 -m pip install "$pkg" || return 1
    done
    
    return 0
}

# 配置应用
configure_app() {
    # 在这里添加应用特定的配置逻辑
    return 0
}

# 主安装流程
main() {
    echo "开始安装 $APP_NAME v$APP_VERSION..."
    
    create_directories || {
        echo "错误: 创建目录失败"
        return 1
    }
    
    install_dependencies || {
        echo "错误: 安装系统依赖失败"
        return 1
    }
    
    install_python_packages || {
        echo "错误: 安装Python包失败"
        return 1
    }
    
    configure_app || {
        echo "错误: 配置应用失败"
        return 1
    }
    
    echo "$APP_NAME 安装完成"
    return 0
}

# 执行安装
main "$@"
EOF

    # 创建配置文件模板
    cat > "$SCRIPT_DIR/templates/config_template.sh" << 'EOF'
#!/bin/bash

# {{APP_NAME}} 配置文件
# 创建时间: {{TIMESTAMP}}

# 应用信息
APP_NAME="{{APP_NAME}}"
APP_VERSION="{{APP_VERSION}}"

# 应用配置继承全局设置
INSTALL_DIR="${BASE_INSTALL_DIR}/${APP_NAME}"
DATA_DIR="${BASE_DATA_DIR}/${APP_NAME}"
CACHE_DIR="${BASE_CACHE_DIR}/${APP_NAME}"
LOG_DIR="${BASE_LOG_DIR}/${APP_NAME}"

# 依赖配置
DEPENDENCIES=(
    "python3"
    "pip3"
    "git"
)

# Python包依赖
PYTHON_PACKAGES=(
    "requests"
    "pyyaml"
)
EOF

    # 设置执行权限
    chmod +x "$SCRIPT_DIR/templates/app_template/install.sh" || {
        log_error "无法设置模板文件权限"
        return 1
    }
    
    log_info "模板文件初始化完成"
    return 0
}

# 初始化函数
init_aitools() {
    log_info "正在初始化 AI Tools..."
    
    # 初始化模板文件
    init_templates || {
        log_error "模板初始化失败"
        return 1
    }
    
    # 检查必要的工具
    local required_tools=("git" "curl" "wget" "python3" "pip3")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "缺少必要工具: $tool"
            return 1
        fi
    done
    
    log_info "初始化完成"
    return 0
}

# 显示主菜单
show_main_menu() {
    local title="AI Tools 安装管理系统 v$VERSION"
    local menu_text="请选择操作:"
    local options=(
        "list"      "列出可用的 AI 工具"
        "install"   "安装 AI 工具"
        "remove"    "删除已安装的工具"
        "update"    "更新已安装的工具"
        "status"    "查看工具状态"
        "create"    "创建新的工具模板"
        "help"      "显示帮助信息"
        "exit"      "退出程序"
    )
    
    while true; do
        local choice
        if check_whiptail; then
            choice=$(whiptail --title "$title" --menu "$menu_text" 20 60 8 "${options[@]}" 3>&1 1>&2 2>&3)
        else
            echo "=== $title ==="
            echo "$menu_text"
            echo
            local i=1
            for ((i=0; i<${#options[@]}; i+=2)); do
                printf "%2d) %-15s - %s\n" $((i/2+1)) "${options[i]}" "${options[i+1]}"
            done
            echo
            read -p "请选择 [1-$((${#options[@]}/2))]: " menu_choice
            case $menu_choice in
                1) choice="list" ;;
                2) choice="install" ;;
                3) choice="remove" ;;
                4) choice="update" ;;
                5) choice="status" ;;
                6) choice="create" ;;
                7) choice="help" ;;
                8) choice="exit" ;;
                *) choice="" ;;
            esac
        fi
        
        case "$choice" in
            "list")
                list_apps
                ;;
            "install")
                show_install_menu
                ;;
            "remove")
                show_remove_menu
                ;;
            "update")
                show_update_menu
                ;;
            "status")
                show_status_menu
                ;;
            "create")
                show_create_menu
                ;;
            "help")
                show_help
                ;;
            "exit")
                echo "再见！"
                return 0
                ;;
            *)
                echo "无效的选择，请重试"
                ;;
        esac
        
        echo
        read -p "按回车键继续..."
    done
}

# 显示安装菜单
show_install_menu() {
    local title="安装 AI 工具"
    local menu_text="请选择要安装的工具:"
    
    # 获取可用的工具列表
    local available_apps=(
        "comfyui"    "Stable Diffusion 图像生成工具"
        "openwebui"  "开源的 Web UI 框架"
        # 可以从配置或目录中动态获取更多选项
    )
    
    local choice
    if check_whiptail; then
        choice=$(whiptail --title "$title" --menu "$menu_text" 20 60 8 "${available_apps[@]}" 3>&1 1>&2 2>&3)
    else
        echo "=== $title ==="
        echo "$menu_text"
        echo
        local i=1
        for ((i=0; i<${#available_apps[@]}; i+=2)); do
            printf "%2d) %-15s - %s\n" $((i/2+1)) "${available_apps[i]}" "${available_apps[i+1]}"
        done
        echo
        read -p "请选择 [1-$((${#available_apps[@]}/2))]: " menu_choice
        case $menu_choice in
            1) choice="comfyui" ;;
            2) choice="openwebui" ;;
            *) choice="" ;;
        esac
    fi
    
    if [ -n "$choice" ]; then
        install_app "$choice"
    fi
}

# 显示删除菜单
show_remove_menu() {
    local title="删除 AI 工具"
    local menu_text="请选择要删除的工具:"
    
    # 获取已安装的工具列表
    local installed_apps=()
    local app_dir="$SCRIPT_DIR/apps"
    for app in "$app_dir"/*; do
        if [ -d "$app" ]; then
            local app_name=$(basename "$app")
            local description=$(get_app_description "$app_name")
            installed_apps+=("$app_name" "$description")
        fi
    done
    
    if [ ${#installed_apps[@]} -eq 0 ]; then
        show_message "提示" "没有已安装的工具"
        return
    fi
    
    local choice
    if check_whiptail; then
        choice=$(whiptail --title "$title" --menu "$menu_text" 20 60 8 "${installed_apps[@]}" 3>&1 1>&2 2>&3)
    else
        echo "=== $title ==="
        echo "$menu_text"
        echo
        local i=1
        for ((i=0; i<${#installed_apps[@]}; i+=2)); do
            printf "%2d) %-15s - %s\n" $((i/2+1)) "${installed_apps[i]}" "${installed_apps[i+1]}"
        done
        echo
        read -p "请选择 [1-$((${#installed_apps[@]}/2))]: " menu_choice
        if [ "$menu_choice" -ge 1 ] && [ "$menu_choice" -le $((${#installed_apps[@]}/2)) ]; then
            choice="${installed_apps[((menu_choice-1)*2)]}"
        fi
    fi
    
    if [ -n "$choice" ]; then
        remove_app "$choice"
    fi
}

# 修改主函数
main() {
    # 先执行初始化
    init_aitools || {
        log_error "初始化失败"
        return 1
    }
    
    # 如果有命令行参数，按命令行方式处理
    if [ $# -gt 0 ]; then
        local command="$1"
        shift || true
        
        case "$command" in
            "init")
                return 0
                ;;
            "list")
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
    else
        # 无参数时显示交互式菜单
        show_main_menu
    fi
}

# 启动程序（使用 set +u 避免未定义变量错误）
set +u
main "$@"
set -u
