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

# 设置测试模式
export TEST_MODE=true
export USE_BASIC_UI=true
export COMMAND="test"

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

# 测试基本工作流
test_basic_workflow() {
    log_info "测试基本工作流..."
    
    # 1. CLI模式测试（包含参数解析）
    "$ROOT_DIR/aitools.sh" --no-ui create test_app -t web || handle_error "CLI创建失败"
    echo "y" | "$ROOT_DIR/aitools.sh" --no-ui install test_app || handle_error "CLI安装失败"
    "$ROOT_DIR/aitools.sh" --no-ui status test_app || handle_error "CLI状态查看失败"
    echo "y" | "$ROOT_DIR/aitools.sh" --no-ui remove test_app || handle_error "CLI删除失败"
    
    # 2. 交互式模式测试
    echo -e "test_interactive\nweb\n1.0.0\n测试描述\n" | "$ROOT_DIR/aitools.sh" create -i || handle_error "交互式创建失败"
    echo "y" | "$ROOT_DIR/aitools.sh" --no-ui remove test_interactive
    
    log_success "基本工作流测试通过"
}

# 测试错误处理
test_error_cases() {
    log_info "测试错误处理..."
    
    # 测试关键错误场景
    "$ROOT_DIR/aitools.sh" --no-ui create "error_app" -t web || handle_error "创建失败"
    "$ROOT_DIR/aitools.sh" --no-ui create "error_app" -t web && handle_error "重复创建未被阻止"
    "$ROOT_DIR/aitools.sh" --no-ui install "non_existent_app" && handle_error "安装不存在应用未被阻止"
    
    # 清理
    echo "y" | "$ROOT_DIR/aitools.sh" --no-ui remove "error_app"
    
    log_success "错误处理测试通过"
}

# 运行所有测试
run_all_tests() {
    # 清理环境
    cleanup
    
    # 添加新的测试
    test_basic_workflow || return 1
    test_error_cases || return 1
    
    # 最后清理
    cleanup
    
    log_success "所有测试通过！"
    return 0
}

# 执行测试
if [ -n "$BASH_SOURCE" ] && [ "$BASH_SOURCE" = "$0" ]; then
    # 直接运行测试脚本时
    run_all_tests
else
    # 通过 aitools.sh test 运行时
    if [ "$COMMAND" = "test" ]; then
        run_all_tests
    fi
fi

test_config_files() {
    log_info "测试配置文件..."
    
    # 测试全局配置
    [ -f "$CONFIG_DIR/settings.yaml" ] || handle_error "全局配置文件不存在"
    
    # 测试应用配置
    [ -f "$TEST_APP_DIR/config/settings.yaml.template" ] || handle_error "应用配置模板不存在"
}

# 添加新的测试场景
test_ui_and_cli_workflow() {
    log_info "测试UI和CLI工作流程..."
    
    # 测试CLI模式的完整工作流
    local CLI_TEST_APP="cli_workflow_test"
    
    # 1. CLI创建应用
    "$ROOT_DIR/aitools.sh" --no-ui create "$CLI_TEST_APP" -t web || handle_error "CLI创建应用失败"
    [ -d "$APPS_DIR/$CLI_TEST_APP" ] || handle_error "CLI创建的应用目录不存在"
    
    # 2. 验证配置文件完整性
    local config_file="$APPS_DIR/$CLI_TEST_APP/config.yaml"
    [ -f "$config_file" ] || handle_error "配置文件不存在"
    [ "$(yaml_get "$config_file" "name")" = "$CLI_TEST_APP" ] || handle_error "配置文件名称不匹配"
    [ "$(yaml_get "$config_file" "type")" = "web" ] || handle_error "配置文件类型不匹配"
    
    # 3. 测试安装流程
    echo "y" | "$ROOT_DIR/aitools.sh" --no-ui install "$CLI_TEST_APP" || handle_error "CLI安装应用失败"
    [ -f "$APPS_DIR/$CLI_TEST_APP/.installed" ] || handle_error "安装标记文件不存在"
    
    # 4. 测试配置文件生成
    [ -f "$APPS_DIR/$CLI_TEST_APP/config/settings.yaml" ] || handle_error "运行时配置文件未生成"
    
    # 5. 清理测试应用
    echo "y" | "$ROOT_DIR/aitools.sh" --no-ui remove "$CLI_TEST_APP" || handle_error "CLI删除应用失败"
    [ ! -d "$APPS_DIR/$CLI_TEST_APP" ] || handle_error "应用目录未被删除"
    
    # 测试交互式CLI模式
    local INTERACTIVE_TEST_APP="interactive_workflow_test"
    
    # 1. 交互式创建
    echo -e "$INTERACTIVE_TEST_APP\nweb\n1.0.0\n测试描述\n" | "$ROOT_DIR/aitools.sh" create -i || handle_error "交互式创建失败"
    [ -d "$APPS_DIR/$INTERACTIVE_TEST_APP" ] || handle_error "交互式创建的应用目录不存在"
    
    # 2. 清理交互式测试应用
    echo "y" | "$ROOT_DIR/aitools.sh" --no-ui remove "$INTERACTIVE_TEST_APP"
    
    log_success "UI和CLI工作流程测试通过"
}
