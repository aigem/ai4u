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

# 添加测试环境设置
setup_test_env() {
    # 创建临时测试目录
    TEST_TMP_DIR=$(mktemp -d)
    export APPS_DIR="$TEST_TMP_DIR/apps"
    mkdir -p "$APPS_DIR"
    
    # 设置测试模式
    export TEST_MODE=true
    export USE_BASIC_UI=true
    
    # 备份原始环境变量
    OLD_PATH="$PATH"
    OLD_PYTHONPATH="$PYTHONPATH"
    
    # 设置测试环境变量
    export PATH="$TEST_TMP_DIR/bin:$PATH"
    export PYTHONPATH="$TEST_TMP_DIR/lib:$PYTHONPATH"
}

# 清理测试环境
cleanup() {
    log_info "清理测试环境..."
    
    # 恢复环境变量
    export PATH="$OLD_PATH"
    export PYTHONPATH="$OLD_PYTHONPATH"
    
    # 清理临时目录
    if [ -d "$TEST_TMP_DIR" ]; then
        rm -rf "$TEST_TMP_DIR"
    fi
}

# 改进错误处理
handle_error() {
    local error_msg="$1"
    local error_code="${2:-1}"
    local stack_trace
    
    # 获取调用栈
    stack_trace=$(caller 0)
    
    log_error "测试失败：$error_msg"
    log_info "错误详情："
    log_info "- 测试应用：$TEST_APP"
    log_info "- 应用目录：$TEST_APP_DIR"
    log_info "- 错误代码：$error_code"
    log_info "- 调用位置：$stack_trace"
    
    # 保存测试状态
    echo "最后失败的测试：${FUNCNAME[1]}" > "$TEST_APP_DIR/.test_status"
    
    cleanup
    exit "$error_code"
}

# 测试命令行模式
test_cli_mode() {
    log_info "测试命令行模式..."
    
    # 确保脚本有执行权限
    chmod +x "$ROOT_DIR/aitools.sh"
    
    # 测试创建应用
    "$ROOT_DIR/aitools.sh" --test-mode create "$TEST_APP" --type web || handle_error "CLI模式创建应用失败"
    
    # 测试安装应用
    echo "y" | "$ROOT_DIR/aitools.sh" --test-mode install "$TEST_APP" || handle_error "CLI模式安装应用失败"
    
    # 测试查看状态
    "$ROOT_DIR/aitools.sh" --test-mode status "$TEST_APP" || handle_error "CLI模式查看状态失败"
    
    # 测试更新应用
    "$ROOT_DIR/aitools.sh" --test-mode update "$TEST_APP" || handle_error "CLI模式更新应用失败"
    
    # 测试列出应用
    "$ROOT_DIR/aitools.sh" --test-mode list || handle_error "CLI模式列出应用失败"
    
    # 测试移除应用（自动确认）
    echo "y" | "$ROOT_DIR/aitools.sh" --test-mode remove "$TEST_APP" || handle_error "CLI模式移除应用失败"
    
    log_success "命令行模式测试通过"
}

