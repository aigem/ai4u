#!/bin/bash

# AI工具安装系统主入口脚本
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$SCRIPT_DIR/lib/core/init.sh"

# 解析命令行参数
parse_arguments "$@"

# 执行请求的命令
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
            create_app_interactive "$APP_NAME"
        else
            if [ -z "$APP_NAME" ] || [ -z "$APP_TYPE" ]; then
                log_error "创建应用需要指定应用名称和类型"
                show_usage
                exit 1
            fi
            create_app "$APP_NAME" "$APP_TYPE"
        fi
        ;;
    *)
        show_usage
        ;;
esac