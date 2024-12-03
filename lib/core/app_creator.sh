#!/bin/bash

# 交互式创建新应用
create_app_interactive() {
    log_info "启动应用创建向导..."
    source ./lib/tui/wizard.sh
    show_creation_wizard
}

# 使用指定参数创建新应用
create_app() {
    local app_name="$1"
    local app_type="$2"
    local app_dir="$APPS_DIR/$app_name"
    
    # 检查应用是否已存在
    if [ -d "$app_dir" ]; then
        log_error "应用 $app_name 已存在"
        return 1
    fi
    
    # 验证应用类型
    case "$app_type" in
        web|cli|service|other)
            ;;
        *)
            log_error "无效的应用类型：$app_type"
            return 1
            ;;
    esac
    
    # 创建应用结构
    create_app_structure "$app_dir" "$app_name" "$app_type" "1.0.0" "自动创建的$app_type应用"
    
    log_success "应用 $app_name 创建成功！"
    show_next_steps "$app_name"
    
    return 0
}

# 创建示例安装脚本
create_install_script() {
    local app_dir="$1"
    local install_script="$app_dir/scripts/install.sh"

    cat > "$install_script" << 'EOF'
#!/bin/bash

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
ROOT_DIR="$(dirname "$(dirname "$APP_DIR")")"

# 加载应用配置
if [ -f "$APP_DIR/config/settings.yaml" ]; then
    source "$APP_DIR/config/settings.yaml"
fi

# 加载工具函数
source "$ROOT_DIR/lib/utils/logger.sh"

# 开始安装
log_info "开始安装应用..."

# 示例：创建必要的目录
log_info "创建必要的目录..."
mkdir -p "$APP_DIR/data"
mkdir -p "$APP_DIR/logs"
mkdir -p "$APP_DIR/config"

# 示例：下载依赖
log_info "下载依赖..."
if command -v pip3 &> /dev/null; then
    pip3 install -r "$APP_DIR/requirements.txt" --user
else
    log_error "未找到pip3，请先安装Python3和pip3"
    exit 1
fi

# 示例：配置权限
log_info "配置权限..."
chmod +x "$APP_DIR/scripts/"*.sh
chmod 755 "$APP_DIR/data"
chmod 755 "$APP_DIR/logs"

# 示例：初始化配置
log_info "初始化配置..."
if [ ! -f "$APP_DIR/config/settings.yaml" ]; then
    cp "$APP_DIR/config/settings.yaml.template" "$APP_DIR/config/settings.yaml"
fi

# 示例：运行测试
log_info "运行测试..."
if [ -f "$APP_DIR/scripts/test.sh" ]; then
    bash "$APP_DIR/scripts/test.sh"
fi

# 创建安装标记
touch "$APP_DIR/.installed"

log_success "安装完成！"
EOF

    chmod +x "$install_script"
}

