#!/bin/bash

# 加载所有必需的库文件
source ./lib/utils/logger.sh
source ./lib/utils/validator.sh
source ./lib/utils/yaml_parser.sh
source ./lib/utils/yaml_utils.sh
source ./lib/utils/system_check.sh
source ./lib/core/app_manager.sh
source ./lib/core/app_creator.sh
source ./lib/core/step_executor.sh
source ./lib/tui/interface.sh

# 初始化全局变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../../config"
TEMPLATES_DIR="$SCRIPT_DIR/../../templates"
APPS_DIR="$SCRIPT_DIR/../../apps"

# 加载全局设置
load_settings() {
    if [ -f "$CONFIG_DIR/settings.yaml" ]; then
        parse_yaml "$CONFIG_DIR/settings.yaml"
    else
        log_error "未找到全局设置文件"
        exit 1
    fi
}

# 解析命令行参数
parse_arguments() {
    COMMAND=""
    APP_NAME=""
    APP_TYPE=""
    INTERACTIVE=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            install|remove|update|status|list|create)
                COMMAND="$1"
                shift
                ;;
            --interactive)
                INTERACTIVE=true
                shift
                ;;
            --type)
                APP_TYPE="$2"
                shift 2
                ;;
            *)
                if [ -z "$APP_NAME" ]; then
                    APP_NAME="$1"
                fi
                shift
                ;;
        esac
    done

    # 验证参数
    case "$COMMAND" in
        install|remove|update|status)
            if [ -z "$APP_NAME" ]; then
                log_error "执行 $COMMAND 命令需要提供应用名称"
                exit 1
            fi
            ;;
        create)
            if [ "$INTERACTIVE" = false ] && [ -z "$APP_NAME" ]; then
                log_error "非交互式创建需要提供应用名称"
                exit 1
            fi
            if [ "$INTERACTIVE" = false ] && [ -z "$APP_TYPE" ]; then
                log_error "非交互式创建需要提供应用类型"
                exit 1
            fi
            ;;
    esac
}

# 显示使用说明
show_usage() {
    cat << EOF
使用方法: ./aitools.sh <命令> [选项]

命令:
  install <应用>              安装AI应用
  remove <应用>              移除AI应用
  update <应用>              更新AI应用
  status <应用>              显示应用状态
  list                      列出所有已安装的应用
  create [选项] <应用>        创建新应用

创建选项:
  --interactive            交互式创建应用
  --type <类型>           指定应用类型

应用类型:
  - text_generation       文本生成
  - image_generation      图像生成
  - speech_recognition    语音识别
  - translation          翻译
  - other               其他类型
EOF
}

# 初始化系统
init_system() {
    # 检查是否为root用户
    check_root_user
    
    # 检查系统依赖
    check_dependencies
    
    # 创建必需的目录
    mkdir -p "$APPS_DIR"
    mkdir -p "$CONFIG_DIR"
}

# 检查是否为root用户
check_root_user() {
    if [ "$(id -u)" != "0" ]; then
        log_error "此脚本需要root权限运行"
        exit 1
    fi
}

# 检查系统依赖
check_dependencies() {
    local deps=(curl wget git python3)
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "缺少必需的依赖：$dep"
            exit 1
        fi
    done
}

# 初始化系统
init_system