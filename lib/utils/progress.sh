#!/bin/bash

# 显示带有消息的进度条
show_progress() {
    local current="$1"
    local total="$2"
    local message="${3:-}"
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    
    printf "\r["
    printf "%${completed}s" | tr ' ' '#'
    printf "%$((width - completed))s" | tr ' ' '-'
    printf "] %3d%%" "$percentage"
    
    if [ -n "$message" ]; then
        printf " - %s" "$message"
    fi
    
    if [ "$current" -eq "$total" ]; then
        printf "\n"
    fi
}

# 显示带有消息的旋转指示器
show_spinner() {
    local pid="$1"
    local message="${2:-}"
    local delay=0.1
    local spinstr='|/-\'
    
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf "\r[%c] " "$spinstr"
        if [ -n "$message" ]; then
            printf "%s" "$message"
        fi
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    printf "\r"
}