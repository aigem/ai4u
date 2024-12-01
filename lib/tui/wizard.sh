#!/bin/bash

# 交互式应用创建向导
show_creation_wizard() {
    clear
    echo "=== AI应用创建向导 ==="
    echo

    # 检查目录权限
    if [ ! -w "$APPS_DIR" ]; then
        log_error "无法写入应用目录: $APPS_DIR"
        log_error "请检查目录权限或以管理员身份运行"
        return 1
    }

    # 步骤1：基本信息
    echo "步骤1：基本信息"
    echo "---------------"
    
    # 应用名称验证
    while true; do
        read -p "应用名称（字母、数字、下划线、连字符）: " name
        
        # 检查名称是否为空
        if [ -z "$name" ]; then
            echo "名称不能为空，请重试。"
            continue
        fi
        
        # 检查名称格式
        if [[ ! $name =~ ^[a-zA-Z0-9_-]+$ ]]; then
            echo "名称格式无效，只能包含字母、数字、下划线和连字符。"
            continue
        fi
        
        # 检查名称长度
        if [ ${#name} -gt 50 ]; then
            echo "名称太长，请使用50个字符以内的名称。"
            continue
        fi
        
        # 检查是否已存在
        if [ -d "$APPS_DIR/$name" ]; then
            echo "应用 '$name' 已存在，请选择其他名称。"
            continue
        fi
        
        break
    done

    # 应用类型选择及说明
    echo -e "\n可用的应用类型："
    echo "1. web    - Web应用（网页界面）"
    echo "2. cli    - 命令行应用（终端运行）"
    echo "3. service- 后台服务（系统服务）"
    echo "4. other  - 其他类型"
    
    while true; do
        read -p "选择类型 [1-4]: " type_choice
        case $type_choice in
            1) type="web"; break;;
            2) type="cli"; break;;
            3) type="service"; break;;
            4) type="other"; break;;
            *) echo "选择无效，请输入1-4之间的数字。";;
        esac
    done

    # 步骤2：版本和描述
    echo -e "\n步骤2：版本和描述"
    echo "-------------------"
    
    # 版本号验证
    while true; do
        read -p "版本号 [1.0.0]: " version
        version=${version:-"1.0.0"}
        
        if [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            break
        else
            echo "版本号格式无效，请使用 x.y.z 格式（例如：1.0.0）"
        fi
    done

    # 描述验证
    while true; do
        read -p "应用描述: " description
        description=${description:-"$name 应用"}
        
        if [ ${#description} -gt 200 ]; then
            echo "描述太长，请限制在200个字符以内。"
            continue
        fi
        
        break
    done

    # 确认信息
    echo -e "\n请确认以下信息："
    echo "-------------------"
    echo "应用名称: $name"
    echo "应用类型: $type"
    echo "版本号  : $version"
    echo "描述    : $description"
    echo

    read -p "确认创建应用？(y/n) " confirm
    if [[ $confirm != [Yy]* ]]; then
        echo "已取消创建应用。"
        return 1
    fi

    # 创建应用
    if create_app "$name" "$type" "$version" "$description"; then
        echo
        log_success "应用 '$name' 创建成功！"
        show_next_steps "$name"
        return 0
    else
        log_error "创建应用失败，请检查错误信息。"
        return 1
    fi
}

# 从向导输入创建应用
create_app() {
    local name="$1"
    local type="$2"
    local version="$3"
    local description="$4"
    
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