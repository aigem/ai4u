#!/bin/bash

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# 加载工具函数
source "$ROOT_DIR/lib/utils/logger.sh"

# 测试应用名称
TEST_APP="test_app"

# 清理函数
cleanup() {
    log_info "清理测试环境..."
    rm -rf "$ROOT_DIR/apps/$TEST_APP"
    rm -f "$SCRIPT_DIR/test_input.txt"
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
    
    # 准备输入数据（用于描述输入）
    cat << EOF > "$SCRIPT_DIR/test_input.txt"
测试应用
EOF
    
    # 创建应用（使用非交互模式）
    bash "$ROOT_DIR/aitools.sh" create "$TEST_APP" --type web || handle_error "创建应用失败"
    
    # 检查目录结构
    for dir in "scripts" "config" "data" "logs"; do
        [ -d "$ROOT_DIR/apps/$TEST_APP/$dir" ] || handle_error "目录不存在：$dir"
    done
    
    # 检查文件
    for file in "config.yaml" "requirements.txt" "config/settings.yaml.template" "scripts/install.sh" "scripts/test.sh"; do
        [ -f "$ROOT_DIR/apps/$TEST_APP/$file" ] || handle_error "文件不存在：$file"
    done
    
    # 检查脚本权限
    for script in "$ROOT_DIR/apps/$TEST_APP/scripts/"*.sh; do
        [ -x "$script" ] || handle_error "脚本没有执行权限：$script"
    done
    
    log_success "创建应用测试通过"
}

# 测试安装应用
test_install_app() {
    log_info "测试安装应用..."
    
    # 准备输入数据
    echo "y" > "$SCRIPT_DIR/test_input.txt"
    
    # 安装应用
    bash "$ROOT_DIR/aitools.sh" install "$TEST_APP" < "$SCRIPT_DIR/test_input.txt" || handle_error "安装应用失败"
    
    # 检查安装标记
    [ -f "$ROOT_DIR/apps/$TEST_APP/.installed" ] || handle_error "安装标记不存在"
    
    log_success "安装应用测试通过"
}

# 测试应用状态
test_app_status() {
    log_info "测试应用状态..."
    
    # 检查状态
    bash "$ROOT_DIR/aitools.sh" status "$TEST_APP" || handle_error "检查状态失败"
    
    log_success "应用状态测试通过"
}

# 测试重新安装
test_reinstall_app() {
    log_info "测试重新安装应用..."
    
    # 准备输入数据
    echo "y" > "$SCRIPT_DIR/test_input.txt"
    
    # 重新安装应用
    bash "$ROOT_DIR/aitools.sh" install "$TEST_APP" < "$SCRIPT_DIR/test_input.txt" || handle_error "重新安装应用失败"
    
    log_success "重新安装应用测试通过"
}

# 测试移除应用
test_remove_app() {
    log_info "测试移除应用..."
    
    # 准备输入数据
    echo "y" > "$SCRIPT_DIR/test_input.txt"
    
    # 移除应用
    bash "$ROOT_DIR/aitools.sh" remove "$TEST_APP" < "$SCRIPT_DIR/test_input.txt" || handle_error "移除应用失败"
    
    # 检查应用是否已移除
    [ ! -d "$ROOT_DIR/apps/$TEST_APP" ] || handle_error "应用未被完全移除"
    
    log_success "移除应用测试通过"
}

# 运行所有测试
run_all_tests() {
    log_info "开始运行集成测试..."
    
    # 清理旧的测试环境
    cleanup
    
    # 运行测试
    test_create_app
    test_install_app
    test_app_status
    test_reinstall_app
    test_remove_app
    
    # 清理测试环境
    cleanup
    rm -f "$SCRIPT_DIR/test_input.txt"
    
    log_success "所有测试通过！"
}

# 执行测试
run_all_tests
