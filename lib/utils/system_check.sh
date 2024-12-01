#!/bin/bash

# 检查系统要求
check_system_requirements() {
    # 检查操作系统
    if ! check_os_compatibility; then
        return 1
    fi

    # 检查Python环境
    if ! check_python_environment; then
        return 1
    fi

    # 检查系统命令
    if ! check_system_commands; then
        return 1
    fi

    # 检查系统资源
    if ! check_system_resources; then
        return 1
    fi

    # 检查UI依赖
    if ! check_ui_dependencies; then
        return 1
    fi

    return 0
}

# 检查操作系统兼容性
check_os_compatibility() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" != "ubuntu" ]] || [[ "${VERSION_ID%%.*}" -lt 20 ]]; then
            log_error "不支持的操作系统。需要 Ubuntu 20.04 或更高版本"
            return 1
        fi
    else
        log_error "无法确定操作系统版本"
        return 1
    fi
    return 0
}

# 检查Python环境
check_python_environment() {
    # 检查Python3
    if ! command -v python3 &> /dev/null; then
        log_error "未找到Python3，请先安装"
        return 1
    fi

    # 检查Python版本
    local python_version=$(python3 -c 'import sys; print(sys.version_info[0:2])')
    if [[ $python_version < "(3, 8)" ]]; then
        log_error "Python版本过低，需要3.8或更高版本"
        return 1
    fi

    # 检查pip3
    if ! command -v pip3 &> /dev/null; then
        log_error "未找到pip3，请先安装"
        return 1
    fi

    # 检查必需的Python包
    local required_packages=("pyyaml>=5.1")
    for package in "${required_packages[@]}"; do
        if ! pip3 list | grep -i "${package%%>=*}" &> /dev/null; then
            log_error "缺少Python包：$package"
            log_info "请运行：pip3 install $package"
            return 1
        fi
    done

    return 0
}

# 检查系统命令
check_system_commands() {
    local required_commands=(
        "curl"
        "wget"
        "git"
        "tar"
        "gzip"
        "awk"
        "sed"
    )

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "缺少必需的命令：$cmd"
            log_info "请运行：sudo apt-get install $cmd"
            return 1
        fi
    done

    return 0
}

# 检查系统资源
check_system_resources() {
    # 检查磁盘空间
    local required_space=1024  # MB
    local available_space=$(df -m "$ROOT_DIR" | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt "$required_space" ]; then
        log_error "磁盘空间不足。需要: ${required_space}MB, 可用: ${available_space}MB"
        return 1
    fi

    # 检查内存
    local required_memory=512  # MB
    local available_memory=$(free -m | awk 'NR==2 {print $7}')
    if [ "$available_memory" -lt "$required_memory" ]; then
        log_error "内存不足。需要: ${required_memory}MB, 可用: ${available_memory}MB"
        return 1
    fi

    return 0
}

# 检查UI依赖
check_ui_dependencies() {
    local missing_deps=()
    
    # 检查whiptail
    if ! command -v whiptail >/dev/null 2>&1; then
        missing_deps+=("whiptail")
    fi
    
    # 检查dialog（可选依赖）
    if ! command -v dialog >/dev/null 2>&1; then
        missing_deps+=("dialog")
    fi
    
    # 如果有缺失的依赖，询问是否安装
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_info "检测到缺少UI组件: ${missing_deps[*]}"
        
        if [ "$AUTO_INSTALL_DEPS" = "true" ] || \
           whiptail --title "缺少依赖" \
                   --yesno "是否安装缺失的UI组件？\n${missing_deps[*]}" \
                   10 60; then
            
            log_info "正在安装UI组件..."
            if [ -f /etc/debian_version ]; then
                # Debian/Ubuntu系统
                sudo apt-get update
                sudo apt-get install -y "${missing_deps[@]}"
            elif [ -f /etc/redhat-release ]; then
                # RHEL/CentOS系统
                sudo yum install -y "${missing_deps[@]}"
            else
                log_error "不支持的系统类型，请手动安装: ${missing_deps[*]}"
                return 1
            fi
        else
            log_warn "用户取消安装UI组件，将使用基础命令行界面"
            export USE_BASIC_UI=true
            return 0
        fi
    fi
    
    return 0
}