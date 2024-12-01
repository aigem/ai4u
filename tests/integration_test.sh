#!/bin/bash

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
APPS_DIR="$ROOT_DIR/apps"

# 加载工具函数
source "$ROOT_DIR/lib/utils/logger.sh"
source "$ROOT_DIR/lib/utils/yaml_utils.sh"
source "$ROOT_DIR/lib/core/app_creator.sh"
source "$ROOT_DIR/lib/core/app_manager.sh"

# 测试应用名称
TEST_APP="test_app"
TEST_APP_DIR="$APPS_DIR/$TEST_APP"

# 清理函数
cleanup() {
    log_info "清理测试环境..."
    if [ -d "$TEST_APP_DIR" ]; then
        rm -rf "$TEST_APP_DIR"
    fi
}

# 错误处理
handle_error() {
    log_error "测试失败：$1"
    cleanup
    exit 1
}

# 测试创建应用
test_create_app() {
    log_info "测试创建应用..."
    
    # 创建应用（使用非交互模式）
    create_app "$TEST_APP" "web" || handle_error "创建应用失败"
    
    # 检查目录结构
    for dir in "scripts" "config" "data" "logs"; do
        [ -d "$TEST_APP_DIR/$dir" ] || handle_error "目录不存在：$dir"
    done
    
    # 检查必要文件
    for file in "config.yaml" "requirements.txt" "config/settings.yaml.template"; do
        [ -f "$TEST_APP_DIR/$file" ] || handle_error "文件不存在：$file"
    done
    
    # 检查必要脚本
    for script in "install.sh" "uninstall.sh" "update.sh" "status.sh" "test.sh"; do
        [ -f "$TEST_APP_DIR/scripts/$script" ] || handle_error "脚本不存在：$script"
        [ -x "$TEST_APP_DIR/scripts/$script" ] || handle_error "脚本没有执行权限：$script"
    done
    
    # 检查配置文件内容
    local name=$(yaml_get "$TEST_APP_DIR/config.yaml" "name")
    local type=$(yaml_get "$TEST_APP_DIR/config.yaml" "type")
    local status=$(yaml_get "$TEST_APP_DIR/config.yaml" "status")
    
    [ "$name" = "$TEST_APP" ] || handle_error "配置文件中的应用名称不正确"
    [ "$type" = "web" ] || handle_error "配置文件中的应用类型不正确"
    [ "$status" = "not_installed" ] || handle_error "配置文件中的应用状态不正确"
    
    log_success "创建应用测试通过"
}

# 测试安装应用
test_install_app() {
    log_info "测试安装应用..."
    
    # 检查应用是否已安装
    if [ -f "$TEST_APP_DIR/.installed" ]; then
        handle_error "应用已经安装"
    fi
    
    # 安装应用
    echo "y" | install_app "$TEST_APP" || handle_error "安装应用失败"
    
    # 检查安装标记
    [ -f "$TEST_APP_DIR/.installed" ] || handle_error "安装标记不存在"
    
    # 检查配置文件状态
    local status=$(yaml_get "$TEST_APP_DIR/config.yaml" "status")
    [ "$status" = "installed" ] || handle_error "安装后应用状态不正确"
    
    log_success "安装应用测试通过"
}

# 测试应用状态
test_app_status() {
    log_info "测试应用状态..."
    
    # 检查状态显示
    show_status "$TEST_APP" || handle_error "获取应用状态失败"
    
    # 检查状态文件
    [ -f "$TEST_APP_DIR/scripts/status.sh" ] || handle_error "状态脚本不存在"
    [ -x "$TEST_APP_DIR/scripts/status.sh" ] || handle_error "状态脚本没有执行权限"
    
    log_success "应用状态测试通过"
}

# 测试重新安装
test_reinstall_app() {
    log_info "测试重新安装应用..."
    
    # 检查应用是否已安装
    if [ ! -f "$TEST_APP_DIR/.installed" ]; then
        handle_error "应用未安装，无法重新安装"
    fi
    
    # 重新安装应用
    echo "y" | install_app "$TEST_APP" || handle_error "重新安装应用失败"
    
    # 检查安装标记
    [ -f "$TEST_APP_DIR/.installed" ] || handle_error "重新安装后安装标记不存在"
    
    log_success "重新安装应用测试通过"
}

# 测试移除应用
test_remove_app() {
    log_info "测试移除应用..."
    
    # 检查应用是否存在
    if [ ! -d "$TEST_APP_DIR" ]; then
        handle_error "应用不存在，无法移除"
    fi
    
    # 移除应用
    echo "y" | remove_app "$TEST_APP" || handle_error "移除应用失败"
    
    # 检查应用目录是否已删除
    [ ! -d "$TEST_APP_DIR" ] || handle_error "应用目录仍然存在"
    
    log_success "移除应用测试通过"
}

# 运行所有测试
run_all_tests() {
    log_info "开始运行集成测试..."
    
    # 初始清理
    cleanup
    
    # 运行测试
    test_create_app
    test_install_app
    test_app_status
    test_reinstall_app
    test_remove_app
    
    # 最终清理
    cleanup
    
    log_success "所有测试通过！"
}

# 执行测试
run_all_tests
