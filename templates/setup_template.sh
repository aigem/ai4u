#!/bin/bash

# 安装入口脚本模板

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 引入必要的库
source "$ROOT_DIR/lib/logger.sh"
source "$ROOT_DIR/lib/error_handler.sh"
source "$ROOT_DIR/lib/utils.sh"
source "$ROOT_DIR/lib/ui.sh"
source "$ROOT_DIR/lib/installer.sh"

# 应用信息
APP_NAME="{{APP_NAME}}"
APP_VERSION="{{APP_VERSION}}"
INSTALL_DIR="$ROOT_DIR/apps/$APP_NAME"

# 显示欢迎信息
show_welcome() {
    show_message "欢迎" "欢迎安装 $APP_NAME v$APP_VERSION"
}

# 检查系统要求
check_requirements() {
    log_info "检查系统要求..."
    check_system_requirements || return 1
    return 0
}

# 获取用户配置
get_user_config() {
    log_info "获取用户配置..."
    
    # 在这里添加获取用户配置的逻辑
    # 例如：安装路径、端口号等
    
    return 0
}

# 执行安装
do_install() {
    log_info "开始安装 $APP_NAME..."
    
    # 调用应用的安装脚本
    bash "$INSTALL_DIR/install.sh" || return 1
    
    return 0
}

# 显示完成信息
show_completion() {
    show_message "安装完成" "$APP_NAME 安装已完成！\n\n请查看 README.md 了解使用方法。"
}

# 主函数
main() {
    show_welcome || return 1
    check_requirements || return 1
    get_user_config || return 1
    do_install || return 1
    show_completion || return 1
    
    return 0
}

# 启动安装
main "$@"
