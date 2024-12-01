#!/bin/bash

# 交互式创建新应用
create_app_interactive() {
    log_info "启动应用创建向导..."
    source ./lib/tui/wizard.sh
    show_creation_wizard
}

# 使用指定参数创建新应用
create_app() {
    local name="$1"
    local type="$2"

    if [ -z "$name" ] || [ -z "$type" ]; then
        log_error "应用名称和类型是必需的"
        return 1
    fi

    # 验证应用类型
    case "$type" in
        text_generation|image_generation|speech_recognition|translation|other)
            ;;
        *)
            log_error "无效的应用类型：$type"
            return 1
            ;;
    esac

    # 创建应用目录
    local app_dir="$APPS_DIR/$name"
    if [ -d "$app_dir" ]; then
        log_error "应用已存在：$name"
        return 1
    fi

    mkdir -p "$app_dir"

    # 复制并更新配置
    cp "$TEMPLATES_DIR/app_configs/base.yaml" "$app_dir/config.yaml"
    update_yaml "$app_dir/config.yaml" "name" "$name"
    update_yaml "$app_dir/config.yaml" "type" "$type"
    update_yaml "$app_dir/config.yaml" "version" "1.0.0"

    # 创建其他必需文件
    touch "$app_dir/status.sh"
    chmod +x "$app_dir/status.sh"

    log_success "应用创建成功：$name"
    return 0
}