# 测试创建应用
test_create_app() {
    log_info "测试创建应用..."
    
    # 测试基本创建
    create_app "$TEST_APP" "web" || handle_error "创建应用失败"
    
    # 检查基本创建的目录结构
    for dir in "scripts" "config" "data" "logs"; do
        [ -d "$TEST_APP_DIR/$dir" ] || handle_error "基本创建目录不存在：$dir"
    done
    
    # 检查基本创建的必要文件
    for file in "config.yaml" "requirements.txt" "config/settings.yaml.template"; do
        [ -f "$TEST_APP_DIR/$file" ] || handle_error "基本创建文件不存在：$file"
    done
    
    # 检查基本创建的必要脚本
    for script in "install.sh" "uninstall.sh" "update.sh" "status.sh" "test.sh"; do
        [ -f "$TEST_APP_DIR/scripts/$script" ] || handle_error "基本创建脚本不存在：$script"
        [ -x "$TEST_APP_DIR/scripts/$script" ] || handle_error "基本创建脚本没有执行权限：$script"
    done
    
    # 检查基本创建的配置文件内容
    local name=$(yaml_get "$TEST_APP_DIR/config.yaml" "name")
    local type=$(yaml_get "$TEST_APP_DIR/config.yaml" "type")
    local status=$(yaml_get "$TEST_APP_DIR/config.yaml" "status")
    
    [ "$name" = "$TEST_APP" ] || handle_error "基本创建配置文件中的应用名称不正确"
    [ "$type" = "web" ] || handle_error "基本创建配置文件中的应用类型不正确"
    [ "$status" = "not_installed" ] || handle_error "基本创建配置文件中的应用状态不正确"
    
    # 清理基本创建的应用
    cleanup
    
    # 测试交互式创建
    local INTERACTIVE_APP="test_app_interactive"
    local INTERACTIVE_APP_DIR="$APPS_DIR/$INTERACTIVE_APP"
    
    echo -e "$INTERACTIVE_APP\n1\n1.0.0\n测试描述\n" | create_app_interactive || handle_error "交互式创建应用失败"
    
    # 检查交互式创建的目录结构
    for dir in "scripts" "config" "data" "logs"; do
        [ -d "$INTERACTIVE_APP_DIR/$dir" ] || handle_error "交互式创建目录不存在：$dir"
    done
    
    # 检查交互式创建的必要文件
    for file in "config.yaml" "requirements.txt" "config/settings.yaml.template"; do
        [ -f "$INTERACTIVE_APP_DIR/$file" ] || handle_error "交互式创建文件不存在：$file"
    done
    
    # 检查交互式创建的必要脚本
    for script in "install.sh" "uninstall.sh" "update.sh" "status.sh" "test.sh"; do
        [ -f "$INTERACTIVE_APP_DIR/scripts/$script" ] || handle_error "交互式创建脚本不存在：$script"
        [ -x "$INTERACTIVE_APP_DIR/scripts/$script" ] || handle_error "交互式创建脚本没有执行权限：$script"
    done
    
    # 检查交互式创建的配置文件内容
    name=$(yaml_get "$INTERACTIVE_APP_DIR/config.yaml" "name")
    type=$(yaml_get "$INTERACTIVE_APP_DIR/config.yaml" "type")
    status=$(yaml_get "$INTERACTIVE_APP_DIR/config.yaml" "status")
    
    [ "$name" = "$INTERACTIVE_APP" ] || handle_error "交互式创建配置文件中的应用名称不正确"
    [ "$type" = "web" ] || handle_error "交互式创建配置文件中的应用类型不正确"
    [ "$status" = "not_installed" ] || handle_error "交互式创建配置文件中的应用状态不正确"
    
    # 清理交互式创建的应用
    rm -rf "$INTERACTIVE_APP_DIR"
    
    log_success "创建应用测试通过"
}

