#!/bin/bash

# 清理屏幕
clear_screen() {
    if [ "$OS_TYPE" = "windows" ]; then
        cmd.exe /c cls 2>/dev/null || clear
    else
        clear
    fi
}

# 显示主菜单
show_menu() {
    clear_screen
    echo "================================"
    echo "      AI工具安装系统"
    echo "================================"
    echo
    echo "  1. 安装应用"
    echo "  2. 卸载应用"
    echo "  3. 更新应用"
    echo "  4. 显示状态"
    echo "  5. 创建新应用"
    echo "  0. 退出"
    echo
    echo "================================"
    
    read -p "请选择操作 [0-5]: " choice
    case "$choice" in
        [0-5]) return "$choice" ;;
        *)
            echo "无效选择，请重试"
            sleep 1
            return 255
            ;;
    esac
}

# 显示进度条
show_progress() {
    local current="$1"
    local total="$2"
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    
    # Windows 控制台特殊处理
    if [ "$OS_TYPE" = "windows" ]; then
        printf "\r%-${width}s\r" "" # 清除当前行
    fi
    
    printf "\r["
    printf "%${completed}s" | tr ' ' '#'
    printf "%$((width - completed))s" | tr ' ' '-'
    printf "] %3d%%" "$percentage"
    
    # 如果完成，换行
    if [ "$current" -eq "$total" ]; then
        echo
    fi
}

# 显示长时间运行操作的旋转指示器
show_spinner() {
    local pid="$1"
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    # Windows 下使用简单的字符
    if [ "$OS_TYPE" = "windows" ]; then
        spinstr='|/-\'
    fi
    
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf "\r[%c] " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    printf "\r    \r" # 清除spinner
}