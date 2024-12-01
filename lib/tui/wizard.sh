#!/bin/bash

# 交互式应用创建向导
show_creation_wizard() {
    clear
    echo "=== AI应用创建向导 ==="
    echo

    # 步骤1：基本信息
    echo "步骤1：基本信息"
    echo "---------------"
    
    # 应用名称验证
    while true; do
        read -p "应用名称（字母、数字、下划线、连字符）: " name
        if [[ $name =~ ^[a-zA-Z0-9_-]+$ ]]; then
            break
        else
            echo "名称格式无效，请重试。"
        fi
    done

    # 应用类型选择及说明
    echo -e "\n可用的应用类型："
    echo "1. text_generation  - 自然语言处理和文本生成"
    echo "2. image_generation - AI驱动的图像创建和处理"
    echo "3. speech_recognition - 语音转文字和音频处理"
    echo "4. translation - 语言翻译和处理"
    echo "5. other - 自定义AI应用类型"
    
    while true; do
        read -p "选择类型 (1-5): " type_choice
        case $type_choice in
            1) type="text_generation"; break;;
            2) type="image_generation"; break;;
            3) type="speech_recognition"; break;;
            4) type="translation"; break;;
            5) type="other"; break;;
            *) echo "选择无效，请选择1-5。";;
        esac
    done

    # 步骤2：依赖项
    echo -e "\n步骤2：依赖项"
    echo "-------------"
    read -p "您的应用是否需要特定的系统包？(y/n): " has_deps
    if [[ $has_deps =~ ^[Yy]$ ]]; then
        read -p "输入包名（用空格分隔）: " -a deps
    fi

    # 步骤3：环境设置
    echo -e "\n步骤3：环境设置"
    echo "-------------"
    read -p "是否需要配置环境变量？(y/n): " has_env
    if [[ $has_env =~ ^[Yy]$ ]]; then
        echo "输入环境变量（格式：KEY=VALUE，每行一个，输入空行结束）："
        while IFS= read -r line; do
            [[ -z "$line" ]] && break
            env_vars+=("$line")
        done
    fi

    # 创建应用
    create_app_from_wizard "$name" "$type" "${deps[@]}" "${env_vars[@]}"
    
    # 显示下一步操作
    show_next_steps "$name"
}

# 从向导输入创建应用
create_app_from_wizard() {
    local name="$1"
    local type="$2"
    shift 2
    local deps=("${@}")

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

    # 如果有依赖项，添加到配置
    if [ ${#deps[@]} -gt 0 ]; then
        for dep in "${deps[@]}"; do
            update_yaml "$app_dir/config.yaml" "dependencies[]" "$dep"
        done
    fi

    # 如果有环境变量，添加到配置
    if [ ${#env_vars[@]} -gt 0 ]; then
        for env in "${env_vars[@]}"; do
            update_yaml "$app_dir/config.yaml" "environment[]" "$env"
        done
    fi

    # 创建其他必需文件
    touch "$app_dir/status.sh"
    chmod +x "$app_dir/status.sh"

    log_success "应用创建成功：$name"
    return 0
}

# 显示创建后的下一步操作
show_next_steps() {
    local name="$1"
    echo -e "\n恭喜！应用 $name 已创建成功。"
    echo "下一步操作："
    echo "1. 运行 ./aitools.sh install $name 安装应用"
    echo "2. 运行 ./aitools.sh status $name 检查应用状态"
    echo "3. 编辑 apps/$name/config.yaml 修改配置"
}