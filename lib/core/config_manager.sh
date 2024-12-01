#!/bin/bash

# 管理应用配置
manage_config() {
    local app_name="$1"
    local action="$2"
    local config_file="$APPS_DIR/$app_name/config.yaml"

    case $action in
        validate)
            validate_config "$config_file"
            ;;
        update)
            update_config "$config_file" "$3" "$4"
            ;;
        backup)
            backup_config "$config_file"
            ;;
        restore)
            restore_config "$config_file"
            ;;
    esac
}

# 验证配置
validate_config() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        handle_error $E_CONFIG_ERROR "未找到配置文件"
        return 1
    fi

    # 验证必需字段
    local required_fields=(name type version cmd)
    for field in "${required_fields[@]}"; do
        if ! yaml_has_field "$config_file" "$field"; then
            handle_error $E_CONFIG_ERROR "缺少必需字段：$field"
            return 1
        fi
    done

    return 0
}

# 更新配置
update_config() {
    local config_file="$1"
    local key="$2"
    local value="$3"

    # 更新前备份
    backup_config "$config_file"

    # 更新配置
    if ! update_yaml "$config_file" "$key" "$value"; then
        restore_config "$config_file"
        handle_error $E_CONFIG_ERROR "更新配置失败"
        return 1
    fi

    return 0
}

# 备份配置
backup_config() {
    local config_file="$1"
    cp "$config_file" "${config_file}.backup"
}

# 从备份恢复配置
restore_config() {
    local config_file="$1"
    if [ -f "${config_file}.backup" ]; then
        mv "${config_file}.backup" "$config_file"
    fi
}