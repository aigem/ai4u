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

# 测试更新应用
test_update_app() {
    log_info "测试更新应用..."
    
    # 确保应用已安装
    [ -f "$TEST_APP_DIR/.installed" ] || handle_error "应用未安装"
    
    # 更新应用
    update_app "$TEST_APP" || handle_error "更新应用失败"
    
    # 检查更新后的状态
    [ "$(yaml_get "$TEST_APP_DIR/config.yaml" "status")" = "installed" ] || handle_error "更新后应用状态不正确"
    
    log_success "更新应用测试通过"
}

# 测试应用列表
test_list_apps() {
    log_info "测试应用列表..."
    
    # 创建另一个测试应用
    local second_app="test_app2"
    local second_app_dir="$APPS_DIR/$second_app"
    
    create_app "$second_app" "cli" || handle_error "创建第二个应用失败"
    
    # 获取应用列表
    local apps_list
    apps_list=$(list_apps)
    
    # 检查两个应用是否都在列表中
    echo "$apps_list" | grep -q "$TEST_APP" || handle_error "应用列表中未找到 $TEST_APP"
    echo "$apps_list" | grep -q "$second_app" || handle_error "应用列表中未找到 $second_app"
    
    # 清理第二个测试应用
    rm -rf "$second_app_dir"
    
    log_success "应用列表测试通过"
}

# 测试交互式创建应用
test_interactive_create() {
    log_info "测试交互式创建应用..."
    
    # 清理可能存在的测试应用
    local interactive_app="interactive_test_app"
    local interactive_app_dir="$APPS_DIR/$interactive_app"
    [ -d "$interactive_app_dir" ] && rm -rf "$interactive_app_dir"
    
    # 模拟用户输入
    {
        echo "$interactive_app"  # 应用名称
        echo "1"                # 选择 web 类型
        echo "1.0.0"           # 版本号
        echo "测试应用"         # 应用描述
        echo "n"               # 不需要特定系统包
        echo "n"               # 不需要环境变量
    } | create_app_interactive || handle_error "交互式创建应用失败"
    
    # 检查应用是否创建成功
    [ -d "$interactive_app_dir" ] || handle_error "交互式创建的应用目录不存在"
    
    # 检查配置文件
    [ -f "$interactive_app_dir/config.yaml" ] || handle_error "交互式创建的应用配置文件不存在"
    
    # 检查应用信息
    [ "$(yaml_get "$interactive_app_dir/config.yaml" "name")" = "$interactive_app" ] || handle_error "应用名称不正确"
    [ "$(yaml_get "$interactive_app_dir/config.yaml" "type")" = "web" ] || handle_error "应用类型不正确"
    [ "$(yaml_get "$interactive_app_dir/config.yaml" "version")" = "1.0.0" ] || handle_error "应用版本不正确"
    
    # 清理交互式测试应用
    rm -rf "$interactive_app_dir"
    
    log_success "交互式创建应用测试通过"
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
    # 清理环境
    cleanup 
    # 运行测试
    test_create_app
    test_install_app
    test_app_status
    test_update_app
    test_list_apps
    test_interactive_create
    test_reinstall_app
    test_remove_app
    
    # 最后清理
    cleanup
    
    log_success "所有测试通过！"
}

# 执行测试
run_all_tests
