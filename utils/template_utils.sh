#!/bin/bash

# 模板处理工具

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 引入必要的库
source "$ROOT_DIR/lib/logger.sh" || {
    echo "错误: 无法加载 logger.sh"
    exit 1
}

# 模板目录
TEMPLATE_DIR="$ROOT_DIR/templates"
APP_TEMPLATE_DIR="$TEMPLATE_DIR/app_template"

# 模板变量替换
replace_template_vars() {
    local template_file="$1"
    local output_file="$2"
    shift 2
    local vars=("$@")
    
    if [ ! -f "$template_file" ]; then
        log_error "模板文件不存在: $template_file"
        return 1
    fi
    
    # 创建临时文件
    local temp_file=$(mktemp)
    cp "$template_file" "$temp_file" || {
        log_error "复制模板文件失败"
        rm -f "$temp_file"
        return 1
    }
    
    # 替换变量
    for var in "${vars[@]}"; do
        local key="${var%%=*}"
        local value="${var#*=}"
        sed -i "s|{{${key}}}|${value}|g" "$temp_file" || {
            log_error "替换变量失败: $key"
            rm -f "$temp_file"
            return 1
        }
    done
    
    # 检查是否还有未替换的变量
    if grep -q '{{.*}}' "$temp_file"; then
        log_warn "存在未替换的变量:"
        grep -n '{{.*}}' "$temp_file"
    fi
    
    # 移动到目标位置
    mv "$temp_file" "$output_file" || {
        log_error "移动文件失败: $output_file"
        rm -f "$temp_file"
        return 1
    }
    
    return 0
}

# 创建应用结构
create_app_structure() {
    local app_name="$1"
    local app_dir="$2"
    
    log_info "创建应用目录结构..."
    
    # 检查应用模板目录
    if [ ! -d "$APP_TEMPLATE_DIR" ]; then
        log_error "应用模板目录不存在: $APP_TEMPLATE_DIR"
        return 1
    fi
    
    # 创建应用目录（如果不存在）
    if [ ! -d "$app_dir" ]; then
        mkdir -p "$app_dir" || {
            log_error "创建应用目录失败: $app_dir"
            return 1
        }
    fi
    
    # 复制模板文件
    cp -r "$APP_TEMPLATE_DIR"/* "$app_dir/" || {
        log_error "复制模板文件失败"
        return 1
    }
    
    # 创建setup目录（如果不存在）
    local setup_dir="$ROOT_DIR/setup"
    mkdir -p "$setup_dir" || {
        log_error "创建setup目录失败: $setup_dir"
        return 1
    }
    
    # 生成入口脚本
    local setup_template="$TEMPLATE_DIR/setup_template.sh"
    local setup_script="$setup_dir/${app_name}_setup.sh"
    
    local vars=(
        "APP_NAME=$app_name"
        "APP_VERSION=1.0.0"
        "TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')"
    )
    
    replace_template_vars "$setup_template" "$setup_script" "${vars[@]}" || {
        log_error "生成入口脚本失败"
        return 1
    }
    
    # 设置执行权限
    chmod +x "$setup_script" || {
        log_error "设置入口脚本执行权限失败"
        return 1
    }
    
    # 生成配置文件
    local config_template="$TEMPLATE_DIR/config_template.sh"
    local config_file="$app_dir/config.sh"
    
    replace_template_vars "$config_template" "$config_file" "${vars[@]}" || {
        log_error "生成配置文件失败"
        return 1
    }
    
    log_info "应用目录结构创建成功"
    return 0
}

# 验证模板
validate_template() {
    local template_file="$1"
    
    if [ ! -f "$template_file" ]; then
        log_error "模板文件不存在: $template_file"
        return 1
    fi
    
    # 检查语法错误
    bash -n "$template_file" || {
        log_error "模板文件语法错误: $template_file"
        return 1
    }
    
    # 检查必需的变量
    local required_vars=("APP_NAME" "APP_VERSION" "TIMESTAMP")
    for var in "${required_vars[@]}"; do
        if ! grep -q "{{$var}}" "$template_file"; then
            log_error "模板缺少必需变量: $var"
            return 1
        fi
    done
    
    return 0
}

# 生成配置文件
generate_config() {
    local app_name="$1"
    local app_dir="$2"
    local config_file="$app_dir/config.sh"
    
    log_info "生成配置文件: $config_file"
    
    cat > "$config_file" << EOF
#!/bin/bash

# $app_name 配置文件
# 创建时间: $(date '+%Y-%m-%d %H:%M:%S')

# 应用信息
APP_NAME="$app_name"
APP_VERSION="1.0.0"

# 安装配置
INSTALL_DIR="\$HOME/.local/share/aitools/$app_name"
DATA_DIR="\$HOME/.local/share/aitools/$app_name/data"
CACHE_DIR="\$HOME/.cache/aitools/$app_name"
LOG_DIR="\$HOME/.local/share/aitools/$app_name/logs"

# 依赖配置
DEPENDENCIES=(
    "python3"
    "pip3"
    "git"
)

# Python包依赖
PYTHON_PACKAGES=(
    "requests"
    "pyyaml"
)
EOF
    
    chmod +x "$config_file"
    return 0
}