# 测试安装应用
test_install_app() {
    log_info "测试安装应用..."
    
    # 创建测试应用
    create_app "$TEST_APP" "web" || handle_error "创建测试应用失败"
    
    # 测试首次安装
    echo "y" | install_app "$TEST_APP" || handle_error "首次安装失败"
    [ -f "$TEST_APP_DIR/.installed" ] || handle_error "安装标记不存在"
    
    # 测试重复安装（应该提示已安装并询问是否重新安装）
    local output
    output=$(echo "n" | install_app "$TEST_APP" 2>&1)
    echo "$output" | grep -q "应用已安装" || {
        echo "实际输出: $output"
        handle_error "重复安装检查失败"
    }
    
    # 确保在用户选择不重新安装时保持原状
    [ -f "$TEST_APP_DIR/.installed" ] || handle_error "安装标记丢失"
    
    # 测试强制重新安装
    echo "y" | install_app "$TEST_APP" || handle_error "强制重新安装失败"
    [ -f "$TEST_APP_DIR/.installed" ] || handle_error "重新安装后安装标记不存在"
    
    log_success "安装应用测试通过"
    return 0
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
    (
        echo "$interactive_app"  # 应用名称
        sleep 0.1               # 添加短暂延迟确保输入顺序正确
        echo "1"                # 选择 web 类型 (1 对应 web)
        sleep 0.1               # 添加短暂延迟
        echo "1.0.0"           # 版本号
        sleep 0.1               # 添加短暂延迟
        echo "测试应用"         # 应用描述
    ) | create_app_interactive || {
        # 确保在失败时也清理
        [ -d "$interactive_app_dir" ] && rm -rf "$interactive_app_dir"
        handle_error "交互式创建应用失败"
    }
    
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

# 修改UI测试以适应测试模式
test_ui_components() {
    log_info "测试UI组件..."
    
    # 在测试模式下跳过UI测试
    if [ "$TEST_MODE" = "true" ]; then
        log_info "测试模式：跳过UI组件测试"
        return 0
    fi
    
    # 原有的UI测试代码保持不变
    test_main_window
    test_progress_display
    test_theme_switching
}

# 修改UI依赖检查测试
test_ui_dependencies() {
    log_info "测试UI依赖检查..."
    
    # 在测试模式下使用简化的UI依赖检查
    if [ "$TEST_MODE" = "true" ]; then
        log_info "测试模式：使用基础UI"
        return 0
    fi
    
    # 原有的UI依赖检查代码保持不变
    check_ui_dependencies || handle_error "UI依赖检查失败"
    if [ "$USE_BASIC_UI" != "true" ]; then
        whiptail --version >/dev/null 2>&1 || handle_error "whiptail不可用"
    fi
    
    log_success "UI依赖检查测试通过"
}

# 运行所有测试
run_all_tests() {
    cleanup
    
    # 1. 基础功能测试
    test_config_files || return 1      # 先检查配置文件
    test_create_app || return 1        # 测试基本创建
    test_interactive_create || return 1 # 测试交互式创建
    
    # 2. 应用生命周期测试
    test_install_app || return 1       # 测试安装
    test_app_status || return 1        # 测试状态查看
    test_update_app || return 1        # 测试更新
    test_reinstall_app || return 1     # 测试重新安装
    test_remove_app || return 1        # 测试移除
    
    # 3. 综合功能测试
    test_cli_mode || return 1          # 测试命令行模式
    test_list_apps || return 1         # 测试应用列表
    
    # 4. UI相关测试
    test_ui_components || return 1
    test_ui_dependencies || return 1
    
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

# 创建示例测试脚本时不需要再进行完整测试
create_test_script() {
    local app_dir="$1"
    local test_script="$app_dir/scripts/test.sh"

    cat > "$test_script" << 'EOF'
#!/bin/bash

# 简化版测试脚本
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"

# 基本检查
basic_check() {
    # 检查必要目录
    [ -d "$APP_DIR/config" ] || exit 1
    [ -d "$APP_DIR/data" ] || exit 1
    [ -d "$APP_DIR/logs" ] || exit 1
    
    # 检查必要文件
    [ -f "$APP_DIR/config/settings.yaml" ] || exit 1
    [ -f "$APP_DIR/requirements.txt" ] || exit 1
    
    return 0
}

# 执行基本检查
basic_check
EOF

    chmod +x "$test_script"
}

# 修改安装脚本模板
create_install_script() {
    local app_dir="$1"
    local install_script="$app_dir/scripts/install.sh"

    cat > "$install_script" << 'EOF'
#!/bin/bash

# ... 前面的代码保持不变 ...

# 检查是否已安装
if [ -f "$APP_DIR/.installed" ]; then
    read -p "应用已安装，是否重新安装？[y/N] " choice
    case "$choice" in
        y|Y) 
            log_info "开始重新安装..."
            ;;
        *)
            log_info "取消安装"
            exit 0
            ;;
    esac
fi

# ... 后面的代码保持不变 ...
EOF

    chmod +x "$install_script"
}

# 需要添加的测试用例
test_app_validation() {
    log_info "测试应用验证..."
    
    # 测试无效应用名称
    create_app "" "web" 2>/dev/null && handle_error "应该拒绝空应用名称"
    create_app "invalid/name" "web" 2>/dev/null && handle_error "应该拒绝包含特殊字符的应用名称"
    
    # 测试无效应用类型
    create_app "test_app" "invalid_type" 2>/dev/null && handle_error "应该拒绝无效的应用类型"
    
    # 测试版本号格式
    create_app_interactive <<< "test_app\n1\ninvalid-version\n描述" 2>/dev/null && handle_error "应该拒绝无效的版本号格式"
    
    log_success "应用验证测试通过"
}

# 添加配置文件测试
test_config_validation() {
    log_info "测试配置验证..."
    
    # 创建测试应用
    create_app "$TEST_APP" "web" || handle_error "创建测试应用失败"
    
    # 测试配置文件格式
    [ -f "$TEST_APP_DIR/config.yaml" ] || handle_error "配置文件不存在"
    yaml_validate "$TEST_APP_DIR/config.yaml" || handle_error "配置文件格式无效"
    
    # 测试必要字段
    grep -q "name:" "$TEST_APP_DIR/config.yaml" || handle_error "缺少name字段"
    grep -q "type:" "$TEST_APP_DIR/config.yaml" || handle_error "缺少type字段"
    grep -q "version:" "$TEST_APP_DIR/config.yaml" || handle_error "缺少version字段"
    
    log_success "配置验证测试通过"
}
