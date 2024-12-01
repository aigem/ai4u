#!/bin/bash

# AI工具安装系统主入口脚本
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 环境变量初始化和检查
if [ -z "$ROOT_DIR" ]; then
    export ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

export APPS_DIR="$ROOT_DIR/apps"
export LIB_DIR="$ROOT_DIR/lib"
export SCRIPTS_DIR="$ROOT_DIR/scripts"

# 确保关键目录存在
mkdir -p "$APPS_DIR"
mkdir -p "$ROOT_DIR/logs"

# 确保脚本有执行权限
chmod +x "$ROOT_DIR/aitools.sh"
find "$LIB_DIR" -type f -name "*.sh" -exec chmod +x {} \;

# 检查操作系统类型
check_os() {
    case "$(uname -s)" in
        CYGWIN*|MINGW*|MSYS*)
            export OS_TYPE="windows"
            ;;
        Linux*)
            export OS_TYPE="linux"
            ;;
        Darwin*)
            export OS_TYPE="macos"
            ;;
        *)
            export OS_TYPE="unknown"
            ;;
    esac
}

# 初始化环境
init_environment() {
    # 检查操作系统
    check_os
    
    # Windows 环境特殊处理
    if [ "$OS_TYPE" = "windows" ]; then
        # 转换路径分隔符
        ROOT_DIR=$(echo "$ROOT_DIR" | sed 's/\\/\//g')
        APPS_DIR=$(echo "$APPS_DIR" | sed 's/\\/\//g')
        
        # 确保使用正确的解释器
        if ! command -v bash &> /dev/null; then
            echo "错误: 未找到 bash。请确保安装了 Git Bash 或 MSYS2。"
            exit 1
        fi
    fi
    
    # 设置通用环境变量
    export PATH="$ROOT_DIR/bin:$PATH"
    export PYTHONPATH="$ROOT_DIR:$PYTHONPATH"
}

# 先加载日志工具
source "$ROOT_DIR/lib/utils/logger.sh"

# 解析命令行参数
parse_arguments() {
    export USE_BASIC_UI=false  # 默认使用TUI
    export TEST_MODE=false     # 添加测试模式标志
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --test-mode)
                export TEST_MODE=true
                export USE_BASIC_UI=true  # 测试模式强制使用命令行界面
                shift
                ;;
            --no-ui)
                export USE_BASIC_UI=true
                shift
                ;;
            create|install|remove|update|status|list|test)
                export COMMAND="$1"
                shift
                ;;
            -i|--interactive)
                export INTERACTIVE=true
                shift
                ;;
            -t|--type)
                export APP_TYPE="$2"
                shift 2
                ;;
            -*)
                log_error "未知选项: $1"
                show_usage
                exit 1
                ;;
            *)
                if [ -z "$APP_NAME" ]; then
                    export APP_NAME="$1"
                fi
                shift
                ;;
        esac
    done
}

# 主函数
main() {
    # 初始化环境
    init_environment
    
    # 加载其他依赖
    source "$ROOT_DIR/lib/utils/yaml_utils.sh"
    
    # 检查基本依赖
    check_dependencies
    
    # 如果是测试命令，直接运行测试
    if [ "$COMMAND" = "test" ]; then
        source "$ROOT_DIR/tests/integration_test.sh"
        return
    fi
    
    # 如果是测试模式，直接执行命令
    if [ "$TEST_MODE" = "true" ]; then
        handle_cli_mode
        return
    fi
    
    # 检查并安装UI依赖
    check_ui_dependencies
    
    # 如果UI可用，使用TUI模式
    if [ "$USE_BASIC_UI" != "true" ]; then
        # 加载TUI组件
        source "$ROOT_DIR/lib/tui/enhanced_interface.sh"
        source "$ROOT_DIR/lib/tui/theme_manager.sh"
        
        # 设置主题
        local theme=$(yaml_get "$CONFIG_DIR/settings.yaml" "ui.theme")
        set_theme "${theme:-dark}"
        
        # 启动TUI界面
        handle_tui_mode
    else
        # 使用基础命令行界面
        handle_cli_mode
    fi
}

