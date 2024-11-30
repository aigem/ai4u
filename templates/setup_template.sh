#!/bin/bash

# {{APP_NAME}} 安装入口脚本
# 版本: {{APP_VERSION}}
# 创建时间: {{TIMESTAMP}}

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/../apps/{{APP_NAME}}"

# 引入必要的库
source "$SCRIPT_DIR/../lib/logger.sh" || {
    echo "错误: 无法加载日志模块"
    exit 1
}
source "$SCRIPT_DIR/../lib/utils.sh" || {
    log_error "无法加载工具模块"
    exit 1
}
source "$SCRIPT_DIR/../lib/error_handler.sh" || {
    log_error "无法加载错误处理模块"
    exit 1
}

# 检查应用目录是否存在
if [ ! -d "$APP_DIR" ]; then
    log_error "应用目录不存在: $APP_DIR"
    exit 1
fi

# 加载应用配置
source "$APP_DIR/config.sh" || {
    log_error "加载应用配置失败"
    exit 1
}

# 检查系统要求
check_system_requirements || {
    log_error "系统要求检查失败"
    exit 1
}

# 创建必要的目录
mkdir -p "$INSTALL_DIR" "$DATA_DIR" "$CACHE_DIR" "$LOG_DIR" || {
    log_error "创建目录失败"
    exit 1
}

# 安装系统依赖
log_info "安装系统依赖..."
for dep in "${DEPENDENCIES[@]}"; do
    install_system_package "$dep" || {
        log_error "安装系统依赖失败: $dep"
        exit 1
    }
done

# 安装Python包依赖
log_info "安装Python包依赖..."
for pkg in "${PYTHON_PACKAGES[@]}"; do
    install_python_package "$pkg" || {
        log_error "安装Python包失败: $pkg"
        exit 1
    }
done

# 运行应用安装脚本
log_info "运行应用安装脚本..."
"$APP_DIR/install.sh" || {
    log_error "应用安装失败"
    exit 1
}

log_info "{{APP_NAME}} 安装完成"
exit 0
