#!/bin/bash

# AI工具安装系统主入口脚本
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_DIR/lib/core/init.sh"

# 解析命令行参数
parse_arguments() {
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
            *)
                # 其他参数处理...
                shift
                ;;
        esac
    done
}

# 处理TUI模式
handle_tui_mode() {
    while true; do
        choice=$(create_main_window)
        case "$choice" in
            "1")
                show_app_browser
                ;;
            "2")
                manage_installed_apps
                ;;
            "3")
                show_settings
                ;;
            "4")
                show_logs
                ;;
            "0"|"")
                exit 0
                ;;
        esac
    done
}

# 处理命令行模式
handle_cli_mode() {
    case "$COMMAND" in
        "install")
            install_app "$APP_NAME"
            ;;
        "remove")
            remove_app "$APP_NAME"
            ;;
        "update")
            update_app "$APP_NAME"
            ;;
        "status")
            show_status "$APP_NAME"
            ;;
        "list")
            list_apps
            ;;
        "create")
            if [ "$INTERACTIVE" = true ]; then
                create_app_interactive
            else
                create_app "$APP_NAME" "$APP_TYPE"
            fi
            ;;
        *)
            show_usage
            ;;
    esac
}

# 主函数
main() {
    # 初始化系统
    init_system
    
    # 根据UI模式选择界面
    if [ "$USE_BASIC_UI" = "true" ]; then
        # 使用基础命令行界面
        handle_cli_mode "$@"
    else
        # 使用TUI界面
        source "$ROOT_DIR/lib/tui/enhanced_interface.sh"
        handle_tui_mode "$@"
    fi
}

# 执行主程序
parse_arguments "$@"
main "$@"