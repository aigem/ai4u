#!/bin/bash

# UI 组件库 - 使用 whiptail 实现现代化的 TUI 界面

# 检查是否安装了 whiptail
check_whiptail() {
    if ! command -v whiptail &> /dev/null; then
        echo "Error: whiptail is not installed. Please install it first."
        return 1
    fi
}

# 获取终端尺寸
get_terminal_size() {
    local height width
    height=$(tput lines)
    width=$(tput cols)
    echo "$height $width"
}

# 显示消息框
show_message() {
    local title="$1"
    local message="$2"
    local height width
    read height width <<< $(get_terminal_size)
    whiptail --title "$title" --msgbox "$message" $((height/3)) $((width/2))
}

# 显示是/否对话框
show_yesno() {
    local title="$1"
    local message="$2"
    local height width
    read height width <<< $(get_terminal_size)
    whiptail --title "$title" --yesno "$message" $((height/3)) $((width/2))
}

# 显示输入框
show_input() {
    local title="$1"
    local message="$2"
    local default="$3"
    local height width
    read height width <<< $(get_terminal_size)
    whiptail --title "$title" --inputbox "$message" $((height/3)) $((width/2)) "$default" 3>&1 1>&2 2>&3
}

# 显示密码输入框
show_password() {
    local title="$1"
    local message="$2"
    local height width
    read height width <<< $(get_terminal_size)
    whiptail --title "$title" --passwordbox "$message" $((height/3)) $((width/2)) 3>&1 1>&2 2>&3
}

# 显示进度条
show_progress() {
    local title="$1"
    local message="$2"
    local percent="$3"
    local height width
    read height width <<< $(get_terminal_size)
    echo "$percent" | whiptail --title "$title" --gauge "$message" $((height/3)) $((width/2)) 0
}

# 显示选择菜单
show_menu() {
    local title="$1"
    local message="$2"
    shift 2
    local options=("$@")
    local height width
    read height width <<< $(get_terminal_size)
    whiptail --title "$title" --menu "$message" $((height/2)) $((width/2)) $((height/3)) "${options[@]}" 3>&1 1>&2 2>&3
}

# 显示多选框
show_checklist() {
    local title="$1"
    local message="$2"
    shift 2
    local options=("$@")
    local height width
    read height width <<< $(get_terminal_size)
    whiptail --title "$title" --checklist "$message" $((height/2)) $((width/2)) $((height/3)) "${options[@]}" 3>&1 1>&2 2>&3
}

# 显示单选框
show_radiolist() {
    local title="$1"
    local message="$2"
    shift 2
    local options=("$@")
    local height width
    read height width <<< $(get_terminal_size)
    whiptail --title "$title" --radiolist "$message" $((height/2)) $((width/2)) $((height/3)) "${options[@]}" 3>&1 1>&2 2>&3
}

# 显示文本信息框
show_textbox() {
    local title="$1"
    local file="$2"
    local height width
    read height width <<< $(get_terminal_size)
    whiptail --title "$title" --textbox "$file" $((height*2/3)) $((width*2/3))
}

# 显示实时日志窗口
show_tail_log() {
    local title="$1"
    local log_file="$2"
    local height width
    read height width <<< $(get_terminal_size)
    tail -f "$log_file" | whiptail --title "$title" --scrolltext --textbox /dev/stdin $((height*2/3)) $((width*2/3))
}
