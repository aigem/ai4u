#!/bin/bash

# 配置文件模板生成器

generate_config() {
    local app_name="$1"
    local install_dir="$2"
    local version="$3"
    
    cat << EOF
# $app_name 配置文件
# 由安装脚本自动生成

# 基本配置
APP_NAME="$app_name"
APP_VERSION="$version"
INSTALL_DIR="$install_dir"

# 目录配置
DATA_DIR="\${INSTALL_DIR}/data"
CONFIG_DIR="\${INSTALL_DIR}/config"
LOG_DIR="\${INSTALL_DIR}/logs"
CACHE_DIR="\${INSTALL_DIR}/cache"

# 运行时配置
PORT="8080"  # 默认端口
MAX_WORKERS="4"  # 最大工作进程数
DEBUG_MODE="false"  # 调试模式

# 日志配置
LOG_LEVEL="info"  # 日志级别：debug, info, warn, error
LOG_FORMAT="[%Y-%m-%d %H:%M:%S] [%level] %message"  # 日志格式
MAX_LOG_SIZE="100M"  # 单个日志文件最大大小
MAX_LOG_FILES="10"  # 最大日志文件数

# 数据库配置
DB_TYPE="sqlite"  # 数据库类型：sqlite, mysql, postgresql
DB_HOST="localhost"
DB_PORT="3306"
DB_NAME="${app_name}_db"
DB_USER=""
DB_PASSWORD=""

# 缓存配置
CACHE_TYPE="local"  # 缓存类型：local, redis
CACHE_TTL="3600"  # 缓存过期时间（秒）

# 安全配置
SECRET_KEY=""  # 将在安装时自动生成
ALLOWED_HOSTS="localhost,127.0.0.1"
CORS_ORIGINS="*"
SSL_ENABLED="false"
SSL_CERT=""
SSL_KEY=""

# 性能配置
TIMEOUT="30"  # 请求超时时间（秒）
MAX_UPLOAD_SIZE="50M"  # 最大上传文件大小
RATE_LIMIT="100/minute"  # API速率限制

# 集成配置
ENABLE_METRICS="false"  # 是否启用指标收集
METRICS_PORT="9090"
ENABLE_TRACING="false"  # 是否启用链路追踪
JAEGER_AGENT_HOST="localhost"
JAEGER_AGENT_PORT="6831"

# 自定义配置
# 在此处添加应用特定的配置项
EOF
}

# 使用示例
# generate_config "myapp" "/opt/myapp" "1.0.0" > config.env