# 处理命令行模式
handle_cli_mode() {
    # 如果没有命令，显示基础菜单
    if [ -z "$COMMAND" ]; then
        source "$ROOT_DIR/lib/tui/interface.sh"
        while true; do
            show_menu
            choice=$?
            case "$choice" in
                1)
                    COMMAND="install"
                    read -p "请输入应用名称: " APP_NAME
                    ;;
                2)
                    COMMAND="remove"
                    read -p "请输入应用名称: " APP_NAME
                    ;;
                3)
                    COMMAND="update"
                    read -p "请输入应用名称: " APP_NAME
                    ;;
                4)
                    COMMAND="status"
                    read -p "请输入应用名称: " APP_NAME
                    ;;
                5)
                    COMMAND="create"
                    INTERACTIVE=true
                    ;;
                0)
                    exit 0
                    ;;
                *)
                    log_error "无效的选择"
                    continue
                    ;;
            esac
            break
        done
    fi

    # 执行命令
    case "$COMMAND" in
        "install")
            [ -z "$APP_NAME" ] && read -p "请输入要安装的应用名称: " APP_NAME
            install_app "$APP_NAME"
            ;;
        "remove")
            [ -z "$APP_NAME" ] && read -p "请输入要卸载的应用名称: " APP_NAME
            remove_app "$APP_NAME"
            ;;
        "update")
            [ -z "$APP_NAME" ] && read -p "请输入要更新的应用名称: " APP_NAME
            update_app "$APP_NAME"
            ;;
        "status")
            [ -z "$APP_NAME" ] && read -p "请输入要查看状态的应用名称: " APP_NAME
            show_status "$APP_NAME"
            ;;
        "list")
            list_apps
            ;;
        "create")
            if [ "$INTERACTIVE" = true ]; then
                create_app_interactive
            else
                [ -z "$APP_NAME" ] && read -p "请输入新应用名称: " APP_NAME
                [ -z "$APP_TYPE" ] && read -p "请输入应用类型(web|cli|service|other): " APP_TYPE
                create_app "$APP_NAME" "$APP_TYPE"
            fi
            ;;
        "test")
            run_tests
            ;;
        *)
            show_usage
            ;;
    esac
}

# 处理TUI模式
handle_tui_mode() {
    while true; do
        choice=$(create_main_window)
        case "$choice" in
            "1")
                # 创建新应用
                source "$ROOT_DIR/lib/tui/interactive_wizard.sh"
                create_app_wizard
                ;;
            "2")
                # 安装应用
                app=$(show_app_browser)
                if [ -n "$app" ]; then
                    show_enhanced_progress "正在安装 $app..."
                    install_app "$app"
                fi
                ;;
            "3")
                # 卸载应用
                local installed_apps=($(ls -1 "$APPS_DIR"))
                if [ ${#installed_apps[@]} -eq 0 ]; then
                    whiptail --msgbox "没有已安装的应用" 10 40
                    continue
                fi
                local app=$(whiptail --menu "选择要卸载的应用" 20 60 10 \
                    "${installed_apps[@]}" 3>&1 1>&2 2>&3)
                if [ -n "$app" ]; then
                    if whiptail --yesno "确定要卸载 $app 吗？" 10 40; then
                        show_enhanced_progress "正在卸载 $app..."
                        remove_app "$app"
                    fi
                fi
                ;;
            "4")
                # 更新应用
                local installed_apps=($(ls -1 "$APPS_DIR"))
                if [ ${#installed_apps[@]} -eq 0 ]; then
                    whiptail --msgbox "没有已安装的应用" 10 40
                    continue
                fi
                local app=$(whiptail --menu "选择要更新的应用" 20 60 10 \
                    "${installed_apps[@]}" 3>&1 1>&2 2>&3)
                if [ -n "$app" ]; then
                    show_enhanced_progress "正在更新 $app..."
                    update_app "$app"
                fi
                ;;
            "5")
                # 查看状态
                local installed_apps=($(ls -1 "$APPS_DIR"))
                if [ ${#installed_apps[@]} -eq 0 ]; then
                    whiptail --msgbox "没有已安装的应用" 10 40
                    continue
                fi
                local app=$(whiptail --menu "选择要查看的应用" 20 60 10 \
                    "${installed_apps[@]}" 3>&1 1>&2 2>&3)
                if [ -n "$app" ]; then
                    show_status "$app" | whiptail --scrolltext --title "应用状态" --textbox /dev/stdin 20 60
                fi
                ;;
            "6")
                # 列出应用
                list_apps | whiptail --scrolltext --title "应用列表" --textbox /dev/stdin 20 60
                ;;
            "0"|"")
                exit 0
                ;;
        esac
    done
}

# 执行主程序
parse_arguments "$@"
main "$@"