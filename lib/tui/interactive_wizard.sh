#!/bin/bash

create_app_wizard() {
    # 验证应用名称
    local app_name
    while true; do
        app_name=$(whiptail --inputbox "请输入应用名称\n(只允许字母、数字、下划线)" 10 60 3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && return 1
        [ -z "$app_name" ] && {
            whiptail --msgbox "应用名称不能为空" 8 40
            continue
        }
        [[ "$app_name" =~ ^[a-zA-Z0-9_]+$ ]] || {
            whiptail --msgbox "应用名称只能包含字母、数字和下划线" 8 40
            continue
        }
        [ -d "$APPS_DIR/$app_name" ] && {
            whiptail --msgbox "应用 $app_name 已存在" 8 40
            continue
        }
        break
    done
    
    # 选择应用类型
    local app_type=$(whiptail --title "选择应用类型" \
        --menu "请选择应用类型" 15 60 4 \
        "web" "Web应用" \
        "cli" "命令行工具" \
        "service" "后台服务" \
        "other" "其他类型" 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return 1
    
    # 验证版本号
    local version
    while true; do
        version=$(whiptail --inputbox "请输入版本号\n(格式: x.y.z)" 10 60 "1.0.0" 3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && return 1
        [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
            whiptail --msgbox "版本号格式不正确，请使用 x.y.z 格式" 8 40
            continue
        }
        break
    done
    
    # 输入描述
    local description=$(whiptail --inputbox "请输入应用描述" 8 60 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return 1
    
    # 确认创建
    whiptail --yesno "确认创建以下应用？\n\n名称: $app_name\n类型: $app_type\n版本: $version\n描述: $description" 12 60 || return 1
    
    # 创建应用
    if create_app "$app_name" "$app_type" "$version" "$description"; then
        whiptail --msgbox "应用 $app_name 创建成功！\n\n下一步：\n1. 编辑配置文件\n2. 运行安装命令" 12 60
        return 0
    else
        whiptail --msgbox "创建应用失败，请检查错误日志" 8 40
        return 1
    fi
} 