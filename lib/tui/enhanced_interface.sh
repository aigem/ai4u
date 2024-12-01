#!/bin/bash

# 使用 dialog 或 whiptail 实现更现代的界面
create_main_window() {
    whiptail --title "AI Tools 管理系统" \
             --menu "请选择操作" 20 60 10 \
             "1" "安装新应用" \
             "2" "管理已安装应用" \
             "3" "系统设置" \
             "4" "查看日志" \
             "0" "退出" 3>&1 1>&2 2>&3
}

# 添加应用浏览器
show_app_browser() {
    local apps=()
    # 动态加载应用列表
    while IFS= read -r app; do
        local status=$(get_app_status "$app")
        apps+=("$app" "$status")
    done < <(list_available_apps)

    whiptail --title "应用浏览器" \
             --menu "选择应用" 20 70 10 \
             "${apps[@]}" 3>&1 1>&2 2>&3
}

# 添加进度显示
show_enhanced_progress() {
    {
        for i in {1..100}; do
            echo $i
            process_step $i
            sleep 0.1
        done
    } | whiptail --gauge "正在安装..." 6 60 0
} 