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
set -e

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
ROOT_DIR="$(dirname "$(dirname "$APP_DIR")")"

# 加载应用配置
if [ -f "$APP_DIR/config/settings.sh" ]; then
    source "$APP_DIR/config/settings.sh"
fi

# 加载工具函数
source "$ROOT_DIR/lib/utils/logger.sh"

# 开始安装
log_info "开始安装【$APP_NAME】..."

# 提示先自行修改配置
echo "本脚本仅支持在 【$PLATFORM_NAME】 平台运行"
echo "请先自行修改配置文件 $APP_DIR/config/settings.sh"

# read -p "按回车键继续..."

# 创建虚拟环境
if [ ! -d "$VENV_DIR/$VENV_NAME" ]; then
    log_info "创建虚拟环境..."
    conda create -n $VENV_NAME python=$PYTHON_VERSION pip ffmpeg -y
    log_success "虚拟环境创建成功"
else
    log_info "虚拟环境已存在，是否覆盖？(y/n)"
    read -p "请输入选项: " choice
    if [ "$choice" == "y" ]; then
        rm -rf "$VENV_DIR/$VENV_NAME"
        conda create -n $VENV_NAME python=$PYTHON_VERSION pip ffmpeg -y
        log_success "虚拟环境创建成功"
    else
        log_info "虚拟环境已存在"
    fi
fi

# 激活虚拟环境，如果已经激活则继续运行脚本
if ! conda activate $VENV_NAME; then
    log_info "虚拟环境已激活,当前环境为: $VENV_NAME"
fi

# 示例：创建必要的目录
log_info "创建必要的目录..."
mkdir -p "$APP_DIR/data"
mkdir -p "$APP_DIR/logs"
mkdir -p "$APP_DIR/config"

# 安装依赖
log_info "安装依赖..."
if [ -f "$APP_DIR/requirements.txt" ]; then
    pip install -r "$APP_DIR/requirements.txt"
fi

# pip install torch==2.4.0 torchvision==0.19.0 torchaudio==2.4.0 -i https://mirrors.aliyun.com/pypi/simple

# 创建安装标记
touch "$APP_DIR/.installed"

# 将配置中的主要内容及启动命令、虚拟环境名称及如何启动虚拟环境及其它必要信息写入使用说明
echo "配置文件: $APP_DIR/config/settings.sh" > "$WORKSPACE_DIR/$APP_NAME使用说明.md"
echo "虚拟环境名称: $VENV_NAME" >> "$WORKSPACE_DIR/$APP_NAME使用说明.md"
echo "启动说明: " >> "$WORKSPACE_DIR/$APP_NAME使用说明.md"
echo "先运行命令启动虚拟环境: conda activate $VENV_NAME" >> "$WORKSPACE_DIR/$APP_NAME使用说明.md"
echo "再运行命令启动 $APP_NAME: export HF_ENDPOINT=https://hf-mirror.com && $run_cmd" >> "$WORKSPACE_DIR/$APP_NAME使用说明.md"
echo "访问地址: http://<host>:$APP_PORT" >> "$WORKSPACE_DIR/$APP_NAME使用说明.md"
echo "需要你自行使用内网穿透工具将 $APP_PORT 端口映射到公网" >> "$WORKSPACE_DIR/$APP_NAME使用说明.md"
echo "以便查看并使用 $APP_NAME 服务。可以新建命令行终端来运行以下命令进行测试:" >> "$WORKSPACE_DIR/$APP_NAME使用说明.md"
echo "ssh -p 443 -R0:127.0.0.1:${APP_PORT} a.pinggy.io" >> "$WORKSPACE_DIR/$APP_NAME使用说明.md"
echo "需要更好的内网穿透工具及教程请查看 https://space.bilibili.com/3493076850968674" >> "$WORKSPACE_DIR/$APP_NAME使用说明.md"
echo "=============================="
log_info "详细使用说明查看 $WORKSPACE_DIR/$APP_NAME使用说明.md 中，请自行查看"
log_success "$APP_NAME 安装完成！"
echo "=============================="

