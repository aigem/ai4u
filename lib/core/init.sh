#!/bin/bash

# 设置目录变量
if [ -z "$ROOT_DIR" ]; then
    # 如果 ROOT_DIR 未设置，则设置它
    SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
    ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi

LIB_DIR="$ROOT_DIR/lib"
CONFIG_DIR="$ROOT_DIR/config"
TEMPLATES_DIR="$ROOT_DIR/templates"
APPS_DIR="$ROOT_DIR/apps"

# 确保必要的目录存在
mkdir -p "$CONFIG_DIR"
mkdir -p "$TEMPLATES_DIR"
mkdir -p "$APPS_DIR"

# 加载所有必需的库文件
for lib in \
    "$LIB_DIR/utils/logger.sh" \
    "$LIB_DIR/utils/validator.sh" \
    "$LIB_DIR/utils/yaml_parser.sh" \
    "$LIB_DIR/utils/yaml_utils.sh" \
    "$LIB_DIR/utils/progress.sh" \
    "$LIB_DIR/core/app_manager.sh" \
    "$LIB_DIR/core/app_creator.sh" \
    "$LIB_DIR/core/step_executor.sh" \
    "$LIB_DIR/tui/interface.sh"; do
    if [ -f "$lib" ]; then
        source "$lib"
    else
        echo "错误：找不到必需的库文件：$lib"
        exit 1
    fi
done

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

    # 第一个参数必须是命令
    if [ $# -eq 0 ]; then
        show_usage
        exit 1
    fi

    case "$1" in
        install|remove|update|status|list|create|test)
            COMMAND="$1"
            shift
            ;;
        *)
            log_error "无效的命令：$1"
            show_usage
            exit 1
            ;;
    esac

    # 解析剩余参数
    while [ $# -gt 0 ]; do
        case "$1" in
            --interactive|-i)
                INTERACTIVE=true
                shift
                ;;
            --type|-t)
                if [ -z "$2" ]; then
                    log_error "缺少应用类型参数"
                    exit 1
                fi
                APP_TYPE="$2"
                shift 2
                ;;
            *)
                if [ -z "$APP_NAME" ]; then
                    APP_NAME="$1"
                else
                    log_error "未知的参数：$1"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # 检查命令特定的参数要求
    case "$COMMAND" in
        create)
            if [ "$INTERACTIVE" = false ] && [ -z "$APP_NAME" ]; then
                log_error "非交互式创建需要提供应用名称"
                show_usage
                exit 1
            fi
            if [ "$INTERACTIVE" = false ] && [ -z "$APP_TYPE" ]; then
                log_error "非交互式创建需要提供应用类型"
                show_usage
                exit 1
            fi
            ;;
        install|remove|update|status)
            if [ -z "$APP_NAME" ]; then
                log_error "命令 $COMMAND 需要提供应用名称"
                show_usage
                exit 1
            fi
            ;;
    esac
}

# 显示使用说明
show_usage() {
    echo "使用方法: $(basename "$0") <命令> [选项] [应用名称]"
    echo
    echo "命令:"
    echo "  create     创建新应用"
    echo "  install    安装应用"
    echo "  remove     移除应用"
    echo "  update     更新应用"
    echo "  status     查看应用状态"
    echo "  list       列出所有应用"
    echo "  test       运行测试"
    echo
    echo "选项:"
    echo "  -i, --interactive    交互式模式"
    echo "  -t, --type TYPE      指定应用类型 (web|cli|service|other)"
    echo
    echo "示例:"
    echo "  $(basename "$0") create myapp --type web     # 创建Web应用"
    echo "  $(basename "$0") create --interactive        # 交互式创建应用"
    echo "  $(basename "$0") install myapp              # 安装应用"
    echo "  $(basename "$0") test                       # 运行所有测试"
}

# 初始化系统
init_system() {
    # 检查是否为root用户
    # check_root_user
    
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
    echo "检查系统依赖..."
    
    # 检查Python环境
    if ! command -v python3 >/dev/null 2>&1; then
        log_error "未找到 Python3，请先安装 Python3"
        return 1
    fi
    
    # 检查pip
    if ! command -v pip3 >/dev/null 2>&1; then
        log_error "未找到 pip3，请先安装 pip3"
        return 1
    fi
    
    # 检查Python依赖
    local missing_deps=()
    
    # 检查PyYAML
    if ! python3 -c "import yaml" 2>/dev/null; then
        missing_deps+=("pyyaml")
    fi
    
    # 如果有缺失的依赖，直接安装
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_warning "检测到缺失的Python依赖: ${missing_deps[*]}"
        for dep in "${missing_deps[@]}"; do
            log_info "正在安装 $dep..."
            pip3 install "$dep" || {
                log_error "安装 $dep 失败"
                return 1
            }
        done
    fi
    
    return 0
}

# 初始化系统
init_system