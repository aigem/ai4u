#!/bin/bash

create_app_wizard() {
    # 第1步：基本信息
    local app_name=$(whiptail --inputbox "应用名称" 8 60 3>&1 1>&2 2>&3)
    
    # 第2步：选择类型
    local app_type=$(whiptail --title "选择应用类型" \
        --radiolist "选择一个类型" 15 60 4 \
        "web" "Web应用" ON \
        "cli" "命令行工具" OFF \
        "service" "后台服务" OFF \
        "other" "其他类型" OFF 3>&1 1>&2 2>&3)
    
    # 第3步：配置选项
    local options=$(whiptail --separate-output --checklist \
        "选择配置选项" 15 60 3 \
        "docker" "使用Docker" OFF \
        "gpu" "需要GPU" OFF \
        "network" "需要网络" ON 3>&1 1>&2 2>&3)
} 