# 运行应用
read -p "是否现在运行 $APP_NAME? (y/n): " choice
echo "=============================="
if [ "$choice" == "y" ]; then
    log_warning "需要你自行使用内网穿透工具将 $APP_PORT 端口映射到公网"
    log_info "以便查看并使用 $APP_NAME 服务。可以新建命令行终端来运行以下命令进行测试:"
    log_info "ssh -p 443 -R0:127.0.0.1:${APP_PORT} a.pinggy.io"
    export HF_ENDPOINT=https://hf-mirror.com && eval $run_cmd
fi
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

# 创建应用安装入口文件
create_install_entry() {
    local app_dir="$1"
    local app_name=$(basename "$app_dir")
    local install_entry="$app_dir/$app_name.sh"
    local current_date=$(date +%Y-%m-%d)

    cat > "$install_entry" << EOF
#!/bin/bash

# 设置项目名称
project_name="${app_name}"
video_url="https://www.bilibili.com/video/BV1mCkEYyEcy/"

# 脚本信息
echo "================================================"
echo "描述: ${app_name} 主程序，用于管理 ${app_name} 的安装和配置"
echo "作者: ai来事"
echo "创建日期: ${current_date}"
echo "参考视频介绍: \$video_url"
echo "================================================"

# 检查是否在 /workspace 目录下
if [ "\$(pwd)" != "/workspace" ]; then
    echo "请在 /workspace 目录下运行此脚本"
    echo "参考视频教程: \$video_url"
    exit 1
fi

# 检查是否安装了git
if ! command -v git &> /dev/null; then
    echo "git 未安装，请先安装git"
    exit 1
fi

# 克隆仓库
if [ ! -d "ai4u" ]; then
    echo "正在克隆 ai4u 仓库..."
    git clone https://gitee.com/fuliai/ai4u.git
else
    echo "ai4u 仓库已存在，正在更新..."
    cd ai4u
    git pull
    cd ..
fi

# 创建必要的目录
echo "创建必要的目录..."
mkdir -p ai4u/apps/${app_name}/scripts

# 复制脚本文件
if [ -d "scripts" ]; then
    echo "复制安装脚本..."
    cp -r scripts/* ai4u/apps/${app_name}/scripts/
else
    echo "错误：scripts 目录不存在"
    echo "请确保已获取正确的安装脚本并解压到 /workspace 目录下"
    echo "================================================"
    echo "获取链接: https://gf.bilibili.com/item/detail/1107198073"
    echo ""
    echo "先看视频教程：\$video_url"
    echo "================================================"
    exit 1
fi

# 检查必要文件是否存在
if [ ! -f "ai4u/apps/${app_name}/scripts/install.sh" ]; then
    echo "错误：install.sh 文件不存在"
    echo "请确保已获取正确的安装脚本并解压到 /workspace 目录下"
    echo "================================================"
    echo "获取链接: https://gf.bilibili.com/item/detail/1107198073"
    echo ""
    echo "先看视频教程：\$video_url"
    echo "================================================"
    exit 1
fi

# 设置执行权限
chmod +x ai4u/aitools.sh

# 进入 ai4u 目录并运行安装
cd ai4u
echo "开始安装 ${app_name}..."
bash aitools.sh install ${app_name}
EOF

    chmod +x "$install_entry"
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
VENV_NAME="ai_$app_name"
# 虚拟环境目录(良心云的默认路径，其他环境请自行修改)
VENV_DIR="/root/miniconda3/envs/"
# python版本
PYTHON_VERSION="3.11"
# 工作目录: 用于存放下载的Ai应用
WORKSPACE_DIR="/workspace"
# 应用端口
APP_PORT="7860"
# 启动命令-请自行修改,必填项
run_cmd="python $APP_DIR/main.py"
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
    
    # 创建应用安装入口文件
    create_install_entry "$app_dir"
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