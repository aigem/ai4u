#!/bin/bash

# UI 组件库

# 设置字符编码
setup_locale() {
    if ! locale -a | grep -i "zh_CN.utf8" > /dev/null; then
        if command -v apt-get >/dev/null 2>&1; then
            DEBIAN_FRONTEND=noninteractive apt-get update
            DEBIAN_FRONTEND=noninteractive apt-get install -y locales
            echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen
            locale-gen
        elif command -v yum >/dev/null 2>&1; then
            yum install -y langpacks-zh_CN glibc-common
            localedef -c -f UTF-8 -i zh_CN zh_CN.UTF-8
        fi
    fi
    
    export LANG=zh_CN.UTF-8
    export LC_ALL=zh_CN.UTF-8
    export LANGUAGE=zh_CN.UTF-8
}

# 检查是否有 whiptail，如果没有尝试安装
check_whiptail() {
    if ! command -v whiptail >/dev/null 2>&1; then
        echo "正在安装 whiptail..."
        if command -v apt-get >/dev/null 2>&1; then
            DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y whiptail
        elif command -v yum >/dev/null 2>&1; then
            yum install -y newt
        else
            echo "无法安装 whiptail，将使用基础命令行界面"
            return 1
        fi
    fi
    return 0
}

# 初始化 UI 环境
setup_ui_env() {
    setup_locale
    check_whiptail
}

# 在脚本开始时调用初始化函数
setup_ui_env

# UI 后备方案
show_message_fallback() {
    local title="$1"
    local message="$2"
    echo "=== $title ==="
    echo "$message"
    echo "=============="
}

show_menu_fallback() {
    local title="$1"
    shift
    local options=("$@")
    
    echo "=== $title ==="
    local i=1
    for opt in "${options[@]}"; do
        echo "$i) $opt"
        ((i++))
    done
    echo "=============="
    
    read -p "请选择 (1-$((i-1))): " choice
    return "$choice"
}

# UI 函数
show_message() {
    local title="$1"
    local message="$2"
    
    if check_whiptail; then
        whiptail --title "$title" --msgbox "$message" 10 60
    else
        show_message_fallback "$title" "$message"
    fi
}

show_menu() {
    local title="$1"
    local message="$2"
    shift 2
    local options=("$@")
    
    if check_whiptail; then
        whiptail --title "$title" --menu "$message" 20 70 10 "${options[@]}" 3>&1 1>&2 2>&3
    else
        echo "=== $title ==="
        echo "$message"
        echo "=============="
        local i=1
        for ((i=0; i<${#options[@]}; i+=2)); do
            echo "$((i/2+1)). ${options[i]} - ${options[i+1]}"
        done
        read -p "请选择 (1-$((${#options[@]}/2))): " choice
        if [ -n "$choice" ] && [ "$choice" -ge 1 ] && [ "$choice" -le $((${#options[@]}/2)) ]; then
            echo "${options[$(((choice-1)*2))]}"
        fi
    fi
}

show_yesno() {
    local title="$1"
    local message="$2"
    
    if check_whiptail; then
        whiptail --title "$title" --yesno "$message" 10 60
    else
        read -p "$message (y/n): " choice
        case $choice in
            y|Y) return 0 ;;
            n|N) return 1 ;;
            *) return 1 ;;
        esac
    fi
}

show_input() {
    local title="$1"
    local message="$2"
    local default="$3"
    
    if check_whiptail; then
        whiptail --title "$title" --inputbox "$message" 10 60 "$default" 3>&1 1>&2 2>&3
    else
        read -p "$message: " input
        echo "$input"
    fi
}

show_password() {
    local title="$1"
    local message="$2"
    
    if check_whiptail; then
        whiptail --title "$title" --passwordbox "$message" 10 60 3>&1 1>&2 2>&3
    else
        read -s -p "$message: " password
        echo "$password"
    fi
}

show_progress() {
    local title="$1"
    local message="$2"
    local percent="$3"
    
    if check_whiptail; then
        echo "$percent" | whiptail --title "$title" --gauge "$message" 10 60 0
    else
        echo "$message ($percent%)"
    fi
}

show_checklist() {
    local title="$1"
    local message="$2"
    shift 2
    local options=("$@")
    
    if check_whiptail; then
        whiptail --title "$title" --checklist "$message" 20 60 10 "${options[@]}" 3>&1 1>&2 2>&3
    else
        local i=1
        for opt in "${options[@]}"; do
            echo "$i) $opt"
            ((i++))
        done
        read -p "请选择 (空格分隔): " choices
        for choice in $choices; do
            echo "${options[$choice-1]}"
        done
    fi
}

show_radiolist() {
    local title="$1"
    local message="$2"
    shift 2
    local options=("$@")
    
    if check_whiptail; then
        whiptail --title "$title" --radiolist "$message" 20 60 10 "${options[@]}" 3>&1 1>&2 2>&3
    else
        local i=1
        for opt in "${options[@]}"; do
            echo "$i) $opt"
            ((i++))
        done
        read -p "请选择 (1-$((i-1))): " choice
        echo "${options[$choice-1]}"
    fi
}

show_textbox() {
    local title="$1"
    local file="$2"
    
    if check_whiptail; then
        whiptail --title "$title" --textbox "$file" 20 60
    else
        cat "$file"
    fi
}

show_tail_log() {
    local title="$1"
    local log_file="$2"
    
    if check_whiptail; then
        tail -f "$log_file" | whiptail --title "$title" --scrolltext --textbox /dev/stdin 20 60
    else
        tail -f "$log_file"
    fi
}
