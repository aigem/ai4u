#!/bin/bash

# 执行安装步骤
execute_steps() {
    local step_type="$1"
    local app_name="$2"
    local app_dir="$APPS_DIR/$app_name"
    local config_file="$app_dir/config.yaml"

    log_info "正在执行 $app_name 的 $step_type 步骤..."

    # 从配置中获取步骤
    local steps=($(yaml_get_array "$config_file" "steps.$step_type"))
    local total_steps=${#steps[@]}
    local current_step=0

    for step in "${steps[@]}"; do
        current_step=$((current_step + 1))
        show_progress $current_step $total_steps

        log_info "执行步骤：$step"
        if ! execute_single_step "$step" "$app_dir"; then
            log_error "步骤失败：$step"
            return 1
        fi
    done

    return 0
}

# 执行单个安装步骤
execute_single_step() {
    local step="$1"
    local app_dir="$2"
    local step_script="$app_dir/steps/$step.sh"

    if [ ! -f "$step_script" ]; then
        log_error "未找到步骤脚本：$step"
        return 1
    fi

    # 执行步骤并处理错误
    if ! bash "$step_script"; then
        log_error "步骤执行失败：$step"
        return 1
    fi

    return 0
}