#!/bin/bash

# AI工具安装系统主入口脚本
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 先加载日志工具
source "$ROOT_DIR/lib/utils/logger.sh"

# 解析命令行参数
parse_arguments() {
    export USE_BASIC_UI=false  # 默认使用TUI
    export TEST_MODE=false     # 默认非测试模式
    export INTERACTIVE=false   # 默认非交互式
    export APP_NAME=""
    export APP_TYPE=""
    export COMMAND=""
    
    # 如果没有参数，默认启动TUI模式
    if [ $# -eq 0 ]; then
        return
    fi
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --test-mode)
                export TEST_MODE=true
                export USE_BASIC_UI=true
                shift
                ;;
            --no-ui)
                export USE_BASIC_UI=true
                shift
                ;;
            create)
                export COMMAND="create"
                shift
                # 检查是否有后续参数
                if [ "$1" = "-i" ] || [ "$1" = "--interactive" ]; then
                    export INTERACTIVE=true
                    shift
                elif [ -n "$1" ] && [[ ! "$1" =~ ^- ]]; then
                    export APP_NAME="$1"
                    shift
                    # 检查是否指定了类型
                    if [ "$1" = "-t" ] || [ "$1" = "--type" ]; then
                        shift
                        export APP_TYPE="$1"
                        shift
                    fi
                fi
                ;;
            install|remove|update|status)
                export COMMAND="$1"
                shift
                if [ -n "$1" ] && [[ ! "$1" =~ ^- ]]; then
                    export APP_NAME="$1"
                    shift
                fi
                ;;
            list|test)
                export COMMAND="$1"
                shift
                ;;
            -i|--interactive)
                export INTERACTIVE=true
                shift
                ;;
            -t|--type)
                if [ -n "$2" ]; then
                    export APP_TYPE="$2"
                    shift 2
                else
                    log_error "缺少应用类型参数"
                    show_usage
                    exit 1
                fi
                ;;
            *)
                if [ -z "$APP_NAME" ] && [ -n "$COMMAND" ]; then
                    export APP_NAME="$1"
                else
                    log_error "未知参数: $1"
                    show_usage
                    exit 1
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
    
    # 检查必要的目录结构
    [ -d "$APPS_DIR" ] || mkdir -p "$APPS_DIR"
    [ -d "$CONFIG_DIR" ] || mkdir -p "$CONFIG_DIR"
    
    # 如果是测试命令，直接运行测试
    if [ "$COMMAND" = "test" ]; then
        source "$ROOT_DIR/tests/integration_test.sh"
        return
    fi
    
    # 检查并加载依赖
    check_dependencies || {
        log_error "依赖检查失败"
        exit 1
    }
    
    # 根据UI模式选择处理方式
    if [ "$USE_BASIC_UI" = "true" ]; then
        handle_cli_mode
    else
        # 检查whiptail
        if ! command -v whiptail >/dev/null 2>&1; then
            log_warning "whiptail未安装，切换到基础UI模式"
            export USE_BASIC_UI=true
            handle_cli_mode
        else
            handle_tui_mode
        fi
    fi
}

# 检查依赖
check_dependencies() {
    # 检查基本命令
    for cmd in "awk" "sed" "grep" "yaml"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "缺少必要命令: $cmd"
            return 1
        fi
    done
    return 0
}

# 处理命令行模式
handle_cli_mode() {
    case "$COMMAND" in
        "create")
            if [ "$INTERACTIVE" = true ]; then
                create_app_interactive
            elif [ -z "$APP_NAME" ] || [ -z "$APP_TYPE" ]; then
                log_error "缺少必要参数。使用方法: create <应用名> -t <类型> 或 create -i"
                show_usage
                return 1
            else
                create_app "$APP_NAME" "$APP_TYPE"
            fi
            ;;
        "install")
            if [ -z "$APP_NAME" ]; then
                # 显示可安装的应用列表
                echo "可安装的应用列表："
                list_apps
                read -p "请输入要安装的应用名称: " APP_NAME
            fi
            if [ ! -d "$APPS_DIR/$APP_NAME" ]; then
                log_error "应用 $APP_NAME 不存在"
                return 1
            fi
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
        choice=$(whiptail --title "AI工具安装系统" --menu "请选择操作" 20 60 10 \
            "1" "创建新应用" \
            "2" "安装应用" \
            "3" "卸载应用" \
            "4" "更新应用" \
            "5" "查看状态" \
            "6" "应用列表" \
            "7" "配置管理" \
            "0" "退出" 3>&1 1>&2 2>&3)
        
        case "$choice" in
            "1") create_app_wizard ;;
            "2") install_app_wizard ;;
            "3") remove_app_wizard ;;
            "4") update_app_wizard ;;
            "5") show_status_wizard ;;
            "6") show_apps_list ;;
            "7") manage_config_wizard ;;
            "0"|"") exit 0 ;;
        esac
    done
}

# 执行主程序
parse_arguments "$@"
main "$@"

# 添加使用说明
show_usage() {
    cat << EOF
使用方法:
    $(basename "$0") [选项] <命令> [参数]

命令:
    create      创建新应用
    install     安装应用
    remove      移除应用
    update      更新应用
    status      查看应用状态
    list        列出所有应用
    test        运行测试

选项:
    -i, --interactive   交互式模式
    --no-ui            使用命令行界面
    -t, --type TYPE    指定应用类型 (用于create命令)

示例:
    # 启动TUI界面
    $(basename "$0")
    
    # 命令行创建应用
    $(basename "$0") create myapp -t web
    
    # 交互式创建应用
    $(basename "$0") create -i
    
    # 安装应用
    $(basename "$0") install myapp
EOF
}