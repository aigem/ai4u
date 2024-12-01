#!/bin/bash

# 显示主菜单
show_menu() {
    echo "AI工具安装系统"
    echo "1. 安装应用"
    echo "2. 卸载应用"
    echo "3. 更新应用"
    echo "4. 显示状态"
    echo "5. 创建新应用"
    echo "0. 退出"
    
    read -p "请选择操作: " choice
    return "$choice"
}

# 显示进度条
show_progress() {
    local current="$1"
    local total="$2"
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    
    printf "\r["
    printf "%${completed}s" | tr ' ' '#'
    printf "%$((width - completed))s" | tr ' ' '-'
    printf "] %d%%" "$percentage"
}

# 显示长时间运行操作的旋转指示器
show_spinner() {
    local pid="$1"
    local delay=0.1
    local spinstr='|/-\'
    
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf "\r[%c] " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    printf "\r"
}