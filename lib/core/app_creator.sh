#!/bin/bash

# 交互式创建新应用
create_app_interactive() {
    log_info "开始交互式创建应用..."
    
    # 获取应用名称
    while true; do
        read -p "请输入应用名称: " name
        if [[ $name =~ ^[a-zA-Z0-9_-]+$ ]]; then
            break
        else
            log_error "名称格式无效。只能使用字母、数字、下划线和连字符。"
        fi
    done

    # 选择应用类型
    echo "可用的应用类型:"
    echo "1. text_generation  (文本生成)"
    echo "2. image_generation (图像生成)"
    echo "3. speech_recognition (语音识别)"
    echo "4. translation (翻译)"
    echo "5. other (其他)"
    
    while true; do
        read -p "请选择类型 (1-5): " type_choice
        case $type_choice in
            1) type="text_generation"; break;;
            2) type="image_generation"; break;;
            3) type="speech_recognition"; break;;
            4) type="translation"; break;;
            5) type="other"; break;;
            *) log_error "选择无效。请选择 1-5。";;
        esac
    done

    # 创建应用目录
    local app_dir="$APPS_DIR/$name"
    if [ -d "$app_dir" ]; then
        log_error "应用已存在：$name"
        return 1
    fi

    mkdir -p "$app_dir"

    # 复制基础配置
    cp "$TEMPLATES_DIR/app_configs/base.yaml" "$app_dir/config.yaml"

    # 更新配置
    update_yaml "$app_dir/config.yaml" "name" "$name"
    update_yaml "$app_dir/config.yaml" "type" "$type"
    update_yaml "$app_dir/config.yaml" "version" "1.0.0"

    # 创建其他必需文件
    touch "$app_dir/status.sh"
    chmod +x "$app_dir/status.sh"

    log_success "应用创建成功：$name"
    return 0
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