#!/bin/bash

# ComfyUI 安装脚本

# 引入必要的库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$ROOT_DIR/lib/logger.sh"
source "$ROOT_DIR/lib/error_handler.sh"
source "$ROOT_DIR/lib/utils.sh"
source "$ROOT_DIR/lib/ui.sh"

# 应用配置
APP_NAME="ComfyUI"
APP_VERSION="latest"
REPO_URL="https://github.com/comfyanonymous/ComfyUI.git"
INSTALL_DIR="${ROOT_DIR}/apps/comfyui"
REQUIRED_SPACE=10000  # 10GB
REQUIRED_MEMORY=8000  # 8GB
PYTHON_VERSION="3.10"

# 安装前检查
pre_install_check() {
    log_info "执行ComfyUI安装前检查..."
    
    # 系统要求检查
    check_system_requirements || return 1
    
    # 检查磁盘空间
    check_disk_space "$REQUIRED_SPACE" "$INSTALL_DIR" || return 1
    
    # 检查内存
    check_memory "$REQUIRED_MEMORY" || return 1
    
    # 检查CUDA支持
    if ! command -v nvidia-smi &> /dev/null; then
        log_warn "未检测到NVIDIA GPU，ComfyUI将使用CPU模式运行"
    fi
    
    log_info "安装前检查完成"
    return 0
}

# 安装依赖
install_dependencies() {
    log_info "安装ComfyUI依赖..."
    
    # 安装Python包
    local required_packages=(
        "torch"
        "torchvision"
        "torchaudio"
        "numpy"
        "pillow"
        "opencv-python"
        "transformers"
    )
    
    for package in "${required_packages[@]}"; do
        log_info "安装 $package..."
        install_python_package "$package" || return 1
    done
    
    log_info "依赖安装完成"
    return 0
}

# 环境配置
setup_environment() {
    log_info "配置ComfyUI环境..."
    
    # 创建必要的目录
    ensure_directory "$INSTALL_DIR/models" || return 1
    ensure_directory "$INSTALL_DIR/outputs" || return 1
    ensure_directory "$INSTALL_DIR/custom_nodes" || return 1
    
    log_info "环境配置完成"
    return 0
}

# 主程序安装
install_main() {
    log_info "安装ComfyUI主程序..."
    
    # 克隆ComfyUI仓库
    if [ ! -d "$INSTALL_DIR/src" ]; then
        clone_git_repo "$REPO_URL" "$INSTALL_DIR/src" || return 1
    else
        log_info "ComfyUI源码已存在，跳过克隆"
    fi
    
    # 安装Python依赖
    cd "$INSTALL_DIR/src" || return 1
    pip install -r requirements.txt || return 1
    
    log_info "主程序安装完成"
    return 0
}

# 应用配置
configure_app() {
    log_info "配置ComfyUI..."
    
    # 生成配置文件
    local config_file="$INSTALL_DIR/config/config.yaml"
    cat > "$config_file" << EOF
# ComfyUI配置文件
host: 0.0.0.0
port: 8188
enable_cuda: true
models_dir: ${INSTALL_DIR}/models
output_dir: ${INSTALL_DIR}/outputs
custom_nodes_dir: ${INSTALL_DIR}/custom_nodes
EOF
    
    log_info "应用配置完成"
    return 0
}

# 安装后处理
post_install() {
    log_info "执行安装后处理..."
    
    # 设置权限
    chmod -R 755 "$INSTALL_DIR/src" || return 1
    
    # 创建启动脚本
    local start_script="$INSTALL_DIR/start.sh"
    cat > "$start_script" << EOF
#!/bin/bash
cd "$INSTALL_DIR/src"
python main.py --listen 0.0.0.0 --port 8188
EOF
    chmod +x "$start_script" || return 1
    
    log_info "安装后处理完成"
    return 0
}

# 验证安装
verify_install() {
    log_info "验证ComfyUI安装..."
    
    # 检查必要文件是否存在
    local required_files=(
        "$INSTALL_DIR/src/main.py"
        "$INSTALL_DIR/config/config.yaml"
        "$INSTALL_DIR/start.sh"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            log_error "缺少必要文件: $file"
            return 1
        fi
    done
    
    log_info "安装验证完成"
    return 0
}

# 清理函数
cleanup() {
    log_info "执行清理..."
    
    if has_errors; then
        log_warn "安装过程中出现错误，正在清理..."
        # 清理逻辑
    fi
    
    log_info "清理完成"
}

# 主安装流程
main() {
    log_info "开始安装 $APP_NAME"
    
    # 执行安装步骤
    pre_install_check || return 1
    install_dependencies || return 1
    setup_environment || return 1
    install_main || return 1
    configure_app || return 1
    post_install || return 1
    verify_install || return 1
    
    log_info "$APP_NAME 安装成功完成"
    
    # 显示使用说明
    cat << EOF

ComfyUI 安装完成！

启动方法：
1. 进入安装目录：cd $INSTALL_DIR
2. 运行启动脚本：./start.sh

ComfyUI将在以下地址运行：http://localhost:8188

目录结构：
- models/: 模型文件目录
- outputs/: 输出文件目录
- custom_nodes/: 自定义节点目录
- config/: 配置文件目录

如需帮助，请访问：https://github.com/comfyanonymous/ComfyUI
EOF
    
    return 0
}

# 注册清理钩子
trap cleanup EXIT

# 启动安装
main "$@"
