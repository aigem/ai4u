#!/bin/bash

# AI工具安装系统主入口脚本
source ./lib/core/init.sh

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