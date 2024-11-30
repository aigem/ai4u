#!/bin/bash

# {{APP_NAME}} 安装脚本
# 版本: {{APP_VERSION}}
# 创建时间: {{TIMESTAMP}}

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 引入配置文件
source "$SCRIPT_DIR/config/config.sh" || {
    echo "错误: 无法加载配置文件"
    exit 1
}

# 创建必要的目录
create_directories() {
    mkdir -p \
        "$INSTALL_DIR" \
        "$DATA_DIR" \
        "$CACHE_DIR" \
        "$LOG_DIR" || return 1
    
    return 0
}

# 安装系统依赖
install_dependencies() {
    for dep in "${DEPENDENCIES[@]}"; do
        echo "安装系统依赖: $dep"
        if command -v apt-get >/dev/null; then
            apt-get install -y "$dep" || return 1
        elif command -v yum >/dev/null; then
            yum install -y "$dep" || return 1
        else
            echo "错误: 不支持的包管理器"
            return 1
        fi
    done
    
    return 0
}

# 安装Python包
install_python_packages() {
    for pkg in "${PYTHON_PACKAGES[@]}"; do
        echo "安装Python包: $pkg"
        python3 -m pip install "$pkg" || return 1
    done
    
    return 0
}

# 配置应用
configure_app() {
    # 在这里添加应用特定的配置逻辑
    return 0
}

# 主安装流程
main() {
    echo "开始安装 $APP_NAME v$APP_VERSION..."
    
    create_directories || {
        echo "错误: 创建目录失败"
        return 1
    }
    
    install_dependencies || {
        echo "错误: 安装系统依赖失败"
        return 1
    }
    
    install_python_packages || {
        echo "错误: 安装Python包失败"
        return 1
    }
    
    configure_app || {
        echo "错误: 配置应用失败"
        return 1
    }
    
    echo "$APP_NAME 安装完成"
    return 0
}

# 执行安装
main "$@"
