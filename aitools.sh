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

# 执行主程序
parse_arguments "$@"
main "$@"