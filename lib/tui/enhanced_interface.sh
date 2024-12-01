#!/bin/bash

# 使用 dialog 或 whiptail 实现更现代的界面
create_main_window() {
    whiptail --title "AI Tools 管理系统" \
             --menu "请选择操作" 20 60 10 \
             "1" "创建新应用" \
             "2" "安装应用" \
             "3" "卸载应用" \
             "4" "更新应用" \
             "5" "查看状态" \
             "6" "列出应用" \
             "0" "退出" 3>&1 1>&2 2>&3
}

# 添加应用浏览器
show_app_browser() {
    # 获取可用应用列表
    local available_apps=($(ls -1 "$TEMPLATES_DIR"))
    local apps_menu=()
    
    # 如果没有可用应用
    if [ ${#available_apps[@]} -eq 0 ]; then
        whiptail --msgbox "没有可用的应用模板" 10 40
        return 1
    }
    
    # 构建菜单项
    for app in "${available_apps[@]}"; do
        local desc=""
        if [ -f "$TEMPLATES_DIR/$app/description.txt" ]; then
            desc=$(head -n1 "$TEMPLATES_DIR/$app/description.txt")
        else
            desc="无描述"
        fi
        apps_menu+=("$app" "$desc")
    done

    # 显示应用选择菜单
    whiptail --title "应用浏览器" \
             --menu "选择要安装的应用" 20 70 10 \
             "${apps_menu[@]}" 3>&1 1>&2 2>&3
}

# 添加进度显示
show_enhanced_progress() {
    local message="$1"
    {
        for i in {1..100}; do
            echo $i
            sleep 0.1
        done
    } | whiptail --gauge "$message" 6 60 0
} 