#!/bin/bash

# AI工具安装系统主入口脚本
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 先加载日志工具
source "$ROOT_DIR/lib/utils/logger.sh"

# 解析命令行参数
parse_arguments() {
    export USE_BASIC_UI=false  # 默认使用TUI
    export COMMAND=""
    export APP_NAME=""
    export APP_TYPE=""
    export INTERACTIVE=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-ui)
                export USE_BASIC_UI=true
                shift
                ;;
            --force-ui)
                export USE_BASIC_UI=false
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
    # 初始化系统
    source "$ROOT_DIR/lib/core/init.sh"
    
    # 如果没有指定命令且UI可用，使用TUI模式
    if [ -z "$COMMAND" ] && [ "$USE_BASIC_UI" != "true" ]; then
        # 使用TUI界面
        source "$ROOT_DIR/lib/tui/enhanced_interface.sh"
        handle_tui_mode "$@"
    else
        # 使用基础命令行界面
        handle_cli_mode "$@"
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

# 执行主程序
parse_arguments "$@"
main "$@"