#!/bin/bash

# 模板处理工具

# 引入必要的库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$ROOT_DIR/lib/logger.sh"

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
    cp "$template_file" "$temp_file"
    
    # 替换变量
    for var in "${vars[@]}"; do
        local key="${var%%=*}"
        local value="${var#*=}"
        sed -i "s|{{${key}}}|${value}|g" "$temp_file"
    done
    
    # 检查是否还有未替换的变量
    if grep -q '{{.*}}' "$temp_file"; then
        log_warn "存在未替换的变量:"
        grep -n '{{.*}}' "$temp_file"
    fi
    
    # 移动到目标位置
    mv "$temp_file" "$output_file"
    return 0
}

# 生成应用骨架
generate_app_skeleton() {
    local app_name="$1"
    local target_dir="$2"
    local template_dir="$ROOT_DIR/templates/app_template"
    
    # 检查模板目录
    if [ ! -d "$template_dir" ]; then
        log_error "模板目录不存在: $template_dir"
        return 1
    fi
    
    # 创建应用目录结构
    mkdir -p "$target_dir"/{config,src,data,logs}
    
    # 复制并处理模板文件
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local vars=(
        "APP_NAME=$app_name"
        "TIMESTAMP=$timestamp"
        "VERSION=1.0.0"
        "AUTHOR=$USER"
    )
    
    # 处理安装脚本
    replace_template_vars "$template_dir/install.sh" "$target_dir/install.sh" "${vars[@]}" || return 1
    chmod +x "$target_dir/install.sh"
    
    # 处理配置文件
    replace_template_vars "$ROOT_DIR/templates/config_template.sh" "$target_dir/config/config.sh" "${vars[@]}" || return 1
    chmod +x "$target_dir/config/config.sh"
    
    # 创建说明文件
    cat > "$target_dir/README.md" << EOF
# $app_name

## 说明
这是一个由 AI Tools 安装管理系统生成的应用骨架。

## 目录结构
- config/: 配置文件目录
- src/: 源代码目录
- data/: 数据目录
- logs/: 日志目录

## 安装
\`\`\`bash
./install.sh
\`\`\`

## 配置
编辑 \`config/config.sh\` 文件进行配置。

## 作者
$USER

## 创建时间
$timestamp
EOF
    
    # 创建版本文件
    echo "1.0.0" > "$target_dir/VERSION"
    
    # 创建更新日志
    cat > "$target_dir/CHANGELOG.md" << EOF
# 更新日志

## [1.0.0] - $timestamp
### 新增
- 初始版本
EOF
    
    log_info "应用骨架生成完成: $target_dir"
    return 0
}

# 验证模板
validate_template() {
    local template_file="$1"
    
    # 检查文件是否存在
    if [ ! -f "$template_file" ]; then
        log_error "模板文件不存在: $template_file"
        return 1
    fi
    
    # 检查语法
    if [[ "$template_file" == *.sh ]]; then
        bash -n "$template_file" || {
            log_error "模板文件语法错误: $template_file"
            return 1
        }
    fi
    
    # 检查变量格式
    local invalid_vars=$(grep -oP '{{[^}]*}}' "$template_file" | grep '[^a-zA-Z0-9_]')
    if [ -n "$invalid_vars" ]; then
        log_error "模板包含无效的变量名:"
        echo "$invalid_vars"
        return 1
    fi
    
    return 0
}

# 生成配置文件
generate_config() {
    local template_file="$1"
    local output_file="$2"
    local app_name="$3"
    local config_vars=("${@:4}")
    
    # 验证模板
    validate_template "$template_file" || return 1
    
    # 添加基本变量
    local vars=(
        "APP_NAME=$app_name"
        "TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')"
        "VERSION=1.0.0"
        "${config_vars[@]}"
    )
    
    # 替换变量
    replace_template_vars "$template_file" "$output_file" "${vars[@]}" || return 1
    
    log_info "配置文件生成完成: $output_file"
    return 0
}