# 创建示例测试脚本
create_test_script() {
    local app_dir="$1"
    local test_script="$app_dir/scripts/test.sh"

    cat > "$test_script" << 'EOF'
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
ROOT_DIR="$(dirname "$(dirname "$APP_DIR")")"

source "$ROOT_DIR/lib/utils/logger.sh"

# 测试配置文件
test_config() {
    log_info "测试配置文件..."
    if [ ! -f "$APP_DIR/config/settings.yaml" ]; then
        log_error "配置文件不存在"
        return 1
    fi
    return 0
}

# 测试依赖项
test_dependencies() {
    log_info "测试依赖项..."
    if [ ! -f "$APP_DIR/requirements.txt" ]; then
        log_error "依赖文件不存在"
        return 1
    fi
    
    # 检查Python包
    while read -r package; do
        if [[ $package =~ ^#.*$ ]] || [ -z "$package" ]; then
            continue
        fi
        package_name="${package%%[>=<]*}"
        if ! pip3 list | grep -i "^$package_name" > /dev/null; then
            log_error "缺少Python包：$package_name"
            return 1
        fi
    done < "$APP_DIR/requirements.txt"
    
    return 0
}

# 测试目录结构
test_directories() {
    log_info "测试目录结构..."
    local required_dirs=("data" "logs" "config" "scripts")
    
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$APP_DIR/$dir" ]; then
            log_error "目录不存在：$dir"
            return 1
        fi
    done
    
    return 0
}

# 运行所有测试
run_all_tests() {
    local failed=0
    
    test_config || failed=1
    test_dependencies || failed=1
    test_directories || failed=1
    
    if [ $failed -eq 0 ]; then
        log_success "所有测试通过！"
        return 0
    else
        log_error "测试失败！"
        return 1
    fi
}

# 执行测试
run_all_tests
EOF

    chmod +x "$test_script"
}

# 创建应用目录结构
create_app_structure() {
    local app_dir="$1"
    local app_name="$2"
    local app_type="$3"
    local version="$4"
    local description="$5"
    
    # 创建目录结构
    mkdir -p "$app_dir"/{scripts,config,data,logs}
    
    # 创建并配置 config.yaml
    cat > "$app_dir/config.yaml" << EOF
name: $app_name
type: $app_type
version: $version
description: $description
status: not_installed
EOF
    
    # 创建 requirements.txt
    cat > "$app_dir/requirements.txt" << EOF
# Python dependencies
PyYAML>=6.0
requests>=2.28.0
EOF
    
    # 创建配置模板
    cat > "$app_dir/config/settings.sh" << EOF
#!/bin/bash

# $app_name 应用配置
APP_NAME="$app_name"
APP_TYPE="$app_type"
APP_VERSION="$version"

# 用于哪个平台的安装
PLATFORM_NAME="良心云"

# 应用特定配置

# 虚拟环境名称
VENV_NAME="ai_$APP_NAME"
# 虚拟环境目录(良心云的默认路径，其他环境请自行修改)
VENV_DIR="/root/miniconda3/envs/"
# python版本
PYTHON_VERSION="3.11"
# 工作目录: 用于存放下载的Ai应用
WORKSPACE_DIR="/workspace"
# 应用端口
APP_PORT="7860" 
EOF
    
    # 创建安装脚本
    create_install_script "$app_dir"
    
    # 创建测试脚本
    create_test_script "$app_dir"
    
    # 创建其他必要脚本
    touch "$app_dir/scripts/uninstall.sh"
    chmod +x "$app_dir/scripts/uninstall.sh"
    
    touch "$app_dir/scripts/update.sh"
    chmod +x "$app_dir/scripts/update.sh"
    
    touch "$app_dir/scripts/status.sh"
    chmod +x "$app_dir/scripts/status.sh"
}

# 显示下一步操作指引
show_next_steps() {
    local app_name="$1"
    local app_dir="$APPS_DIR/$app_name"
    
    cat << EOF

[下一步操作]
1. 编辑配置文件：
   $app_dir/config/settings.sh

2. 安装应用：
   ./aitools.sh install $app_name

3. 检查应用状态：
   ./aitools.sh status $app_name
EOF
}

# 交互式创建应用
create_app_interactive() {
    local app_name="$1"
    
    if [ -z "$app_name" ]; then
        read -p "请输入应用名称: " app_name
    fi
    
    local app_dir="$APPS_DIR/$app_name"
    
    # 检查应用是否已存在
    if [ -d "$app_dir" ]; then
        log_error "应用 $app_name 已存在"
        return 1
    fi

    # 选择应用类型
    echo "请选择应用类型："
    select app_type in "web" "cli" "service" "other"; do
        case $app_type in
            web|cli|service|other)
                break
                ;;
            *) echo "请选择有效的选项 1-4";;
        esac
    done

    # 输入版本号
    read -p "请输入版本号 [1.0.0]: " app_version
    app_version=${app_version:-"1.0.0"}

    # 输入描述
    read -p "请输入应用描述: " app_description
    
    # 创建应用结构
    create_app_structure "$app_dir" "$app_name" "$app_type" "$app_version" "$app_description"
    
    log_success "应用 $app_name 创建成功！"
    
    # 显示下一步操作指引
    cat << EOF

[下一步操作]
1. 编辑配置文件：
   $app_dir/config.yaml

2. 安装应用：
   ./aitools.sh install $app_name

3. 检查应用状态：
   ./aitools.sh status $app_name
EOF
}