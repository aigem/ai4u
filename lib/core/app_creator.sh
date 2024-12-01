#!/bin/bash

# 交互式创建新应用
create_app_interactive() {
    log_info "启动应用创建向导..."
    source ./lib/tui/wizard.sh
    show_creation_wizard
}

# 使用指定参数创建新应用
create_app() {
    local name="$1"
    local type="$2"

    if [ -z "$name" ] || [ -z "$type" ]; then
        log_error "应用名称和类型是必需的"
        return 1
    fi

    # 验证应用类型
    case "$type" in
        text_generation|image_generation|speech_recognition|translation|other)
            ;;
        *)
            log_error "无效的应用类型：$type"
            return 1
            ;;
    esac

    # 创建应用目录
    local app_dir="$APPS_DIR/$name"
    if [ -d "$app_dir" ]; then
        log_error "应用已存在：$name"
        return 1
    fi

    mkdir -p "$app_dir"

    # 复制并更新配置
    cp "$TEMPLATES_DIR/app_configs/base.yaml" "$app_dir/config.yaml"
    update_yaml "$app_dir/config.yaml" "name" "$name"
    update_yaml "$app_dir/config.yaml" "type" "$type"
    update_yaml "$app_dir/config.yaml" "version" "1.0.0"

    # 创建其他必需文件
    touch "$app_dir/status.sh"
    chmod +x "$app_dir/status.sh"

    log_success "应用创建成功：$name"
    return 0
}

# 创建应用
create_app() {
    local app_name="$1"
    local app_type="$2"
    
    source "$LIB_DIR/tui/wizard.sh"
    create_app_interactive "$app_name"
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
    local app_version="$4"
    local app_description="$5"

    # 创建目录
    mkdir -p "$app_dir"/{scripts,config,data,logs}

    # 创建配置文件
    cat > "$app_dir/config.yaml" << EOF
name: "$app_name"
type: "$app_type"
version: "$app_version"
description: "$app_description"

dependencies: []
environment: {}

steps:
  pre:
    - "mkdir -p data"
    - "mkdir -p logs"
  main:
    - "pip3 install -r requirements.txt --user"
  post:
    - "chmod +x scripts/*.sh"

command: ""
working_dir: ""
log_dir: "logs"
EOF

    # 创建示例依赖文件
    cat > "$app_dir/requirements.txt" << EOF
# 示例依赖
pyyaml>=5.1
requests>=2.25.1
EOF

    # 创建示例配置模板
    cat > "$app_dir/config/settings.yaml.template" << EOF
# 应用配置模板
app:
  name: $app_name
  env: production

server:
  host: localhost
  port: 8080

logging:
  level: INFO
  file: ../logs/app.log
EOF

    # 创建脚本
    create_install_script "$app_dir"
    create_test_script "$app_dir"
    
    # 创建其他脚本
    for script in uninstall.sh update.sh status.sh; do
        touch "$app_dir/scripts/$script"
        chmod +x "$app_dir/scripts/$script"
    done
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
    show_next_steps "$app_name"
}