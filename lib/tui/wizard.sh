#!/bin/bash

# 交互式应用创建向导
show_creation_wizard() {
    clear
    echo "=== AI应用创建向导 ==="
    echo

    # 步骤1：基本信息
    echo "步骤1：基本信息"
    echo "---------------"
    
    # 应用名称验证
    while true; do
        read -p "应用名称（字母、数字、下划线、连字符）: " name
        if [[ $name =~ ^[a-zA-Z0-9_-]+$ ]]; then
            break
        else
            echo "名称格式无效，请重试。"
        fi
    done

    # 应用类型选择及说明
    echo -e "\n可用的应用类型："
    echo "1. web - Web应用"
    echo "2. cli - 命令行应用"
    echo "3. service - 后台服务"
    echo "4. other - 其他类型"
    
    while true; do
        read -p "选择类型 (1-4): " type_choice
        case $type_choice in
            1) type="web"; break;;
            2) type="cli"; break;;
            3) type="service"; break;;
            4) type="other"; break;;
            *) echo "选择无效，请选择1-4。";;
        esac
    done

    # 步骤2：版本和描述
    echo -e "\n步骤2：版本和描述"
    echo "-------------------"
    
    # 版本号验证
    while true; do
        read -p "版本号 (例如: 1.0.0): " version
        if [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            break
        else
            echo "版本号格式无效，请使用 x.y.z 格式。"
        fi
    done

    # 应用描述
    read -p "应用描述: " description

    # 步骤3：依赖项
    echo -e "\n步骤3：依赖项"
    echo "-------------"
    local dependencies=()
    read -p "您的应用是否需要特定的系统包？(y/n): " has_deps
    if [[ $has_deps =~ ^[Yy]$ ]]; then
        read -p "输入包名（用空格分隔）: " -a dependencies
    fi

    # 步骤4：环境设置
    echo -e "\n步骤4：环境设置"
    echo "-------------"
    local env_vars=()
    read -p "是否需要配置环境变量？(y/n): " has_env
    if [[ $has_env =~ ^[Yy]$ ]]; then
        echo "输入环境变量（格式：KEY=VALUE，每行一个，输入空行结束）："
        while IFS= read -r line; do
            [[ -z "$line" ]] && break
            env_vars+=("$line")
        done
    fi

    # 创建应用
    create_app_from_wizard "$name" "$type" "$version" "$description" "${dependencies[@]}" "${env_vars[@]}"
    
    # 显示下一步操作
    show_next_steps "$name"
}

# 从向导输入创建应用
create_app_from_wizard() {
    local name="$1"
    local type="$2"
    local version="$3"
    local description="$4"
    shift 4
    local dependencies=()
    local env_vars=()
    
    # 分离依赖项和环境变量
    while [ $# -gt 0 ]; do
        if [[ "$1" == *"="* ]]; then
            env_vars+=("$1")
        else
            dependencies+=("$1")
        fi
        shift
    done

    # 创建应用配置目录
    local app_dir="$APPS_DIR/$name"
    if [ -d "$app_dir" ]; then
        log_error "应用已存在：$name"
        return 1
    fi

    mkdir -p "$app_dir"
    mkdir -p "$app_dir/scripts"

    # 复制基础配置
    cp "$TEMPLATES_DIR/app_configs/base.yaml" "$app_dir/config.yaml"

    # 创建基本配置
    cat > "$app_dir/config.yaml" << EOL
name: $name
type: $type
version: $version
description: "$description"

# 依赖项配置
dependencies:
EOL

    # 添加依赖项
    if [ ${#dependencies[@]} -gt 0 ]; then
        for dep in "${dependencies[@]}"; do
            echo "  - $dep" >> "$app_dir/config.yaml"
        done
    fi

    # 添加环境变量
    echo -e "\n# 环境变量配置\nenvironment:" >> "$app_dir/config.yaml"
    if [ ${#env_vars[@]} -gt 0 ]; then
        for env in "${env_vars[@]}"; do
            local key="${env%%=*}"
            local value="${env#*=}"
            echo "  $key: \"$value\"" >> "$app_dir/config.yaml"
        done
    fi

    # 添加安装步骤
    cat >> "$app_dir/config.yaml" << EOL

# 安装步骤配置
steps:
  pre: []    # 安装前执行的步骤
  main: []   # 主要安装步骤
  post: []   # 安装后执行的步骤
EOL

    # 创建必要的脚本文件
    touch "$app_dir/scripts/install.sh"
    touch "$app_dir/scripts/uninstall.sh"
    touch "$app_dir/scripts/update.sh"
    touch "$app_dir/scripts/status.sh"
    chmod +x "$app_dir/scripts/"*.sh

    log_success "应用创建成功：$name"
    return 0
}

# 显示创建后的下一步操作
show_next_steps() {
    local name="$1"
    echo -e "\n恭喜！应用 $name 已创建成功。"
    echo "下一步操作："
    echo "1. 编辑 apps/$name/scripts 目录下的脚本文件"
    echo "2. 编辑 apps/$name/config.yaml 完善配置"
    echo "3. 运行 ./aitools.sh install $name 安装应用"
    echo "4. 运行 ./aitools.sh status $name 检查应用状态"
}

# 创建安装脚本
create_install_script() {
    local app_dir="$1"
    local install_script="$app_dir/scripts/install.sh"

    cat > "$install_script" << 'EOF'
#!/bin/bash

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"

# 加载工具函数
source "$APP_DIR/../lib/utils/logger.sh"

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

    # 设置可执行权限
    chmod +x "$install_script"
}

create_app_interactive() {
    local app_name="$1"
    local app_dir="$APPS_DIR/$app_name"

    # 创建应用目录
    mkdir -p "$app_dir"
    mkdir -p "$app_dir/scripts"
    mkdir -p "$app_dir/config"
    mkdir -p "$app_dir/data"
    mkdir -p "$app_dir/logs"

    # 收集应用信息
    local app_type=""
    local app_version=""
    local app_description=""

    # 选择应用类型
    echo "请选择应用类型："
    select type in "web" "cli" "service" "other"; do
        case $type in
            web|cli|service|other)
                app_type=$type
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

    # 创建各种脚本
    create_install_script "$app_dir"
    
    # 创建其他脚本
    for script in uninstall.sh update.sh status.sh; do
        touch "$app_dir/scripts/$script"
        chmod +x "$app_dir/scripts/$script"
    done

    log_success "应用 $app_name 创建成功！"
    show_next_steps "$app_name"
}