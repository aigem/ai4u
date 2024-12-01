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