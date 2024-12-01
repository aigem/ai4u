#!/bin/bash

# 交互式创建新应用
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
    local app_type=""
    echo "请选择应用类型："
    echo "1) web"
    echo "2) cli"
    echo "3) service"
    echo "4) other"
    read -p "请选择 (1-4): " choice
    
    case "$choice" in
        1) app_type="web";;
        2) app_type="cli";;
        3) app_type="service";;
        4) app_type="other";;
        *) 
            log_error "无效的选项：$choice"
            return 1
            ;;
    esac

    # 输入版本号
    read -p "请输入版本号 [1.0.0]: " app_version
    app_version=${app_version:-"1.0.0"}

    # 输入描述
    read -p "请输入应用描述: " app_description
    
    # 创建应用结构
    create_app_structure "$app_dir" "$app_name" "$app_type" "$app_version" "$app_description"
    
    log_success "应用 $app_name 创建成功！"
    show_next_steps "$app_name"
    
    return 0
}

# 使用指定参数创建新应用
create_app() {
    local app_name="$1"
    local app_type="$2"
    local app_version="${3:-1.0.0}"
    local app_description="${4:-${app_name} 应用}"
    
    # 验证必需参数
    if [ -z "$app_name" ]; then
        log_error "应用名称不能为空"
        return 1
    fi
    
    if [ -z "$app_type" ]; then
        log_error "应用类型不能为空"
        return 1
    fi
    
    # 验证应用名称格式
    if [[ ! $app_name =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_error "应用名称格式无效，只能包含字母、数字、下划线和连字符"
        return 1
    fi
    
    # 验证应用类型
    case "$app_type" in
        web|cli|service|other) ;;
        *)
            log_error "无效的应用类型：$app_type（有效类型：web|cli|service|other）"
            return 1
            ;;
    esac
    
    # 验证版本号格式
    if [[ ! $app_version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_error "版本号格式无效，请使用 x.y.z 格式（例如：1.0.0）"
        return 1
    fi
    
    # 检查应用是否已存在
    local app_dir="$APPS_DIR/$app_name"
    if [ -d "$app_dir" ]; then
        log_error "应用 '$app_name' 已存在"
        return 1
    fi
    
    # 创建应用结构
    log_info "创建应用 '$app_name'..."
    if ! create_app_structure "$app_dir" "$app_name" "$app_type" "$app_version" "$app_description"; then
        log_error "创建应用结构失败"
        return 1
    fi
    
    # 创建示例配置文件
    log_info "创建配置文件..."
    if ! create_config_files "$app_dir" "$app_name" "$app_type" "$app_version" "$app_description"; then
        log_error "创建配置文件失败"
        return 1
    fi
    
    # 创建必要的脚本
    log_info "创建脚本文件..."
    if ! create_script_files "$app_dir" "$app_name" "$app_type"; then
        log_error "创建脚本文件失败"
        return 1
    fi
    
    # 设置文件权限
    if ! set_permissions "$app_dir"; then
        log_error "设置文件权限失败"
        return 1
    fi
    
    log_success "应用 '$app_name' 创建成功"
    return 0
}

# 创建配置文件
create_config_files() {
    local app_dir="$1"
    local app_name="$2"
    local app_type="$3"
    local app_version="$4"
    local app_description="$5"
    
    # 创建主配置文件
    cat > "$app_dir/config.yaml" << EOL
name: $app_name
type: $app_type
version: $app_version
description: $app_description
status: not_installed
install_time: 
update_time: 
EOL
    
    # 创建设置模板
    cat > "$app_dir/config/settings.yaml.template" << EOL
# $app_name 配置
app:
  name: $app_name
  type: $app_type
  version: $app_version
  description: $app_description

# 应用设置
settings:
  # 在此添加应用特定设置
  example_setting: default_value

# 环境变量
environment:
  # 在此添加需要的环境变量
  # EXAMPLE_VAR: value

# 依赖项
dependencies:
  # 在此添加依赖项
  # - dependency1
  # - dependency2
EOL
    
    # 创建空的依赖文件
    touch "$app_dir/requirements.txt"
    
    return 0
}

# 创建脚本文件
create_script_files() {
    local app_dir="$1"
    local app_name="$2"
    local app_type="$3"
    
    # 创建基本脚本
    for script in install uninstall update status test; do
        create_script "$app_dir" "$script" "$app_name" "$app_type"
    done
    
    return 0
}

# 设置文件权限
set_permissions() {
    local app_dir="$1"
    
    # 设置目录权限
    chmod 755 "$app_dir"
    chmod 755 "$app_dir/scripts"
    chmod 755 "$app_dir/config"
    chmod 755 "$app_dir/data"
    chmod 755 "$app_dir/logs"
    
    # 设置脚本执行权限
    find "$app_dir/scripts" -type f -name "*.sh" -exec chmod 755 {} \;
    
    # 设置配置文件权限
    chmod 644 "$app_dir/config.yaml"
    chmod 644 "$app_dir/config/settings.yaml.template"
    chmod 644 "$app_dir/requirements.txt"
    
    return 0
}

# 创建示例安装脚本
create_install_script() {
    local app_dir="$1"
    local app_name="$2"
    local app_type="$3"
    local install_script="$app_dir/scripts/install.sh"

    cat > "$install_script" << 'EOF'
#!/bin/bash

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
ROOT_DIR="$(dirname "$(dirname "$APP_DIR")")"

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
    local app_name="$2"
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
    local app_version="$4"
    local app_description="$5"
    
    # 确保父目录存在
    if ! mkdir -p "$app_dir"; then
        log_error "无法创建应用目录: $app_dir"
        return 1
    fi
    
    # 创建必要的子目录
    for dir in "scripts" "config" "data" "logs"; do
        if ! mkdir -p "$app_dir/$dir"; then
            log_error "无法创建目录: $app_dir/$dir"
            return 1
        fi
    done
    
    # 创建并设置权限
    create_install_script "$app_dir" "$app_name" "$app_type"
    create_test_script "$app_dir" "$app_name"
    
    # 设置脚本权限
    find "$app_dir/scripts" -type f -name "*.sh" -exec chmod +x {} \;
    
    # 创建配置文件
    cat > "$app_dir/config.yaml" << EOL
name: $app_name
type: $app_type
version: $app_version
description: $app_description
status: not_installed
install_time: 
update_time: 
EOL
    
    # 创建示例配置模板
    cat > "$app_dir/config/settings.yaml.template" << EOL
# $app_name 配置模板
app_name: $app_name
version: $app_version
type: $app_type

# 应用特定配置
settings:
  # 在此添加应用配置项
  example_setting: default_value
EOL
    
    # 创建空的requirements.txt
    touch "$app_dir/requirements.txt"
    
    return 0
}

# 显示下一步操作指引
show_next_steps() {
    local app_name="$1"
    local app_dir="$APPS_DIR/$app_name"
    
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