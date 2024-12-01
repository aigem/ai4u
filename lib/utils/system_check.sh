#!/bin/bash

# 检查系统要求
check_system_requirements() {
    log_info "正在检查系统要求..."

    # 检查操作系统
    if [ ! -f /etc/os-release ]; then
        log_error "无法确定操作系统类型"
        return 1
    fi

    source /etc/os-release
    if [ "$ID" != "ubuntu" ] || [ "${VERSION_ID%%.*}" -lt "20" ]; then
        log_error "此脚本需要 Ubuntu 20.04 或更高版本"
        return 1
    fi

    # 检查可用磁盘空间
    local required_space=1024  # 1GB（单位：MB）
    local available_space=$(df -m /home | awk 'NR==2 {print $4}')
    
    if [ "$available_space" -lt "$required_space" ]; then
        log_error "磁盘空间不足。需要：${required_space}MB，可用：${available_space}MB"
        return 1
    fi

    # 检查内存
    local required_memory=512  # 512MB（单位：MB）
    local available_memory=$(free -m | awk '/Mem:/ {print $2}')
    
    if [ "$available_memory" -lt "$required_memory" ]; then
        log_error "内存不足。需要：${required_memory}MB，可用：${available_memory}MB"
        return 1
    fi

    log_success "系统要求检查通过"
    return 0
}