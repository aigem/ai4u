#!/bin/bash

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
ROOT_DIR="$(dirname "$(dirname "$APP_DIR")")"

# 加载工具函数
source "$ROOT_DIR/lib/utils/logger.sh"

# 开始安装
log_info "开始安装应用..."

#

# 安装依赖
log_info "安装依赖..."
pip install -r "$APP_DIR/requirements.txt"

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
