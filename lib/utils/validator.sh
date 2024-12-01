#!/bin/bash

# 验证应用配置
validate_app_config() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        log_error "未找到配置文件：$config_file"
        return 1
    fi

    # 加载验证规则
    local validator_file="$TEMPLATES_DIR/validators/base.yaml"
    if [ ! -f "$validator_file" ]; then
        log_error "未找到验证规则文件"
        return 1
    fi

    # 验证必需字段
    local required_fields=(name type version cmd)
    for field in "${required_fields[@]}"; do
        if ! yaml_has_field "$config_file" "$field"; then
            log_error "缺少必需字段：$field"
            return 1
        fi
    done

    return 0
}

# 验证环境变量
validate_env_vars() {
    local config_file="$1"
    local required_vars=($(yaml_get_array "$config_file" "env_rules.required"))
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            log_error "缺少必需的环境变量：$var"
            return 1
        fi
    done

    return 0
}